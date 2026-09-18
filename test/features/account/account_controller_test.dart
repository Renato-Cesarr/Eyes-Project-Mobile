import 'package:eyes_mobile/core/recovery/operational_failure.dart';
import 'package:eyes_mobile/core/session/remote_session_store.dart';
import 'package:eyes_mobile/features/account/application/account_controller.dart';
import 'package:eyes_mobile/features/account/application/auth_gateway.dart';
import 'package:eyes_mobile/features/account/application/metadata_sync_queue.dart';
import 'package:eyes_mobile/features/account/application/sync_preferences_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_account.dart';

void main() {
  test(
    'restores local state and authenticates without storing password',
    () async {
      final store = InMemoryRemoteSessionStore();
      final gateway = FakeAuthGateway();
      final preferences = InMemorySyncPreferencesRepository();
      final queue = InMemoryMetadataSyncQueue();
      final container = _container(store, gateway, preferences, queue);
      addTearDown(() async {
        container.dispose();
        await store.dispose();
      });

      await container.read(accountControllerProvider.future);
      await container
          .read(accountControllerProvider.notifier)
          .login(email: '  pessoa@example.com ', password: 'secret-value');

      final state = container.read(accountControllerProvider).requireValue;
      expect(state.session, testRemoteSession);
      expect(gateway.lastEmail, 'pessoa@example.com');
      expect(gateway.lastPassword, 'secret-value');
      expect(store.session?.accessToken, 'test-access-token');
    },
  );

  test('maps invalid credentials and preserves offline operation', () async {
    final store = InMemoryRemoteSessionStore();
    final gateway = FakeAuthGateway(
      failure: const AuthenticationFailure(
        AuthenticationFailureKind.invalidCredentials,
      ),
    );
    final container = _container(
      store,
      gateway,
      InMemorySyncPreferencesRepository(),
      InMemoryMetadataSyncQueue(),
    );
    addTearDown(() async {
      container.dispose();
      await store.dispose();
    });

    await container.read(accountControllerProvider.future);
    await container
        .read(accountControllerProvider.notifier)
        .login(email: 'pessoa@example.com', password: 'wrong');

    final state = container.read(accountControllerProvider).requireValue;
    expect(state.session, isNull);
    expect(state.failure?.kind, OperationalFailureKind.invalidCredentials);
    expect(state.failure?.impact, OperationalFailureImpact.degraded);
  });

  test('revoking consent clears queued metadata', () async {
    final store = InMemoryRemoteSessionStore(session: testRemoteSession);
    final preferences = InMemorySyncPreferencesRepository(consent: true);
    final queue = InMemoryMetadataSyncQueue();
    final container = _container(store, FakeAuthGateway(), preferences, queue);
    addTearDown(() async {
      container.dispose();
      await store.dispose();
    });

    await container.read(accountControllerProvider.future);
    await container
        .read(accountControllerProvider.notifier)
        .setSyncConsent(false);

    expect(preferences.consent, isFalse);
    expect(queue.clearCalls, 1);
  });

  test('signing out revokes consent and clears queued metadata', () async {
    final store = InMemoryRemoteSessionStore(session: testRemoteSession);
    final preferences = InMemorySyncPreferencesRepository(consent: true);
    final queue = InMemoryMetadataSyncQueue();
    final container = _container(store, FakeAuthGateway(), preferences, queue);
    addTearDown(() async {
      container.dispose();
      await store.dispose();
    });

    await container.read(accountControllerProvider.future);
    await container.read(accountControllerProvider.notifier).signOut();

    final state = container.read(accountControllerProvider).requireValue;
    expect(state.session, isNull);
    expect(state.syncConsent, isFalse);
    expect(preferences.consent, isFalse);
    expect(queue.clearCalls, 1);
  });

  test(
    'session expiration becomes a recoverable remote-only failure',
    () async {
      final store = InMemoryRemoteSessionStore(session: testRemoteSession);
      final container = _container(
        store,
        FakeAuthGateway(),
        InMemorySyncPreferencesRepository(),
        InMemoryMetadataSyncQueue(),
      );
      addTearDown(() async {
        container.dispose();
        await store.dispose();
      });

      await container.read(accountControllerProvider.future);
      await store.expire();
      await Future<void>.delayed(Duration.zero);

      final state = container.read(accountControllerProvider).requireValue;
      expect(state.session, isNull);
      expect(state.failure?.kind, OperationalFailureKind.sessionExpired);
      expect(state.failure?.blocksAssistiveScan, isFalse);
    },
  );
}

ProviderContainer _container(
  InMemoryRemoteSessionStore store,
  FakeAuthGateway gateway,
  InMemorySyncPreferencesRepository preferences,
  InMemoryMetadataSyncQueue queue,
) => ProviderContainer(
  overrides: [
    remoteSessionStoreProvider.overrideWithValue(store),
    authGatewayProvider.overrideWithValue(gateway),
    syncPreferencesRepositoryProvider.overrideWithValue(preferences),
    metadataSyncQueueProvider.overrideWithValue(queue),
  ],
);
