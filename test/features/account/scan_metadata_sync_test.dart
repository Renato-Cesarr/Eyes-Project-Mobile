import 'dart:async';

import 'package:eyes_mobile/core/session/remote_session.dart';
import 'package:eyes_mobile/features/account/application/scan_metadata_alert_observer.dart';
import 'package:eyes_mobile/features/account/application/scan_metadata_sync.dart';
import 'package:eyes_mobile/features/account/infrastructure/shared_preferences_scan_metadata_store.dart';
import 'package:eyes_mobile/features/assistive_feedback/application/assistive_alert_observer.dart';
import 'package:eyes_mobile/features/assistive_feedback/domain/assistive_alert_message.dart';
import 'package:eyes_mobile/features/assistive_feedback/domain/feedback_preferences.dart';
import 'package:eyes_mobile/features/object_detection/domain/detected_object.dart';
import 'package:eyes_mobile/features/proximity/domain/proximity_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../../support/fake_account.dart';
import '../../support/flaky_scan_metadata_store.dart';
import '../../support/scan_metadata_fixture.dart';

Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 20));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SharedPreferencesScanMetadataStore store;
  late InMemorySyncPreferencesRepository preferences;
  late InMemoryRemoteSessionStore accounts;
  late FakeScanMetadataGateway gateway;
  late ScanMetadataSync sync;
  late DateTime now;

  setUp(() async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    store = SharedPreferencesScanMetadataStore(SharedPreferencesAsync());
    preferences = InMemorySyncPreferencesRepository();
    accounts = InMemoryRemoteSessionStore(session: testRemoteSession);
    gateway = FakeScanMetadataGateway();
    now = metadataStart;
    sync = ScanMetadataSync(
      store: store,
      preferences: preferences,
      accounts: accounts,
      gateway: gateway,
      clock: () => now,
      retryDelays: const [],
    );
    await sync.ready;
  });
  tearDown(() async {
    await sync.dispose();
    await accounts.dispose();
  });

  DetectionBatch frame() => DetectionBatch(
    detections: [],
    capturedAt: now,
    timings: const DetectionTimings(
      preprocessing: Duration.zero,
      inference: Duration(milliseconds: 4),
      postprocessing: Duration.zero,
    ),
  );

  ProximityAlertEvent event() => ProximityAlertEvent(
    trackId: 1,
    kind: DetectedObjectKind.table,
    band: ProximityBand.veryNear,
    direction: ProximityDirection.left,
    score: 0.98,
    confidence: 0.87654321,
    priority: 1,
    occurredAt: now,
  );

  test(
    'no consent, absent account and legacy boolean never produce or upload',
    () async {
      preferences.consent = true; // old version had no account-bound grant
      sync.setScanning(true);
      sync.recordFrame(frame());
      sync.setScanning(false);
      await settle();
      await sync.retryManually();
      expect(await store.pending(), isEmpty);
      expect(gateway.sent, isEmpty);
      await accounts.clear();
      await settle();
      await sync.setConsent(true);
      expect(sync.consented, isFalse);
    },
  );

  test(
    'records actual TTS landmarks and model confidence; no HTTP during scan',
    () async {
      await sync.setConsent(true);
      sync.setScanning(true);
      sync.recordFrame(frame());
      final alert = event();
      final message = AssistiveAlertMessageComposer.compose(
        alert,
        VoiceDetailLevel.concise,
      );
      final observer = ScanMetadataAlertObserver(
        sync,
        const NoopAssistiveAlertObserver(),
      );
      observer.onAlertQueued(alert, message);
      observer.onPlaybackRequested(message);
      now = now.add(const Duration(milliseconds: 750));
      sync.recordSpeechStarted(message.text, now);
      sync.recordSpeechStarted(message.text, now); // duplicate native callback
      await sync.retry();
      expect(gateway.sent, isEmpty);
      sync.setScanning(false);
      await settle();
      expect(gateway.sent, hasLength(1));
      final data = gateway.sent.single;
      expect(data.events.single.confidence, 0.876543);
      expect(data.events.single.kind, DetectedObjectKind.table);
      expect(data.processedFrames, 1);
      expect(data.inferenceMillisTotal, 4);
      expect(data.ttsLatencySamples, 1);
      expect(data.ttsLatencyMillisTotal, 750);
      expect(await store.pending(), isEmpty);
    },
  );

  test(
    'queue entries without a real playback start are not announced events',
    () async {
      await sync.setConsent(true);
      sync.setScanning(true);
      sync.recordFrame(frame());
      final alert = event();
      final message = AssistiveAlertMessageComposer.compose(
        alert,
        VoiceDetailLevel.concise,
      );
      sync.onAlertQueued(alert, message);
      now = now.add(const Duration(seconds: 1));
      sync.setScanning(false);
      await settle();
      expect(gateway.sent.single.events, isEmpty);
      expect(gateway.sent.single.ttsLatencySamples, 0);
    },
  );

  test(
    'segments 201 spoken events into 200 and 1 with real frame counts',
    () async {
      await sync.setConsent(true);
      sync.setScanning(true);
      for (var i = 0; i < 201; i++) {
        now = now.add(const Duration(milliseconds: 10));
        sync.recordFrame(frame());
        final alert = event();
        final message = AssistiveAlertMessageComposer.compose(
          alert,
          VoiceDetailLevel.concise,
        );
        sync.onAlertQueued(alert, message);
        sync.onPlaybackRequested(message);
        sync.recordSpeechStarted(
          message.text,
          now.add(const Duration(milliseconds: 2)),
        );
      }
      sync.setScanning(false);
      await settle();
      expect(gateway.sent.map((s) => s.events.length), [200, 1]);
      expect(gateway.sent.map((s) => s.processedFrames), [200, 1]);
    },
  );

  test(
    'timer retry uses bounded backoff and stops at configured limit',
    () async {
      await sync.dispose();
      sync = ScanMetadataSync(
        store: store,
        preferences: preferences,
        accounts: accounts,
        gateway: gateway,
        clock: () => now,
        retryDelays: const [
          Duration(milliseconds: 10),
          Duration(milliseconds: 20),
        ],
      );
      await sync.ready;
      await sync.setConsent(true);
      await store.add(metadataFixture());
      gateway.onUpload = (_, _) async => throw metadataHttpFailure(500);
      await sync.retryManually();
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(gateway.sent, hasLength(3));
      await Future<void>.delayed(const Duration(milliseconds: 40));
      expect(gateway.sent, hasLength(3));
      expect(await store.pending(), hasLength(1));
    },
  );

  test(
    'deletion failure never claims success and can be retried explicitly',
    () async {
      await sync.setConsent(true);
      await store.add(metadataFixture());
      gateway.onDelete = (_) async => throw metadataHttpFailure(500);
      await sync.deleteHistory();
      expect(sync.snapshot.status, ScanSyncStatus.deleteFailed);
      expect(sync.consented, isFalse);
      gateway.onDelete = null;
      await sync.deleteHistory();
      expect(sync.snapshot.status, ScanSyncStatus.deleted);
    },
  );

  test('unconfigured server cannot enable consent or collect', () async {
    await sync.dispose();
    sync = ScanMetadataSync(
      store: store,
      preferences: preferences,
      accounts: accounts,
      gateway: gateway,
      remoteAvailable: false,
      clock: () => now,
    );
    await sync.ready;
    await sync.setConsent(true);
    expect(sync.consented, isFalse);
    expect(sync.snapshot.status, ScanSyncStatus.unavailable);
    sync.setScanning(true);
    sync.recordFrame(frame());
    sync.setScanning(false);
    await settle();
    expect(gateway.sent, isEmpty);
  });

  test(
    'failed local persistence is visible and can be recovered without HTTP data loss',
    () async {
      await sync.dispose();
      final flaky = FlakyScanMetadataStore(store);
      sync = ScanMetadataSync(
        store: flaky,
        preferences: preferences,
        accounts: accounts,
        gateway: gateway,
        clock: () => now,
        retryDelays: const [],
      );
      await sync.ready;
      await sync.setConsent(true);
      sync.setScanning(true);
      sync.recordFrame(frame());
      now = now.add(const Duration(seconds: 1));
      sync.setScanning(false);
      await settle();
      expect(sync.snapshot.status, ScanSyncStatus.storageFailure);
      expect(sync.snapshot.pendingSessions, 1);
      expect(gateway.sent, isEmpty);
      flaky.failWrites = false;
      await sync.retryManually();
      expect(gateway.sent.single.processedFrames, 1);
      expect(await store.pending(), isEmpty);
    },
  );

  test(
    'corrupt queue blocks upload and keeps bytes for explicit recovery',
    () async {
      await sync.setConsent(true);
      final preferencesStore = SharedPreferencesAsync();
      await preferencesStore.setStringList(
        SharedPreferencesScanMetadataStore.queueKey,
        ['bad-json'],
      );
      await sync.retryManually();
      expect(sync.snapshot.status, ScanSyncStatus.storageFailure);
      expect(gateway.sent, isEmpty);
      expect(
        await preferencesStore.getStringList(
          SharedPreferencesScanMetadataStore.queueKey,
        ),
        ['bad-json'],
      );
    },
  );

  test(
    'inference sums preserve sub-millisecond measurements before rounding',
    () async {
      await sync.setConsent(true);
      sync.setScanning(true);
      for (var i = 0; i < 2; i++) {
        sync.recordFrame(
          DetectionBatch(
            detections: [],
            capturedAt: now,
            timings: const DetectionTimings(
              preprocessing: Duration.zero,
              inference: Duration(microseconds: 600),
              postprocessing: Duration.zero,
            ),
          ),
        );
      }
      now = now.add(const Duration(seconds: 1));
      sync.setScanning(false);
      await settle();
      expect(gateway.sent.single.inferenceMillisTotal, 1);
    },
  );

  test(
    'restored consent survives camera starting during asynchronous hydration',
    () async {
      await sync.dispose();
      await store.writeConsentOwner(testRemoteSession.user.id);
      preferences.consent = true;
      sync = ScanMetadataSync(
        store: store,
        preferences: preferences,
        accounts: accounts,
        gateway: gateway,
        clock: () => now,
        retryDelays: const [],
      );
      sync.setScanning(true);
      await sync.ready;
      expect(sync.consented, isTrue);
      expect(sync.snapshot.status, ScanSyncStatus.collecting);
      sync.recordFrame(frame());
      now = now.add(const Duration(seconds: 1));
      sync.setScanning(false);
      await settle();
      expect(gateway.sent.single.processedFrames, 1);
    },
  );

  for (final status in <int?>[null, 500, 408, 429, 401, 403, 404, 409, 422]) {
    test(
      'HTTP $status preserves immutable envelope and stops aggressive retry',
      () async {
        await sync.setConsent(true);
        final data = metadataFixture();
        await store.add(data);
        gateway.onUpload = (_, _) async => throw metadataHttpFailure(status);
        await sync.retryManually();
        await settle();
        expect((await store.pending()).single.toJson(), data.toJson());
        expect(gateway.sent, hasLength(1));
        expect(
          sync.snapshot.status,
          status == 401
              ? ScanSyncStatus.authenticationRequired
              : status == 409
              ? ScanSyncStatus.unavailable
              : status == null ||
                    status >= 500 ||
                    status == 408 ||
                    status == 429
              ? ScanSyncStatus.retryable
              : ScanSyncStatus.blocked,
        );
        if (status == 401) expect(accounts.session, isNull);
      },
    );
  }

  test(
    'transient failure retries exact IDs and removes only after confirmation',
    () async {
      await sync.setConsent(true);
      final data = metadataFixture();
      await store.add(data);
      gateway.onUpload = (_, _) async => throw metadataHttpFailure(500);
      await sync.retryManually();
      gateway.onUpload = null;
      await sync.retryManually();
      expect(gateway.sent.map((s) => s.toJson()), [
        data.toJson(),
        data.toJson(),
      ]);
      expect(await store.pending(), isEmpty);
    },
  );

  test('new scan cancels upload and leaves closed session queued', () async {
    await sync.setConsent(true);
    await store.add(metadataFixture());
    final entered = Completer<void>();
    gateway.onUpload = (_, token) async {
      entered.complete();
      await token.whenCancel;
      throw metadataHttpFailure(null);
    };
    final upload = sync.retryManually();
    await entered.future;
    sync.setScanning(true);
    await upload;
    expect(await store.pending(), hasLength(1));
    expect(sync.snapshot.status, ScanSyncStatus.collecting);
  });

  test(
    'revocation drains cancellation then clears pending; deletion follows upload',
    () async {
      await sync.setConsent(true);
      await store.add(metadataFixture());
      final entered = Completer<void>();
      final order = <String>[];
      gateway.onUpload = (_, token) async {
        entered.complete();
        await token.whenCancel;
        order.add('cancelled');
      };
      gateway.onDelete = (_) async => order.add('delete');
      final upload = sync.retryManually();
      await entered.future;
      await sync.deleteHistory();
      await upload;
      expect(order, ['cancelled', 'delete']);
      expect(sync.consented, isFalse);
      expect(preferences.consent, isFalse);
      expect(await store.pending(), isEmpty);
      expect(await store.readConsentOwner(), isNull);
      expect(sync.snapshot.status, ScanSyncStatus.deleted);
    },
  );

  test(
    'expired account keeps queue and resumes only for original owner',
    () async {
      await sync.setConsent(true);
      final data = metadataFixture();
      await store.add(data);
      await accounts.expire();
      await settle();
      await accounts.save(
        const RemoteSession(
          accessToken: 'other',
          user: RemoteUser(
            id: 'other-owner',
            name: 'Other',
            email: 'other@example.com',
          ),
        ),
      );
      await settle();
      await sync.retryManually();
      expect(gateway.sent, isEmpty);
      expect((await store.pending()).single.id, data.id);
      await accounts.save(testRemoteSession);
      await settle();
      await sync.retryManually();
      expect(gateway.owners, [testRemoteSession.user.id]);
      expect(await store.pending(), isEmpty);
    },
  );

  test(
    'expired local data is retained and surfaced without futile HTTP',
    () async {
      await sync.setConsent(true);
      await store.add(
        metadataFixture(
          start: metadataStart.subtract(const Duration(days: 31)),
        ),
      );
      await sync.retryManually();
      expect(gateway.sent, isEmpty);
      expect(await store.pending(), hasLength(1));
      expect(sync.snapshot.status, ScanSyncStatus.blocked);
    },
  );

  test(
    'queue capacity pauses collection without discarding previous sessions',
    () async {
      await sync.setConsent(true);
      await Future.wait(List.generate(20, (_) => store.add(metadataFixture())));
      await sync.retryManually(); // preserve queue on service failure
      // refill after the successful fake upload
      await Future.wait(List.generate(20, (_) => store.add(metadataFixture())));
      gateway.onUpload = (_, _) async => throw metadataHttpFailure(500);
      await sync.retryManually();
      sync.setScanning(true);
      sync.recordFrame(frame());
      expect(sync.snapshot.status, ScanSyncStatus.queueFull);
      expect(await store.pending(), hasLength(20));
    },
  );
}
