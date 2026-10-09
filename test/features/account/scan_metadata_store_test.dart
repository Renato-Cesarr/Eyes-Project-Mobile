import 'dart:convert';

import 'package:eyes_mobile/features/account/application/scan_metadata_store.dart';
import 'package:eyes_mobile/features/account/domain/scan_metadata.dart';
import 'package:eyes_mobile/features/account/infrastructure/shared_preferences_scan_metadata_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../../support/scan_metadata_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(
    () => SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty(),
  );

  test(
    'concurrent writes, duplicate replay and removal preserve other sessions',
    () async {
      final store = SharedPreferencesScanMetadataStore(
        SharedPreferencesAsync(),
      );
      final entries = List.generate(10, (_) => metadataFixture());
      await Future.wait(entries.map(store.add));
      await Future.wait(entries.map(store.add));
      expect(
        (await store.pending()).map((e) => e.id),
        entries.map((e) => e.id),
      );
      await Future.wait([
        store.remove(entries.first.id),
        store.add(metadataFixture()),
      ]);
      expect(await store.pending(), hasLength(10));
      expect(
        (await store.pending()).map((s) => s.id),
        isNot(contains(entries.first.id)),
      );
    },
  );

  test('full queue refuses new data without evicting existing data', () async {
    final store = SharedPreferencesScanMetadataStore(SharedPreferencesAsync());
    final entries = List.generate(20, (_) => metadataFixture());
    await Future.wait(entries.map(store.add));
    await expectLater(
      store.add(metadataFixture()),
      throwsA(isA<ScanMetadataQueueFull>()),
    );
    expect((await store.pending()).map((e) => e.id), entries.map((e) => e.id));
    await store.clear();
    expect(await store.pending(), isEmpty);
  });

  test(
    'installation identity persists and resets when consent is revoked',
    () async {
      final store = SharedPreferencesScanMetadataStore(
        SharedPreferencesAsync(),
      );
      await store.writeConsentOwner('owner');
      final first = await store.installationId();
      expect(await store.installationId(), first);
      expect(await store.readConsentOwner(), 'owner');
      await store.writeConsentOwner(null);
      expect(await store.readConsentOwner(), isNull);
      expect(await store.installationId(), isNot(first));
    },
  );

  test('corrupt queue is surfaced and not silently erased', () async {
    final preferences = SharedPreferencesAsync();
    final store = SharedPreferencesScanMetadataStore(preferences);
    await preferences.setStringList(
      SharedPreferencesScanMetadataStore.queueKey,
      ['invalid-json'],
    );
    await expectLater(store.pending(), throwsFormatException);
    expect(
      await preferences.getStringList(
        SharedPreferencesScanMetadataStore.queueKey,
      ),
      ['invalid-json'],
    );
  });

  test(
    'typed roundtrip contains no media, token, geometry or proximity score',
    () {
      final source = metadataFixture();
      final encoded = jsonEncode(source.toJson());
      expect(
        ScanMetadata.fromJson(
          jsonDecode(encoded) as Map<String, dynamic>,
        ).toJson(),
        source.toJson(),
      );
      expect(source.events.single.toJson()['objectClass'], 'table_desk');
      expect(source.startPayload.keys, isNot(contains('ownerId')));
      expect(
        RegExp(
          'token|password|boundingBox|image|audio|score',
        ).hasMatch(encoded),
        isFalse,
      );
      expect(
        () => ScanMetadataEvent(
          id: metadataUuid(),
          kind: source.events.single.kind,
          confidence: 0.1234567,
          band: source.events.single.band,
          direction: source.events.single.direction,
          occurredAt: metadataStart,
        ),
        throwsFormatException,
      );
    },
  );

  test('conflicting local id never replaces an existing envelope', () async {
    final store = SharedPreferencesScanMetadataStore(SharedPreferencesAsync());
    final source = metadataFixture();
    await store.add(source);
    await expectLater(
      store.add(metadataFixture(id: source.id, events: 2)),
      throwsFormatException,
    );
    expect((await store.pending()).single.events, hasLength(1));
  });
}
