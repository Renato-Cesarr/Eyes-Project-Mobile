import 'package:eyes_mobile/features/assistive_feedback/domain/assistive_alert_message.dart';
import 'package:eyes_mobile/features/assistive_feedback/domain/feedback_preferences.dart';
import 'package:eyes_mobile/features/object_detection/domain/detected_object.dart';
import 'package:eyes_mobile/features/proximity/domain/proximity_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('compõe frase curta determinística por classe, faixa e direção', () {
    final message = AssistiveAlertMessageComposer.compose(
      _event(),
      VoiceDetailLevel.concise,
    );

    expect(message.text, 'Cadeira muito próxima, à esquerda. Cuidado.');
    expect(message.deduplicationKey, 'chair:veryNear:left');
    expect(message.isCritical, isTrue);
  });

  test('nível detalhado acrescenta orientação sem jargão técnico', () {
    final message = AssistiveAlertMessageComposer.compose(
      _event(direction: ProximityDirection.ahead),
      VoiceDetailLevel.detailed,
    );

    expect(
      message.text,
      'Cadeira muito próxima, à frente. Cuidado, reduza o passo.',
    );
    expect(message.text, isNot(contains(RegExp('tensor|threshold|score'))));
  });
}

ProximityAlertEvent _event({
  ProximityDirection direction = ProximityDirection.left,
}) {
  return ProximityAlertEvent(
    trackId: 1,
    kind: DetectedObjectKind.chair,
    band: ProximityBand.veryNear,
    direction: direction,
    score: 0.92,
    priority: 210,
    occurredAt: DateTime.utc(2026),
  );
}
