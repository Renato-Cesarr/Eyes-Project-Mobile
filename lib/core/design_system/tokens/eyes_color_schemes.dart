import 'package:flutter/material.dart';

/// Material color schemes mirrored from Eyes Design System 1.0.0 (REN-50).
abstract final class EyesColorSchemes {
  static const ColorScheme light = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF005A84),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFCBE8FF),
    onPrimaryContainer: Color(0xFF002D44),
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
    onSurface: Color(0xFF131B2A),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFF7F9FC),
    surfaceContainer: Color(0xFFF3F7FC),
    surfaceContainerHigh: Color(0xFFE5EAF0),
    surfaceContainerHighest: Color(0xFFE5EAF0),
    onSurfaceVariant: Color(0xFF3E4856),
    outline: Color(0xFF66717F),
    outlineVariant: Color(0xFFC7D0DA),
    shadow: Color(0xFF0B121A),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFF111923),
    onInverseSurface: Color(0xFFE4EAF1),
    inversePrimary: Color(0xFF8DCDFF),
    surfaceTint: Color(0xFF005A84),
  );

  static const ColorScheme dark = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF8DCDFF),
    onPrimary: Color(0xFF00344D),
    primaryContainer: Color(0xFF004C70),
    onPrimaryContainer: Color(0xFFCBE8FF),
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
    errorContainer: Color(0xFF111923),
    onErrorContainer: Color(0xFFFFB4AB),
    surface: Color(0xFF111923),
    onSurface: Color(0xFFE4EAF1),
    surfaceContainerLowest: Color(0xFF0B121A),
    surfaceContainerLow: Color(0xFF111923),
    surfaceContainer: Color(0xFF1B2530),
    surfaceContainerHigh: Color(0xFF26313D),
    surfaceContainerHighest: Color(0xFF26313D),
    onSurfaceVariant: Color(0xFFC7D0DA),
    outline: Color(0xFF909BA8),
    outlineVariant: Color(0xFF3E4856),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFFE4EAF1),
    onInverseSurface: Color(0xFF111923),
    inversePrimary: Color(0xFF005A84),
    surfaceTint: Color(0xFF8DCDFF),
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
