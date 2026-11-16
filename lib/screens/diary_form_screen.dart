import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart' show ImageSource;

import '../data/database_helper.dart';
import '../models/meal_entry.dart';
import '../services/location_service.dart';
import '../services/media_service.dart';
import '../services/speech_service.dart';
import '../widgets/app_drawer.dart';

enum _LocationChoice { retry, saveWithout, cancel }

class DiaryFormScreen extends StatefulWidget {
  const DiaryFormScreen({super.key});

  @override
  State<DiaryFormScreen> createState() => _DiaryFormScreenState();
}

class _DiaryFormScreenState extends State<DiaryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  final _media = MediaService();
  final _location = LocationService();
  final _speech = SpeechService();

  String _mealType = AppDrawer.mealTypes.first;
  String? _imagePath;
  bool _saveLocation = true;
  bool _saving = false;
  bool _listening = false;
  String _notesBeforeDictation = '';
  String _statusText = 'Guardando...';

  @override
  void dispose() {
    _speech.cancel();
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }


  Future<void> _showSourceSheet() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Tomar foto'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Elegir de la galería'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source != null) await _pickImage(source);
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final path = await _media.pickImage(source);
      if (path == null || !mounted) return;
      setState(() => _imagePath = path);
    } on MediaPermissionException catch (e) {
      if (!mounted) return;
      _showMessage(e.message);
    } catch (e) {
      if (!mounted) return;
      _showMessage('No se pudo obtener la imagen: $e');
    }
  }

  void _removeImage() {
    final path = _imagePath;
    setState(() => _imagePath = null);
    if (path != null) _media.deleteImage(path);
  }


  Future<void> _toggleDictation() async {
    if (_listening) {
      await _speech.stopListening();
      if (mounted) setState(() => _listening = false);
      return;
    }

    _notesBeforeDictation = _notesController.text.trim();

    try {
      await _speech.startListening(
        onResult: (text, isFinal) {
          if (!mounted) return;
          final joined = _notesBeforeDictation.isEmpty
              ? text
              : '$_notesBeforeDictation $text';
          setState(() {
            _notesController.text = joined;
            _notesController.selection =
                TextSelection.collapsed(offset: joined.length);
          });
        },
        onError: (message) {
          if (!mounted) return;
          setState(() => _listening = false);
          _showMessage(message);
        },
        onDone: () {
          if (!mounted) return;
          setState(() => _listening = false);
        },
      );
      if (mounted) setState(() => _listening = true);
    } on SpeechException catch (e) {
      if (!mounted) return;
      setState(() => _listening = false);
      _showMessage(e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _listening = false);
      _showMessage('No se pudo iniciar el dictado: $e');
    }
  }


  Future<_LocationChoice?> _askLocationChoice(LocationException e) {
    return showDialog<_LocationChoice>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Ubicación no disponible'),
        content: Text(e.message),
        actions: [
          if (e.permanentlyDenied)
            TextButton(
              onPressed: () async {
                await _location.openAppSettings();
                if (ctx.mounted) Navigator.pop(ctx, _LocationChoice.cancel);
              },
              child: const Text('Abrir ajustes'),
            ),
          if (e.serviceDisabled)
            TextButton(
              onPressed: () async {
                await _location.openLocationSettings();
                if (ctx.mounted) Navigator.pop(ctx, _LocationChoice.cancel);
              },
              child: const Text('Activar GPS'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, _LocationChoice.saveWithout),
            child: const Text('Guardar sin ubicación'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, _LocationChoice.retry),
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Future<Coordinates?> _captureLocation() async {
    while (true) {
      try {
        return await _location.getCurrentCoordinates();
      } on LocationException catch (e) {
        if (!mounted) throw _Cancelled();
        final choice = await _askLocationChoice(e);
        if (!mounted) throw _Cancelled();
        if (choice == _LocationChoice.retry) continue;
        if (choice == _LocationChoice.saveWithout) return null;
        throw _Cancelled();
      }
    }
  }


  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _statusText = 'Guardando...';
    });

    try {
      Coordinates? coords;
      if (_saveLocation) {
        setState(() => _statusText = 'Obteniendo ubicación...');
        coords = await _captureLocation();
        if (!mounted) return;
        setState(() => _statusText = 'Guardando...');
      }

      final entry = MealEntry(
        title: _titleController.text.trim(),
        mealType: _mealType,
        notes: _notesController.text.trim(),
        imagePath: _imagePath,
        latitude: coords?.latitude,
        longitude: coords?.longitude,
        createdAt: DateTime.now(),
      );
      await DatabaseHelper.instance.insert(entry);
      if (!mounted) return;
      Navigator.pop(context, true);
    } on _Cancelled {
      if (!mounted) return;
      setState(() => _saving = false);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _showMessage('No se pudo guardar: $e');
    }
  }


  Widget _buildPhotoPicker() {
    final scheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: _showSourceSheet,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 200,
          width: double.infinity,
          color: scheme.surfaceContainerHighest,
          child: _imagePath == null
              ? const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_a_photo_outlined, size: 40),
              SizedBox(height: 8),
              Text('Agregar foto'),
            ],
          )
              : Stack(
            fit: StackFit.expand,
            children: [
              Image.file(File(_imagePath!), fit: BoxFit.cover),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton.filledTonal(
                  tooltip: 'Quitar foto',
                  onPressed: _removeImage,
                  icon: const Icon(Icons.close),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nueva entrada')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildPhotoPicker(),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Platillo',
                hintText: 'Ej. Tacos de cochinita',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.sentences,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Escribe el nombre del platillo'
                  : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _mealType,
              decoration: const InputDecoration(
                labelText: 'Tipo de comida',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final t in AppDrawer.mealTypes)
                  DropdownMenuItem(value: t, child: Text(t)),
              ],
              onChanged: (v) => setState(() => _mealType = v ?? _mealType),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: InputDecoration(
                labelText: 'Notas',
                alignLabelWithHint: true,
                border: const OutlineInputBorder(),
                helperText: _listening
                    ? 'Escuchando... habla ahora (toca el micrófono para terminar)'
                    : 'Escribe o toca el micrófono para dictar',
                suffixIcon: IconButton(
                  tooltip: _listening ? 'Detener dictado' : 'Dictar notas',
                  onPressed: _saving ? null : _toggleDictation,
                  icon: Icon(
                    _listening ? Icons.stop_circle : Icons.mic,
                    color: _listening ? Colors.red : null,
                  ),
                ),
              ),
              minLines: 4,
              maxLines: 8,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(Icons.place_outlined),
              title: const Text('Guardar mi ubicación'),
              subtitle: const Text('Se captura con el GPS al guardar'),
              value: _saveLocation,
              onChanged: _saving ? null : (v) => setState(() => _saveLocation = v),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : const Icon(Icons.save),
              label: Text(_saving ? _statusText : 'Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Cancelled implements Exception {}