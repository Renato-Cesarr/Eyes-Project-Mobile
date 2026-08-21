import 'dart:convert';

enum ModelTensorDataType { uint8, float32 }

enum ModelOutput { boxes, classes, scores, count }

final class ModelArtifactContract {
  const ModelArtifactContract({
    required this.filename,
    required this.sha256,
    required this.sizeBytes,
    required this.licenseSpdxId,
  });

  final String filename;
  final String sha256;
  final int sizeBytes;
  final String licenseSpdxId;
}

final class ModelTensorContract {
  const ModelTensorContract({
    required this.name,
    required this.shape,
    required this.dataType,
  });

  final String name;
  final List<int> shape;
  final ModelTensorDataType dataType;
}

final class ModelClassContract {
  const ModelClassContract({
    required this.domainId,
    required this.displayNamePtBr,
    required this.modelLabelIndex,
  });

  final String domainId;
  final String displayNamePtBr;
  final int modelLabelIndex;
}

final class ModelContract {
  const ModelContract({
    required this.schemaVersion,
    required this.modelId,
    required this.modelVersion,
    required this.framework,
    required this.artifact,
    required this.input,
    required this.outputs,
    required this.maximumDetections,
    required this.enabledClasses,
  });

  static const expectedModelId = 'efficientdet-lite0-coco2017-int8';
  static const expectedModelVersion = 'tensorflow-metadata-1';
  static const expectedArtifactSha256 =
      '2e04c53bfeac0ac2a30c057c7e2a777594ce39baaac35a92f74fb1e8c4fc4e0b';
  static const expectedArtifactSizeBytes = 4563519;

  final int schemaVersion;
  final String modelId;
  final String modelVersion;
  final String framework;
  final ModelArtifactContract artifact;
  final ModelTensorContract input;
  final Map<ModelOutput, ModelTensorContract> outputs;
  final int maximumDetections;
  final List<ModelClassContract> enabledClasses;

  ModelClassContract? classForLabelIndex(int index) {
    for (final modelClass in enabledClasses) {
      if (modelClass.modelLabelIndex == index) {
        return modelClass;
      }
    }
    return null;
  }
}

final class ModelContractParser {
  const ModelContractParser();

  ModelContract parse(String source) {
    final Object? decoded;
    try {
      decoded = jsonDecode(source);
    } on FormatException catch (error) {
      throw FormatException('Manifesto JSON inválido: ${error.message}');
    }

    final root = _asMap(decoded, r'$');
    final artifactJson = _asMap(root['artifact'], r'$.artifact');
    final licenseJson = _asMap(artifactJson['license'], r'$.artifact.license');
    final runtimeJson = _asMap(root['runtime'], r'$.runtime');
    final inputJson = _asMap(runtimeJson['input'], r'$.runtime.input');
    final outputsJson = _asMap(runtimeJson['outputs'], r'$.runtime.outputs');
    final postprocessingJson = _asMap(
      runtimeJson['postprocessing'],
      r'$.runtime.postprocessing',
    );

    final contract = ModelContract(
      schemaVersion: _asInt(root['schema_version'], r'$.schema_version'),
      modelId: _asString(root['model_id'], r'$.model_id'),
      modelVersion: _asString(root['model_version'], r'$.model_version'),
      framework: _asString(root['framework'], r'$.framework'),
      artifact: ModelArtifactContract(
        filename: _asString(artifactJson['filename'], r'$.artifact.filename'),
        sha256: _asString(artifactJson['sha256'], r'$.artifact.sha256'),
        sizeBytes: _asInt(artifactJson['size_bytes'], r'$.artifact.size_bytes'),
        licenseSpdxId: _asString(
          licenseJson['spdx_id'],
          r'$.artifact.license.spdx_id',
        ),
      ),
      input: _parseTensor(inputJson, r'$.runtime.input'),
      outputs: Map<ModelOutput, ModelTensorContract>.unmodifiable({
        for (final output in ModelOutput.values)
          output: _parseTensor(
            _asMap(
              outputsJson[output.name],
              r'$.runtime.outputs.${output.name}',
            ),
            r'$.runtime.outputs.${output.name}',
          ),
      }),
      maximumDetections: _asInt(
        postprocessingJson['maximum_detections'],
        r'$.runtime.postprocessing.maximum_detections',
      ),
      enabledClasses: List<ModelClassContract>.unmodifiable(
        _asList(root['enabled_classes'], r'$.enabled_classes').map((entry) {
          final json = _asMap(entry, r'$.enabled_classes[]');
          return ModelClassContract(
            domainId: _asString(
              json['domain_id'],
              r'$.enabled_classes[].domain_id',
            ),
            displayNamePtBr: _asString(
              json['display_name_pt_br'],
              r'$.enabled_classes[].display_name_pt_br',
            ),
            modelLabelIndex: _asInt(
              json['model_label_index'],
              r'$.enabled_classes[].model_label_index',
            ),
          );
        }),
      ),
    );

    _validateCompatibility(contract, runtimeJson, postprocessingJson);
    return contract;
  }

  ModelTensorContract _parseTensor(Map<String, Object?> json, String path) {
    final dataTypeName = _asString(json['dtype'], '$path.dtype');
    final dataType = switch (dataTypeName) {
      'uint8' => ModelTensorDataType.uint8,
      'float32' => ModelTensorDataType.float32,
      _ => throw FormatException('$path.dtype não é suportado: $dataTypeName'),
    };
    return ModelTensorContract(
      name: _asString(json['name'], '$path.name'),
      shape: List<int>.unmodifiable(
        _asList(
          json['shape'],
          '$path.shape',
        ).map((dimension) => _asInt(dimension, '$path.shape[]')),
      ),
      dataType: dataType,
    );
  }

  void _validateCompatibility(
    ModelContract contract,
    Map<String, Object?> runtimeJson,
    Map<String, Object?> postprocessingJson,
  ) {
    _expect(contract.schemaVersion == 1, 'schema_version incompatível');
    _expect(
      contract.modelId == ModelContract.expectedModelId,
      'model_id incompatível',
    );
    _expect(
      contract.modelVersion == ModelContract.expectedModelVersion,
      'model_version incompatível',
    );
    _expect(
      contract.artifact.filename == 'efficientdet-lite0.tflite',
      'nome do artefato incompatível',
    );
    _expect(
      contract.artifact.sha256 == ModelContract.expectedArtifactSha256,
      'SHA-256 do artefato incompatível',
    );
    _expect(
      contract.artifact.sizeBytes == ModelContract.expectedArtifactSizeBytes,
      'tamanho do artefato incompatível',
    );
    _expect(
      contract.artifact.licenseSpdxId == 'Apache-2.0',
      'licença do artefato incompatível',
    );
    _expect(
      contract.input.name == 'serving_default_images:0' &&
          _sameShape(contract.input.shape, const [1, 320, 320, 3]) &&
          contract.input.dataType == ModelTensorDataType.uint8,
      'contrato do tensor de entrada incompatível',
    );
    _expect(contract.framework == 'TensorFlow Lite', 'framework incompatível');
    _expect(
      _asString(
            _asMap(runtimeJson['input'], r'$.runtime.input')['color_space'],
            r'$.runtime.input.color_space',
          ) ==
          'RGB',
      'espaço de cores incompatível',
    );
    _expect(
      _asString(
            _asMap(runtimeJson['input'], r'$.runtime.input')['resize_method'],
            r'$.runtime.input.resize_method',
          ) ==
          'bilinear',
      'método de redimensionamento incompatível',
    );
    final valueRange = _asList(
      _asMap(runtimeJson['input'], r'$.runtime.input')['value_range'],
      r'$.runtime.input.value_range',
    );
    _expect(
      valueRange.length == 2 &&
          _asInt(valueRange[0], r'$.runtime.input.value_range[0]') == 0 &&
          _asInt(valueRange[1], r'$.runtime.input.value_range[1]') == 255,
      'faixa de valores da entrada incompatível',
    );
    _expect(
      _asBool(
        postprocessingJson['embedded_in_model'],
        r'$.runtime.postprocessing.embedded_in_model',
      ),
      'pós-processamento precisa estar incorporado ao modelo',
    );
    _expect(
      !_asBool(
        postprocessingJson['additional_nms_required'],
        r'$.runtime.postprocessing.additional_nms_required',
      ),
      'NMS adicional não é suportado',
    );
    _expect(
      contract.maximumDetections == 25,
      'limite de detecções incompatível',
    );

    const expectedOutputs = <ModelOutput, (String, List<int>)>{
      ModelOutput.boxes: ('StatefulPartitionedCall:3', [1, 25, 4]),
      ModelOutput.classes: ('StatefulPartitionedCall:2', [1, 25]),
      ModelOutput.scores: ('StatefulPartitionedCall:1', [1, 25]),
      ModelOutput.count: ('StatefulPartitionedCall:0', [1]),
    };
    for (final entry in expectedOutputs.entries) {
      final output = contract.outputs[entry.key]!;
      _expect(
        output.name == entry.value.$1 &&
            _sameShape(output.shape, entry.value.$2) &&
            output.dataType == ModelTensorDataType.float32,
        'contrato da saída ${entry.key.name} incompatível',
      );
    }

    const expectedClasses = <String, int>{
      'person': 0,
      'chair': 61,
      'table_desk': 66,
      'backpack': 26,
    };
    _expect(
      contract.enabledClasses.length == expectedClasses.length &&
          contract.enabledClasses.every(
            (item) => expectedClasses[item.domainId] == item.modelLabelIndex,
          ),
      'classes habilitadas incompatíveis',
    );
  }
}

Map<String, Object?> _asMap(Object? value, String path) {
  if (value is! Map) {
    throw FormatException('$path deve ser um objeto JSON');
  }
  return value.map((key, value) => MapEntry(key.toString(), value));
}

List<Object?> _asList(Object? value, String path) {
  if (value is! List) {
    throw FormatException('$path deve ser uma lista JSON');
  }
  return value.cast<Object?>();
}

String _asString(Object? value, String path) {
  if (value is! String || value.isEmpty) {
    throw FormatException('$path deve ser uma string não vazia');
  }
  return value;
}

int _asInt(Object? value, String path) {
  if (value is! int) {
    throw FormatException('$path deve ser um inteiro');
  }
  return value;
}

bool _asBool(Object? value, String path) {
  if (value is! bool) {
    throw FormatException('$path deve ser booleano');
  }
  return value;
}

bool _sameShape(List<int> actual, List<int> expected) {
  if (actual.length != expected.length) {
    return false;
  }
  for (var index = 0; index < actual.length; index++) {
    if (actual[index] != expected[index]) {
      return false;
    }
  }
  return true;
}

void _expect(bool condition, String message) {
  if (!condition) {
    throw FormatException(message);
  }
}
