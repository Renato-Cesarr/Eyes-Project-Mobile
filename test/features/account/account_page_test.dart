import 'package:eyes_mobile/app/app.dart';
import 'package:eyes_mobile/app/config/app_environment.dart';
import 'package:eyes_mobile/app/routing/app_router.dart';
import 'package:eyes_mobile/core/accessibility/accessible_feedback_service.dart';
import 'package:eyes_mobile/core/error/app_error_reporter.dart';
import 'package:eyes_mobile/core/logging/secure_logger.dart';
import 'package:eyes_mobile/core/session/remote_session_store.dart';
import 'package:eyes_mobile/features/account/application/auth_gateway.dart';
import 'package:eyes_mobile/features/account/application/metadata_sync_queue.dart';
import 'package:eyes_mobile/features/account/application/sync_preferences_repository.dart';
import 'package:eyes_mobile/features/onboarding/application/onboarding_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_account.dart';
import '../../support/fake_onboarding.dart';

final class _SilentFeedback implements AccessibleFeedbackService {
  @override
  Future<void> confirm() async {}

  @override
  Future<void> warn() async {}
}

void main() {
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
}) async {
  final environment = AppEnvironment.dev();
  final logger = SecureLogger(environment);
  final sessionStore = store ?? InMemoryRemoteSessionStore();
  final container = ProviderContainer(
    overrides: [
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
