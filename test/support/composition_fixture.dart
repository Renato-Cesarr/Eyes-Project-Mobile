import 'dart:async';

import 'package:eyes_mobile/app/config/app_environment.dart';
import 'package:eyes_mobile/core/accessibility/accessible_feedback_service.dart';
import 'package:eyes_mobile/core/error/app_error_reporter.dart';
import 'package:eyes_mobile/core/logging/secure_logger.dart';
import 'package:eyes_mobile/core/session/remote_session_store.dart';
import 'package:eyes_mobile/features/account/application/auth_gateway.dart';
import 'package:eyes_mobile/features/account/application/metadata_sync_queue.dart';
import 'package:eyes_mobile/features/account/application/sync_preferences_repository.dart';
import 'package:eyes_mobile/features/appearance/application/appearance_repository.dart';
import 'package:eyes_mobile/features/assistive_feedback/application/assistive_feedback_controller.dart';
import 'package:eyes_mobile/features/object_detection/application/vision_frame.dart';
import 'package:eyes_mobile/features/object_detection/application/vision_worker.dart';
import 'package:eyes_mobile/features/object_detection/domain/detected_object.dart';
import 'package:eyes_mobile/features/onboarding/application/onboarding_repository.dart';
import 'package:eyes_mobile/features/scanning/application/camera_configuration.dart';
import 'package:eyes_mobile/features/scanning/application/camera_gateway.dart';
import 'package:eyes_mobile/features/scanning/application/scan_transition_feedback.dart';
import 'package:eyes_mobile/features/scanning/application/scan_wake_lock_gateway.dart';
import 'package:eyes_mobile/features/scanning/domain/camera_permission_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'fake_account.dart';
import 'fake_appearance.dart';
import 'fake_assistive_feedback.dart';
import 'fake_onboarding.dart';

/// Widget-only services. No camera, network, TTS or physical evidence.
final class CompositionFixture {
  CompositionFixture({
    bool connected = false,
    bool modelFailure = false,
    String? modelFailureCode,
  }) {
    store = InMemoryRemoteSessionStore(
      session: connected ? testRemoteSession : null,
    );
    worker = CompositionVisionWorker(
      fails: modelFailure,
      failureCode: modelFailureCode,
    );
    final environment = AppEnvironment.dev();
    final logger = SecureLogger(environment);
    container = ProviderContainer(
      overrides: [
        appEnvironmentProvider.overrideWithValue(environment),
        secureLoggerProvider.overrideWithValue(logger),
        appErrorReporterProvider.overrideWithValue(AppErrorReporter(logger)),
        accessibleFeedbackServiceProvider.overrideWithValue(feedback),
        appearanceRepositoryProvider.overrideWithValue(
          InMemoryAppearanceRepository(),
        ),
        speechGatewayProvider.overrideWithValue(speech),
        assistiveHapticsProvider.overrideWithValue(haptics),
        feedbackPreferencesRepositoryProvider.overrideWithValue(
          InMemoryFeedbackPreferencesRepository(),
        ),
        onboardingRepositoryProvider.overrideWithValue(
          InMemoryOnboardingRepository(),
        ),
        remoteSessionStoreProvider.overrideWithValue(store),
        authGatewayProvider.overrideWithValue(FakeAuthGateway()),
        syncPreferencesRepositoryProvider.overrideWithValue(preferences),
        metadataSyncQueueProvider.overrideWithValue(queue),
        cameraGatewayProvider.overrideWithValue(camera),
        visionWorkerProvider.overrideWithValue(worker),
        scanWakeLockGatewayProvider.overrideWithValue(wakeLock),
        scanTransitionFeedbackProvider.overrideWithValue(transitions),
      ],
    );
  }

  late final ProviderContainer container;
  late final InMemoryRemoteSessionStore store;
  late final CompositionVisionWorker worker;
  final camera = CompositionCameraGateway();
  final speech = FakeSpeechGateway();
  final haptics = FakeAssistiveHaptics();
  final preferences = InMemorySyncPreferencesRepository();
  final queue = InMemoryMetadataSyncQueue();
  final feedback = CompositionFeedback();
  final wakeLock = CompositionWakeLock();
  final transitions = CompositionTransitions();

  Future<void> dispose() async {
    container.dispose();
    await store.dispose();
    await worker.close();
  }
}

final class CompositionCameraGateway implements CameraGateway {
  CameraPermissionState permission = CameraPermissionState.granted;
  bool streaming = false;
  int requestCalls = 0;
  int releaseCalls = 0;
  @override
  bool get isPreviewReady => streaming;
  @override
  double? get previewAspectRatio => streaming ? 4 / 3 : null;
  @override
  Future<CameraPermissionState> checkPermission() async => permission;
  @override
  Future<CameraPermissionState> requestPermission() async {
    requestCalls++;
    return permission;
  }

  @override
  Future<void> initialize(CameraConfiguration configuration) async {}
  @override
  Future<bool> openSettings() async => true;
  @override
  Future<void> release() async {
    streaming = false;
    releaseCalls++;
  }

  @override
  Future<void> startStream({
    required CameraFrameHandler onFrame,
    required CameraTelemetryHandler onTelemetry,
    required CameraErrorHandler onError,
  }) async {
    streaming = true;
  }
}

final class CompositionVisionWorker implements VisionWorker {
  CompositionVisionWorker({this.fails = false, this.failureCode});
  final bool fails;
  final String? failureCode;
  final _changes = StreamController<VisionWorkerSnapshot>.broadcast(sync: true);
  @override
  VisionWorkerSnapshot snapshot = const VisionWorkerSnapshot.idle();
  @override
  Stream<VisionWorkerSnapshot> get snapshots => _changes.stream;
  @override
  Future<void> start() async {
    if (fails) {
      final failure = VisionWorkerException(
        VisionWorkerFailureReason.initialization,
        'widget fixture',
        technicalCode: failureCode,
      );
      snapshot = VisionWorkerSnapshot(
        phase: VisionWorkerPhase.failed,
        failure: failure,
      );
      throw failure;
    }
    snapshot = const VisionWorkerSnapshot(phase: VisionWorkerPhase.ready);
    _changes.add(snapshot);
  }

  @override
  Future<DetectionBatch> detect(VisionFrame frame) =>
      throw UnimplementedError();
  @override
  Future<void> dispose() async {
    snapshot = const VisionWorkerSnapshot.idle();
    if (!_changes.isClosed) _changes.add(snapshot);
  }

  Future<void> close() => _changes.close();
}

final class CompositionFeedback implements AccessibleFeedbackService {
  @override
  Future<void> confirm() async {}
  @override
  Future<void> warn() async {}
}

final class CompositionWakeLock implements ScanWakeLockGateway {
  bool enabled = false;
  @override
  Future<void> enable() async => enabled = true;
  @override
  Future<void> disable() async => enabled = false;
}

final class CompositionTransitions implements ScanTransitionFeedback {
  final delivered = <ScanTransition>[];
  @override
  Future<void> deliver(ScanTransition transition) async =>
      delivered.add(transition);
}
