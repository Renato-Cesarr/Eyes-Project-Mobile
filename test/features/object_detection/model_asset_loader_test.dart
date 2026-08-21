import 'package:eyes_mobile/features/object_detection/infrastructure/model_asset_loader.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'valida tamanho e SHA-256 do modelo distribuído no aplicativo',
    () async {
      final result = await ModelAssetLoader().loadAndVerify();

      expect(result.bytes, hasLength(4563519));
      expect(
        result.contract.artifact.sha256,
        '2e04c53bfeac0ac2a30c057c7e2a777594ce39baaac35a92f74fb1e8c4fc4e0b',
      );
    },
  );

  test('falha de forma segura quando o artefato é adulterado', () async {
    final manifest = await rootBundle.loadString(
      'assets/models/model-manifest.v1.json',
    );
    final original = await rootBundle.load(
      'assets/models/efficientdet-lite0.tflite',
    );
    final model = Uint8List.fromList(
      original.buffer.asUint8List(
        original.offsetInBytes,
        original.lengthInBytes,
      ),
    );
    model[model.length - 1] ^= 0xff;
    final bundle = _MemoryAssetBundle({
      'assets/models/model-manifest.v1.json': Uint8List.fromList(
        manifest.codeUnits,
      ),
      'assets/models/efficientdet-lite0.tflite': model,
    });

    expect(
      () => ModelAssetLoader(bundle: bundle).loadAndVerify(),
      throwsA(
        isA<ModelAssetException>().having(
          (error) => error.code,
          'code',
          ModelAssetErrorCode.hashMismatch,
        ),
      ),
    );
  });
}

final class _MemoryAssetBundle extends CachingAssetBundle {
  _MemoryAssetBundle(this.assets);

  final Map<String, Uint8List> assets;

  @override
  Future<ByteData> load(String key) async {
    final bytes = assets[key];
    if (bytes == null) {
      throw StateError('Asset ausente: $key');
    }
    return ByteData.sublistView(bytes);
  }
}
