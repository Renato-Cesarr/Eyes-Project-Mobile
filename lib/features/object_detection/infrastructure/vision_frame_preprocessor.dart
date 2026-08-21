import 'dart:math' as math;
import 'dart:typed_data';

import 'package:eyes_mobile/features/object_detection/application/vision_frame.dart';

enum VisionPreprocessingErrorCode {
  invalidDimensions,
  invalidPlaneLayout,
  unsupportedFormat,
}

final class VisionPreprocessingException implements Exception {
  const VisionPreprocessingException(this.code, this.message);

  final VisionPreprocessingErrorCode code;
  final String message;

  @override
  String toString() => 'VisionPreprocessingException(${code.name}): $message';
}

final class RgbImage {
  RgbImage({
    required this.width,
    required this.height,
    required Uint8List bytes,
  }) : bytes = bytes.asUnmodifiableView() {
    if (width <= 0 || height <= 0 || bytes.length != width * height * 3) {
      throw ArgumentError('Buffer RGB incompatível com suas dimensões.');
    }
  }

  final int width;
  final int height;
  final Uint8List bytes;
}

final class VisionFramePreprocessor {
  const VisionFramePreprocessor();

  RgbImage preprocess(
    VisionFrame frame, {
    required int targetWidth,
    required int targetHeight,
  }) {
    if (frame.width <= 0 ||
        frame.height <= 0 ||
        targetWidth <= 0 ||
        targetHeight <= 0) {
      throw const VisionPreprocessingException(
        VisionPreprocessingErrorCode.invalidDimensions,
        'As dimensões da imagem precisam ser positivas.',
      );
    }

    final decoded = switch (frame.format) {
      VisionPixelFormat.nv21 => _decodeNv21(frame),
      VisionPixelFormat.yuv420 => _decodeYuv420(frame),
    };
    final rotated = _rotate(decoded, frame.rotation);
    return _resizeBilinear(rotated, targetWidth, targetHeight);
  }

  RgbImage _decodeNv21(VisionFrame frame) {
    if (frame.planes.length != 1) {
      throw const VisionPreprocessingException(
        VisionPreprocessingErrorCode.invalidPlaneLayout,
        'NV21 precisa ser fornecido em um único plano intercalado.',
      );
    }
    final plane = frame.planes.single;
    final rowStride = plane.bytesPerRow;
    if (frame.width.isOdd ||
        frame.height.isOdd ||
        rowStride < frame.width ||
        plane.bytesPerPixel != 1) {
      throw const VisionPreprocessingException(
        VisionPreprocessingErrorCode.invalidPlaneLayout,
        'Os strides do plano NV21 são inválidos.',
      );
    }
    final yLength = rowStride * frame.height;
    final chromaRows = (frame.height + 1) ~/ 2;
    final requiredLength = yLength + (rowStride * chromaRows);
    if (plane.bytes.length < requiredLength) {
      throw const VisionPreprocessingException(
        VisionPreprocessingErrorCode.invalidPlaneLayout,
        'O plano NV21 está truncado.',
      );
    }

    final rgb = Uint8List(frame.width * frame.height * 3);
    for (var y = 0; y < frame.height; y++) {
      for (var x = 0; x < frame.width; x++) {
        final yValue = plane.bytes[(y * rowStride) + x];
        final chromaIndex = yLength + ((y >> 1) * rowStride) + (x & ~1);
        final vValue = plane.bytes[chromaIndex];
        final uValue = plane.bytes[chromaIndex + 1];
        _writeYuvPixel(
          rgb,
          ((y * frame.width) + x) * 3,
          yValue,
          uValue,
          vValue,
        );
      }
    }
    return RgbImage(width: frame.width, height: frame.height, bytes: rgb);
  }

  RgbImage _decodeYuv420(VisionFrame frame) {
    if (frame.planes.length != 3) {
      throw const VisionPreprocessingException(
        VisionPreprocessingErrorCode.invalidPlaneLayout,
        'YUV420 precisa conter os planos Y, U e V.',
      );
    }
    final yPlane = frame.planes[0];
    final uPlane = frame.planes[1];
    final vPlane = frame.planes[2];
    _validatePlane(yPlane, frame.width, frame.height, 'Y');
    _validatePlane(
      uPlane,
      (frame.width + 1) ~/ 2,
      (frame.height + 1) ~/ 2,
      'U',
    );
    _validatePlane(
      vPlane,
      (frame.width + 1) ~/ 2,
      (frame.height + 1) ~/ 2,
      'V',
    );

    final rgb = Uint8List(frame.width * frame.height * 3);
    for (var y = 0; y < frame.height; y++) {
      for (var x = 0; x < frame.width; x++) {
        final yValue = _readPlane(yPlane, x, y);
        final chromaX = x >> 1;
        final chromaY = y >> 1;
        final uValue = _readPlane(uPlane, chromaX, chromaY);
        final vValue = _readPlane(vPlane, chromaX, chromaY);
        _writeYuvPixel(
          rgb,
          ((y * frame.width) + x) * 3,
          yValue,
          uValue,
          vValue,
        );
      }
    }
    return RgbImage(width: frame.width, height: frame.height, bytes: rgb);
  }

  void _validatePlane(
    VisionFramePlane plane,
    int logicalWidth,
    int logicalHeight,
    String name,
  ) {
    if (plane.bytesPerRow <= 0 || plane.bytesPerPixel <= 0) {
      throw VisionPreprocessingException(
        VisionPreprocessingErrorCode.invalidPlaneLayout,
        'Os strides do plano $name são inválidos.',
      );
    }
    final lastIndex =
        ((logicalHeight - 1) * plane.bytesPerRow) +
        ((logicalWidth - 1) * plane.bytesPerPixel);
    if (lastIndex < 0 || lastIndex >= plane.bytes.length) {
      throw VisionPreprocessingException(
        VisionPreprocessingErrorCode.invalidPlaneLayout,
        'O plano $name está truncado.',
      );
    }
  }

  int _readPlane(VisionFramePlane plane, int x, int y) {
    return plane.bytes[(y * plane.bytesPerRow) + (x * plane.bytesPerPixel)];
  }

  void _writeYuvPixel(
    Uint8List target,
    int offset,
    int yValue,
    int uValue,
    int vValue,
  ) {
    final c = math.max(0, yValue - 16);
    final d = uValue - 128;
    final e = vValue - 128;
    target[offset] = _clampByte((298 * c + 409 * e + 128) >> 8);
    target[offset + 1] = _clampByte((298 * c - 100 * d - 208 * e + 128) >> 8);
    target[offset + 2] = _clampByte((298 * c + 516 * d + 128) >> 8);
  }

  int _clampByte(int value) => value.clamp(0, 255);

  RgbImage _rotate(RgbImage source, VisionRotation rotation) {
    if (rotation == VisionRotation.degrees0) {
      return source;
    }
    final swapsDimensions =
        rotation == VisionRotation.degrees90 ||
        rotation == VisionRotation.degrees270;
    final width = swapsDimensions ? source.height : source.width;
    final height = swapsDimensions ? source.width : source.height;
    final result = Uint8List(width * height * 3);

    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final (sourceX, sourceY) = switch (rotation) {
          VisionRotation.degrees0 => (x, y),
          VisionRotation.degrees90 => (y, source.height - 1 - x),
          VisionRotation.degrees180 => (
            source.width - 1 - x,
            source.height - 1 - y,
          ),
          VisionRotation.degrees270 => (source.width - 1 - y, x),
        };
        final sourceOffset = ((sourceY * source.width) + sourceX) * 3;
        final targetOffset = ((y * width) + x) * 3;
        result.setRange(
          targetOffset,
          targetOffset + 3,
          source.bytes,
          sourceOffset,
        );
      }
    }
    return RgbImage(width: width, height: height, bytes: result);
  }

  RgbImage _resizeBilinear(RgbImage source, int width, int height) {
    if (source.width == width && source.height == height) {
      return source;
    }
    final result = Uint8List(width * height * 3);
    for (var targetY = 0; targetY < height; targetY++) {
      final sourceY = (((targetY + 0.5) * source.height / height) - 0.5).clamp(
        0.0,
        source.height - 1.0,
      );
      final y0 = sourceY.floor();
      final y1 = math.min(y0 + 1, source.height - 1);
      final yWeight = sourceY - y0;
      for (var targetX = 0; targetX < width; targetX++) {
        final sourceX = (((targetX + 0.5) * source.width / width) - 0.5).clamp(
          0.0,
          source.width - 1.0,
        );
        final x0 = sourceX.floor();
        final x1 = math.min(x0 + 1, source.width - 1);
        final xWeight = sourceX - x0;
        final targetOffset = ((targetY * width) + targetX) * 3;
        for (var channel = 0; channel < 3; channel++) {
          final topLeft =
              source.bytes[((y0 * source.width) + x0) * 3 + channel];
          final topRight =
              source.bytes[((y0 * source.width) + x1) * 3 + channel];
          final bottomLeft =
              source.bytes[((y1 * source.width) + x0) * 3 + channel];
          final bottomRight =
              source.bytes[((y1 * source.width) + x1) * 3 + channel];
          final top = topLeft + ((topRight - topLeft) * xWeight);
          final bottom = bottomLeft + ((bottomRight - bottomLeft) * xWeight);
          result[targetOffset + channel] = (top + ((bottom - top) * yWeight))
              .round()
              .clamp(0, 255);
        }
      }
    }
    return RgbImage(width: width, height: height, bytes: result);
  }
}
