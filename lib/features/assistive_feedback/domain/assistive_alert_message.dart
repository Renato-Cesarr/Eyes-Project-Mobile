import 'package:eyes_mobile/features/assistive_feedback/domain/feedback_preferences.dart';
import 'package:eyes_mobile/features/object_detection/domain/detected_object.dart';
import 'package:eyes_mobile/features/proximity/domain/proximity_models.dart';

final class AssistiveAlertMessage {
  const AssistiveAlertMessage({
    required this.text,
    required this.deduplicationKey,
    required this.priority,
    required this.isCritical,
  });

  final String text;
  final String deduplicationKey;
  final double priority;
  final bool isCritical;
}

abstract final class AssistiveAlertMessageComposer {
  static AssistiveAlertMessage compose(
    ProximityAlertEvent event,
    VoiceDetailLevel detailLevel,
  ) {
    final object = _objectName(event.kind);
    final direction = _direction(event.direction);
    final distance = event.band == ProximityBand.veryNear
        ? 'muito próxima'
        : 'próxima';
    final suffix = detailLevel == VoiceDetailLevel.detailed
        ? event.isCritical
              ? ' Cuidado, reduza o passo.'
              : ' Continue com atenção.'
        : event.isCritical
        ? ' Cuidado.'
        : '';
    return AssistiveAlertMessage(
      text: '$object $distance, $direction.$suffix',
      deduplicationKey:
          '${event.kind.name}:${event.band.name}:${event.direction.name}',
      priority: event.priority,
      isCritical: event.isCritical,
    );
  }

  static String _objectName(DetectedObjectKind kind) => switch (kind) {
    DetectedObjectKind.person => 'Pessoa',
    DetectedObjectKind.chair => 'Cadeira',
    DetectedObjectKind.table => 'Mesa',
    DetectedObjectKind.backpack => 'Mochila',
  };

  static String _direction(ProximityDirection direction) => switch (direction) {
    ProximityDirection.left => 'à esquerda',
    ProximityDirection.ahead => 'à frente',
    ProximityDirection.right => 'à direita',
  };
}
