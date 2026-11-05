import 'package:eyes_mobile/features/account/application/scan_metadata_sync.dart';
import 'package:eyes_mobile/features/assistive_feedback/application/assistive_alert_observer.dart';
import 'package:eyes_mobile/features/assistive_feedback/domain/assistive_alert_message.dart';
import 'package:eyes_mobile/features/proximity/domain/proximity_models.dart';

final class ScanMetadataAlertObserver
    implements AssistiveAlertObserver, AssistivePlaybackObserver {
  const ScanMetadataAlertObserver(
    this.sync,
    this.calibration, {
    this.diagnostics,
  });
  final ScanMetadataSync sync;
  final AssistiveAlertObserver calibration;
  final AssistiveAlertObserver? diagnostics;

  @override
  void onAlertQueued(ProximityAlertEvent event, AssistiveAlertMessage message) {
    calibration.onAlertQueued(event, message);
    sync.onAlertQueued(event, message);
    diagnostics?.onAlertQueued(event, message);
  }

  @override
  void onPlaybackRequested(AssistiveAlertMessage message) =>
      sync.onPlaybackRequested(message);
}
