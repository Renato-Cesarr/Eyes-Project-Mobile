import 'package:eyes_mobile/features/account/application/scan_metadata_store.dart';
import 'package:eyes_mobile/features/account/domain/scan_metadata.dart';

final class FlakyScanMetadataStore implements ScanMetadataStore {
  FlakyScanMetadataStore(this.delegate);
  final ScanMetadataStore delegate;
  bool failWrites = true;
  @override
  Future<void> add(ScanMetadata session) async {
    if (failWrites) throw StateError('Synthetic storage unavailable.');
    await delegate.add(session);
  }

  @override
  Future<void> clear() => delegate.clear();
  @override
  Future<String> installationId() => delegate.installationId();
  @override
  Future<List<ScanMetadata>> pending() => delegate.pending();
  @override
  Future<String?> readConsentOwner() => delegate.readConsentOwner();
  @override
  Future<void> remove(String id) => delegate.remove(id);
  @override
  Future<void> writeConsentOwner(String? owner) =>
      delegate.writeConsentOwner(owner);
}
