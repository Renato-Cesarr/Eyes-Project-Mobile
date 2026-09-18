import 'dart:convert';

import 'package:eyes_mobile/features/account/application/metadata_sync_queue.dart';
import 'package:eyes_mobile/features/account/application/sync_preferences_repository.dart';
import 'package:eyes_mobile/features/account/domain/sync_metadata_record.dart';
import 'package:shared_preferences/shared_preferences.dart';

final class SharedPreferencesMetadataSyncQueue implements MetadataSyncQueue {
  const SharedPreferencesMetadataSyncQueue(
    this._preferences,
    this._syncPreferencesRepository,
  );

  static const String _queueKey = 'account.metadata-sync-queue.v1';
  static const int _maximumItems = 200;

  final SharedPreferencesAsync _preferences;
  final SyncPreferencesRepository _syncPreferencesRepository;

  @override
  Future<List<SyncMetadataRecord>> readPending() async {
    final rawItems = await _preferences.getStringList(_queueKey) ?? <String>[];
    final records = <SyncMetadataRecord>[];
    for (final rawItem in rawItems) {
      try {
        final decoded = jsonDecode(rawItem);
        if (decoded is Map<String, Object?>) {
          records.add(SyncMetadataRecord.fromJson(decoded));
        }
      } on Object {
        // A malformed local entry is ignored instead of blocking offline use.
      }
    }
    return List<SyncMetadataRecord>.unmodifiable(records);
  }

  @override
  Future<bool> enqueue(SyncMetadataRecord record) async {
    if (!await _syncPreferencesRepository.readConsent()) {
      return false;
    }
    final records = (await readPending()).toList(growable: true);
    if (records.any((item) => item.idempotencyKey == record.idempotencyKey)) {
      return false;
    }
    records.add(record);
    if (records.length > _maximumItems) {
      records.removeRange(0, records.length - _maximumItems);
    }
    await _write(records);
    return true;
  }

  @override
  Future<void> remove(String idempotencyKey) async {
    final records = (await readPending())
        .where((record) => record.idempotencyKey != idempotencyKey)
        .toList(growable: false);
    await _write(records);
  }

  @override
  Future<void> clear() => _preferences.remove(_queueKey);

  Future<void> _write(List<SyncMetadataRecord> records) {
    final encoded = records
        .map((record) => jsonEncode(record.toJson()))
        .toList(growable: false);
    return _preferences.setStringList(_queueKey, encoded);
  }
}
