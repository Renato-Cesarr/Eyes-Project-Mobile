import 'package:eyes_mobile/core/recovery/operational_failure.dart';
import 'package:eyes_mobile/features/assistive_feedback/application/assistive_feedback_state.dart';
import 'package:eyes_mobile/features/object_detection/application/vision_worker.dart';
import 'package:eyes_mobile/features/scanning/domain/camera_failure.dart';

abstract final class ScanFailurePolicy {
  static OperationalFailure fromCamera(CameraFailure failure) {
    final kind = switch (failure.reason) {
      CameraFailureReason.permissionDenied =>
        OperationalFailureKind.cameraPermissionDenied,
      CameraFailureReason.permissionPermanentlyDenied =>
        OperationalFailureKind.cameraPermissionPermanentlyDenied,
      CameraFailureReason.permissionRestricted =>
        OperationalFailureKind.cameraRestricted,
      CameraFailureReason.cameraBusy => OperationalFailureKind.cameraBusy,
      CameraFailureReason.noCamera => OperationalFailureKind.cameraMissing,
      CameraFailureReason.initializationTimeout =>
        OperationalFailureKind.cameraStartupTimeout,
      CameraFailureReason.initializationFailed =>
        OperationalFailureKind.cameraInitialization,
      CameraFailureReason.streamFailed => OperationalFailureKind.cameraStream,
    };

    return OperationalFailure(
      kind: kind,
      impact: OperationalFailureImpact.blocking,
      primaryAction:
          failure.reason == CameraFailureReason.permissionPermanentlyDenied
          ? OperationalRecoveryAction.openDeviceSettings
          : _cameraCanRetry(failure.reason)
          ? OperationalRecoveryAction.retry
          : OperationalRecoveryAction.returnToSafety,
      secondaryAction:
          failure.reason == CameraFailureReason.permissionPermanentlyDenied ||
              _cameraCanRetry(failure.reason)
          ? OperationalRecoveryAction.returnToSafety
          : null,
      diagnosticCode: failure.technicalCode,
    );
  }

  static OperationalFailure fromVision(Object error) {
    if (error is! VisionWorkerException) {
      return const OperationalFailure(
        kind: OperationalFailureKind.unexpected,
        impact: OperationalFailureImpact.blocking,
        primaryAction: OperationalRecoveryAction.retry,
        secondaryAction: OperationalRecoveryAction.returnToSafety,
      );
    }

    final kind = switch (error.reason) {
      VisionWorkerFailureReason.startupTimeout =>
        OperationalFailureKind.modelStartupTimeout,
      VisionWorkerFailureReason.initialization => _modelInitializationKind(
        error.technicalCode,
      ),
      VisionWorkerFailureReason.disposeTimeout ||
      VisionWorkerFailureReason.isolateCrashed ||
      VisionWorkerFailureReason.requestTimeout ||
      VisionWorkerFailureReason.inference ||
      VisionWorkerFailureReason.invalidFrame ||
      VisionWorkerFailureReason.notReady ||
      VisionWorkerFailureReason.busy => OperationalFailureKind.modelRuntime,
    };

    return OperationalFailure(
      kind: kind,
      impact: OperationalFailureImpact.blocking,
      primaryAction: OperationalRecoveryAction.retry,
      secondaryAction: OperationalRecoveryAction.returnToSafety,
      diagnosticCode: error.technicalCode,
    );
  }

  static OperationalFailure? fromFeedbackNotice(FeedbackNotice notice) {
    final kind = switch (notice) {
      FeedbackNotice.speechUnavailable =>
        OperationalFailureKind.speechUnavailable,
      FeedbackNotice.hapticsUnavailable =>
        OperationalFailureKind.hapticsUnavailable,
      FeedbackNotice.persistenceFailed =>
        OperationalFailureKind.preferencesUnavailable,
      FeedbackNotice.none ||
      FeedbackNotice.preferencesSaved ||
      FeedbackNotice.defaultsRestored ||
      FeedbackNotice.voiceTestSucceeded ||
      FeedbackNotice.hapticTestSucceeded => null,
    };
    if (kind == null) {
      return null;
    }
    return OperationalFailure(
      kind: kind,
      impact: OperationalFailureImpact.degraded,
      primaryAction: OperationalRecoveryAction.openFeedbackSettings,
    );
  }

  static bool _cameraCanRetry(CameraFailureReason reason) => switch (reason) {
    CameraFailureReason.permissionDenied ||
    CameraFailureReason.cameraBusy ||
    CameraFailureReason.initializationTimeout ||
    CameraFailureReason.initializationFailed ||
    CameraFailureReason.streamFailed => true,
    CameraFailureReason.permissionPermanentlyDenied ||
    CameraFailureReason.permissionRestricted ||
    CameraFailureReason.noCamera => false,
  };

  static OperationalFailureKind _modelInitializationKind(String? code) {
    final normalized = code?.toLowerCase() ?? '';
    if (_containsAny(normalized, const [
      'asset',
      'manifest',
      'hash',
      'tensor',
      'contract',
      'model',
    ])) {
      return OperationalFailureKind.modelInvalidAsset;
    }
    if (_containsAny(normalized, const ['memory', 'allocation', 'alloc'])) {
      return OperationalFailureKind.modelOutOfMemory;
    }
    if (normalized.contains('delegate')) {
      return OperationalFailureKind.modelDelegateUnavailable;
    }
    return OperationalFailureKind.modelRuntime;
  }

  static bool _containsAny(String value, List<String> candidates) =>
      candidates.any(value.contains);
}
