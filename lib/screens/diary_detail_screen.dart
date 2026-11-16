import 'package:flutter/material.dart';

import '../data/database_helper.dart';
import '../models/meal_entry.dart';
import '../services/map_service.dart';
import '../widgets/meal_thumb.dart';

class DiaryDetailScreen extends StatelessWidget {
  final MealEntry entry;

  const DiaryDetailScreen({super.key, required this.entry});

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} '
          '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  Future<void> _openMap(BuildContext context) async {
    final opened = await MapService().openCoordinates(
      entry.latitude!,
      entry.longitude!,
    );
    if (opened || !context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No se pudo abrir el mapa en este dispositivo.')),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar entrada'),
        content: Text('¿Seguro que quieres eliminar "${entry.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm != true || entry.id == null) return;

    try {
      await DatabaseHelper.instance.delete(entry.id!);
      if (!context.mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo eliminar: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(entry.title),
        actions: [
          IconButton(
            tooltip: 'Eliminar',
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(child: MealThumb(entry: entry, size: 240)),
          const SizedBox(height: 16),
          Text(entry.title, style: textTheme.headlineSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              Chip(
                avatar: Icon(iconForMealType(entry.mealType), size: 18),
                label: Text(entry.mealType),
              ),
              Chip(
                avatar: const Icon(Icons.schedule, size: 18),
                label: Text(_formatDate(entry.createdAt)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            entry.notes.isEmpty ? 'Sin notas.' : entry.notes,
            style: textTheme.bodyLarge,
          ),
          if (entry.hasLocation) ...[
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.place_outlined),
              title: Text(
                '${entry.latitude!.toStringAsFixed(5)}, '
                    '${entry.longitude!.toStringAsFixed(5)}',
              ),
              subtitle: const Text('Ubicación guardada'),
            ),
            const SizedBox(height: 8),
            FilledButton.tonalIcon(
              onPressed: () => _openMap(context),
              icon: const Icon(Icons.map_outlined),
              label: const Text('Ver en Google Maps'),
            ),
          ],
        ],
      ),
    );
  }
}