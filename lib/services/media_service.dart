import 'dart:io';

import 'package:flutter/services.dart' show PlatformException;
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class MediaPermissionException implements Exception {
  final String message;
  MediaPermissionException(this.message);

  @override
  String toString() => 'MediaPermissionException: $message';
}

class MediaService {
  final ImagePicker _picker;

  MediaService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  Future<String?> pickImage(ImageSource source) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 85,
      );
      if (picked == null) return null;

      final docsDir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory(p.join(docsDir.path, 'meal_images'));
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }

      final fileName =
          'meal_${DateTime.now().millisecondsSinceEpoch}${p.extension(picked.path)}';
      final saved = await File(picked.path).copy(p.join(imagesDir.path, fileName));
      return saved.path;
    } on PlatformException catch (e) {
      if (e.code == 'camera_access_denied') {
        throw MediaPermissionException(
          'Permiso de cámara denegado. Actívalo en Ajustes del teléfono para tomar fotos.',
        );
      }
      if (e.code == 'photo_access_denied') {
        throw MediaPermissionException(
          'Permiso de galería denegado. Actívalo en Ajustes del teléfono para elegir fotos.',
        );
      }
      rethrow;
    }
  }

  Future<void> deleteImage(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }
}