import 'dart:async';

import 'package:eyes_mobile/core/error/app_error_reporter.dart';
import 'package:eyes_mobile/features/scanning/application/camera_gateway.dart';
import 'package:eyes_mobile/features/scanning/domain/camera_failure.dart';
import 'package:eyes_mobile/features/scanning/domain/camera_permission_state.dart';
import 'package:eyes_mobile/features/scanning/domain/camera_scan_status.dart';
import 'package:eyes_mobile/features/scanning/domain/camera_session_state.dart';
import 'package:eyes_mobile/features/scanning/domain/camera_telemetry.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final class ScanController extends AsyncNotifier<CameraSessionState> {
  int _operationToken = 0;
  bool _resumeAfterLifecycle = false;
  bool _isDisposed = false;

  @override
  Future<CameraSessionState> build() async {
    _isDisposed = false;
    final gateway = ref.read(cameraGatewayProvider);
    ref.onDispose(() {
      _isDisposed = true;
      _operationToken++;
      unawaited(gateway.release());
    });
    return const CameraSessionState();
  }

  Future<void> start() async {
    final current = state.asData?.value;
    if (current == null || current.isOperationPending) {
      return;
    }
    if (current.status == CameraScanStatus.streaming) {
      return;
    }

    final token = ++_operationToken;
    _resumeAfterLifecycle = false;
    final gateway = ref.read(cameraGatewayProvider);
    _setState(
      current.copyWith(
        status: CameraScanStatus.requestingPermission,
        clearFailure: true,
        clearPreview: true,
      ),
    );

    try {
      var permission = await gateway.checkPermission();
      if (!_isCurrent(token)) {
        return;
      }
      if (permission == CameraPermissionState.denied) {
        permission = await gateway.requestPermission();
      }
      if (!_isCurrent(token)) {
        return;
      }
      if (permission != CameraPermissionState.granted) {
        _setPermissionFailure(permission);
        return;
      }

      _setState(
        current.copyWith(
          status: CameraScanStatus.preparing,
          clearFailure: true,
          clearPreview: true,
        ),
      );
      final configuration = ref.read(cameraConfigurationProvider);
      await gateway
          .initialize(configuration)
          .timeout(configuration.initializationTimeout);
      if (!_isCurrent(token)) {
        await gateway.release();
        return;
      }

      await gateway.startStream(
        onFrame: ref.read(cameraFrameHandlerProvider),
        onTelemetry: (CameraTelemetry telemetry) {
          if (!_isCurrent(token)) {
            return;
          }
          final active = state.asData?.value;
          if (active?.status == CameraScanStatus.streaming) {
            _setState(active!.copyWith(telemetry: telemetry));
          }
        },
        onError: (CameraGatewayException failure) {
          if (_isCurrent(token)) {
            unawaited(_handleRuntimeFailure(failure));
          }
        },
      );
      if (!_isCurrent(token)) {
        await gateway.release();
        return;
      }

      _setState(
        CameraSessionState(
          status: CameraScanStatus.streaming,
          previewAspectRatio: gateway.previewAspectRatio,
        ),
      );
    } on TimeoutException catch (error, stackTrace) {
      if (!_isCurrent(token)) {
        return;
      }
      ref
          .read(appErrorReporterProvider)
          .capture(
            error,
            stackTrace,
            source: 'camera-initialization-timeout',
            diagnosticCode: 'initialization-timeout',
          );
      await gateway.release();
      _setFailure(
        CameraScanStatus.unavailable,
        const CameraFailure(
          reason: CameraFailureReason.initializationTimeout,
          technicalCode: 'initialization-timeout',
        ),
      );
    } on CameraGatewayException catch (error, stackTrace) {
      if (!_isCurrent(token)) {
        return;
      }
      ref
          .read(appErrorReporterProvider)
          .capture(
            error,
            stackTrace,
            source: 'camera-gateway',
            diagnosticCode: error.code,
          );
      await gateway.release();
      _applyGatewayFailure(error);
    } on Object catch (error, stackTrace) {
      if (!_isCurrent(token)) {
        return;
      }
      ref
          .read(appErrorReporterProvider)
          .capture(
            error,
            stackTrace,
            source: 'camera-unexpected',
            diagnosticCode: 'unexpected-camera-failure',
          );
      await gateway.release();
      _setFailure(
        CameraScanStatus.unavailable,
        const CameraFailure(
          reason: CameraFailureReason.initializationFailed,
          technicalCode: 'unexpected-camera-failure',
        ),
      );
    }
  }

  Future<void> pause() async {
    _resumeAfterLifecycle = false;
    await _pauseAndRelease();
  }

  Future<void> resume() => start();

  Future<void> retry() => start();

  Future<void> stop() async {
    _resumeAfterLifecycle = false;
    ++_operationToken;
    await ref.read(cameraGatewayProvider).release();
    _setState(const CameraSessionState());
  }

  Future<bool> openSettings() {
    return ref.read(cameraGatewayProvider).openSettings();
  }

  Future<void> handleBackground() async {
    final current = state.asData?.value;
    if (current == null) {
      return;
    }
    if (current.status == CameraScanStatus.paused) {
      return;
    }
    _resumeAfterLifecycle =
        current.status == CameraScanStatus.streaming ||
        current.status == CameraScanStatus.preparing ||
        current.status == CameraScanStatus.requestingPermission;
    if (_resumeAfterLifecycle) {
      await _pauseAndRelease(preserveLifecycleResume: true);
    }
  }

  Future<void> handleForeground() async {
    if (!_resumeAfterLifecycle) {
      return;
    }
    _resumeAfterLifecycle = false;
    await start();
  }

  Future<void> _pauseAndRelease({bool preserveLifecycleResume = false}) async {
    final current = state.asData?.value;
    if (current == null || current.status == CameraScanStatus.idle) {
      return;
    }
    final shouldResume = _resumeAfterLifecycle;
    ++_operationToken;
    await ref.read(cameraGatewayProvider).release();
    _setState(
      current.copyWith(
        status: CameraScanStatus.paused,
        clearFailure: true,
        clearPreview: true,
      ),
    );
    _resumeAfterLifecycle = preserveLifecycleResume && shouldResume;
  }

  Future<void> _handleRuntimeFailure(CameraGatewayException failure) async {
    ref
        .read(appErrorReporterProvider)
        .capture(
          failure,
          StackTrace.current,
          source: 'camera-stream',
          diagnosticCode: failure.code,
        );
    ++_operationToken;
    await ref.read(cameraGatewayProvider).release();
    _applyGatewayFailure(failure);
  }

  void _setPermissionFailure(CameraPermissionState permission) {
    switch (permission) {
      case CameraPermissionState.denied:
        _setFailure(
          CameraScanStatus.denied,
          const CameraFailure(reason: CameraFailureReason.permissionDenied),
        );
      case CameraPermissionState.permanentlyDenied:
        _setFailure(
          CameraScanStatus.permanentlyDenied,
          const CameraFailure(
            reason: CameraFailureReason.permissionPermanentlyDenied,
          ),
        );
      case CameraPermissionState.restricted:
        _setFailure(
          CameraScanStatus.unavailable,
          const CameraFailure(reason: CameraFailureReason.permissionRestricted),
        );
      case CameraPermissionState.granted:
        break;
    }
  }

  void _applyGatewayFailure(CameraGatewayException failure) {
    switch (failure.reason) {
      case CameraGatewayFailureReason.permissionDenied:
        _setFailure(
          CameraScanStatus.denied,
          CameraFailure(
            reason: CameraFailureReason.permissionDenied,
            technicalCode: failure.code,
          ),
        );
      case CameraGatewayFailureReason.permissionPermanentlyDenied:
        _setFailure(
          CameraScanStatus.permanentlyDenied,
          CameraFailure(
            reason: CameraFailureReason.permissionPermanentlyDenied,
            technicalCode: failure.code,
          ),
        );
      case CameraGatewayFailureReason.permissionRestricted:
        _setFailure(
          CameraScanStatus.unavailable,
          CameraFailure(
            reason: CameraFailureReason.permissionRestricted,
            technicalCode: failure.code,
          ),
        );
      case CameraGatewayFailureReason.busy:
        _setFailure(
          CameraScanStatus.busy,
          CameraFailure(
            reason: CameraFailureReason.cameraBusy,
            technicalCode: failure.code,
          ),
        );
      case CameraGatewayFailureReason.noCamera:
        _setFailure(
          CameraScanStatus.unavailable,
          CameraFailure(
            reason: CameraFailureReason.noCamera,
            technicalCode: failure.code,
          ),
        );
      case CameraGatewayFailureReason.initialization:
        _setFailure(
          CameraScanStatus.unavailable,
          CameraFailure(
            reason: CameraFailureReason.initializationFailed,
            technicalCode: failure.code,
          ),
        );
      case CameraGatewayFailureReason.stream:
        _setFailure(
          CameraScanStatus.unavailable,
          CameraFailure(
            reason: CameraFailureReason.streamFailed,
            technicalCode: failure.code,
          ),
        );
    }
  }

  void _setFailure(CameraScanStatus status, CameraFailure failure) {
    final current = state.asData?.value ?? const CameraSessionState();
    _setState(
      current.copyWith(status: status, failure: failure, clearPreview: true),
    );
  }

  void _setState(CameraSessionState value) {
    if (!_isDisposed) {
      state = AsyncData<CameraSessionState>(value);
    }
  }

  bool _isCurrent(int token) => !_isDisposed && token == _operationToken;
}

final AsyncNotifierProvider<ScanController, CameraSessionState>
scanControllerProvider =
    AsyncNotifierProvider<ScanController, CameraSessionState>(
      ScanController.new,
    );
