import 'package:eyes_mobile/features/assistive_feedback/application/speech_gateway.dart';
import 'package:flutter_tts/flutter_tts.dart';

typedef SpeechPlaybackStarted =
    void Function(String message, DateTime startedAt);
typedef SpeechClock = DateTime Function();

final class FlutterTtsSpeechGateway implements SpeechGateway {
  FlutterTtsSpeechGateway({
    FlutterTts? tts,
    this.onPlaybackStarted,
    SpeechClock? clock,
  }) : _tts = tts ?? FlutterTts(),
       _clock = clock ?? DateTime.now;

  final FlutterTts _tts;
  final SpeechPlaybackStarted? onPlaybackStarted;
  final SpeechClock _clock;
  bool _initialized = false;
  String? _activeMessage;

  @override
  Future<void> configure(SpeechConfiguration configuration) async {
    if (!_initialized) {
      _ensureSuccess(
        await _tts.setLanguage('pt-BR'),
        'idioma pt-BR indisponível',
      );
      await _tts.awaitSpeakCompletion(true);
      _tts.setStartHandler(_handlePlaybackStarted);
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
    _activeMessage = message;
    try {
      final result = await _tts.speak(message);
      if (result is int && result == 0) {
        // flutter_tts returns zero when an awaited utterance is intentionally
        // stopped. This is cancellation, not proof that the engine is missing.
        throw const SpeechPlaybackInterruptedException();
      }
      _ensureSuccess(result, 'síntese de voz indisponível');
    } finally {
      if (_activeMessage == message) {
        _activeMessage = null;
      }
    }
  }

  @override
  Future<void> stop() async {
    _ensureSuccess(await _tts.stop(), 'não foi possível interromper a voz');
  }

  @override
  Future<void> dispose() => stop();

  void _handlePlaybackStarted() {
    final message = _activeMessage;
    if (message == null) {
      return;
    }
    onPlaybackStarted?.call(message, _clock());
  }

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
