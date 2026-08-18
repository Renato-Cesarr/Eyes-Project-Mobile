import 'dart:typed_data';

enum CameraPixelFormat { nv21, yuv420, bgra8888, unknown }

final class CameraFramePlane {
  CameraFramePlane({
    required Uint8List bytes,
    required this.bytesPerRow,
    this.bytesPerPixel,
  }) : bytes = bytes.asUnmodifiableView();

  final Uint8List bytes;
  final int bytesPerRow;
  final int? bytesPerPixel;
}

final class CameraFrame {
  CameraFrame({
    required this.width,
    required this.height,
    required this.format,
    required List<CameraFramePlane> planes,
    required this.capturedAt,
  }) : planes = List<CameraFramePlane>.unmodifiable(planes);

  final int width;
  final int height;
  final CameraPixelFormat format;
  final List<CameraFramePlane> planes;
  final DateTime capturedAt;
}
