import 'package:speech_to_text/speech_to_text.dart';

class SpeechException implements Exception {
  final String message;

  final bool permissionDenied;

  SpeechException(this.message, {this.permissionDenied = false});

  @override
  String toString() => 'SpeechException: $message';
}

class SpeechService {
  final SpeechToText _speech = SpeechToText();

  bool _initialized = false;
  String? _localeId;

  void Function(String message)? _onError;
  void Function()? _onDone;

  bool get isListening => _speech.isListening;

  Future<void> startListening({
    required void Function(String text, bool isFinal) onResult,
    required void Function(String message) onError,
    required void Function() onDone,
  }) async {
    _onError = onError;
    _onDone = onDone;

    if (!_initialized) {
      bool available;
      try {
        available = await _speech.initialize(
          onError: (error) => _onError?.call(_friendlyError(error.errorMsg)),
          onStatus: (status) {
            if (status == 'done' || status == 'notListening') _onDone?.call();
          },
        );
      } catch (e) {
        throw SpeechException('No se pudo iniciar el dictado: $e');
      }

      if (!available) {
        final hasPermission = await _speech.hasPermission;
        if (!hasPermission) {
          throw SpeechException(
            'Permiso de micrófono denegado. Actívalo en Ajustes para dictar tus notas.',
            permissionDenied: true,
          );
        }
        throw SpeechException(
          'El reconocimiento de voz no está disponible en este dispositivo.',
        );
      }

      _initialized = true;
      _localeId = await _pickSpanishLocale();
    }

    await _speech.listen(
      onResult: (result) => onResult(result.recognizedWords, result.finalResult),
      localeId: _localeId,
      listenFor: const Duration(seconds: 60),
      pauseFor: const Duration(seconds: 5),
      listenOptions: SpeechListenOptions(
        partialResults: true,
        listenMode: ListenMode.dictation,
        cancelOnError: true,
      ),
    );
  }

  Future<void> stopListening() => _speech.stop();

  Future<void> cancel() => _speech.cancel();

  Future<String?> _pickSpanishLocale() async {
    try {
      final locales = await _speech.locales();
      const preferred = ['es_MX', 'es-MX', 'es_ES', 'es-ES'];
      for (final id in preferred) {
        for (final locale in locales) {
          if (locale.localeId == id) return locale.localeId;
        }
      }
      for (final locale in locales) {
        if (locale.localeId.startsWith('es')) return locale.localeId;
      }
    } catch (_) {}
    return null;
  }

  String _friendlyError(String code) {
    if (code.contains('no_match') || code.contains('speech_timeout')) {
      return 'No se escuchó nada. Intenta de nuevo y habla más cerca del micrófono.';
    }
    if (code.contains('permission')) {
      return 'Permiso de micrófono denegado. Actívalo en Ajustes.';
    }
    if (code.contains('network')) {
      return 'Sin conexión: el dictado necesita internet en este dispositivo.';
    }
    return 'Error de dictado ($code).';
  }
}