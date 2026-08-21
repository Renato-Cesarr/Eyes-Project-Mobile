import 'dart:typed_data';

import 'package:eyes_mobile/features/object_detection/application/object_detector_gateway.dart';
import 'package:eyes_mobile/features/object_detection/application/vision_frame.dart';
import 'package:eyes_mobile/features/object_detection/domain/detected_object.dart';
import 'package:eyes_mobile/features/object_detection/infrastructure/lite_interpreter.dart';
import 'package:eyes_mobile/features/object_detection/infrastructure/model_asset_loader.dart';
import 'package:eyes_mobile/features/object_detection/infrastructure/model_contract.dart';
import 'package:eyes_mobile/features/object_detection/infrastructure/vision_frame_preprocessor.dart';

enum ObjectDetectorErrorCode { invalidTensorContract, closed, inferenceFailed }

final class ObjectDetectorException implements Exception {
  const ObjectDetectorException(this.code, this.message);

  final ObjectDetectorErrorCode code;
  final String message;

  @override
  String toString() => 'ObjectDetectorException(${code.name}): $message';
}

final class TfliteObjectDetector implements ObjectDetectorGateway {
  TfliteObjectDetector({
    required VerifiedModelAsset model,
    required LiteInterpreterFactory interpreterFactory,
    this.preprocessor = const VisionFramePreprocessor(),
    this.scoreThreshold = 0.4,
    int threadCount = 4,
  }) : _contract = model.contract,
       _interpreter = interpreterFactory.create(
         model.bytes,
         threads: threadCount,
       ) {
    if (!scoreThreshold.isFinite || scoreThreshold < 0 || scoreThreshold > 1) {
      _interpreter.close();
      throw RangeError.range(scoreThreshold, 0, 1, 'scoreThreshold');
    }
    try {
      _validateTensorContract();
    } catch (_) {
      _interpreter.close();
      rethrow;
    }
  }

  final ModelContract _contract;
  final VisionFramePreprocessor preprocessor;
  final LiteInterpreter _interpreter;
  final double scoreThreshold;
  var _closed = false;

  @override
  Future<DetectionBatch> detect(VisionFrame frame) async {
    if (_closed) {
      throw const ObjectDetectorException(
        ObjectDetectorErrorCode.closed,
        'O detector já foi encerrado.',
      );
    }

    final preprocessingWatch = Stopwatch()..start();
    final input = preprocessor.preprocess(
      frame,
      targetWidth: _contract.input.shape[2],
      targetHeight: _contract.input.shape[1],
    );
    preprocessingWatch.stop();

    final inferenceWatch = Stopwatch()..start();
    try {
      _interpreter.writeInput(input.bytes);
      _interpreter.invoke();
    } catch (_) {
      throw const ObjectDetectorException(
        ObjectDetectorErrorCode.inferenceFailed,
        'A inferência local não pôde ser concluída.',
      );
    } finally {
      inferenceWatch.stop();
    }

    final postprocessingWatch = Stopwatch()..start();
    final detections = _decodeDetections();
    postprocessingWatch.stop();
    return DetectionBatch(
      detections: detections,
      capturedAt: frame.capturedAt,
      timings: DetectionTimings(
        preprocessing: preprocessingWatch.elapsed,
        inference: inferenceWatch.elapsed,
        postprocessing: postprocessingWatch.elapsed,
      ),
    );
  }

  List<DetectedObject> _decodeDetections() {
    final boxes = _float32Output(ModelOutput.boxes);
    final classes = _float32Output(ModelOutput.classes);
    final scores = _float32Output(ModelOutput.scores);
    final countValues = _float32Output(ModelOutput.count);
    if (countValues.isEmpty || !countValues.first.isFinite) {
      throw const ObjectDetectorException(
        ObjectDetectorErrorCode.inferenceFailed,
        'O modelo retornou uma contagem de detecções inválida.',
      );
    }
    final count = countValues.first.round().clamp(
      0,
      _contract.maximumDetections,
    );
    final detections = <DetectedObject>[];
    for (var index = 0; index < count; index++) {
      final score = scores[index].toDouble();
      final labelValue = classes[index];
      if (!score.isFinite || score < scoreThreshold || !labelValue.isFinite) {
        continue;
      }
      final modelClass = _contract.classForLabelIndex(labelValue.round());
      final kind = modelClass == null ? null : _domainKind(modelClass.domainId);
      if (kind == null) {
        continue;
      }
      final boxOffset = index * 4;
      final coordinates = boxes
          .sublist(boxOffset, boxOffset + 4)
          .map((value) => value.toDouble())
          .toList(growable: false);
      if (coordinates.any((coordinate) => !coordinate.isFinite)) {
        continue;
      }
      final top = coordinates[0].clamp(0.0, 1.0);
      final left = coordinates[1].clamp(0.0, 1.0);
      final bottom = coordinates[2].clamp(0.0, 1.0);
      final right = coordinates[3].clamp(0.0, 1.0);
      if (bottom <= top || right <= left) {
        continue;
      }
      detections.add(
        DetectedObject(
          kind: kind,
          confidence: score.clamp(0.0, 1.0),
          boundingBox: NormalizedBoundingBox(
            top: top,
            left: left,
            bottom: bottom,
            right: right,
          ),
        ),
      );
    }
    return detections;
  }

  Float32List _float32Output(ModelOutput output) {
    final tensor = _contract.outputs[output]!;
    final bytes = _interpreter.readOutput(tensor.name);
    final expectedElements = tensor.shape.fold<int>(
      1,
      (total, item) => total * item,
    );
    if (bytes.length != expectedElements * Float32List.bytesPerElement) {
      throw ObjectDetectorException(
        ObjectDetectorErrorCode.inferenceFailed,
        'A saída ${output.name} possui tamanho inválido.',
      );
    }
    final data = ByteData.sublistView(bytes);
    final values = Float32List(expectedElements);
    for (var index = 0; index < expectedElements; index++) {
      values[index] = data.getFloat32(
        index * Float32List.bytesPerElement,
        Endian.little,
      );
    }
    return values;
  }

  DetectedObjectKind? _domainKind(String domainId) => switch (domainId) {
    'person' => DetectedObjectKind.person,
    'chair' => DetectedObjectKind.chair,
    'table_desk' => DetectedObjectKind.table,
    'backpack' => DetectedObjectKind.backpack,
    _ => null,
  };

  void _validateTensorContract() {
    if (_interpreter.inputTensors.length != 1 ||
        !_matches(_interpreter.inputTensors.single, _contract.input)) {
      throw const ObjectDetectorException(
        ObjectDetectorErrorCode.invalidTensorContract,
        'O tensor de entrada do artefato diverge do manifesto.',
      );
    }
    if (_interpreter.outputTensors.length != _contract.outputs.length) {
      throw const ObjectDetectorException(
        ObjectDetectorErrorCode.invalidTensorContract,
        'A quantidade de tensores de saída diverge do manifesto.',
      );
    }
    for (final expected in _contract.outputs.values) {
      final actual = _interpreter.outputTensors
          .where((tensor) => tensor.name == expected.name)
          .firstOrNull;
      if (actual == null || !_matches(actual, expected)) {
        throw ObjectDetectorException(
          ObjectDetectorErrorCode.invalidTensorContract,
          'O tensor ${expected.name} diverge do manifesto.',
        );
      }
    }
  }

  bool _matches(LiteTensorMetadata actual, ModelTensorContract expected) {
    if (actual.name != expected.name ||
        actual.dataType != expected.dataType ||
        actual.shape.length != expected.shape.length) {
      return false;
    }
    for (var index = 0; index < actual.shape.length; index++) {
      if (actual.shape[index] != expected.shape[index]) {
        return false;
      }
    }
    return true;
  }

  @override
  Future<void> close() async {
    if (_closed) {
      return;
    }
    _closed = true;
    _interpreter.close();
  }
}
