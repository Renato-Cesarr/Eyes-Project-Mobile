import 'dart:async';

import 'package:eyes_mobile/app/app.dart';
import 'package:eyes_mobile/app/config/app_environment.dart';
import 'package:eyes_mobile/app/routing/app_router.dart';
import 'package:eyes_mobile/core/accessibility/accessible_feedback_service.dart';
import 'package:eyes_mobile/core/error/app_error_reporter.dart';
import 'package:eyes_mobile/core/logging/secure_logger.dart';
import 'package:eyes_mobile/core/session/remote_session_store.dart';
import 'package:eyes_mobile/features/account/application/account_controller.dart';
import 'package:eyes_mobile/features/account/application/auth_gateway.dart';
import 'package:eyes_mobile/features/account/application/metadata_sync_queue.dart';
import 'package:eyes_mobile/features/account/application/scan_metadata_sync.dart';
import 'package:eyes_mobile/features/account/application/sync_preferences_repository.dart';
import 'package:eyes_mobile/features/account/infrastructure/shared_preferences_scan_metadata_store.dart';
import 'package:eyes_mobile/features/onboarding/application/onboarding_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../../support/fake_account.dart';
import '../../support/fake_onboarding.dart';
import '../../support/scan_metadata_fixture.dart';

final class _SilentFeedback implements AccessibleFeedbackService {
  @override
  Future<void> confirm() async {}

  @override
  Future<void> warn() async {}
}

void main() {
  testWidgets(
    'guest without pending metadata keeps optional login uncluttered',
    (tester) async {
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();
      final sessions = InMemoryRemoteSessionStore();
      final sync = ScanMetadataSync(
        store: SharedPreferencesScanMetadataStore(SharedPreferencesAsync()),
        preferences: InMemorySyncPreferencesRepository(),
        accounts: sessions,
        gateway: FakeScanMetadataGateway(),
        retryDelays: const [],
      );
      await sync.ready;
      final fixture = await _pumpAccount(tester, store: sessions, sync: sync);
      expect(find.text('Entrar'), findsOneWidget);
      expect(find.textContaining('Sessões pendentes:'), findsNothing);
      expect(find.text('Continuar para a varredura offline'), findsOneWidget);
      expect(tester.takeException(), isNull);
      fixture.container.dispose();
      unawaited(sync.dispose());
      await tester.pump();
      await sessions.dispose();
    },
  );

  testWidgets(
    '401 keeps pending status visible and recovers after login at 200 percent',
    (tester) async {
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();
      final sessions = InMemoryRemoteSessionStore(session: testRemoteSession);
      final prefs = InMemorySyncPreferencesRepository();
      final store = SharedPreferencesScanMetadataStore(
        SharedPreferencesAsync(),
      );
      final gateway = FakeScanMetadataGateway()
        ..onUpload = (_, _) async => throw metadataHttpFailure(401);
      final sync = ScanMetadataSync(
        store: store,
        preferences: prefs,
        accounts: sessions,
        gateway: gateway,
        retryDelays: const [],
      );
      await sync.ready;
      await sync.setConsent(true);
      await store.add(metadataFixture());
      await sync.retryManually();
      tester.view.physicalSize = const Size(320, 844);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        tester.platformDispatcher.clearTextScaleFactorTestValue();
      });
      final fixture = await _pumpAccount(
        tester,
        store: sessions,
        preferences: prefs,
        sync: sync,
      );
      expect(
        find.textContaining('Entre novamente na mesma conta'),
        findsOneWidget,
      );
      expect(find.textContaining('Sessões pendentes: 1.'), findsOneWidget);
      expect(find.text('Tentar enviar pendentes'), findsNothing);
      expect(find.text('Excluir histórico de metadados'), findsNothing);
      expect(await store.pending(), hasLength(1));
      gateway.onUpload = null;
      await tester.ensureVisible(find.widgetWithText(TextFormField, 'E-mail'));
      await tester.enterText(
        find.widgetWithText(TextFormField, 'E-mail'),
        'pessoa@example.com',
      );
      await tester.ensureVisible(find.widgetWithText(TextFormField, 'Senha'));
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Senha'),
        'test-password',
      );
      await tester.ensureVisible(find.text('Entrar'));
      await tester.tap(find.text('Entrar'));
      await tester.pumpAndSettle();
      expect(find.text('Conta conectada'), findsOneWidget);
      expect(await store.pending(), isEmpty);
      expect(find.textContaining('Sessões pendentes: 0.'), findsOneWidget);
      expect(tester.takeException(), isNull);
      fixture.container.dispose();
      unawaited(sync.dispose());
      await tester.pump();
      await sessions.dispose();
    },
  );

  testWidgets('pending sync is recoverable and reachable at 200 percent text', (
    tester,
  ) async {
    late InMemoryRemoteSessionStore sessions;
    late InMemorySyncPreferencesRepository prefs;
    late SharedPreferencesScanMetadataStore store;
    late FakeScanMetadataGateway gateway;
    late ScanMetadataSync sync;
    {
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();
      sessions = InMemoryRemoteSessionStore(session: testRemoteSession);
      prefs = InMemorySyncPreferencesRepository();
      store = SharedPreferencesScanMetadataStore(SharedPreferencesAsync());
      gateway = FakeScanMetadataGateway()
        ..onUpload = (_, _) async => throw metadataHttpFailure(500);
      sync = ScanMetadataSync(
        store: store,
        preferences: prefs,
        accounts: sessions,
        gateway: gateway,
        retryDelays: const [],
      );
      await sync.ready;
      await sync.setConsent(true);
      await store.add(metadataFixture());
      await sync.retryManually();
    }
    tester.view.physicalSize = const Size(320, 844);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.platformDispatcher.clearTextScaleFactorTestValue();
    });
    final fixture = await _pumpAccount(
      tester,
      store: sessions,
      preferences: prefs,
      sync: sync,
    );

    expect(
      find.textContaining('pendentes permanecem neste aparelho'),
      findsOneWidget,
    );
    expect(find.textContaining('Sessões pendentes: 1.'), findsOneWidget);
    await tester.ensureVisible(find.text('Tentar enviar pendentes'));
    await tester.pumpAndSettle();
    gateway.onUpload = null;
    await tester.tap(find.text('Tentar enviar pendentes'));
    await tester.pumpAndSettle();
    expect(await store.pending(), isEmpty);
    expect(find.textContaining('Sem sessões pendentes'), findsOneWidget);
    expect(tester.takeException(), isNull);
    fixture.container.dispose();
    unawaited(sync.dispose());
    await tester.pump();
    await sessions.dispose();
  });

  testWidgets(
    'history deletion requires explicit confirmation and updates consent',
    (tester) async {
      late InMemoryRemoteSessionStore sessions;
      late InMemorySyncPreferencesRepository prefs;
      late SharedPreferencesScanMetadataStore store;
      late FakeScanMetadataGateway gateway;
      late ScanMetadataSync sync;
      {
        SharedPreferencesAsyncPlatform.instance =
            InMemorySharedPreferencesAsync.empty();
        sessions = InMemoryRemoteSessionStore(session: testRemoteSession);
        prefs = InMemorySyncPreferencesRepository();
        store = SharedPreferencesScanMetadataStore(SharedPreferencesAsync());
        gateway = FakeScanMetadataGateway();
        sync = ScanMetadataSync(
          store: store,
          preferences: prefs,
          accounts: sessions,
          gateway: gateway,
          retryDelays: const [],
        );
        await sync.ready;
        await sync.setConsent(true);
      }
      final fixture = await _pumpAccount(
        tester,
        store: sessions,
        preferences: prefs,
        sync: sync,
      );

      await tester.ensureVisible(find.text('Excluir histórico de metadados'));
      await tester.tap(find.text('Excluir histórico de metadados'));
      await tester.pumpAndSettle();
      expect(gateway.deleteCalls, 0);
      expect(
        find.textContaining('exclusão só será confirmada'),
        findsOneWidget,
      );
      await tester.tap(find.text('Desativar e excluir'));
      await tester.pumpAndSettle();
      expect(gateway.deleteCalls, 1);
      expect(
        fixture.container
            .read(accountControllerProvider)
            .requireValue
            .syncConsent,
        isFalse,
      );
      expect(find.textContaining('Histórico remoto excluído'), findsOneWidget);
      expect(tester.takeException(), isNull);
      fixture.container.dispose();
      unawaited(sync.dispose());
      await tester.pump();
      await sessions.dispose();
    },
  );

  testWidgets('login is optional, accessible and safe at 200 percent text', (
    WidgetTester tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final fixture = await _pumpAccount(tester);
    addTearDown(fixture.dispose);

    expect(find.text('Conta opcional'), findsOneWidget);
    expect(
      find.textContaining('continuam funcionando localmente'),
      findsOneWidget,
    );
    expect(find.byType(AutofillGroup), findsOneWidget);
    expect(find.byTooltip('Mostrar senha'), findsOneWidget);
    expect(find.text('Continuar para a varredura offline'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('validates fields and maps invalid credentials accessibly', (
    WidgetTester tester,
  ) async {
    final fixture = await _pumpAccount(
      tester,
      gateway: FakeAuthGateway(
        failure: const AuthenticationFailure(
          AuthenticationFailureKind.invalidCredentials,
        ),
      ),
    );
    addTearDown(fixture.dispose);

    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();
    expect(find.text('Informe o e-mail.'), findsOneWidget);
    expect(find.text('Informe a senha.'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'E-mail'),
      'pessoa@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Senha'),
      'incorrect',
    );
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();

    expect(find.text('Não foi possível entrar'), findsOneWidget);
    expect(
      find.textContaining('continue usando a varredura offline'),
      findsOneWidget,
    );
    expect(find.text('Continuar para a varredura offline'), findsOneWidget);
  });

  testWidgets('requires explicit consent and revokes it with local queue', (
    WidgetTester tester,
  ) async {
    final store = InMemoryRemoteSessionStore(session: testRemoteSession);
    final preferences = InMemorySyncPreferencesRepository();
    final queue = InMemoryMetadataSyncQueue();
    final fixture = await _pumpAccount(
      tester,
      store: store,
      preferences: preferences,
      queue: queue,
    );
    addTearDown(fixture.dispose);

    expect(find.text('Conta conectada'), findsOneWidget);
    final consentSwitch = find.byType(Switch);
    await tester.ensureVisible(consentSwitch);
    await tester.pumpAndSettle();
    await tester.tap(consentSwitch);
    await tester.pumpAndSettle();
    expect(find.text('Permitir sincronização?'), findsOneWidget);
    expect(preferences.consent, isFalse);

    await tester.tap(find.widgetWithText(FilledButton, 'Permitir'));
    await tester.pumpAndSettle();
    expect(preferences.consent, isTrue);
    expect(
      find.text('Consentimento de sincronização ativado.'),
      findsOneWidget,
    );

    await tester.ensureVisible(consentSwitch);
    await tester.pumpAndSettle();
    await tester.tap(consentSwitch);
    await tester.pumpAndSettle();
    expect(preferences.consent, isFalse);
    expect(queue.clearCalls, 1);
  });
}

Future<_AccountFixture> _pumpAccount(
  WidgetTester tester, {
  InMemoryRemoteSessionStore? store,
  FakeAuthGateway? gateway,
  InMemorySyncPreferencesRepository? preferences,
  InMemoryMetadataSyncQueue? queue,
  ScanMetadataSync? sync,
}) async {
  final environment = AppEnvironment.dev();
  final logger = SecureLogger(environment);
  final sessionStore = store ?? InMemoryRemoteSessionStore();
  final container = ProviderContainer(
    overrides: [
      scanMetadataSyncProvider.overrideWithValue(sync),
      appEnvironmentProvider.overrideWithValue(environment),
      secureLoggerProvider.overrideWithValue(logger),
      appErrorReporterProvider.overrideWithValue(AppErrorReporter(logger)),
      accessibleFeedbackServiceProvider.overrideWithValue(_SilentFeedback()),
      onboardingRepositoryProvider.overrideWithValue(
        InMemoryOnboardingRepository(completed: true),
      ),
      remoteSessionStoreProvider.overrideWithValue(sessionStore),
      authGatewayProvider.overrideWithValue(gateway ?? FakeAuthGateway()),
      syncPreferencesRepositoryProvider.overrideWithValue(
        preferences ?? InMemorySyncPreferencesRepository(),
      ),
      metadataSyncQueueProvider.overrideWithValue(
        queue ?? InMemoryMetadataSyncQueue(),
      ),
    ],
  );
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const EyesApp()),
  );
  await tester.pumpAndSettle();
  container.read(appRouterProvider).goNamed(AppRoutes.account);
  await tester.pumpAndSettle();
  return _AccountFixture(container, sessionStore);
}

final class _AccountFixture {
  const _AccountFixture(this.container, this.store);

  final ProviderContainer container;
  final InMemoryRemoteSessionStore store;

  Future<void> dispose() async {
    container.dispose();
    await store.dispose();
  }
}
