import 'package:eyes_mobile/core/recovery/accessible_recovery_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('announces a sanitized summary and exposes ordered actions', (
    WidgetTester tester,
  ) async {
    final semantics = tester.ensureSemantics();
    var primaryCalls = 0;
    var secondaryCalls = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AccessibleRecoveryPanel(
            announcementKey: 'camera-timeout',
            title: 'A câmera demorou para iniciar',
            message: 'A varredura permaneceu desligada.',
            primaryActionLabel: 'Tentar novamente',
            onPrimaryAction: () => primaryCalls++,
            secondaryActionLabel: 'Voltar ao início',
            onSecondaryAction: () => secondaryCalls++,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(
      find.bySemanticsLabel(
        'A câmera demorou para iniciar. A varredura permaneceu desligada.',
      ),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel(RegExp(r'tensor|FPS|\d+\s*ms')), findsNothing);

    await tester.tap(find.text('Tentar novamente'));
    await tester.tap(find.text('Voltar ao início'));
    expect(primaryCalls, 1);
    expect(secondaryCalls, 1);
    semantics.dispose();
  });

  testWidgets('keeps both recovery actions usable at 200 percent text', (
    WidgetTester tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: AccessibleRecoveryPanel(
              announcementKey: 'model-timeout',
              title: 'A inteligência artificial demorou para iniciar',
              message: 'A varredura permaneceu desligada.',
              primaryActionLabel: 'Tentar novamente',
              onPrimaryAction: () {},
              secondaryActionLabel: 'Voltar ao início',
              onSecondaryAction: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Tentar novamente'), findsOneWidget);
    expect(find.text('Voltar ao início'), findsOneWidget);
  });
}
