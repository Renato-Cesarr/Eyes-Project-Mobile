import 'package:eyes_mobile/core/recovery/operational_failure.dart';
import 'package:eyes_mobile/features/assistive_feedback/application/assistive_feedback_state.dart';
import 'package:eyes_mobile/features/object_detection/application/vision_worker.dart';
import 'package:eyes_mobile/features/scanning/application/scan_failure_policy.dart';
import 'package:eyes_mobile/features/scanning/domain/camera_failure.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('camera failure policy', () {
    test('permanent denial opens settings and offers a safe exit', () {
      final failure = ScanFailurePolicy.fromCamera(
        const CameraFailure(
          reason: CameraFailureReason.permissionPermanentlyDenied,
          technicalCode: 'native-permission-code',
        ),
      );

      expect(
        failure.kind,
        OperationalFailureKind.cameraPermissionPermanentlyDenied,
      );
      expect(
        failure.primaryAction,
        OperationalRecoveryAction.openDeviceSettings,
      );
      expect(failure.secondaryAction, OperationalRecoveryAction.returnToSafety);
      expect(failure.blocksAssistiveScan, isTrue);
      expect(failure.diagnosticCode, 'native-permission-code');
    });

    test('busy camera can be retried without hiding diagnostics', () {
      final failure = ScanFailurePolicy.fromCamera(
        const CameraFailure(
          reason: CameraFailureReason.cameraBusy,
          technicalCode: 'camera-in-use',
        ),
      );

      expect(failure.kind, OperationalFailureKind.cameraBusy);
      expect(failure.primaryAction, OperationalRecoveryAction.retry);
      expect(failure.blocksAssistiveScan, isTrue);
    });
  });

  group('vision failure policy', () {
    test('classifies timeout independently from runtime failures', () {
      final failure = ScanFailurePolicy.fromVision(
        const VisionWorkerException(
          VisionWorkerFailureReason.startupTimeout,
          'technical startup message',
          technicalCode: 'vision-start-timeout',
        ),
      );

      expect(failure.kind, OperationalFailureKind.modelStartupTimeout);
      expect(failure.primaryAction, OperationalRecoveryAction.retry);
      expect(failure.blocksAssistiveScan, isTrue);
    });

    test('classifies invalid asset without carrying its message to UI', () {
      final failure = ScanFailurePolicy.fromVision(
        const VisionWorkerException(
          VisionWorkerFailureReason.initialization,
          'sha256 expected secret-like-payload',
          technicalCode: 'model-manifest-hash-mismatch',
        ),
      );

      expect(failure.kind, OperationalFailureKind.modelInvalidAsset);
      expect(failure.diagnosticCode, 'model-manifest-hash-mismatch');
    });

    test('classifies allocation and delegate initialization failures', () {
      final allocation = ScanFailurePolicy.fromVision(
        const VisionWorkerException(
          VisionWorkerFailureReason.initialization,
          'allocation failed',
          technicalCode: 'interpreter-allocation-failed',
        ),
      );
      final delegate = ScanFailurePolicy.fromVision(
        const VisionWorkerException(
          VisionWorkerFailureReason.initialization,
          'delegate failed',
          technicalCode: 'gpu-delegate-unavailable',
        ),
      );

      expect(allocation.kind, OperationalFailureKind.modelOutOfMemory);
      expect(delegate.kind, OperationalFailureKind.modelDelegateUnavailable);
    });
  });

  group('degraded feedback policy', () {
    test('speech failure does not claim that scanning stopped', () {
      final failure = ScanFailurePolicy.fromFeedbackNotice(
        FeedbackNotice.speechUnavailable,
      );

      expect(failure, isNotNull);
      expect(failure!.kind, OperationalFailureKind.speechUnavailable);
      expect(failure.blocksAssistiveScan, isFalse);
      expect(
        failure.primaryAction,
        OperationalRecoveryAction.openFeedbackSettings,
      );
    });

    test('success notices are not operational failures', () {
      expect(
        ScanFailurePolicy.fromFeedbackNotice(FeedbackNotice.preferencesSaved),
        isNull,
      );
    });
  });
}
