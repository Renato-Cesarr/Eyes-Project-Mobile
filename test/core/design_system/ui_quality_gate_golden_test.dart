import 'dart:io';

import 'package:eyes_mobile/app/theme/app_theme.dart';
import 'package:eyes_mobile/core/design_system/eyes_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await Future.wait(<Future<void>>[
      _loadMaterialIcons(),
      _loadFont('Lexend', 'assets/fonts/Lexend-Variable.ttf'),
      _loadFont(
        'Atkinson Hyperlegible',
        'assets/fonts/AtkinsonHyperlegible-Regular.ttf',
      ),
      _loadFont(
        'Atkinson Hyperlegible',
        'assets/fonts/AtkinsonHyperlegible-Bold.ttf',
      ),
    ]);
  });

  final cases = <({String name, ThemeData theme, double textScale})>[
    (name: 'light', theme: AppTheme.light, textScale: 1),
    (name: 'dark', theme: AppTheme.dark, textScale: 1),
    (
      name: 'high_contrast_light',
      theme: AppTheme.highContrastLight,
      textScale: 1,
    ),
    (
      name: 'high_contrast_dark',
      theme: AppTheme.highContrastDark,
      textScale: 1,
    ),
    (
      name: 'high_contrast_dark_text_200',
      theme: AppTheme.highContrastDark,
      textScale: 2,
    ),
  ];

  for (final goldenCase in cases) {
    testWidgets('visual gate ${goldenCase.name}', (WidgetTester tester) async {
      await _setPhoneSurface(tester);
      await tester.pumpWidget(
        _GoldenApp(
          theme: goldenCase.theme,
          textScaler: TextScaler.linear(goldenCase.textScale),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      await expectLater(
        find.byKey(_goldenBoundaryKey),
        matchesGoldenFile('goldens/ui_quality_gate/${goldenCase.name}.png'),
      );
    });
  }

  testWidgets('quality gate preserves Semantics and minimum touch targets', (
    WidgetTester tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await _setPhoneSurface(tester);
      await tester.pumpWidget(
        _GoldenApp(
          theme: AppTheme.highContrastDark,
          textScaler: const TextScaler.linear(2),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('Iniciar varredura'), findsOneWidget);
      expect(
        find.bySemanticsLabel(RegExp('Configurações de áudio')),
        findsOneWidget,
      );
      expect(
        tester.getSize(find.bySemanticsLabel('Iniciar varredura')).height,
        greaterThanOrEqualTo(48),
      );
      expect(
        tester.getSize(find.byType(EyesActionTile)).height,
        greaterThanOrEqualTo(48),
      );
      expect(tester.takeException(), isNull);
    } finally {
      semantics.dispose();
    }
  });
}

const Key _goldenBoundaryKey = ValueKey<String>('ui-quality-golden');

Future<void> _loadFont(String family, String asset) async {
  final loader = FontLoader(family)..addFont(rootBundle.load(asset));
  await loader.load();
}

Future<void> _loadMaterialIcons() async {
  final font = File('test/fixtures/fonts/MaterialIcons-Regular.otf');
  final bytes = await font.readAsBytes();
  final loader = FontLoader('MaterialIcons')
    ..addFont(Future<ByteData>.value(ByteData.sublistView(bytes)));
  await loader.load();
}

Future<void> _setPhoneSurface(WidgetTester tester) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 844);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
}

final class _GoldenApp extends StatelessWidget {
  const _GoldenApp({required this.theme, required this.textScaler});

  final ThemeData theme;
  final TextScaler textScaler;

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: theme,
    home: Builder(
      builder: (BuildContext context) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(disableAnimations: true, textScaler: textScaler),
        child: RepaintBoundary(
          key: _goldenBoundaryKey,
          child: Scaffold(
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    const EyesPageHeader(
                      title: 'Varredura assistiva',
                      description:
                          'Identifique obstáculos com avisos por voz e vibração.',
                      leading: ExcludeSemantics(
                        child: Icon(Icons.visibility_outlined, size: 48),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const EyesStatusBanner(
                      title: 'Pronto para começar',
                      message: 'A detecção funciona offline neste aparelho.',
                      tone: EyesStatusTone.success,
                    ),
                    const SizedBox(height: 20),
                    EyesButton(
                      label: 'Iniciar varredura',
                      semanticHint: 'Abre a câmera',
                      icon: Icons.center_focus_strong_outlined,
                      expand: true,
                      onPressed: () {},
                    ),
                    const SizedBox(height: 20),
                    EyesSection(
                      title: 'Ajustes e suporte',
                      description:
                          'Personalize a experiência antes de começar.',
                      icon: Icons.tune_outlined,
                      children: <Widget>[
                        EyesActionTile(
                          title: 'Configurações de áudio',
                          subtitle: 'Voz, volume e vibração',
                          icon: Icons.volume_up_outlined,
                          onTap: () {},
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
