import 'dart:async';

import 'package:geolocator/geolocator.dart';

class Coordinates {
  final double latitude;
  final double longitude;

  const Coordinates(this.latitude, this.longitude);
}

class LocationException implements Exception {
  final String message;

  final bool serviceDisabled;

  final bool permanentlyDenied;

  LocationException(
      this.message, {
        this.serviceDisabled = false,
        this.permanentlyDenied = false,
      });

  @override
  String toString() => 'LocationException: $message';
}


class LocationService {
  static const Duration _timeout = Duration(seconds: 15);

  Future<Coordinates> getCurrentCoordinates() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw LocationException(
        'El GPS del teléfono está desactivado. Actívalo para guardar la ubicación.',
        serviceDisabled: true,
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw LocationException('Permiso de ubicación denegado.');
    }
    if (permission == LocationPermission.deniedForever) {
      throw LocationException(
        'El permiso de ubicación está bloqueado. Actívalo en Ajustes de la app.',
        permanentlyDenied: true,
      );
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: _timeout,
        ),
      );
      return Coordinates(position.latitude, position.longitude);
    } on TimeoutException {
      throw LocationException(
        'No se pudo obtener la ubicación a tiempo. Revisa tu señal de GPS.',
      );
    } catch (e) {
      throw LocationException('No se pudo obtener la ubicación: $e');
    }
  }

  Future<void> openAppSettings() => Geolocator.openAppSettings();

  Future<void> openLocationSettings() => Geolocator.openLocationSettings();
}