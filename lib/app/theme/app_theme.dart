import 'package:flutter/material.dart';

abstract final class AppTheme {
  static final ThemeData light = _build(
    brightness: Brightness.light,
    highContrast: false,
  );
  static final ThemeData dark = _build(
    brightness: Brightness.dark,
    highContrast: false,
  );
  static final ThemeData highContrastLight = _build(
    brightness: Brightness.light,
    highContrast: true,
  );
  static final ThemeData highContrastDark = _build(
    brightness: Brightness.dark,
    highContrast: true,
  );

  static ThemeData _build({
    required Brightness brightness,
    required bool highContrast,
  }) {
    final isDark = brightness == Brightness.dark;
    final seedColor = _seedColor(highContrast: highContrast, isDark: isDark);
    final colorScheme = ColorScheme.fromSeed(
      brightness: brightness,
      contrastLevel: highContrast ? 1 : 0.35,
      seedColor: seedColor,
    );
    final base = ThemeData(
      brightness: brightness,
      colorScheme: colorScheme,
      focusColor: colorScheme.primary.withValues(alpha: 0.28),
      materialTapTargetSize: MaterialTapTargetSize.padded,
      scaffoldBackgroundColor: colorScheme.surface,
      useMaterial3: true,
      visualDensity: VisualDensity.standard,
    );

    return base.copyWith(
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        foregroundColor: colorScheme.onSurface,
        backgroundColor: colorScheme.surface,
        titleTextStyle: base.textTheme.titleLarge?.copyWith(
          color: colorScheme.onSurface,
          fontSize: 24,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surfaceContainerHighest,
        elevation: highContrast ? 0 : 1,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: highContrast
                ? colorScheme.outline
                : colorScheme.outlineVariant,
            width: highContrast ? 2 : 1,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll<Size>(Size(48, 56)),
          padding: const WidgetStatePropertyAll<EdgeInsetsGeometry>(
            EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          ),
          textStyle: WidgetStatePropertyAll<TextStyle?>(
            base.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ),
      textTheme: base.textTheme.copyWith(
        bodyLarge: base.textTheme.bodyLarge?.copyWith(
          fontSize: 18,
          height: 1.5,
        ),
        bodyMedium: base.textTheme.bodyMedium?.copyWith(
          fontSize: 16,
          height: 1.5,
        ),
        headlineMedium: base.textTheme.headlineMedium?.copyWith(
          fontSize: 30,
          fontWeight: FontWeight.w700,
          height: 1.2,
        ),
        titleLarge: base.textTheme.titleLarge?.copyWith(
          fontSize: 24,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  static Color _seedColor({required bool highContrast, required bool isDark}) {
    if (!highContrast) {
      return const Color(0xFF005A9C);
    }
    return isDark ? const Color(0xFF8FCBFF) : const Color(0xFF002B52);
  }
}
