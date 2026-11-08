import 'package:flutter/material.dart';

/// Orbit color schemes mirrored from Eyes Design System 1.1.0 (REN-65).
abstract final class EyesColorSchemes {
  static const ColorScheme light = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF0052A8),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFE2EFFF),
    onPrimaryContainer: Color(0xFF12253B),
    secondary: Color(0xFF00695F),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFF9FF2E5),
    onSecondaryContainer: Color(0xFF00201C),
    tertiary: Color(0xFF00695F),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFF9FF2E5),
    onTertiaryContainer: Color(0xFF00201C),
    error: Color(0xFFB3261E),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFFFFFF),
    onErrorContainer: Color(0xFFB3261E),
    surface: Color(0xFFFFFFFF),
    onSurface: Color(0xFF12253B),
    surfaceContainerLowest: Color(0xFFEDF3FA),
    surfaceContainerLow: Color(0xFFEDF3FA),
    surfaceContainer: Color(0xFFF4F7FC),
    surfaceContainerHigh: Color(0xFFE3EDF8),
    surfaceContainerHighest: Color(0xFFE3EDF8),
    onSurfaceVariant: Color(0xFF44566E),
    outline: Color(0xFF61738C),
    outlineVariant: Color(0xFFD6DFEC),
    shadow: Color(0xFF080F1C),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFF111E30),
    onInverseSurface: Color(0xFFEFF6FF),
    inversePrimary: Color(0xFF79CCFF),
    surfaceTint: Color(0xFF0052A8),
  );

  static const ColorScheme dark = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF79CCFF),
    onPrimary: Color(0xFF071D30),
    primaryContainer: Color(0xFF15344D),
    onPrimaryContainer: Color(0xFFE2EFFF),
    secondary: Color(0xFF7AD8CB),
    onSecondary: Color(0xFF003732),
    secondaryContainer: Color(0xFF004F47),
    onSecondaryContainer: Color(0xFF9FF2E5),
    tertiary: Color(0xFF7AD8CB),
    onTertiary: Color(0xFF003732),
    tertiaryContainer: Color(0xFF004F47),
    onTertiaryContainer: Color(0xFF9FF2E5),
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
    errorContainer: Color(0xFF111E30),
    onErrorContainer: Color(0xFFFFB4AB),
    surface: Color(0xFF111E30),
    onSurface: Color(0xFFEFF6FF),
    surfaceContainerLowest: Color(0xFF080F1C),
    surfaceContainerLow: Color(0xFF111E30),
    surfaceContainer: Color(0xFF16253A),
    surfaceContainerHigh: Color(0xFF16253A),
    surfaceContainerHighest: Color(0xFF16253A),
    onSurfaceVariant: Color(0xFFB0BFD3),
    outline: Color(0xFF8296AF),
    outlineVariant: Color(0xFF2C3C52),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFFEFF6FF),
    onInverseSurface: Color(0xFF111E30),
    inversePrimary: Color(0xFF0052A8),
    surfaceTint: Color(0xFF79CCFF),
  );

  static final ColorScheme highContrastLight = _highContrastScheme(
    brightness: Brightness.light,
    primary: Color(0xFF003B59),
    secondary: Color(0xFF004F47),
    error: Color(0xFF690005),
    inversePrimary: Color(0xFFB9E1FF),
  );

  static final ColorScheme highContrastDark = _highContrastScheme(
    brightness: Brightness.dark,
    primary: Color(0xFFB9E1FF),
    secondary: Color(0xFF9FF2E5),
    error: Color(0xFFFFB4AB),
    inversePrimary: Color(0xFF003B59),
  );

  static ColorScheme _highContrastScheme({
    required Brightness brightness,
    required Color primary,
    required Color secondary,
    required Color error,
    required Color inversePrimary,
  }) {
    final background = brightness == Brightness.dark
        ? const Color(0xFF000000)
        : const Color(0xFFFFFFFF);
    final foreground = brightness == Brightness.dark
        ? const Color(0xFFFFFFFF)
        : const Color(0xFF000000);

    return ColorScheme(
      brightness: brightness,
      primary: primary,
      onPrimary: background,
      primaryContainer: background,
      onPrimaryContainer: foreground,
      secondary: secondary,
      onSecondary: background,
      secondaryContainer: background,
      onSecondaryContainer: foreground,
      tertiary: secondary,
      onTertiary: background,
      tertiaryContainer: background,
      onTertiaryContainer: foreground,
      error: error,
      onError: background,
      errorContainer: background,
      onErrorContainer: foreground,
      surface: background,
      onSurface: foreground,
      surfaceContainerLowest: background,
      surfaceContainerLow: background,
      surfaceContainer: background,
      surfaceContainerHigh: background,
      surfaceContainerHighest: background,
      onSurfaceVariant: foreground,
      outline: foreground,
      outlineVariant: foreground,
      shadow: const Color(0xFF000000),
      scrim: const Color(0xFF000000),
      inverseSurface: foreground,
      onInverseSurface: background,
      inversePrimary: inversePrimary,
      surfaceTint: primary,
    );
  }
}
