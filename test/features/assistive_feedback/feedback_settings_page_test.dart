import 'dart:io';

import 'package:eyes_mobile/app/config/app_environment.dart';
import 'package:eyes_mobile/app/theme/app_theme.dart';
import 'package:eyes_mobile/core/error/app_error_reporter.dart';
import 'package:eyes_mobile/core/logging/secure_logger.dart';
import 'package:eyes_mobile/features/appearance/application/appearance_repository.dart';
import 'package:eyes_mobile/features/appearance/domain/appearance_preference.dart';
import 'package:eyes_mobile/features/assistive_feedback/application/assistive_feedback_controller.dart';
import 'package:eyes_mobile/features/assistive_feedback/presentation/feedback_settings_page.dart';
import 'package:eyes_mobile/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_appearance.dart';
import '../../support/fake_assistive_feedback.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final iconBytes = await File(
      'test/fixtures/fonts/MaterialIcons-Regular.otf',
    ).readAsBytes();
    await Future.wait(<Future<void>>[
      (FontLoader('MaterialIcons')
            ..addFont(Future<ByteData>.value(ByteData.sublistView(iconBytes))))
          .load(),
      (FontLoader(
        'Lexend',
      )..addFont(rootBundle.load('assets/fonts/Lexend-Variable.ttf'))).load(),
      (FontLoader('Atkinson Hyperlegible')..addFont(
            rootBundle.load('assets/fonts/AtkinsonHyperlegible-Regular.ttf'),
          ))
          .load(),
      (FontLoader('Atkinson Hyperlegible')..addFont(
            rootBundle.load('assets/fonts/AtkinsonHyperlegible-Bold.ttf'),
          ))
          .load(),
    ]);
  });

  testWidgets('settings has a compact, continuous reading flow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await _pumpPage(
      tester,
      InMemoryFeedbackPreferencesRepository(),
      FakeSpeechGateway(),
      FakeAssistiveHaptics(),
    );
    expect(find.text('Áudio, alertas e vibração'), findsOneWidget);
    expect(find.text('Voz'), findsOneWidget);
    expect(tester.takeException(), isNull);
    if (Platform.isWindows) {
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/windows/feedback-settings-light.png'),
      );
    }
  });

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
    await tester.ensureVisible(attention);
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
    await tester.ensureVisible(hapticTest);
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
    await tester.ensureVisible(restore);
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

  testWidgets('permite escolher e persistir alto contraste', (tester) async {
    final appearance = InMemoryAppearanceRepository();
    await _pumpPage(
      tester,
      InMemoryFeedbackPreferencesRepository(),
      FakeSpeechGateway(),
      FakeAssistiveHaptics(),
      appearance: appearance,
    );

    await tester.tap(find.text('Padrão do aparelho').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Alto contraste escuro').last);
    await tester.pumpAndSettle();

    expect(appearance.preference, AppearancePreference.highContrastDark);
    expect(appearance.saveCalls, 1);
    expect(find.text('Aparência atualizada.'), findsOneWidget);
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
    await tester.ensureVisible(restore);
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
    await tester.ensureVisible(failure);
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
  FakeAssistiveHaptics haptics, {
  InMemoryAppearanceRepository? appearance,
}) async {
  final logger = SecureLogger(AppEnvironment.dev());
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appErrorReporterProvider.overrideWithValue(AppErrorReporter(logger)),
        appearanceRepositoryProvider.overrideWithValue(
          appearance ?? InMemoryAppearanceRepository(),
        ),
        speechGatewayProvider.overrideWithValue(speech),
        assistiveHapticsProvider.overrideWithValue(haptics),
        feedbackPreferencesRepositoryProvider.overrideWithValue(repository),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
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
