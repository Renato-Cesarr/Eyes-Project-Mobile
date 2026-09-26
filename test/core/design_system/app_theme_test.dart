import 'dart:math' as math;

import 'package:eyes_mobile/app/theme/app_theme.dart';
import 'package:eyes_mobile/core/design_system/tokens/eyes_layout_tokens.dart';
import 'package:eyes_mobile/core/design_system/tokens/eyes_motion_tokens.dart';
import 'package:eyes_mobile/core/design_system/tokens/eyes_semantic_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('maps the canonical colors to every supported theme', () {
    expect(AppTheme.light.colorScheme.primary, const Color(0xFF005A84));
    expect(AppTheme.dark.colorScheme.primary, const Color(0xFF8DCDFF));
    expect(
      AppTheme.highContrastLight.colorScheme.primary,
      const Color(0xFF003B59),
    );
    expect(
      AppTheme.highContrastDark.colorScheme.primary,
      const Color(0xFFB9E1FF),
    );

    for (final theme in <ThemeData>[
      AppTheme.light,
      AppTheme.dark,
      AppTheme.highContrastLight,
      AppTheme.highContrastDark,
    ]) {
      expect(theme.useMaterial3, isTrue);
      expect(theme.textTheme.bodyLarge?.fontFamily, 'Atkinson Hyperlegible');
      expect(theme.textTheme.titleLarge?.fontFamily, 'Lexend');
      expect(theme.extension<EyesSemanticColors>(), isNotNull);
      expect(theme.extension<EyesLayoutTokens>()?.minimumTapTarget, 48);
      expect(
        theme.extension<EyesMotionTokens>()?.emphasized,
        const Duration(milliseconds: 300),
      );
    }
  });

  test('keeps critical text pairs above their contrast target', () {
    final pairs = <({Color foreground, Color background, double minimum})>[
      (
        foreground: AppTheme.light.colorScheme.onSurface,
        background: AppTheme.light.colorScheme.surface,
        minimum: 7,
      ),
      (
        foreground: AppTheme.light.colorScheme.onPrimary,
        background: AppTheme.light.colorScheme.primary,
        minimum: 7,
      ),
      (
        foreground: AppTheme.dark.colorScheme.onSurface,
        background: AppTheme.dark.colorScheme.surface,
        minimum: 7,
      ),
      (
        foreground: AppTheme.dark.colorScheme.onPrimary,
        background: AppTheme.dark.colorScheme.primary,
        minimum: 7,
      ),
      (
        foreground: AppTheme.highContrastLight.colorScheme.onPrimary,
        background: AppTheme.highContrastLight.colorScheme.primary,
        minimum: 7,
      ),
      (
        foreground: AppTheme.highContrastDark.colorScheme.onPrimary,
        background: AppTheme.highContrastDark.colorScheme.primary,
        minimum: 7,
      ),
    ];

    for (final pair in pairs) {
      expect(
        _contrastRatio(pair.foreground, pair.background),
        greaterThanOrEqualTo(pair.minimum),
      );
    }
  });

  test('bundles fonts and their OFL licenses for offline operation', () async {
    for (final asset in <String>[
      'assets/fonts/Lexend-Variable.ttf',
      'assets/fonts/AtkinsonHyperlegible-Regular.ttf',
      'assets/fonts/AtkinsonHyperlegible-Bold.ttf',
    ]) {
      expect((await rootBundle.load(asset)).lengthInBytes, greaterThan(0));
    }

    for (final asset in <String>[
      'assets/licenses/Lexend-OFL-1.1.txt',
      'assets/licenses/AtkinsonHyperlegible-OFL-1.1.txt',
    ]) {
      expect(
        await rootBundle.loadString(asset),
        contains('SIL OPEN FONT LICENSE Version 1.1'),
      );
    }
  });
}

double _contrastRatio(Color first, Color second) {
  final lightest = math.max(
    first.computeLuminance(),
    second.computeLuminance(),
  );
  final darkest = math.min(first.computeLuminance(), second.computeLuminance());
  return (lightest + 0.05) / (darkest + 0.05);
}
