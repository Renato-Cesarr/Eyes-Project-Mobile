import 'package:eyes_mobile/features/scanning/domain/camera_failure.dart';
import 'package:eyes_mobile/features/scanning/domain/camera_scan_status.dart';
import 'package:eyes_mobile/features/scanning/domain/camera_telemetry.dart';

final class CameraSessionState {
  const CameraSessionState({
    this.status = CameraScanStatus.idle,
    this.telemetry = const CameraTelemetry(),
    this.failure,
    this.previewAspectRatio,
  });

  final CameraScanStatus status;
  final CameraTelemetry telemetry;
  final CameraFailure? failure;
  final double? previewAspectRatio;

  bool get canStart =>
      status == CameraScanStatus.idle ||
      status == CameraScanStatus.ended ||
      status == CameraScanStatus.denied ||
      status == CameraScanStatus.busy ||
      status == CameraScanStatus.unavailable;

  bool get isOperationPending =>
      status == CameraScanStatus.requestingPermission ||
      status == CameraScanStatus.preparing;

  CameraSessionState copyWith({
    CameraScanStatus? status,
    CameraTelemetry? telemetry,
    CameraFailure? failure,
    bool clearFailure = false,
    double? previewAspectRatio,
    bool clearPreview = false,
  }) {
    return CameraSessionState(
      status: status ?? this.status,
      telemetry: telemetry ?? this.telemetry,
      failure: clearFailure ? null : failure ?? this.failure,
      previewAspectRatio: clearPreview
          ? null
          : previewAspectRatio ?? this.previewAspectRatio,
    );
  }
}
