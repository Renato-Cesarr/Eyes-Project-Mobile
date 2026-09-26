import 'package:flutter/material.dart';

@immutable
final class EyesLayoutTokens extends ThemeExtension<EyesLayoutTokens> {
  const EyesLayoutTokens({
    required this.spaceXs,
    required this.spaceSm,
    required this.spaceMd,
    required this.spaceLg,
    required this.spaceXl,
    required this.spaceXxl,
    required this.radiusSm,
    required this.radiusMd,
    required this.radiusLg,
    required this.minimumTapTarget,
    required this.readingMaxWidth,
    required this.contentMaxWidth,
  });

  static const EyesLayoutTokens standard = EyesLayoutTokens(
    spaceXs: 4,
    spaceSm: 8,
    spaceMd: 12,
    spaceLg: 16,
    spaceXl: 24,
    spaceXxl: 32,
    radiusSm: 8,
    radiusMd: 12,
    radiusLg: 16,
    minimumTapTarget: 48,
    readingMaxWidth: 640,
    contentMaxWidth: 1200,
  );

  final double spaceXs;
  final double spaceSm;
  final double spaceMd;
  final double spaceLg;
  final double spaceXl;
  final double spaceXxl;
  final double radiusSm;
  final double radiusMd;
  final double radiusLg;
  final double minimumTapTarget;
  final double readingMaxWidth;
  final double contentMaxWidth;

  EdgeInsets pagePaddingFor(double width) => EdgeInsets.symmetric(
    horizontal: width >= 600 ? spaceXl : spaceLg,
    vertical: spaceXl,
  );

  @override
  EyesLayoutTokens copyWith({
    double? spaceXs,
    double? spaceSm,
    double? spaceMd,
    double? spaceLg,
    double? spaceXl,
    double? spaceXxl,
    double? radiusSm,
    double? radiusMd,
    double? radiusLg,
    double? minimumTapTarget,
    double? readingMaxWidth,
    double? contentMaxWidth,
  }) => EyesLayoutTokens(
    spaceXs: spaceXs ?? this.spaceXs,
    spaceSm: spaceSm ?? this.spaceSm,
    spaceMd: spaceMd ?? this.spaceMd,
    spaceLg: spaceLg ?? this.spaceLg,
    spaceXl: spaceXl ?? this.spaceXl,
    spaceXxl: spaceXxl ?? this.spaceXxl,
    radiusSm: radiusSm ?? this.radiusSm,
    radiusMd: radiusMd ?? this.radiusMd,
    radiusLg: radiusLg ?? this.radiusLg,
    minimumTapTarget: minimumTapTarget ?? this.minimumTapTarget,
    readingMaxWidth: readingMaxWidth ?? this.readingMaxWidth,
    contentMaxWidth: contentMaxWidth ?? this.contentMaxWidth,
  );

  @override
  EyesLayoutTokens lerp(
    covariant ThemeExtension<EyesLayoutTokens>? other,
    double t,
  ) {
    if (other is! EyesLayoutTokens) return this;
    return EyesLayoutTokens(
      spaceXs: _lerp(spaceXs, other.spaceXs, t),
      spaceSm: _lerp(spaceSm, other.spaceSm, t),
      spaceMd: _lerp(spaceMd, other.spaceMd, t),
      spaceLg: _lerp(spaceLg, other.spaceLg, t),
      spaceXl: _lerp(spaceXl, other.spaceXl, t),
      spaceXxl: _lerp(spaceXxl, other.spaceXxl, t),
      radiusSm: _lerp(radiusSm, other.radiusSm, t),
      radiusMd: _lerp(radiusMd, other.radiusMd, t),
      radiusLg: _lerp(radiusLg, other.radiusLg, t),
      minimumTapTarget: _lerp(minimumTapTarget, other.minimumTapTarget, t),
      readingMaxWidth: _lerp(readingMaxWidth, other.readingMaxWidth, t),
      contentMaxWidth: _lerp(contentMaxWidth, other.contentMaxWidth, t),
    );
  }

  static double _lerp(double first, double second, double t) =>
      first + (second - first) * t;
}

extension EyesLayoutTokensContext on BuildContext {
  EyesLayoutTokens get eyesLayout =>
      Theme.of(this).extension<EyesLayoutTokens>()!;
}
