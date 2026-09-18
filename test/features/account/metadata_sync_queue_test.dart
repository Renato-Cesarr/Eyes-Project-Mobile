import 'package:eyes_mobile/features/account/domain/sync_metadata_record.dart';
import 'package:eyes_mobile/features/account/infrastructure/shared_preferences_metadata_sync_queue.dart';
import 'package:eyes_mobile/features/account/infrastructure/shared_preferences_sync_preferences_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  test('queue is idempotent and stores only scalar metadata', () async {
    final storage = SharedPreferencesAsync();
    final consent = SharedPreferencesSyncPreferencesRepository(storage);
    final queue = SharedPreferencesMetadataSyncQueue(storage, consent);
    await consent.writeConsent(true);
    final record = SyncMetadataRecord(
      idempotencyKey: 'session-1:scan-started',
      eventType: 'scan_started',
      occurredAt: DateTime.utc(2026, 9, 18, 12),
      properties: const <String, Object?>{
        'appVersion': '0.1.0',
        'offline': true,
      },
    );

    expect(await queue.enqueue(record), isTrue);
    expect(await queue.enqueue(record), isFalse);
    expect(await queue.readPending(), hasLength(1));
  });

  test('does not enqueue metadata without active consent', () async {
    final storage = SharedPreferencesAsync();
    final consent = SharedPreferencesSyncPreferencesRepository(storage);
    final queue = SharedPreferencesMetadataSyncQueue(storage, consent);
    final record = SyncMetadataRecord(
      idempotencyKey: 'session-1:scan-started',
      eventType: 'scan_started',
      occurredAt: DateTime.utc(2026, 9, 18, 12),
      properties: const <String, Object?>{'offline': true},
    );

    expect(await queue.enqueue(record), isFalse);
    expect(await queue.readPending(), isEmpty);
  });

  test('rejects media, secrets and structured payloads', () {
    expect(
      () => SyncMetadataRecord(
        idempotencyKey: 'unsafe-image',
        eventType: 'scan',
        occurredAt: DateTime.utc(2026),
        properties: const <String, Object?>{'imageBase64': 'secret'},
      ),
      throwsArgumentError,
    );
    expect(
      () => SyncMetadataRecord(
        idempotencyKey: 'unsafe-object',
        eventType: 'scan',
        occurredAt: DateTime.utc(2026),
        properties: const <String, Object?>{
          'details': <String, Object?>{'nested': true},
        },
      ),
      throwsArgumentError,
    );
  });
}
