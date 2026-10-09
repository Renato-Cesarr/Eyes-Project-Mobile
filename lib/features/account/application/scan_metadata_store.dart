import 'package:eyes_mobile/features/account/domain/scan_metadata.dart';

abstract interface class ScanMetadataStore {
  Future<String?> readConsentOwner();
  Future<void> writeConsentOwner(String? owner);
  Future<String> installationId();
  Future<List<ScanMetadata>> pending();
  Future<void> add(ScanMetadata session);
  Future<void> remove(String id);
  Future<void> clear();
}

final class ScanMetadataQueueFull implements Exception {
  const ScanMetadataQueueFull();
}
