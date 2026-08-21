import 'package:eyes_mobile/features/object_detection/infrastructure/model_contract.dart';
import 'package:eyes_mobile/features/object_detection/infrastructure/vision_worker_protocol.dart';
import 'package:flutter/services.dart';

abstract interface class VisionModelAssetSource {
  Future<TransferableModelAssets> load();
}

/// Reads Flutter assets on the root isolate. AssetBundle depends on
/// ServicesBinding and cannot be used safely from a spawned background isolate.
final class RootVisionModelAssetSource implements VisionModelAssetSource {
  const RootVisionModelAssetSource({
    this.manifestPath = 'assets/models/model-manifest.v1.json',
    this.modelDirectory = 'assets/models',
    this.parser = const ModelContractParser(),
  });

  final String manifestPath;
  final String modelDirectory;
  final ModelContractParser parser;

  @override
  Future<TransferableModelAssets> load() async {
    final manifestSource = await rootBundle.loadString(
      manifestPath,
      cache: false,
    );
    final contract = parser.parse(manifestSource);
    final data = await rootBundle.load(
      '$modelDirectory/${contract.artifact.filename}',
    );
    return TransferableModelAssets.fromBytes(
      manifestSource: manifestSource,
      modelBytes: data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      ),
    );
  }
}
