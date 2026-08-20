import 'package:crypto/crypto.dart';
import 'package:eyes_mobile/features/object_detection/infrastructure/model_contract.dart';
import 'package:flutter/services.dart';

enum ModelAssetErrorCode {
  assetUnavailable,
  invalidManifest,
  sizeMismatch,
  hashMismatch,
}

final class ModelAssetException implements Exception {
  const ModelAssetException(this.code, this.message);

  final ModelAssetErrorCode code;
  final String message;

  @override
  String toString() => 'ModelAssetException(${code.name}): $message';
}

final class VerifiedModelAsset {
  VerifiedModelAsset({required Uint8List bytes, required this.contract})
    : bytes = Uint8List.fromList(bytes);

  final Uint8List bytes;
  final ModelContract contract;
}

final class ModelAssetLoader {
  ModelAssetLoader({
    AssetBundle? bundle,
    this.parser = const ModelContractParser(),
    this.manifestPath = 'assets/models/model-manifest.v1.json',
    this.modelDirectory = 'assets/models',
  }) : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;
  final ModelContractParser parser;
  final String manifestPath;
  final String modelDirectory;

  Future<VerifiedModelAsset> loadAndVerify() async {
    final String manifestSource;
    try {
      manifestSource = await _bundle.loadString(manifestPath, cache: false);
    } catch (_) {
      throw const ModelAssetException(
        ModelAssetErrorCode.assetUnavailable,
        'O manifesto do modelo não está disponível.',
      );
    }

    final ModelContract contract;
    try {
      contract = parser.parse(manifestSource);
    } on FormatException catch (error) {
      throw ModelAssetException(
        ModelAssetErrorCode.invalidManifest,
        'O manifesto do modelo é incompatível: ${error.message}',
      );
    }

    final ByteData data;
    try {
      data = await _bundle.load(
        '$modelDirectory/${contract.artifact.filename}',
      );
    } catch (_) {
      throw const ModelAssetException(
        ModelAssetErrorCode.assetUnavailable,
        'O artefato do modelo não está disponível.',
      );
    }
    final bytes = data.buffer.asUint8List(
      data.offsetInBytes,
      data.lengthInBytes,
    );

    if (bytes.length != contract.artifact.sizeBytes) {
      throw ModelAssetException(
        ModelAssetErrorCode.sizeMismatch,
        'O tamanho do modelo não corresponde ao manifesto.',
      );
    }
    final actualHash = sha256.convert(bytes).toString();
    if (actualHash != contract.artifact.sha256) {
      throw const ModelAssetException(
        ModelAssetErrorCode.hashMismatch,
        'A integridade SHA-256 do modelo não pôde ser confirmada.',
      );
    }

    return VerifiedModelAsset(bytes: bytes, contract: contract);
  }
}
