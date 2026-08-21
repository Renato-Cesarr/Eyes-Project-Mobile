import 'package:camera/camera.dart';
import 'package:eyes_mobile/features/scanning/domain/camera_frame.dart';
import 'package:eyes_mobile/features/scanning/infrastructure/camera_frame_rotation_resolver.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('resolves every device orientation for the rear camera', () {
    const expected = <DeviceOrientation, CameraFrameRotation>{
      DeviceOrientation.portraitUp: CameraFrameRotation.degrees90,
      DeviceOrientation.landscapeLeft: CameraFrameRotation.degrees0,
      DeviceOrientation.portraitDown: CameraFrameRotation.degrees270,
      DeviceOrientation.landscapeRight: CameraFrameRotation.degrees180,
    };

    for (final entry in expected.entries) {
      expect(
        CameraFrameRotationResolver.resolve(
          sensorOrientation: 90,
          deviceOrientation: entry.key,
          lensDirection: CameraLensDirection.back,
        ),
        entry.value,
      );
    }
  });

  test('accounts for the mirrored coordinate system of the front lens', () {
    const expected = <DeviceOrientation, CameraFrameRotation>{
      DeviceOrientation.portraitUp: CameraFrameRotation.degrees90,
      DeviceOrientation.landscapeLeft: CameraFrameRotation.degrees180,
      DeviceOrientation.portraitDown: CameraFrameRotation.degrees270,
      DeviceOrientation.landscapeRight: CameraFrameRotation.degrees0,
    };

    for (final entry in expected.entries) {
      expect(
        CameraFrameRotationResolver.resolve(
          sensorOrientation: 90,
          deviceOrientation: entry.key,
          lensDirection: CameraLensDirection.front,
        ),
        entry.value,
      );
    }
  });

  test('rejects non-right-angle sensor metadata', () {
    expect(
      () => CameraFrameRotationResolver.resolve(
        sensorOrientation: 45,
        deviceOrientation: DeviceOrientation.portraitUp,
        lensDirection: CameraLensDirection.back,
      ),
      throwsStateError,
    );
  });
}
