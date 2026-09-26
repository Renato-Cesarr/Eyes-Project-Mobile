import 'dart:ui' show Tristate;

import 'package:eyes_mobile/app/theme/app_theme.dart';
import 'package:eyes_mobile/core/design_system/eyes_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('button exposes one accessible action and a 48dp target', (
    WidgetTester tester,
  ) async {
    var presses = 0;

    await tester.pumpWidget(
      _TestApp(
        child: EyesButton(
          label: 'Iniciar varredura',
          semanticHint: 'Abre a câmera',
          onPressed: () => presses += 1,
        ),
      ),
    );

    final semantics = tester.getSemantics(
      find.bySemanticsLabel('Iniciar varredura'),
    );
    expect(semantics.flagsCollection.isButton, isTrue);
    expect(semantics.flagsCollection.isEnabled, Tristate.isTrue);
    expect(semantics.hint, 'Abre a câmera');
    expect(
      tester.getSize(find.byType(EyesButton)).height,
      greaterThanOrEqualTo(48),
    );

    await tester.tap(find.bySemanticsLabel('Iniciar varredura'));
    expect(presses, 1);
  });

  testWidgets('loading button reports progress and remains disabled', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const _TestApp(
        child: EyesButton(label: 'Salvar', onPressed: null, loading: true),
      ),
    );

    final semantics = tester.getSemantics(
      find.bySemanticsLabel('Salvar. Carregando.'),
    );
    expect(semantics.flagsCollection.isButton, isTrue);
    expect(semantics.flagsCollection.isEnabled, Tristate.isFalse);
    expect(semantics.flagsCollection.isLiveRegion, isTrue);
  });

  testWidgets('status and recovery action stay available to TalkBack', (
    WidgetTester tester,
  ) async {
    var retries = 0;
    await tester.pumpWidget(
      _TestApp(
        child: Column(
          children: <Widget>[
            const EyesStatusBanner(
              title: 'Câmera pronta',
              message: 'Varredura disponível.',
              tone: EyesStatusTone.success,
              liveRegion: true,
            ),
            EyesStateView.error(
              title: 'Não foi possível carregar',
              message: 'Tente novamente.',
              actionLabel: 'Tentar novamente',
              onAction: () => retries += 1,
            ),
          ],
        ),
      ),
    );

    expect(
      find.bySemanticsLabel('Câmera pronta. Varredura disponível.'),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('Tentar novamente'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Tentar novamente'));
    expect(retries, 1);
  });

  testWidgets('components support high contrast and 200 percent text', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _TestApp(
        theme: AppTheme.highContrastDark,
        textScaler: const TextScaler.linear(2),
        child: SingleChildScrollView(
          child: EyesCard(
            child: EyesStateView.empty(
              title: 'Nenhum objeto encontrado',
              message: 'Mova a câmera lentamente e tente novamente.',
              actionLabel: 'Continuar',
              onAction: () {},
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.bySemanticsLabel('Continuar'), findsOneWidget);
    expect(
      Theme.of(tester.element(find.byType(EyesCard))).brightness,
      Brightness.dark,
    );
  });

  testWidgets('motion duration is removed when animations are disabled', (
    WidgetTester tester,
  ) async {
    late Duration resolved;
    await tester.pumpWidget(
      _TestApp(
        disableAnimations: true,
        child: Builder(
          builder: (BuildContext context) {
            resolved = context.eyesMotion.resolve(
              context,
              context.eyesMotion.emphasized,
            );
            return const SizedBox();
          },
        ),
      ),
    );

    expect(resolved, Duration.zero);
  });
}

final class _TestApp extends StatelessWidget {
  const _TestApp({
    required this.child,
    this.theme,
    this.textScaler = TextScaler.noScaling,
    this.disableAnimations = false,
  });

  final Widget child;
  final ThemeData? theme;
  final TextScaler textScaler;
  final bool disableAnimations;

  @override
  Widget build(BuildContext context) => MaterialApp(
    theme: theme ?? AppTheme.light,
    home: Builder(
      builder: (BuildContext context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          disableAnimations: disableAnimations,
          textScaler: textScaler,
        ),
        child: Scaffold(body: Center(child: child)),
      ),
    ),
  );
}
