import 'package:eyes_mobile/features/object_detection/domain/detected_object.dart';

enum ProximityBand { distant, attention, veryNear }

enum ProximityDirection { left, ahead, right }

final class ProximityObservation {
  const ProximityObservation({
    required this.trackId,
    required this.kind,
    required this.band,
    required this.direction,
    required this.score,
    required this.centrality,
    required this.persistenceFrames,
    required this.boundingBox,
  });

  final int trackId;
  final DetectedObjectKind kind;
  final ProximityBand band;
  final ProximityDirection direction;
  final double score;
  final double centrality;
  final int persistenceFrames;
  final NormalizedBoundingBox boundingBox;
}

/// Privacy-safe event produced only when an alert passes stabilization,
/// prioritization and cooldown. It deliberately contains no image or pixels.
final class ProximityAlertEvent {
  const ProximityAlertEvent({
    required this.trackId,
    required this.kind,
    required this.band,
    required this.direction,
    required this.score,
    required this.priority,
    required this.occurredAt,
  });

  final int trackId;
  final DetectedObjectKind kind;
  final ProximityBand band;
  final ProximityDirection direction;
  final double score;
  final double priority;
  final DateTime occurredAt;

  bool get isCritical => band == ProximityBand.veryNear;
}

final class ProximityEvaluation {
  ProximityEvaluation({
    required List<ProximityObservation> observations,
    required this.capturedAt,
    this.announcedEvent,
  }) : observations = List<ProximityObservation>.unmodifiable(observations);

  final List<ProximityObservation> observations;
  final DateTime capturedAt;
  final ProximityAlertEvent? announcedEvent;
}
