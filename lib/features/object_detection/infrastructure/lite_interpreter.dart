import 'dart:typed_data';

import 'package:eyes_mobile/features/object_detection/infrastructure/model_contract.dart';

final class LiteTensorMetadata {
  const LiteTensorMetadata({
    required this.name,
    required this.shape,
    required this.dataType,
  });

  final String name;
  final List<int> shape;
  final ModelTensorDataType dataType;
}

abstract interface class LiteInterpreter {
  List<LiteTensorMetadata> get inputTensors;

  List<LiteTensorMetadata> get outputTensors;

  void writeInput(Uint8List bytes);

  void invoke();

  Uint8List readOutput(String name);

  void close();
}

abstract interface class LiteInterpreterFactory {
  LiteInterpreter create(Uint8List modelBytes, {required int threads});
}
