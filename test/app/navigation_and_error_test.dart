import 'package:eyes_mobile/app/app.dart';
import 'package:eyes_mobile/app/config/app_environment.dart';
import 'package:eyes_mobile/app/routing/app_router.dart';
import 'package:eyes_mobile/core/error/app_error_reporter.dart';
import 'package:eyes_mobile/core/error/global_error_view.dart';
import 'package:eyes_mobile/core/logging/secure_logger.dart';
import 'package:eyes_mobile/features/onboarding/application/onboarding_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_onboarding.dart';

void main() {
  testWidgets('unknown route explains the error and returns home', (
    WidgetTester tester,
  ) async {
    final environment = AppEnvironment.dev();
    final logger = SecureLogger(environment);
    final container = ProviderContainer(
      overrides: [
        appEnvironmentProvider.overrideWithValue(environment),
        secureLoggerProvider.overrideWithValue(logger),
        appErrorReporterProvider.overrideWithValue(AppErrorReporter(logger)),
        onboardingRepositoryProvider.overrideWithValue(
          InMemoryOnboardingRepository(completed: true),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const EyesApp()),
    );
    container.read(appRouterProvider).go('/unknown');
    await tester.pumpAndSettle();

    expect(find.text('Tela não encontrada'), findsOneWidget);
    expect(
      find.text('Não foi possível encontrar a tela solicitada.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Voltar ao início'));
    await tester.pumpAndSettle();

    expect(find.text('Assistência visual ao seu alcance'), findsOneWidget);
  });

  testWidgets('global error fallback exposes an accessible live message', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: GlobalErrorView()));

    expect(
      find.byWidgetPredicate(
        (Widget widget) =>
            widget is Semantics &&
            widget.properties.liveRegion == true &&
            widget.properties.label ==
                'Ocorreu um erro inesperado. Feche e abra o aplicativo.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('Feche e abra o aplicativo.'), findsOneWidget);
  });
}
