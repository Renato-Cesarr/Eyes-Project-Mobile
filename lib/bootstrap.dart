import 'dart:async';

import 'package:eyes_mobile/app/app.dart';
import 'package:eyes_mobile/app/config/app_environment.dart';
import 'package:eyes_mobile/core/accessibility/accessible_feedback_service.dart';
import 'package:eyes_mobile/core/error/app_error_reporter.dart';
import 'package:eyes_mobile/core/error/global_error_view.dart';
import 'package:eyes_mobile/core/logging/secure_logger.dart';
import 'package:eyes_mobile/core/persistence/storage_providers.dart';
import 'package:eyes_mobile/features/assistive_feedback/application/assistive_feedback_controller.dart';
import 'package:eyes_mobile/features/assistive_feedback/infrastructure/flutter_tts_speech_gateway.dart';
import 'package:eyes_mobile/features/assistive_feedback/infrastructure/shared_preferences_feedback_repository.dart';
import 'package:eyes_mobile/features/assistive_feedback/infrastructure/system_assistive_haptics.dart';
import 'package:eyes_mobile/features/object_detection/application/vision_controller.dart';
import 'package:eyes_mobile/features/object_detection/application/vision_worker.dart';
import 'package:eyes_mobile/features/object_detection/infrastructure/isolate_vision_worker.dart';
import 'package:eyes_mobile/features/onboarding/application/onboarding_repository.dart';
import 'package:eyes_mobile/features/onboarding/infrastructure/shared_preferences_onboarding_repository.dart';
import 'package:eyes_mobile/features/proximity/application/proximity_controller.dart';
import 'package:eyes_mobile/features/scanning/application/camera_gateway.dart';
import 'package:eyes_mobile/features/scanning/application/camera_vision_frame_adapter.dart';
import 'package:eyes_mobile/features/scanning/application/scan_transition_feedback.dart';
import 'package:eyes_mobile/features/scanning/application/scan_wake_lock_gateway.dart';
import 'package:eyes_mobile/features/scanning/infrastructure/mobile_camera_gateway.dart';
import 'package:eyes_mobile/features/scanning/infrastructure/system_scan_transition_feedback.dart';
import 'package:eyes_mobile/features/scanning/infrastructure/wakelock_plus_scan_gateway.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> bootstrap(AppEnvironment environment) async {
  WidgetsFlutterBinding.ensureInitialized();

  final logger = SecureLogger(environment)..initialize();
  final errorReporter = AppErrorReporter(logger);

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    errorReporter.captureFlutterError(details);
  };

  PlatformDispatcher.instance.onError = (Object error, StackTrace stackTrace) {
    errorReporter.capture(error, stackTrace, source: 'platform-dispatcher');
    return true;
  };

  ErrorWidget.builder = (FlutterErrorDetails details) {
    errorReporter.captureFlutterError(details);
    return const GlobalErrorView();
  };

  await runZonedGuarded<Future<void>>(
    () async {
      runApp(
        ProviderScope(
          overrides: [
            appEnvironmentProvider.overrideWithValue(environment),
            secureLoggerProvider.overrideWithValue(logger),
            appErrorReporterProvider.overrideWithValue(errorReporter),
            accessibleFeedbackServiceProvider.overrideWith((Ref ref) {
              return SystemAccessibleFeedbackService(
                hapticsEnabled: () =>
                    ref
                        .read(assistiveFeedbackControllerProvider)
                        .asData
                        ?.value
                        .preferences
                        .hapticsEnabled ??
                    true,
              );
            }),
            speechGatewayProvider.overrideWith((Ref ref) {
              final gateway = FlutterTtsSpeechGateway();
              ref.onDispose(() => unawaited(gateway.dispose()));
              return gateway;
            }),
            assistiveHapticsProvider.overrideWithValue(
              SystemAssistiveHaptics(),
            ),
            feedbackPreferencesRepositoryProvider.overrideWith((Ref ref) {
              return SharedPreferencesFeedbackRepository(
                ref.read(sharedPreferencesProvider),
              );
            }),
            onboardingRepositoryProvider.overrideWith((Ref ref) {
              return SharedPreferencesOnboardingRepository(
                ref.read(sharedPreferencesProvider),
              );
            }),
            visionWorkerProvider.overrideWith((Ref ref) {
              final worker = IsolateVisionWorker();
              ref.onDispose(() => unawaited(worker.dispose()));
              return worker;
            }),
            cameraGatewayProvider.overrideWith((Ref ref) {
              final gateway = MobileCameraGateway();
              ref.onDispose(() => unawaited(gateway.release()));
              return gateway;
            }),
            scanWakeLockGatewayProvider.overrideWithValue(
              const WakelockPlusScanGateway(),
            ),
            scanTransitionFeedbackProvider.overrideWith((Ref ref) {
              return SystemScanTransitionFeedback(
                hapticsEnabled: () =>
                    ref
                        .read(assistiveFeedbackControllerProvider)
                        .asData
                        ?.value
                        .preferences
                        .hapticsEnabled ??
                    true,
              );
            }),
            cameraFrameHandlerProvider.overrideWith((Ref ref) {
              const adapter = CameraVisionFrameAdapter();
              return (frame) async {
                final batch = await ref
                    .read(visionControllerProvider.notifier)
                    .process(adapter.adapt(frame));
                ref.read(proximityControllerProvider.notifier).process(batch);
              };
            }),
          ],
          child: const EyesApp(),
        ),
      );
    },
    (Object error, StackTrace stackTrace) {
      errorReporter.capture(error, stackTrace, source: 'root-zone');
      if (kDebugMode) {
        FlutterError.dumpErrorToConsole(
          FlutterErrorDetails(exception: error, stack: stackTrace),
        );
      }
    },
  );
}
