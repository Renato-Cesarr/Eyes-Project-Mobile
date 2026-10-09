import 'dart:async';
import 'dart:io';

import 'package:eyes_mobile/app/theme/app_theme.dart';
import 'package:eyes_mobile/core/design_system/eyes_design_system.dart';
import 'package:eyes_mobile/features/account/presentation/account_page.dart';
import 'package:eyes_mobile/features/help/presentation/help_and_safety_page.dart';
import 'package:eyes_mobile/features/onboarding/application/onboarding_controller.dart';
import 'package:eyes_mobile/features/onboarding/application/onboarding_state.dart';
import 'package:eyes_mobile/features/onboarding/presentation/onboarding_page.dart';
import 'package:eyes_mobile/features/scanning/application/assistive_scan_coordinator.dart';
import 'package:eyes_mobile/features/scanning/domain/camera_permission_state.dart';
import 'package:eyes_mobile/features/scanning/presentation/assistive_scan_page.dart';
import 'package:eyes_mobile/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/composition_fixture.dart';
import '../../support/fake_account.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final bytes = await File(
      'test/fixtures/fonts/MaterialIcons-Regular.otf',
    ).readAsBytes();
    await Future.wait([
      (FontLoader(
        'MaterialIcons',
      )..addFont(Future.value(ByteData.sublistView(bytes)))).load(),
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
  for (final entry in themes.entries) {
    for (final width in [320.0, 390.0]) {
      for (final page in ['onboarding', 'help', 'account', 'scan']) {
        testWidgets(
          '$page ${entry.key} width=$width text=100/150/200 reduced-motion',
          (tester) async {
            tester.view.physicalSize = Size(width, 844);
            tester.view.devicePixelRatio = 1;
            addTearDown(() {
              tester.view.resetPhysicalSize();
              tester.view.resetDevicePixelRatio();
              tester.platformDispatcher.clearTextScaleFactorTestValue();
            });
            final semantics = tester.ensureSemantics();
            try {
              for (final scale in [1.0, 1.5, 2.0]) {
                tester.platformDispatcher.textScaleFactorTestValue = scale;
                final fixture = CompositionFixture();
                try {
                  final widget = switch (page) {
                    'onboarding' => const OnboardingPage(),
                    'help' => const HelpAndSafetyPage(),
                    'account' => const AccountPage(),
                    _ => const AssistiveScanPage(),
                  };
                  await _pump(
                    tester,
                    fixture,
                    entry.value,
                    widget,
                    withBackStack: page == 'help' || page == 'account',
                  );
                  if (page == 'onboarding') {
                    for (final step in OnboardingStep.values) {
                      await _check(tester);
                      expect(
                        find.bySemanticsLabel('Etapa ${step.index + 1} de 5'),
                        findsOneWidget,
                      );
                      expect(fixture.camera.requestCalls, 0);
                      if (scale == 1) {
                        final action = find.widgetWithText(
                          EyesButton,
                          step == OnboardingStep.camera
                              ? 'Permitir acesso à câmera'
                              : 'Avançar',
                        );
                        expect(
                          tester.getBottomRight(action).dy,
                          lessThanOrEqualTo(844),
                        );
                      }
                      await _golden(
                        tester,
                        '$page-${step.name}',
                        entry.key,
                        width,
                        scale,
                      );
                      final last = step == OnboardingStep.camera
                          ? find.text('Voltar')
                          : find.text(step.index == 0 ? 'Avançar' : 'Voltar');
                      await _reachable(tester, last);
                      fixture.container
                          .read(onboardingControllerProvider.notifier)
                          .next();
                      await tester.pumpAndSettle();
                      await _scrollTop(tester);
                      await _check(tester);
                    }
                  } else if (page == 'help') {
                    await _check(tester);
                    if (scale == 1) {
                      expect(
                        tester
                            .getBottomRight(
                              find.text('Repetir testes de voz e vibração'),
                            )
                            .dy,
                        lessThanOrEqualTo(844),
                      );
                    }
                    await _golden(tester, 'help', entry.key, width, scale);
                    await _reachable(
                      tester,
                      find.text('Repetir primeiros passos'),
                    );
                  } else if (page == 'account') {
                    await _check(tester);
                    if (scale == 1) {
                      expect(
                        tester
                            .getBottomRight(
                              find.widgetWithText(EyesButton, 'Entrar'),
                            )
                            .dy,
                        lessThanOrEqualTo(844),
                      );
                    }
                    await _golden(
                      tester,
                      'account-optional',
                      entry.key,
                      width,
                      scale,
                    );
                    await _reachable(
                      tester,
                      find.text('Continuar para a varredura offline'),
                    );
                    await fixture.store.save(testRemoteSession);
                    await tester.pumpAndSettle();
                    await _scrollTop(tester);
                    await _check(tester);
                    expect(
                      find.textContaining(
                        'os dados ficam vinculados à sua conta por até 30 dias',
                      ),
                      findsOneWidget,
                    );
                    await _golden(
                      tester,
                      'account-connected',
                      entry.key,
                      width,
                      scale,
                    );
                    await _reachable(tester, find.text('Sair da conta'));
                  } else {
                    final coordinator = fixture.container.read(
                      assistiveScanCoordinatorProvider,
                    );
                    await _check(tester);
                    await coordinator.start();
                    await tester.pumpAndSettle();
                    await _check(tester);
                    final status = find.text(
                      'Câmera pronta. Varredura assistiva ativa.',
                    );
                    final statusMaterial = tester.widget<Material>(
                      find
                          .ancestor(of: status, matching: find.byType(Material))
                          .first,
                    );
                    final dock = find.byKey(
                      const ValueKey<String>('scan-control-dock'),
                    );
                    final dockMaterial = tester.widget<Material>(
                      find
                          .descendant(of: dock, matching: find.byType(Material))
                          .first,
                    );
                    // Fully opaque surfaces have the same contrast over a bright
                    // or dark camera scene. This is not a real camera capture.
                    for (final surface in [
                      statusMaterial.color!,
                      dockMaterial.color!,
                    ]) {
                      expect(surface.a, 1);
                      for (final scene in [Colors.white, Colors.black]) {
                        expect(Color.alphaBlend(surface, scene), surface);
                      }
                    }
                    await _golden(
                      tester,
                      'scan-active',
                      entry.key,
                      width,
                      scale,
                    );
                    await _reachable(tester, find.text('Pausar varredura'));
                    await _reachable(tester, find.text('Encerrar varredura'));
                    await coordinator.pause();
                    await tester.pumpAndSettle();
                    await _scrollTop(tester);
                    expect(fixture.camera.streaming, isFalse);
                    expect(fixture.wakeLock.enabled, isFalse);
                    await _check(tester);
                    await _golden(
                      tester,
                      'scan-paused',
                      entry.key,
                      width,
                      scale,
                    );
                    await _reachable(tester, find.text('Retomar varredura'));
                    await coordinator.stop();
                    await tester.pumpAndSettle();
                    await _scrollTop(tester);
                    await _check(tester);
                    await _golden(
                      tester,
                      'scan-ended',
                      entry.key,
                      width,
                      scale,
                    );
                    fixture.camera.permission = CameraPermissionState.denied;
                    await coordinator.start();
                    await tester.pumpAndSettle();
                    await _check(tester);
                    await _golden(
                      tester,
                      'scan-denied',
                      entry.key,
                      width,
                      scale,
                    );
                    await _reachable(tester, find.text('Tentar novamente'));
                    await _reachable(tester, find.text('Voltar ao início'));
                  }
                } finally {
                  await tester.pumpWidget(const SizedBox());
                  await tester.pumpAndSettle();
                  await fixture.dispose();
                }
              }
            } finally {
              semantics.dispose();
            }
          },
        );
      }
    }
  }
  for (final entry in themes.entries) {
    for (final failure in ['runtime', 'memory']) {
      testWidgets('$failure model failure ${entry.key} width=320 text=200', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(320, 844);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
          tester.platformDispatcher.clearTextScaleFactorTestValue();
        });
        final semantics = tester.ensureSemantics();
        final fixture = CompositionFixture(
          modelFailure: true,
          modelFailureCode: failure == 'memory'
              ? 'interpreter-allocation-failed'
              : null,
        );
        try {
          await _pump(tester, fixture, entry.value, const AssistiveScanPage());
          await _check(tester);
          expect(fixture.camera.streaming, isFalse);
          expect(fixture.wakeLock.enabled, isFalse);
          expect(find.textContaining('widget fixture'), findsNothing);
          await _reachable(tester, find.text('Tentar novamente'));
          await _reachable(tester, find.text('Voltar ao início'));
          if (Platform.isWindows && entry.key == 'high-contrast-dark') {
            await _scrollTop(tester);
            await expectLater(
              find.byType(MaterialApp),
              matchesGoldenFile(
                'goldens/windows/scan-$failure-error-high-contrast-dark-text-200.png',
              ),
            );
          }
        } finally {
          await tester.pumpWidget(const SizedBox());
          await tester.pumpAndSettle();
          await fixture.dispose();
          semantics.dispose();
        }
      });
    }
  }
}

Future<void> _pump(
  WidgetTester tester,
  CompositionFixture fixture,
  ThemeData theme,
  Widget child, {
  bool withBackStack = false,
}) async {
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: fixture.container,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: theme,
        locale: const Locale('pt', 'BR'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
        home: withBackStack ? const Scaffold() : child,
      ),
    ),
  );
  await tester.pumpAndSettle();
  if (withBackStack) {
    unawaited(
      tester
          .state<NavigatorState>(find.byType(Navigator))
          .push<void>(MaterialPageRoute(builder: (_) => child)),
    );
    await tester.pumpAndSettle();
  }
}

Future<void> _check(WidgetTester tester) async {
  expect(tester.takeException(), isNull);
  final title = find.descendant(
    of: find.byType(AppBar),
    matching: find.byType(Text),
  );
  final paragraph = tester.renderObject<RenderParagraph>(title.first);
  expect(title.first.hitTestable(), findsOneWidget);
  expect(paragraph.didExceedMaxLines, isFalse);
  final toolbar = tester.getRect(find.byType(AppBar));
  final rect = tester.getRect(title.first);
  expect(rect.top, greaterThanOrEqualTo(toolbar.top));
  expect(rect.bottom, lessThanOrEqualTo(toolbar.bottom));
  await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
  await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
  await expectLater(tester, meetsGuideline(textContrastGuideline));
}

Future<void> _reachable(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  expect(target.hitTestable(), findsOneWidget);
  expect(tester.takeException(), isNull);
}

Future<void> _scrollTop(WidgetTester tester) async {
  for (final state in tester.stateList<ScrollableState>(
    find.byType(Scrollable),
  )) {
    state.position.jumpTo(state.position.minScrollExtent);
  }
  await tester.pumpAndSettle();
}

const _references = {
  'onboarding-welcome': 'light',
  'onboarding-safety': 'high-contrast-dark',
  'onboarding-privacy': 'dark',
  'onboarding-feedback': 'light',
  'onboarding-camera': 'high-contrast-light',
  'help': 'light',
  'account-optional': 'light',
  'account-connected': 'dark',
  'scan-active': 'light',
  'scan-paused': 'dark',
  'scan-ended': 'high-contrast-dark',
  'scan-denied': 'high-contrast-light',
};

Future<void> _golden(
  WidgetTester tester,
  String state,
  String theme,
  double width,
  double scale,
) async {
  if (Platform.isWindows &&
      width == 390 &&
      scale == 1 &&
      _references[state] == theme) {
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/windows/$state-$theme.png'),
    );
  }
}
