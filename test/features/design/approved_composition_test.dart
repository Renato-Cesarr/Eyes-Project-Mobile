import 'dart:io';

import 'package:eyes_mobile/app/config/app_environment.dart';
import 'package:eyes_mobile/app/routing/app_router.dart';
import 'package:eyes_mobile/app/theme/app_theme.dart';
import 'package:eyes_mobile/core/accessibility/accessible_feedback_service.dart';
import 'package:eyes_mobile/core/design_system/eyes_design_system.dart';
import 'package:eyes_mobile/core/error/app_error_reporter.dart';
import 'package:eyes_mobile/core/logging/secure_logger.dart';
import 'package:eyes_mobile/features/appearance/application/appearance_repository.dart';
import 'package:eyes_mobile/features/assistive_feedback/application/assistive_feedback_controller.dart';
import 'package:eyes_mobile/features/assistive_feedback/presentation/feedback_settings_page.dart';
import 'package:eyes_mobile/features/home/presentation/home_page.dart';
import 'package:eyes_mobile/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../support/fake_appearance.dart';
import '../../support/fake_assistive_feedback.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final iconBytes = await File(
      'test/fixtures/fonts/MaterialIcons-Regular.otf',
    ).readAsBytes();
    await Future.wait([
      (FontLoader(
        'MaterialIcons',
      )..addFont(Future.value(ByteData.sublistView(iconBytes)))).load(),
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
  final themes = <String, ThemeData>{
    'light': AppTheme.light,
    'dark': AppTheme.dark,
    'high-contrast-light': AppTheme.highContrastLight,
    'high-contrast-dark': AppTheme.highContrastDark,
  };
  for (final screen in ['home', 'settings']) {
    for (final entry in themes.entries) {
      for (final width in [320.0, 390.0]) {
        for (final scale in [1.0, 1.5, 2.0]) {
          testWidgets('$screen ${entry.key} width=$width text=$scale', (
            tester,
          ) async {
            tester.view.physicalSize = Size(width, 844);
            tester.view.devicePixelRatio = 1;
            tester.platformDispatcher.textScaleFactorTestValue = scale;
            addTearDown(() {
              tester.view.resetPhysicalSize();
              tester.view.resetDevicePixelRatio();
              tester.platformDispatcher.clearTextScaleFactorTestValue();
            });
            final semantics = tester.ensureSemantics();
            try {
              await tester.pumpWidget(
                _providers(
                  MaterialApp(
                    debugShowCheckedModeBanner: false,
                    theme: entry.value,
                    locale: const Locale('pt', 'BR'),
                    localizationsDelegates: _delegates,
                    supportedLocales: AppLocalizations.supportedLocales,
                    home: screen == 'home'
                        ? const HomePage()
                        : const FeedbackSettingsPage(),
                  ),
                ),
              );
              await tester.pumpAndSettle();
              expect(tester.takeException(), isNull);
              final title = find.descendant(
                of: find.byType(AppBar),
                matching: find.text(
                  screen == 'home' ? 'Eyes' : 'Áudio e alertas',
                ),
              );
              final paragraph = tester.renderObject<RenderParagraph>(title);
              expect(paragraph.didExceedMaxLines, isFalse);
              final toolbar = tester.getRect(find.byType(AppBar));
              final titleRect = tester.getRect(title);
              expect(titleRect.top, greaterThanOrEqualTo(toolbar.top));
              expect(titleRect.bottom, lessThanOrEqualTo(toolbar.bottom));
              await expectLater(
                tester,
                meetsGuideline(androidTapTargetGuideline),
              );
              await expectLater(
                tester,
                meetsGuideline(labeledTapTargetGuideline),
              );
              await expectLater(tester, meetsGuideline(textContrastGuideline));
              if (scale == 1) {
                final action = find.widgetWithText(
                  EyesButton,
                  screen == 'home' ? 'Abrir câmera' : 'Testar voz',
                );
                expect(
                  tester.getBottomRight(action).dy,
                  lessThanOrEqualTo(844),
                );
                if (screen == 'home') {
                  expect(
                    tester.getSize(action).height,
                    greaterThanOrEqualTo(64),
                  );
                }
              }
              if (Platform.isWindows && width == 390 && scale == 1) {
                await expectLater(
                  find.byType(MaterialApp),
                  matchesGoldenFile('goldens/windows/$screen-${entry.key}.png'),
                );
              }
              final last = screen == 'home'
                  ? find.text('Nenhuma foto ou vídeo é salvo.')
                  : find.text('Restaurar configurações padrão');
              await tester.ensureVisible(last);
              await tester.pumpAndSettle();
              expect(tester.takeException(), isNull);
              expect(last.hitTestable(), findsOneWidget);
            } finally {
              semantics.dispose();
            }
          });
        }
      }
    }
  }
  testWidgets('home actions preserve camera, settings and feedback behavior', (
    tester,
  ) async {
    final feedback = _Feedback();
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => const HomePage()),
        GoRoute(
          path: '/camera',
          name: AppRoutes.camera,
          builder: (_, _) => const Scaffold(body: Text('Camera route')),
        ),
        GoRoute(
          path: '/settings',
          name: AppRoutes.settings,
          builder: (_, _) => const FeedbackSettingsPage(),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      _providers(
        MaterialApp.router(
          theme: AppTheme.light,
          routerConfig: router,
          locale: const Locale('pt', 'BR'),
          localizationsDelegates: _delegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
        feedback: feedback,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Testar som e vibração'));
    await tester.pumpAndSettle();
    expect(feedback.confirmations, 1);
    expect(find.text('Feedback tátil e sonoro confirmado.'), findsOneWidget);
    await tester.tap(find.text('Abrir câmera'));
    await tester.pumpAndSettle();
    expect(find.text('Camera route'), findsOneWidget);
    router.go('/');
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Abrir configurações'));
    await tester.pumpAndSettle();
    expect(find.byType(FeedbackSettingsPage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

const _delegates = [
  AppLocalizations.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
];

Widget _providers(Widget child, {AccessibleFeedbackService? feedback}) {
  final logger = SecureLogger(AppEnvironment.dev());
  return ProviderScope(
    overrides: [
      appErrorReporterProvider.overrideWithValue(AppErrorReporter(logger)),
      appearanceRepositoryProvider.overrideWithValue(
        InMemoryAppearanceRepository(),
      ),
      speechGatewayProvider.overrideWithValue(FakeSpeechGateway()),
      assistiveHapticsProvider.overrideWithValue(FakeAssistiveHaptics()),
      feedbackPreferencesRepositoryProvider.overrideWithValue(
        InMemoryFeedbackPreferencesRepository(),
      ),
      if (feedback != null)
        accessibleFeedbackServiceProvider.overrideWithValue(feedback),
    ],
    child: child,
  );
}

final class _Feedback implements AccessibleFeedbackService {
  int confirmations = 0;
  @override
  Future<void> confirm() async => confirmations++;
  @override
  Future<void> warn() async {}
}
