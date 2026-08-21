import 'dart:typed_data';

import 'package:eyes_mobile/features/object_detection/application/vision_frame.dart';
import 'package:eyes_mobile/features/scanning/application/camera_vision_frame_adapter.dart';
import 'package:eyes_mobile/features/scanning/domain/camera_frame.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'preserves frame metadata and maps rotation into the vision contract',
    () {
      final bytes = Uint8List.fromList([16, 16, 16, 16, 128, 128]);
      final capturedAt = DateTime.utc(2026);
      final result = const CameraVisionFrameAdapter().adapt(
        CameraFrame(
          width: 2,
          height: 2,
          format: CameraPixelFormat.nv21,
          planes: [CameraFramePlane(bytes: bytes, bytesPerRow: 2)],
          rotation: CameraFrameRotation.degrees270,
          capturedAt: capturedAt,
        ),
      );

      expect(result.width, 2);
      expect(result.height, 2);
      expect(result.format, VisionPixelFormat.nv21);
      expect(result.rotation, VisionRotation.degrees270);
      expect(result.capturedAt, capturedAt);
      bytes[0] = 99;
      expect(result.planes.single.bytes.first, 99);
      expect(result.planes.single.bytesPerPixel, 1);
    },
  );

  test('rejects formats that are not part of the Android MVP contract', () {
    expect(
      () => const CameraVisionFrameAdapter().adapt(
        CameraFrame(
          width: 2,
          height: 2,
          format: CameraPixelFormat.bgra8888,
          planes: [
            CameraFramePlane(
              bytes: Uint8List(16),
              bytesPerRow: 8,
              bytesPerPixel: 4,
            ),
          ],
          rotation: CameraFrameRotation.degrees0,
          capturedAt: DateTime.utc(2026),
        ),
      ),
      throwsA(
        isA<CameraVisionFrameException>().having(
          (error) => error.technicalCode,
          'technicalCode',
          'unsupported-pixel-format',
        ),
      ),
    );
  });
}
