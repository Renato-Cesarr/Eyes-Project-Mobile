import 'package:eyes_mobile/features/proximity/domain/proximity_models.dart';

final class ProximityState {
  ProximityState({
    this.latestEvaluation,
    this.lastAlert,
    List<ProximityAlertEvent> recentEvents = const [],
    this.processedFrames = 0,
  }) : recentEvents = List<ProximityAlertEvent>.unmodifiable(recentEvents);

  final ProximityEvaluation? latestEvaluation;

  /// Most recent announcement while its track remains relevant to the view.
  final ProximityAlertEvent? lastAlert;
  final List<ProximityAlertEvent> recentEvents;
  final int processedFrames;
}
