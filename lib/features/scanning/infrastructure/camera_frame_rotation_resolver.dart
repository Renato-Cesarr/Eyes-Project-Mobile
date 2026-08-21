import 'package:camera/camera.dart';
import 'package:eyes_mobile/features/scanning/domain/camera_frame.dart';
import 'package:flutter/services.dart';

/// Resolves the clockwise rotation needed to make a native camera frame
/// upright before it is sent to the object detector.
abstract final class CameraFrameRotationResolver {
  static CameraFrameRotation resolve({
    required int sensorOrientation,
    required DeviceOrientation deviceOrientation,
    required CameraLensDirection lensDirection,
  }) {
    final deviceDegrees = switch (deviceOrientation) {
      DeviceOrientation.portraitUp => 0,
      DeviceOrientation.landscapeLeft => 90,
      DeviceOrientation.portraitDown => 180,
      DeviceOrientation.landscapeRight => 270,
    };
    final normalizedSensor = sensorOrientation % 360;
    final clockwiseDegrees = lensDirection == CameraLensDirection.front
        ? (normalizedSensor + deviceDegrees) % 360
        : (normalizedSensor - deviceDegrees + 360) % 360;

    return switch (clockwiseDegrees) {
      0 => CameraFrameRotation.degrees0,
      90 => CameraFrameRotation.degrees90,
      180 => CameraFrameRotation.degrees180,
      270 => CameraFrameRotation.degrees270,
      _ => throw StateError(
        'Unsupported camera orientation: $clockwiseDegrees degrees.',
      ),
    };
  }
}
