import 'package:eyes_mobile/features/object_detection/application/vision_frame.dart';
import 'package:eyes_mobile/features/scanning/domain/camera_frame.dart';

final class CameraVisionFrameAdapter {
  const CameraVisionFrameAdapter();

  VisionFrame adapt(CameraFrame frame) {
    final format = switch (frame.format) {
      CameraPixelFormat.nv21 => VisionPixelFormat.nv21,
      CameraPixelFormat.yuv420 => VisionPixelFormat.yuv420,
      CameraPixelFormat.bgra8888 || CameraPixelFormat.unknown =>
        throw const CameraVisionFrameException('unsupported-pixel-format'),
    };

    return VisionFrame(
      width: frame.width,
      height: frame.height,
      format: format,
      planes: frame.planes
          .map(
            (plane) => VisionFramePlane(
              bytes: plane.bytes,
              bytesPerRow: plane.bytesPerRow,
              bytesPerPixel:
                  plane.bytesPerPixel ??
                  (frame.format == CameraPixelFormat.nv21
                      ? 1
                      : throw const CameraVisionFrameException(
                          'missing-yuv-pixel-stride',
                        )),
            ),
          )
          .toList(growable: false),
      rotation: switch (frame.rotation) {
        CameraFrameRotation.degrees0 => VisionRotation.degrees0,
        CameraFrameRotation.degrees90 => VisionRotation.degrees90,
        CameraFrameRotation.degrees180 => VisionRotation.degrees180,
        CameraFrameRotation.degrees270 => VisionRotation.degrees270,
      },
      capturedAt: frame.capturedAt,
    );
  }
}

final class CameraVisionFrameException implements Exception {
  const CameraVisionFrameException(this.technicalCode);

  final String technicalCode;
}
