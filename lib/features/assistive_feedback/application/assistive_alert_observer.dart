import 'package:eyes_mobile/features/assistive_feedback/domain/assistive_alert_message.dart';
import 'package:eyes_mobile/features/proximity/domain/proximity_models.dart';

/// Optional observation point for privacy-safe diagnostics and calibration.
///
/// Implementations must never retain frames, pixels or native error payloads.
abstract interface class AssistiveAlertObserver {
  void onAlertQueued(ProximityAlertEvent event, AssistiveAlertMessage message);
}

final class NoopAssistiveAlertObserver implements AssistiveAlertObserver {
  const NoopAssistiveAlertObserver();

  @override
  void onAlertQueued(
    ProximityAlertEvent event,
    AssistiveAlertMessage message,
  ) {}
}
