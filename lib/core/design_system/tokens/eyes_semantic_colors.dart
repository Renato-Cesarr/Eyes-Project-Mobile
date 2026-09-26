import 'package:flutter/material.dart';

@immutable
final class EyesSemanticColors extends ThemeExtension<EyesSemanticColors> {
  const EyesSemanticColors({
    required this.success,
    required this.onSuccess,
    required this.warning,
    required this.onWarning,
    required this.focusRing,
    required this.onFocusRing,
  });

  static const EyesSemanticColors light = EyesSemanticColors(
    success: Color(0xFF126B38),
    onSuccess: Color(0xFFFFFFFF),
    warning: Color(0xFF7A5300),
    onWarning: Color(0xFFFFFFFF),
    focusRing: Color(0xFF005A84),
    onFocusRing: Color(0xFFFFFFFF),
  );
  static const EyesSemanticColors dark = EyesSemanticColors(
    success: Color(0xFF75DB96),
    onSuccess: Color(0xFF003915),
    warning: Color(0xFFF3C65A),
    onWarning: Color(0xFF3E2E00),
    focusRing: Color(0xFF8DCDFF),
    onFocusRing: Color(0xFF00344D),
  );
  static const EyesSemanticColors highContrastLight = EyesSemanticColors(
    success: Color(0xFF003915),
    onSuccess: Color(0xFFFFFFFF),
    warning: Color(0xFF3E2E00),
    onWarning: Color(0xFFFFFFFF),
    focusRing: Color(0xFF003B59),
    onFocusRing: Color(0xFFFFFFFF),
  );
  static const EyesSemanticColors highContrastDark = EyesSemanticColors(
    success: Color(0xFF75DB96),
    onSuccess: Color(0xFF000000),
    warning: Color(0xFFFFD54F),
    onWarning: Color(0xFF000000),
    focusRing: Color(0xFFFFD54F),
    onFocusRing: Color(0xFF000000),
  );

  final Color success;
  final Color onSuccess;
  final Color warning;
  final Color onWarning;
  final Color focusRing;
  final Color onFocusRing;

  @override
  EyesSemanticColors copyWith({
    Color? success,
    Color? onSuccess,
    Color? warning,
    Color? onWarning,
    Color? focusRing,
    Color? onFocusRing,
  }) => EyesSemanticColors(
    success: success ?? this.success,
    onSuccess: onSuccess ?? this.onSuccess,
    warning: warning ?? this.warning,
    onWarning: onWarning ?? this.onWarning,
    focusRing: focusRing ?? this.focusRing,
    onFocusRing: onFocusRing ?? this.onFocusRing,
  );

  @override
  EyesSemanticColors lerp(
    covariant ThemeExtension<EyesSemanticColors>? other,
    double t,
  ) {
    if (other is! EyesSemanticColors) return this;
    return EyesSemanticColors(
      success: Color.lerp(success, other.success, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      onWarning: Color.lerp(onWarning, other.onWarning, t)!,
      focusRing: Color.lerp(focusRing, other.focusRing, t)!,
      onFocusRing: Color.lerp(onFocusRing, other.onFocusRing, t)!,
    );
  }
}

extension EyesSemanticColorsContext on BuildContext {
  EyesSemanticColors get eyesColors =>
      Theme.of(this).extension<EyesSemanticColors>()!;
}
