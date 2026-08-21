import 'dart:typed_data';

import 'package:eyes_mobile/features/object_detection/infrastructure/lite_interpreter.dart';
import 'package:eyes_mobile/features/object_detection/infrastructure/model_contract.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

final class TfliteLiteInterpreterFactory implements LiteInterpreterFactory {
  const TfliteLiteInterpreterFactory();

  @override
  LiteInterpreter create(Uint8List modelBytes, {required int threads}) {
    if (threads <= 0) {
      throw RangeError.range(threads, 1, null, 'threads');
    }
    final options = InterpreterOptions()..threads = threads;
    try {
      return TfliteLiteInterpreter._(
        Interpreter.fromBuffer(modelBytes, options: options),
      );
    } finally {
      options.delete();
    }
  }
}

final class TfliteLiteInterpreter implements LiteInterpreter {
  TfliteLiteInterpreter._(this._interpreter)
    : inputTensors = _interpreter.getInputTensors().map(_metadata).toList(),
      outputTensors = _interpreter.getOutputTensors().map(_metadata).toList();

  final Interpreter _interpreter;

  @override
  final List<LiteTensorMetadata> inputTensors;

  @override
  final List<LiteTensorMetadata> outputTensors;

  @override
  void writeInput(Uint8List bytes) {
    _interpreter.getInputTensor(0).data = bytes;
  }

  @override
  void invoke() => _interpreter.invoke();

  @override
  Uint8List readOutput(String name) {
    final tensors = _interpreter.getOutputTensors();
    final tensor = tensors.where((item) => item.name == name).firstOrNull;
    if (tensor == null) {
      throw StateError('Tensor de saída não encontrado: $name');
    }
    return Uint8List.fromList(tensor.data);
  }

  @override
  void close() => _interpreter.close();

  static LiteTensorMetadata _metadata(Tensor tensor) {
    final dataType = switch (tensor.type) {
      TensorType.uint8 => ModelTensorDataType.uint8,
      TensorType.float32 => ModelTensorDataType.float32,
      _ => throw StateError(
        'Tipo de tensor não suportado: ${tensor.type.name}',
      ),
    };
    return LiteTensorMetadata(
      name: tensor.name,
      shape: List<int>.unmodifiable(tensor.shape),
      dataType: dataType,
    );
  }
}
