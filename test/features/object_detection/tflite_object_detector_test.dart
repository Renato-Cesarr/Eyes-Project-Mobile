import 'dart:typed_data';

import 'package:eyes_mobile/features/object_detection/application/vision_frame.dart';
import 'package:eyes_mobile/features/object_detection/domain/detected_object.dart';
import 'package:eyes_mobile/features/object_detection/infrastructure/lite_interpreter.dart';
import 'package:eyes_mobile/features/object_detection/infrastructure/model_asset_loader.dart';
import 'package:eyes_mobile/features/object_detection/infrastructure/model_contract.dart';
import 'package:eyes_mobile/features/object_detection/infrastructure/tflite_object_detector.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ModelContract contract;
  setUpAll(() async {
    final source = await rootBundle.loadString(
      'assets/models/model-manifest.v1.json',
    );
    contract = const ModelContractParser().parse(source);
  });

  test(
    'decodifica apenas entidades do domínio sem aplicar segundo NMS',
    () async {
      final interpreter = _FakeLiteInterpreter.valid(
        outputs: {
          'StatefulPartitionedCall:3': _floatBytes([
            0.1,
            0.2,
            0.5,
            0.6,
            0.0,
            0.0,
            1.0,
            1.0,
            0.2,
            0.2,
            0.3,
            0.3,
            0.3,
            0.4,
            0.8,
            0.9,
            ...List<double>.filled(84, 0),
          ]),
          'StatefulPartitionedCall:2': _floatBytes([
            0,
            61,
            5,
            26,
            ...List<double>.filled(21, 0),
          ]),
          'StatefulPartitionedCall:1': _floatBytes([
            0.9,
            0.8,
            0.95,
            0.7,
            ...List<double>.filled(21, 0),
          ]),
          'StatefulPartitionedCall:0': _floatBytes([4]),
        },
      );
      final detector = TfliteObjectDetector(
        model: VerifiedModelAsset(bytes: Uint8List(1), contract: contract),
        interpreterFactory: _FakeLiteInterpreterFactory(interpreter),
      );

      final result = await detector.detect(_blackFrame());

      expect(result.detections.map((detection) => detection.kind), [
        DetectedObjectKind.person,
        DetectedObjectKind.chair,
        DetectedObjectKind.backpack,
      ]);
      expect(result.detections.first.confidence, closeTo(0.9, 0.0001));
      expect(result.detections.first.boundingBox.left, closeTo(0.2, 0.0001));
      expect(interpreter.invocations, 1);
      expect(interpreter.lastInput, hasLength(320 * 320 * 3));
      await detector.close();
      expect(interpreter.closed, isTrue);
    },
  );

  test('rejeita artefato cujo tensor diverge do manifesto', () {
    final interpreter = _FakeLiteInterpreter.valid(
      outputs: _emptyOutputs(),
      inputShape: const [1, 224, 224, 3],
    );

    expect(
      () => TfliteObjectDetector(
        model: VerifiedModelAsset(bytes: Uint8List(1), contract: contract),
        interpreterFactory: _FakeLiteInterpreterFactory(interpreter),
      ),
      throwsA(
        isA<ObjectDetectorException>().having(
          (error) => error.code,
          'code',
          ObjectDetectorErrorCode.invalidTensorContract,
        ),
      ),
    );
    expect(interpreter.closed, isTrue);
  });

  test('não permite inferência depois do encerramento', () async {
    final detector = TfliteObjectDetector(
      model: VerifiedModelAsset(bytes: Uint8List(1), contract: contract),
      interpreterFactory: _FakeLiteInterpreterFactory(
        _FakeLiteInterpreter.valid(outputs: _emptyOutputs()),
      ),
    );
    await detector.close();

    expect(
      () => detector.detect(_blackFrame()),
      throwsA(
        isA<ObjectDetectorException>().having(
          (error) => error.code,
          'code',
          ObjectDetectorErrorCode.closed,
        ),
      ),
    );
  });
}

VisionFrame _blackFrame() => VisionFrame(
  width: 2,
  height: 2,
  format: VisionPixelFormat.nv21,
  planes: [
    VisionFramePlane(
      bytes: Uint8List.fromList([16, 16, 16, 16, 128, 128]),
      bytesPerRow: 2,
      bytesPerPixel: 1,
    ),
  ],
  rotation: VisionRotation.degrees0,
  capturedAt: DateTime.utc(2026),
);

Map<String, Uint8List> _emptyOutputs() => {
  'StatefulPartitionedCall:3': _floatBytes(List<double>.filled(100, 0)),
  'StatefulPartitionedCall:2': _floatBytes(List<double>.filled(25, 0)),
  'StatefulPartitionedCall:1': _floatBytes(List<double>.filled(25, 0)),
  'StatefulPartitionedCall:0': _floatBytes([0]),
};

Uint8List _floatBytes(List<double> values) {
  final data = ByteData(values.length * Float32List.bytesPerElement);
  for (var index = 0; index < values.length; index++) {
    data.setFloat32(
      index * Float32List.bytesPerElement,
      values[index],
      Endian.little,
    );
  }
  return data.buffer.asUint8List();
}

final class _FakeLiteInterpreterFactory implements LiteInterpreterFactory {
  const _FakeLiteInterpreterFactory(this.interpreter);

  final LiteInterpreter interpreter;

  @override
  LiteInterpreter create(Uint8List modelBytes, {required int threads}) {
    expect(threads, 4);
    return interpreter;
  }
}

final class _FakeLiteInterpreter implements LiteInterpreter {
  _FakeLiteInterpreter.valid({
    required this.outputs,
    List<int> inputShape = const [1, 320, 320, 3],
  }) : inputTensors = [
         LiteTensorMetadata(
           name: 'serving_default_images:0',
           shape: inputShape,
           dataType: ModelTensorDataType.uint8,
         ),
       ],
       outputTensors = const [
         LiteTensorMetadata(
           name: 'StatefulPartitionedCall:3',
           shape: [1, 25, 4],
           dataType: ModelTensorDataType.float32,
         ),
         LiteTensorMetadata(
           name: 'StatefulPartitionedCall:2',
           shape: [1, 25],
           dataType: ModelTensorDataType.float32,
         ),
         LiteTensorMetadata(
           name: 'StatefulPartitionedCall:1',
           shape: [1, 25],
           dataType: ModelTensorDataType.float32,
         ),
         LiteTensorMetadata(
           name: 'StatefulPartitionedCall:0',
           shape: [1],
           dataType: ModelTensorDataType.float32,
         ),
       ];

  final Map<String, Uint8List> outputs;

  @override
  final List<LiteTensorMetadata> inputTensors;

  @override
  final List<LiteTensorMetadata> outputTensors;

  Uint8List? lastInput;
  int invocations = 0;
  bool closed = false;

  @override
  void writeInput(Uint8List bytes) => lastInput = Uint8List.fromList(bytes);

  @override
  void invoke() => invocations++;

  @override
  Uint8List readOutput(String name) => Uint8List.fromList(outputs[name]!);

  @override
  void close() => closed = true;
}
