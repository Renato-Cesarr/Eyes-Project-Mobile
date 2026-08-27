import 'package:eyes_mobile/features/assistive_feedback/application/speech_gateway.dart';
import 'package:flutter_tts/flutter_tts.dart';

final class FlutterTtsSpeechGateway implements SpeechGateway {
  FlutterTtsSpeechGateway({FlutterTts? tts}) : _tts = tts ?? FlutterTts();

  final FlutterTts _tts;
  bool _initialized = false;

  @override
  Future<void> configure(SpeechConfiguration configuration) async {
    if (!_initialized) {
      _ensureSuccess(
        await _tts.setLanguage('pt-BR'),
        'idioma pt-BR indisponível',
      );
      await _tts.awaitSpeakCompletion(true);
      _initialized = true;
    }
    _ensureSuccess(
      await _tts.setSpeechRate(configuration.rate),
      'velocidade de voz indisponível',
    );
    _ensureSuccess(
      await _tts.setVolume(configuration.volume),
      'volume de voz indisponível',
    );
    _ensureSuccess(await _tts.setPitch(1), 'tom de voz indisponível');
  }

  @override
  Future<void> speak(String message) async {
    _ensureSuccess(await _tts.speak(message), 'síntese de voz indisponível');
  }

  @override
  Future<void> stop() async {
    _ensureSuccess(await _tts.stop(), 'não foi possível interromper a voz');
  }

  @override
  Future<void> dispose() => stop();

  void _ensureSuccess(Object? result, String message) {
    if (result is int && result != 1) {
      throw SpeechGatewayException(message);
    }
  }
}

final class SpeechGatewayException implements Exception {
  const SpeechGatewayException(this.message);

  final String message;

  @override
  String toString() => 'SpeechGatewayException: $message';
}
