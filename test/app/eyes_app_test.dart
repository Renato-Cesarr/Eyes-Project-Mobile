import 'package:eyes_mobile/app/app.dart';
import 'package:eyes_mobile/app/config/app_environment.dart';
import 'package:eyes_mobile/core/accessibility/accessible_feedback_service.dart';
import 'package:eyes_mobile/core/error/app_error_reporter.dart';
import 'package:eyes_mobile/core/logging/secure_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final class _FakeAccessibleFeedbackService
    implements AccessibleFeedbackService {
  var confirmationCount = 0;

  @override
  Future<void> confirm() async => confirmationCount++;

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
        ],
        child: const EyesApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Assistência visual ao seu alcance'), findsOneWidget);
  });
}
