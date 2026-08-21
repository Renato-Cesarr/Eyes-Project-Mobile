import 'package:eyes_mobile/features/proximity/domain/proximity_models.dart';

final class ProximityState {
  ProximityState({
    this.latestEvaluation,
    this.lastAlert,
    List<ProximityAlertEvent> recentEvents = const [],
    this.processedFrames = 0,
  }) : recentEvents = List<ProximityAlertEvent>.unmodifiable(recentEvents);

  final ProximityEvaluation? latestEvaluation;
  final ProximityAlertEvent? lastAlert;
  final List<ProximityAlertEvent> recentEvents;
  final int processedFrames;
}
