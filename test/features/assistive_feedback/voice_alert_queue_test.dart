import 'dart:async';

import 'package:eyes_mobile/features/assistive_feedback/application/speech_gateway.dart';
import 'package:eyes_mobile/features/assistive_feedback/application/voice_alert_queue.dart';
import 'package:eyes_mobile/features/assistive_feedback/domain/assistive_alert_message.dart';
import 'package:flutter_test/flutter_test.dart';

final class _ControlledSpeechGateway implements SpeechGateway {
  final List<String> spoken = [];
  Completer<void>? active;
  int stops = 0;

  @override
  Future<void> configure(SpeechConfiguration configuration) async {}

  @override
  Future<void> speak(String message) {
    spoken.add(message);
    active = Completer<void>();
    return active!.future;
  }

  @override
  Future<void> stop() async {
    stops++;
    if (active case final completer? when !completer.isCompleted) {
      completer.complete();
    }
  }

  @override
  Future<void> dispose() => stop();

  void completeSpeech() {
    if (active case final completer? when !completer.isCompleted) {
      completer.complete();
    }
  }
}

void main() {
  test('deduplica o mesmo alerta durante cooldown', () async {
    final gateway = _ControlledSpeechGateway();
    var now = DateTime.utc(2026);
    final queue = VoiceAlertQueue(gateway, clock: () => now);
    addTearDown(queue.dispose);

    queue.enqueue(_message('Cadeira próxima', key: 'chair'));
    gateway.completeSpeech();
    await queue.idle;
    queue.enqueue(_message('Cadeira próxima', key: 'chair'));
    await Future<void>.delayed(Duration.zero);

    expect(gateway.spoken, ['Cadeira próxima']);
    now = now.add(const Duration(seconds: 5));
    queue.enqueue(_message('Cadeira próxima', key: 'chair'));
    gateway.completeSpeech();
    await queue.idle;
    expect(gateway.spoken, hasLength(2));
  });

  test(
    'alerta crítico interrompe fala informativa e assume prioridade',
    () async {
      final gateway = _ControlledSpeechGateway();
      final queue = VoiceAlertQueue(gateway);
      addTearDown(queue.dispose);

      queue.enqueue(_message('Mochila próxima', key: 'info'));
      await Future<void>.delayed(Duration.zero);
      queue.enqueue(
        _message('Cadeira muito próxima', key: 'critical', critical: true),
      );
      await Future<void>.delayed(Duration.zero);

      expect(gateway.stops, 1);
      expect(gateway.spoken, ['Mochila próxima', 'Cadeira muito próxima']);
      gateway.completeSpeech();
      await queue.idle;
    },
  );

  test('limita backlog e mantém os alertas de maior prioridade', () async {
    final gateway = _ControlledSpeechGateway();
    final queue = VoiceAlertQueue(gateway, maximumPending: 2);
    addTearDown(queue.dispose);

    queue.enqueue(_message('em curso', key: 'current', priority: 1));
    await Future<void>.delayed(Duration.zero);
    queue
      ..enqueue(_message('baixo', key: 'low', priority: 2))
      ..enqueue(_message('alto', key: 'high', priority: 20))
      ..enqueue(_message('médio', key: 'medium', priority: 10));

    expect(queue.pendingCount, 2);
    gateway.completeSpeech();
    await Future<void>.delayed(Duration.zero);
    expect(gateway.spoken.last, 'alto');
    gateway.completeSpeech();
    await Future<void>.delayed(Duration.zero);
    expect(gateway.spoken.last, 'médio');
    gateway.completeSpeech();
    await queue.idle;
    expect(gateway.spoken, isNot(contains('baixo')));
  });
}

AssistiveAlertMessage _message(
  String text, {
  required String key,
  double priority = 100,
  bool critical = false,
}) {
  return AssistiveAlertMessage(
    text: text,
    deduplicationKey: key,
    priority: priority,
    isCritical: critical,
  );
}
