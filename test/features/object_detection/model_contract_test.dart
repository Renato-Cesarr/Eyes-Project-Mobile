import 'package:eyes_mobile/features/object_detection/infrastructure/model_contract.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'interpreta e valida o contrato versionado do EfficientDet-Lite0',
    () async {
      final source = await rootBundle.loadString(
        'assets/models/model-manifest.v1.json',
      );

      final contract = const ModelContractParser().parse(source);

      expect(contract.schemaVersion, 1);
      expect(contract.modelId, ModelContract.expectedModelId);
      expect(contract.input.shape, [1, 320, 320, 3]);
      expect(contract.input.dataType, ModelTensorDataType.uint8);
      expect(contract.outputs[ModelOutput.boxes]!.shape, [1, 25, 4]);
      expect(contract.maximumDetections, 25);
      expect(contract.classForLabelIndex(66)?.displayNamePtBr, 'mesa');
      expect(contract.classForLabelIndex(999), isNull);
    },
  );

  test('rejeita versão de schema incompatível', () async {
    final source = await rootBundle.loadString(
      'assets/models/model-manifest.v1.json',
    );

    expect(
      () => const ModelContractParser().parse(
        source.replaceFirst('"schema_version": 1', '"schema_version": 2'),
      ),
      throwsFormatException,
    );
  });

  test('rejeita contrato que solicita NMS adicional', () async {
    final source = await rootBundle.loadString(
      'assets/models/model-manifest.v1.json',
    );

    expect(
      () => const ModelContractParser().parse(
        source.replaceFirst(
          '"additional_nms_required": false',
          '"additional_nms_required": true',
        ),
      ),
      throwsFormatException,
    );
  });

  test(
    'rejeita a troca do hash aprovado mesmo com SHA-256 bem formado',
    () async {
      final source = await rootBundle.loadString(
        'assets/models/model-manifest.v1.json',
      );

      expect(
        () => const ModelContractParser().parse(
          source.replaceFirst(
            ModelContract.expectedArtifactSha256,
            'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
          ),
        ),
        throwsFormatException,
      );
    },
  );
}
