import 'dart:typed_data';

enum VisionPixelFormat { nv21, yuv420 }

enum VisionRotation {
  degrees0(0),
  degrees90(90),
  degrees180(180),
  degrees270(270);

  const VisionRotation(this.clockwiseDegrees);

  final int clockwiseDegrees;
}

final class VisionFramePlane {
  VisionFramePlane({
    required Uint8List bytes,
    required this.bytesPerRow,
    required this.bytesPerPixel,
  }) : bytes = bytes.asUnmodifiableView();

  final Uint8List bytes;
  final int bytesPerRow;
  final int bytesPerPixel;
}

final class VisionFrame {
  VisionFrame({
    required this.width,
    required this.height,
    required this.format,
    required List<VisionFramePlane> planes,
    required this.rotation,
    required this.capturedAt,
  }) : planes = List<VisionFramePlane>.unmodifiable(planes);

  final int width;
  final int height;
  final VisionPixelFormat format;
  final List<VisionFramePlane> planes;
  final VisionRotation rotation;
  final DateTime capturedAt;
}
