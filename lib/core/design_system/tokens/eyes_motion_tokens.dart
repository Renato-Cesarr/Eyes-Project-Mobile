import 'package:flutter/material.dart';

@immutable
final class EyesMotionTokens extends ThemeExtension<EyesMotionTokens> {
  const EyesMotionTokens({
    required this.fast,
    required this.standard,
    required this.emphasized,
  });

  static const EyesMotionTokens defaults = EyesMotionTokens(
    fast: Duration(milliseconds: 120),
    standard: Duration(milliseconds: 200),
    emphasized: Duration(milliseconds: 300),
  );

  final Duration fast;
  final Duration standard;
  final Duration emphasized;

  Duration resolve(BuildContext context, Duration duration) {
    final mediaQuery = MediaQuery.maybeOf(context);
    return mediaQuery?.disableAnimations ?? false ? Duration.zero : duration;
  }

  @override
  EyesMotionTokens copyWith({
    Duration? fast,
    Duration? standard,
    Duration? emphasized,
  }) => EyesMotionTokens(
    fast: fast ?? this.fast,
    standard: standard ?? this.standard,
    emphasized: emphasized ?? this.emphasized,
  );

  @override
  EyesMotionTokens lerp(
    covariant ThemeExtension<EyesMotionTokens>? other,
    double t,
  ) {
    if (other is! EyesMotionTokens) return this;
    return EyesMotionTokens(
      fast: _lerp(fast, other.fast, t),
      standard: _lerp(standard, other.standard, t),
      emphasized: _lerp(emphasized, other.emphasized, t),
    );
  }

  static Duration _lerp(Duration first, Duration second, double t) => Duration(
    microseconds:
        first.inMicroseconds +
        ((second.inMicroseconds - first.inMicroseconds) * t).round(),
  );
}

extension EyesMotionTokensContext on BuildContext {
  EyesMotionTokens get eyesMotion =>
      Theme.of(this).extension<EyesMotionTokens>()!;
}
