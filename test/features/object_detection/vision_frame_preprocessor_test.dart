import 'dart:typed_data';

import 'package:eyes_mobile/features/object_detection/application/vision_frame.dart';
import 'package:eyes_mobile/features/object_detection/infrastructure/vision_frame_preprocessor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const preprocessor = VisionFramePreprocessor();

  test('converte NV21 para RGB respeitando a faixa limitada YUV', () {
    final frame = _nv21Frame(width: 2, height: 2, yValues: [16, 235, 16, 235]);

    final result = preprocessor.preprocess(
      frame,
      targetWidth: 2,
      targetHeight: 2,
    );

    expect(result.bytes, [0, 0, 0, 255, 255, 255, 0, 0, 0, 255, 255, 255]);
  });

  test('aplica rotação horária antes do redimensionamento', () {
    final frame = _nv21Frame(
      width: 2,
      height: 2,
      yValues: [16, 82, 145, 235],
      rotation: VisionRotation.degrees90,
    );

    final result = preprocessor.preprocess(
      frame,
      targetWidth: 2,
      targetHeight: 2,
    );

    expect(_redChannel(result), [150, 0, 255, 77]);
  });

  test('converte YUV420 considerando row stride e pixel stride', () {
    final frame = VisionFrame(
      width: 2,
      height: 2,
      format: VisionPixelFormat.yuv420,
      planes: [
        VisionFramePlane(
          bytes: Uint8List.fromList([16, 235, 99, 82, 145, 99]),
          bytesPerRow: 3,
          bytesPerPixel: 1,
        ),
        VisionFramePlane(
          bytes: Uint8List.fromList([128, 99]),
          bytesPerRow: 2,
          bytesPerPixel: 1,
        ),
        VisionFramePlane(
          bytes: Uint8List.fromList([128, 99]),
          bytesPerRow: 2,
          bytesPerPixel: 1,
        ),
      ],
      rotation: VisionRotation.degrees0,
      capturedAt: DateTime.utc(2026),
    );

    final result = preprocessor.preprocess(
      frame,
      targetWidth: 2,
      targetHeight: 2,
    );

    expect(_redChannel(result), [0, 255, 77, 150]);
  });

  test('redimensiona por interpolação bilinear para o tensor do modelo', () {
    final frame = _nv21Frame(width: 2, height: 2, yValues: [82, 82, 82, 82]);

    final result = preprocessor.preprocess(
      frame,
      targetWidth: 320,
      targetHeight: 320,
    );

    expect(result.bytes, hasLength(320 * 320 * 3));
    expect(result.bytes.every((value) => value == 77), isTrue);
  });

  test('interpolação bilinear preserva os pixels das bordas', () {
    final frame = _nv21Frame(width: 2, height: 2, yValues: [16, 235, 16, 235]);

    final result = preprocessor.preprocess(
      frame,
      targetWidth: 4,
      targetHeight: 4,
    );

    expect(_redChannel(result).take(4), [0, 64, 191, 255]);
    expect(_redChannel(result).skip(12), [0, 64, 191, 255]);
  });

  test('rejeita plano NV21 truncado antes de acessar memória inválida', () {
    final frame = VisionFrame(
      width: 2,
      height: 2,
      format: VisionPixelFormat.nv21,
      planes: [
        VisionFramePlane(
          bytes: Uint8List.fromList([16, 16]),
          bytesPerRow: 2,
          bytesPerPixel: 1,
        ),
      ],
      rotation: VisionRotation.degrees0,
      capturedAt: DateTime.utc(2026),
    );

    expect(
      () => preprocessor.preprocess(frame, targetWidth: 320, targetHeight: 320),
      throwsA(
        isA<VisionPreprocessingException>().having(
          (error) => error.code,
          'code',
          VisionPreprocessingErrorCode.invalidPlaneLayout,
        ),
      ),
    );
  });
}

VisionFrame _nv21Frame({
  required int width,
  required int height,
  required List<int> yValues,
  VisionRotation rotation = VisionRotation.degrees0,
}) {
  final bytes = Uint8List.fromList([
    ...yValues,
    for (var index = 0; index < width * ((height + 1) ~/ 2); index += 2) ...[
      128,
      128,
    ],
  ]);
  return VisionFrame(
    width: width,
    height: height,
    format: VisionPixelFormat.nv21,
    planes: [
      VisionFramePlane(bytes: bytes, bytesPerRow: width, bytesPerPixel: 1),
    ],
    rotation: rotation,
    capturedAt: DateTime.utc(2026),
  );
}

List<int> _redChannel(RgbImage image) => [
  for (var offset = 0; offset < image.bytes.length; offset += 3)
    image.bytes[offset],
];
