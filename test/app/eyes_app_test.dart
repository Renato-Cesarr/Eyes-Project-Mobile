import 'dart:async';

import 'package:eyes_mobile/app/app.dart';
import 'package:eyes_mobile/app/config/app_environment.dart';
import 'package:eyes_mobile/core/accessibility/accessible_feedback_service.dart';
import 'package:eyes_mobile/core/error/app_error_reporter.dart';
import 'package:eyes_mobile/core/logging/secure_logger.dart';
import 'package:eyes_mobile/features/home/application/home_controller.dart';
import 'package:eyes_mobile/features/home/domain/home_state.dart';
import 'package:eyes_mobile/features/onboarding/application/onboarding_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_onboarding.dart';

final class _FakeAccessibleFeedbackService
    implements AccessibleFeedbackService {
  var confirmationCount = 0;

  @override
  Future<void> confirm() async => confirmationCount++;

  @override
  Future<void> warn() async {}
}

final class _FailingAccessibleFeedbackService
    implements AccessibleFeedbackService {
  @override
  Future<void> confirm() => Future<void>.error(StateError('unavailable'));

  @override
  Future<void> warn() async {}
}

void main() {
  testWidgets('renders an accessible foundation and delivers feedback', (
    WidgetTester tester,
  ) async {
    final environment = AppEnvironment.dev();
    final logger = SecureLogger(environment);
    final errorReporter = AppErrorReporter(logger);
    final feedbackService = _FakeAccessibleFeedbackService();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appEnvironmentProvider.overrideWithValue(environment),
          secureLoggerProvider.overrideWithValue(logger),
          appErrorReporterProvider.overrideWithValue(errorReporter),
          accessibleFeedbackServiceProvider.overrideWithValue(feedbackService),
          onboardingRepositoryProvider.overrideWithValue(
            InMemoryOnboardingRepository(completed: true),
          ),
        ],
        child: const EyesApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Assistência visual ao seu alcance'), findsOneWidget);
    expect(find.bySemanticsLabel('Testar vibração e som'), findsWidgets);

    final feedbackButton = find.text('Testar vibração e som');
    await tester.ensureVisible(feedbackButton);
    await tester.pumpAndSettle();
    await tester.tap(feedbackButton);
    await tester.pumpAndSettle();

    expect(feedbackService.confirmationCount, 1);
    expect(find.text('Feedback tátil e sonoro confirmado.'), findsOneWidget);
  });

  testWidgets('supports large fonts and high contrast without overflow', (
    WidgetTester tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(highContrast: true);
    addTearDown(() {
      tester.platformDispatcher.clearTextScaleFactorTestValue();
      tester.platformDispatcher.clearAccessibilityFeaturesTestValue();
    });

    final environment = AppEnvironment.dev();
    final logger = SecureLogger(environment);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appEnvironmentProvider.overrideWithValue(environment),
          secureLoggerProvider.overrideWithValue(logger),
          appErrorReporterProvider.overrideWithValue(AppErrorReporter(logger)),
          accessibleFeedbackServiceProvider.overrideWithValue(
            _FakeAccessibleFeedbackService(),
          ),
          onboardingRepositoryProvider.overrideWithValue(
            InMemoryOnboardingRepository(completed: true),
          ),
        ],
        child: const EyesApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Assistência visual ao seu alcance'), findsOneWidget);
  });

  testWidgets('announces an accessible fallback when device feedback fails', (
    WidgetTester tester,
  ) async {
    final environment = AppEnvironment.dev();
    final logger = SecureLogger(environment);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appEnvironmentProvider.overrideWithValue(environment),
          secureLoggerProvider.overrideWithValue(logger),
          appErrorReporterProvider.overrideWithValue(AppErrorReporter(logger)),
          accessibleFeedbackServiceProvider.overrideWithValue(
            _FailingAccessibleFeedbackService(),
          ),
          onboardingRepositoryProvider.overrideWithValue(
            InMemoryOnboardingRepository(completed: true),
          ),
        ],
        child: const EyesApp(),
      ),
    );
    await tester.pumpAndSettle();

    final feedbackButton = find.text('Testar vibração e som');
    await tester.ensureVisible(feedbackButton);
    await tester.pumpAndSettle();
    await tester.tap(feedbackButton);
    await tester.pumpAndSettle();

    expect(
      find.text('Não foi possível reproduzir o feedback neste aparelho.'),
      findsOneWidget,
    );
  });

  testWidgets('announces loading while the home state is pending', (
    WidgetTester tester,
  ) async {
    final pendingState = Completer<HomeState>();
    final environment = AppEnvironment.dev();
    final logger = SecureLogger(environment);
    addTearDown(() {
      if (!pendingState.isCompleted) {
        pendingState.complete(const HomeState());
      }
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appEnvironmentProvider.overrideWithValue(environment),
          secureLoggerProvider.overrideWithValue(logger),
          appErrorReporterProvider.overrideWithValue(AppErrorReporter(logger)),
          homeControllerProvider.overrideWithBuild(
            (ref, notifier) => pendingState.future,
          ),
          onboardingRepositoryProvider.overrideWithValue(
            InMemoryOnboardingRepository(completed: true),
          ),
        ],
        child: const EyesApp(),
      ),
    );
    await tester.pump();

    expect(find.bySemanticsLabel('Carregando'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('offers retry when loading the home state fails', (
    WidgetTester tester,
  ) async {
    final environment = AppEnvironment.dev();
    final logger = SecureLogger(environment);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appEnvironmentProvider.overrideWithValue(environment),
          secureLoggerProvider.overrideWithValue(logger),
          appErrorReporterProvider.overrideWithValue(AppErrorReporter(logger)),
          homeControllerProvider.overrideWithBuild(
            (ref, notifier) async => throw StateError('load failed'),
          ),
          onboardingRepositoryProvider.overrideWithValue(
            InMemoryOnboardingRepository(completed: true),
          ),
        ],
        child: const EyesApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ocorreu um erro inesperado.'), findsOneWidget);
    await tester.tap(find.text('Tentar novamente'));
    await tester.pumpAndSettle();
    expect(find.text('Ocorreu um erro inesperado.'), findsOneWidget);
  });
}
