import 'package:eyes_mobile/core/design_system/tokens/eyes_color_schemes.dart';
import 'package:eyes_mobile/core/design_system/tokens/eyes_layout_tokens.dart';
import 'package:eyes_mobile/core/design_system/tokens/eyes_motion_tokens.dart';
import 'package:eyes_mobile/core/design_system/tokens/eyes_semantic_colors.dart';
import 'package:flutter/material.dart';

abstract final class AppTheme {
  static final ThemeData light = _build(
    colorScheme: EyesColorSchemes.light,
    semanticColors: EyesSemanticColors.light,
    highContrast: false,
  );
  static final ThemeData dark = _build(
    colorScheme: EyesColorSchemes.dark,
    semanticColors: EyesSemanticColors.dark,
    highContrast: false,
  );
  static final ThemeData highContrastLight = _build(
    colorScheme: EyesColorSchemes.highContrastLight,
    semanticColors: EyesSemanticColors.highContrastLight,
    highContrast: true,
  );
  static final ThemeData highContrastDark = _build(
    colorScheme: EyesColorSchemes.highContrastDark,
    semanticColors: EyesSemanticColors.highContrastDark,
    highContrast: true,
  );

  static ThemeData _build({
    required ColorScheme colorScheme,
    required EyesSemanticColors semanticColors,
    required bool highContrast,
  }) {
    final base = ThemeData(
      brightness: colorScheme.brightness,
      colorScheme: colorScheme,
      extensions: <ThemeExtension<dynamic>>[
        semanticColors,
        EyesLayoutTokens.standard,
        EyesMotionTokens.defaults,
      ],
      focusColor: semanticColors.focusRing.withValues(alpha: 0.24),
      fontFamily: 'Atkinson Hyperlegible',
      materialTapTargetSize: MaterialTapTargetSize.padded,
      scaffoldBackgroundColor: colorScheme.surfaceContainerLow,
      useMaterial3: true,
      visualDensity: VisualDensity.standard,
    );
    final textTheme = _textTheme(base.textTheme, colorScheme);
    final borderWidth = highContrast ? 2.0 : 1.0;

    return base.copyWith(
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        foregroundColor: colorScheme.onSurface,
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        elevation: highContrast ? 0 : 1,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            EyesLayoutTokens.standard.radiusLg,
          ),
          side: BorderSide(
            color: highContrast
                ? colorScheme.outline
                : colorScheme.outlineVariant,
            width: borderWidth,
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            EyesLayoutTokens.standard.radiusLg,
          ),
          side: BorderSide(color: colorScheme.outline, width: borderWidth),
        ),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyLarge,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: _buttonStyle(textTheme, EyesLayoutTokens.standard),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: _buttonStyle(textTheme, EyesLayoutTokens.standard).copyWith(
          side: WidgetStatePropertyAll<BorderSide>(
            BorderSide(color: colorScheme.outline, width: borderWidth),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: _buttonStyle(textTheme, EyesLayoutTokens.standard),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            EyesLayoutTokens.standard.radiusMd,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            EyesLayoutTokens.standard.radiusMd,
          ),
          borderSide: BorderSide(
            color: colorScheme.outline,
            width: borderWidth,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            EyesLayoutTokens.standard.radiusMd,
          ),
          borderSide: BorderSide(
            color: semanticColors.focusRing,
            width: highContrast ? 3 : 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            EyesLayoutTokens.standard.radiusMd,
          ),
          borderSide: BorderSide(color: colorScheme.error, width: borderWidth),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onInverseSurface,
        ),
      ),
      textTheme: textTheme,
    );
  }

  static ButtonStyle _buttonStyle(
    TextTheme textTheme,
    EyesLayoutTokens layout,
  ) => ButtonStyle(
    minimumSize: WidgetStatePropertyAll<Size>(
      Size(layout.minimumTapTarget, layout.minimumTapTarget),
    ),
    padding: WidgetStatePropertyAll<EdgeInsetsGeometry>(
      EdgeInsets.symmetric(horizontal: layout.spaceXl, vertical: 14),
    ),
    textStyle: WidgetStatePropertyAll<TextStyle?>(
      textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
    ),
  );

  static TextTheme _textTheme(TextTheme source, ColorScheme colors) {
    final body = source.apply(
      bodyColor: colors.onSurface,
      displayColor: colors.onSurface,
      fontFamily: 'Atkinson Hyperlegible',
    );

    return body.copyWith(
      bodyLarge: body.bodyLarge?.copyWith(fontSize: 18, height: 1.6),
      bodyMedium: body.bodyMedium?.copyWith(fontSize: 16, height: 1.6),
      bodySmall: body.bodySmall?.copyWith(fontSize: 14, height: 1.5),
      displayLarge: _heading(body.displayLarge, 40, 1.25),
      displayMedium: _heading(body.displayMedium, 36, 1.25),
      displaySmall: _heading(body.displaySmall, 32, 1.25),
      headlineLarge: _heading(body.headlineLarge, 32, 1.3),
      headlineMedium: _heading(body.headlineMedium, 30, 1.3),
      headlineSmall: _heading(body.headlineSmall, 26, 1.3),
      titleLarge: _heading(body.titleLarge, 24, 1.3),
      titleMedium: _heading(body.titleMedium, 20, 1.3),
      titleSmall: _heading(body.titleSmall, 18, 1.3),
    );
  }

  static TextStyle? _heading(TextStyle? source, double size, double height) =>
      source?.copyWith(
        fontFamily: 'Lexend',
        fontSize: size,
        fontWeight: FontWeight.w600,
        height: height,
      );
}
