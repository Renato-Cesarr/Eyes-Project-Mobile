import 'package:eyes_mobile/app/config/app_environment.dart';
import 'package:eyes_mobile/app/theme/app_theme.dart';
import 'package:eyes_mobile/core/error/app_error_reporter.dart';
import 'package:eyes_mobile/core/logging/secure_logger.dart';
import 'package:eyes_mobile/features/assistive_feedback/application/assistive_feedback_controller.dart';
import 'package:eyes_mobile/features/assistive_feedback/presentation/feedback_settings_page.dart';
import 'package:eyes_mobile/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_assistive_feedback.dart';

void main() {
  testWidgets('expõe controles acessíveis e persiste alterações', (
    tester,
  ) async {
    final repository = InMemoryFeedbackPreferencesRepository();
    final speech = FakeSpeechGateway();
    final haptics = FakeAssistiveHaptics();
    await _pumpPage(tester, repository, speech, haptics);

    expect(find.text('Áudio, alertas e vibração'), findsOneWidget);
    expect(find.bySemanticsLabel('Velocidade da voz'), findsOneWidget);
    expect(find.bySemanticsLabel('Volume da voz'), findsOneWidget);

    final attention = find.text('Avisar também objetos próximos');
    await tester.drag(find.byType(ListView), const Offset(0, -260));
    await tester.pumpAndSettle();
    await tester.tap(attention);
    await tester.pumpAndSettle();
    expect(repository.preferences.announceAttention, isFalse);

    final voiceTest = find.text('Testar voz');
    await tester.ensureVisible(voiceTest);
    await tester.tap(voiceTest);
    await tester.pumpAndSettle();
    expect(speech.spoken, contains('Teste de voz do Eyes concluído.'));

    final hapticTest = find.text('Testar vibração');
    await tester.drag(find.byType(ListView), const Offset(0, -420));
    await tester.pumpAndSettle();
    await tester.tap(hapticTest);
    await tester.pumpAndSettle();
    expect(haptics.confirmations, 1);
  });

  testWidgets('restauração exige confirmação acessível', (tester) async {
    final repository = InMemoryFeedbackPreferencesRepository();
    await _pumpPage(
      tester,
      repository,
      FakeSpeechGateway(),
      FakeAssistiveHaptics(),
    );

    final restore = find.text('Restaurar configurações padrão');
    await tester.drag(find.byType(ListView), const Offset(0, -1100));
    await tester.pumpAndSettle();
    await tester.tap(restore);
    await tester.pumpAndSettle();

    expect(find.text('Restaurar configurações?'), findsOneWidget);
    expect(find.text('Cancelar'), findsOneWidget);
    await tester.tap(find.text('Restaurar').last);
    await tester.pumpAndSettle();
    expect(repository.clears, 1);
    expect(find.text('Configurações padrão restauradas.'), findsOneWidget);
  });

  testWidgets('mantém a tela utilizável com fonte em 200 por cento', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await _pumpPage(
      tester,
      InMemoryFeedbackPreferencesRepository(),
      FakeSpeechGateway(),
      FakeAssistiveHaptics(),
    );

    final restore = find.text('Restaurar configurações padrão');
    await tester.drag(find.byType(ListView), const Offset(0, -1800));
    await tester.pumpAndSettle();
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(restore, findsOneWidget);
  });

  testWidgets('falha do TTS é comunicada sem encerrar a tela', (tester) async {
    await _pumpPage(
      tester,
      InMemoryFeedbackPreferencesRepository(),
      FakeSpeechGateway(failure: StateError('tts missing')),
      FakeAssistiveHaptics(),
    );

    final failure = find.textContaining('A voz está indisponível');
    await tester.drag(find.byType(ListView), const Offset(0, -1400));
    await tester.pumpAndSettle();
    await tester.pumpAndSettle();

    expect(failure, findsOneWidget);
    expect(find.text('Restaurar configurações padrão'), findsOneWidget);
  });
}

Future<void> _pumpPage(
  WidgetTester tester,
  InMemoryFeedbackPreferencesRepository repository,
  FakeSpeechGateway speech,
  FakeAssistiveHaptics haptics,
) async {
  final logger = SecureLogger(AppEnvironment.dev());
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appErrorReporterProvider.overrideWithValue(AppErrorReporter(logger)),
        speechGatewayProvider.overrideWithValue(speech),
        assistiveHapticsProvider.overrideWithValue(haptics),
        feedbackPreferencesRepositoryProvider.overrideWithValue(repository),
      ],
      child: MaterialApp(
        locale: const Locale('pt', 'BR'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AppTheme.light,
        home: const FeedbackSettingsPage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
