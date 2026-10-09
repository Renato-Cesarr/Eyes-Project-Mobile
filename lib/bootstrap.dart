import 'dart:async';

import 'package:eyes_mobile/app/app.dart';
import 'package:eyes_mobile/app/config/app_environment.dart';
import 'package:eyes_mobile/app/routing/app_router.dart';
import 'package:eyes_mobile/core/accessibility/accessible_feedback_service.dart';
import 'package:eyes_mobile/core/design_system/licenses/font_license_registry.dart';
import 'package:eyes_mobile/core/error/app_error_reporter.dart';
import 'package:eyes_mobile/core/error/global_error_view.dart';
import 'package:eyes_mobile/core/logging/secure_logger.dart';
import 'package:eyes_mobile/core/network/dio_provider.dart';
import 'package:eyes_mobile/core/persistence/secure_remote_session_store.dart';
import 'package:eyes_mobile/core/persistence/storage_providers.dart';
import 'package:eyes_mobile/core/session/remote_session_store.dart';
import 'package:eyes_mobile/features/account/application/auth_gateway.dart';
import 'package:eyes_mobile/features/account/application/metadata_sync_queue.dart';
import 'package:eyes_mobile/features/account/application/scan_metadata_alert_observer.dart';
import 'package:eyes_mobile/features/account/application/scan_metadata_sync.dart';
import 'package:eyes_mobile/features/account/application/sync_preferences_repository.dart';
import 'package:eyes_mobile/features/account/infrastructure/dio_auth_gateway.dart';
import 'package:eyes_mobile/features/account/infrastructure/dio_scan_metadata_gateway.dart';
import 'package:eyes_mobile/features/account/infrastructure/shared_preferences_metadata_sync_queue.dart';
import 'package:eyes_mobile/features/account/infrastructure/shared_preferences_scan_metadata_store.dart';
import 'package:eyes_mobile/features/account/infrastructure/shared_preferences_sync_preferences_repository.dart';
import 'package:eyes_mobile/features/appearance/application/appearance_repository.dart';
import 'package:eyes_mobile/features/appearance/infrastructure/shared_preferences_appearance_repository.dart';
import 'package:eyes_mobile/features/assistive_feedback/application/assistive_feedback_controller.dart';
import 'package:eyes_mobile/features/assistive_feedback/infrastructure/flutter_tts_speech_gateway.dart';
import 'package:eyes_mobile/features/assistive_feedback/infrastructure/shared_preferences_feedback_repository.dart';
import 'package:eyes_mobile/features/assistive_feedback/infrastructure/system_assistive_haptics.dart';
import 'package:eyes_mobile/features/calibration/application/calibration_event_sink.dart';
import 'package:eyes_mobile/features/calibration/application/calibration_recorder.dart';
import 'package:eyes_mobile/features/calibration/domain/calibration_configuration.dart';
import 'package:eyes_mobile/features/calibration/infrastructure/android_log_calibration_event_sink.dart';
import 'package:eyes_mobile/features/calibration/infrastructure/platform_calibration_configuration_source.dart';
import 'package:eyes_mobile/features/object_detection/application/vision_controller.dart';
import 'package:eyes_mobile/features/object_detection/application/vision_worker.dart';
import 'package:eyes_mobile/features/object_detection/infrastructure/isolate_vision_worker.dart';
import 'package:eyes_mobile/features/onboarding/application/onboarding_repository.dart';
import 'package:eyes_mobile/features/onboarding/infrastructure/shared_preferences_onboarding_repository.dart';
import 'package:eyes_mobile/features/proximity/application/proximity_controller.dart';
import 'package:eyes_mobile/features/scanning/application/camera_gateway.dart';
import 'package:eyes_mobile/features/scanning/application/camera_vision_frame_adapter.dart';
import 'package:eyes_mobile/features/scanning/application/scan_controller.dart';
import 'package:eyes_mobile/features/scanning/application/scan_transition_feedback.dart';
import 'package:eyes_mobile/features/scanning/application/scan_wake_lock_gateway.dart';
import 'package:eyes_mobile/features/scanning/domain/camera_scan_status.dart';
import 'package:eyes_mobile/features/scanning/infrastructure/mobile_camera_gateway.dart';
import 'package:eyes_mobile/features/scanning/infrastructure/system_scan_transition_feedback.dart';
import 'package:eyes_mobile/features/scanning/infrastructure/wakelock_plus_scan_gateway.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> bootstrap(AppEnvironment environment) async {
  WidgetsFlutterBinding.ensureInitialized();
  await registerEyesFontLicenses();

  final logger = SecureLogger(environment)..initialize();
  final errorReporter = AppErrorReporter(logger);
  var calibrationConfiguration = const CalibrationConfiguration.disabled();
  try {
    calibrationConfiguration =
        await PlatformCalibrationConfigurationSource.forBuild(
          calibrationEnabled: const bool.fromEnvironment('EYES_CALIBRATION'),
          isProduction: environment.isProduction,
        ).load();
  } on Object catch (error, stackTrace) {
    errorReporter.capture(
      error,
      stackTrace,
      source: 'calibration-configuration',
      diagnosticCode: 'calibration-configuration-invalid',
    );
  }
  final calibrationRecorder = CalibrationRecorder(
    calibrationConfiguration,
    calibrationConfiguration.enabled
        ? const AndroidLogCalibrationEventSink()
        : const NoopCalibrationEventSink(),
  )..start();

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
            designSystemGalleryEnabledProvider.overrideWithValue(
              !environment.isProduction,
            ),
            secureLoggerProvider.overrideWithValue(logger),
            appErrorReporterProvider.overrideWithValue(errorReporter),
            remoteSessionStoreProvider.overrideWith((Ref ref) {
              final store = SecureRemoteSessionStore(
                ref.read(secureStorageProvider),
                logger,
              );
              ref.onDispose(() => unawaited(store.dispose()));
              return store;
            }),
            authGatewayProvider.overrideWith(
              (Ref ref) => DioAuthGateway(ref.read(dioProvider)),
            ),
            syncPreferencesRepositoryProvider.overrideWith((Ref ref) {
              return SharedPreferencesSyncPreferencesRepository(
                ref.read(sharedPreferencesProvider),
              );
            }),
            metadataSyncQueueProvider.overrideWith((Ref ref) {
              return SharedPreferencesMetadataSyncQueue(
                ref.read(sharedPreferencesProvider),
                ref.read(syncPreferencesRepositoryProvider),
              );
            }),
            scanMetadataSyncProvider.overrideWith((Ref ref) {
              final sync = ScanMetadataSync(
                store: SharedPreferencesScanMetadataStore(
                  ref.read(sharedPreferencesProvider),
                ),
                preferences: ref.read(syncPreferencesRepositoryProvider),
                accounts: ref.read(remoteSessionStoreProvider),
                gateway: DioScanMetadataGateway(ref.read(dioProvider)),
                remoteAvailable:
                    environment.apiBaseUrl.host != 'api.example.invalid',
              );
              ref.listen(scanControllerProvider, (previous, next) {
                sync.setScanning(
                  next.asData?.value.status == CameraScanStatus.streaming,
                );
              });
              ref.onDispose(() => unawaited(sync.dispose()));
              return sync;
            }),
            calibrationRecorderProvider.overrideWithValue(calibrationRecorder),
            assistiveAlertObserverProvider.overrideWith(
              (Ref ref) => ScanMetadataAlertObserver(
                ref.read(scanMetadataSyncProvider)!,
                calibrationRecorder,
              ),
            ),
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
              final gateway = FlutterTtsSpeechGateway(
                onPlaybackStarted: (message, startedAt) {
                  calibrationRecorder.recordSpeechStarted(message, startedAt);
                  ref
                      .read(scanMetadataSyncProvider)!
                      .recordSpeechStarted(message, startedAt);
                },
              );
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
            appearanceRepositoryProvider.overrideWith((Ref ref) {
              return SharedPreferencesAppearanceRepository(
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
                ref.read(scanMetadataSyncProvider)!.recordFrame(batch);
                final evaluation = ref
                    .read(proximityControllerProvider.notifier)
                    .process(batch);
                calibrationRecorder.recordEvaluation(batch, evaluation);
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
