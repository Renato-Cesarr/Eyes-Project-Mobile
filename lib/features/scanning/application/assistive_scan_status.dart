import 'package:eyes_mobile/features/object_detection/application/vision_runtime_state.dart';
import 'package:eyes_mobile/features/scanning/domain/camera_scan_status.dart';
import 'package:eyes_mobile/features/scanning/domain/camera_session_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AssistiveScanPhase {
  loadingModel,
  ready,
  requestingPermission,
  preparingCamera,
  scanning,
  paused,
  ended,
  unavailable,
}

final class AssistiveScanStatus {
  const AssistiveScanStatus(this.phase);

  final AssistiveScanPhase phase;

  bool get isScanning => phase == AssistiveScanPhase.scanning;

  bool get isPending => switch (phase) {
    AssistiveScanPhase.loadingModel ||
    AssistiveScanPhase.requestingPermission ||
    AssistiveScanPhase.preparingCamera => true,
    _ => false,
  };

  static AssistiveScanStatus resolve(
    CameraSessionState camera,
    AsyncValue<VisionRuntimeState> vision,
  ) {
    if (vision.hasError) {
      return const AssistiveScanStatus(AssistiveScanPhase.unavailable);
    }
    if (camera.status == CameraScanStatus.ended) {
      return const AssistiveScanStatus(AssistiveScanPhase.ended);
    }
    if (vision.isLoading ||
        vision.asData?.value.status == VisionRuntimeStatus.recovering) {
      return const AssistiveScanStatus(AssistiveScanPhase.loadingModel);
    }

    return AssistiveScanStatus(switch (camera.status) {
      CameraScanStatus.idle => AssistiveScanPhase.ready,
      CameraScanStatus.requestingPermission =>
        AssistiveScanPhase.requestingPermission,
      CameraScanStatus.preparing => AssistiveScanPhase.preparingCamera,
      CameraScanStatus.streaming => AssistiveScanPhase.scanning,
      CameraScanStatus.paused => AssistiveScanPhase.paused,
      CameraScanStatus.ended => AssistiveScanPhase.ended,
      CameraScanStatus.denied ||
      CameraScanStatus.permanentlyDenied ||
      CameraScanStatus.busy ||
      CameraScanStatus.unavailable => AssistiveScanPhase.unavailable,
    });
  }
}
