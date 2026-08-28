import 'package:eyes_mobile/features/object_detection/application/vision_runtime_state.dart';
import 'package:eyes_mobile/features/scanning/application/assistive_scan_status.dart';
import 'package:eyes_mobile/features/scanning/domain/camera_scan_status.dart';
import 'package:eyes_mobile/features/scanning/domain/camera_session_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const readyVision = AsyncData<VisionRuntimeState>(VisionRuntimeState.ready());

  test('maps the complete camera lifecycle to stable product phases', () {
    const expectations = <CameraScanStatus, AssistiveScanPhase>{
      CameraScanStatus.idle: AssistiveScanPhase.ready,
      CameraScanStatus.requestingPermission:
          AssistiveScanPhase.requestingPermission,
      CameraScanStatus.preparing: AssistiveScanPhase.preparingCamera,
      CameraScanStatus.streaming: AssistiveScanPhase.scanning,
      CameraScanStatus.paused: AssistiveScanPhase.paused,
      CameraScanStatus.ended: AssistiveScanPhase.ended,
      CameraScanStatus.denied: AssistiveScanPhase.unavailable,
      CameraScanStatus.permanentlyDenied: AssistiveScanPhase.unavailable,
      CameraScanStatus.busy: AssistiveScanPhase.unavailable,
      CameraScanStatus.unavailable: AssistiveScanPhase.unavailable,
    };

    for (final entry in expectations.entries) {
      final status = AssistiveScanStatus.resolve(
        CameraSessionState(status: entry.key),
        readyVision,
      );
      expect(status.phase, entry.value, reason: entry.key.name);
    }
  });

  test('model loading and failure take precedence over camera readiness', () {
    final loading = AssistiveScanStatus.resolve(
      const CameraSessionState(status: CameraScanStatus.streaming),
      const AsyncLoading<VisionRuntimeState>(),
    );
    final failed = AssistiveScanStatus.resolve(
      const CameraSessionState(status: CameraScanStatus.streaming),
      AsyncError<VisionRuntimeState>(StateError('failed'), StackTrace.empty),
    );

    expect(loading.phase, AssistiveScanPhase.loadingModel);
    expect(failed.phase, AssistiveScanPhase.unavailable);
  });

  test('ended is stable even after the model runtime is released', () {
    final status = AssistiveScanStatus.resolve(
      const CameraSessionState(status: CameraScanStatus.ended),
      const AsyncData<VisionRuntimeState>(VisionRuntimeState.paused()),
    );

    expect(status.phase, AssistiveScanPhase.ended);
    expect(status.isScanning, isFalse);
    expect(status.isPending, isFalse);
  });
}
