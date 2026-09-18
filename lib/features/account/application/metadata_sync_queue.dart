import 'package:eyes_mobile/features/account/domain/sync_metadata_record.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract interface class MetadataSyncQueue {
  Future<List<SyncMetadataRecord>> readPending();

  Future<bool> enqueue(SyncMetadataRecord record);

  Future<void> remove(String idempotencyKey);

  Future<void> clear();
}

final Provider<MetadataSyncQueue> metadataSyncQueueProvider =
    Provider<MetadataSyncQueue>((Ref ref) {
      throw StateError('MetadataSyncQueue must be configured at bootstrap.');
    });
