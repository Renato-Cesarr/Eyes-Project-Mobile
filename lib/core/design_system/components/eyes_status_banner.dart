import 'package:eyes_mobile/core/design_system/tokens/eyes_layout_tokens.dart';
import 'package:eyes_mobile/core/design_system/tokens/eyes_semantic_colors.dart';
import 'package:flutter/material.dart';

enum EyesStatusTone { info, success, warning, error }

final class EyesStatusBanner extends StatelessWidget {
  const EyesStatusBanner({
    required this.title,
    required this.message,
    this.tone = EyesStatusTone.info,
    this.liveRegion = false,
    super.key,
  });

  final String title;
  final String message;
  final EyesStatusTone tone;
  final bool liveRegion;

  @override
  Widget build(BuildContext context) {
    final colors = _colors(context);
    final layout = context.eyesLayout;
    return Semantics(
      container: true,
      excludeSemantics: true,
      label: '$title. $message',
      liveRegion: liveRegion,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.background,
          border: Border.all(color: colors.foreground),
          borderRadius: BorderRadius.circular(layout.radiusMd),
        ),
        child: Padding(
          padding: EdgeInsets.all(layout.spaceLg),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(_icon, color: colors.foreground),
              SizedBox(width: layout.spaceMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: colors.foreground,
                      ),
                    ),
                    SizedBox(height: layout.spaceXs),
                    Text(
                      message,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.copyWith(color: colors.foreground),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData get _icon => switch (tone) {
    EyesStatusTone.info => Icons.info_outline,
    EyesStatusTone.success => Icons.check_circle_outline,
    EyesStatusTone.warning => Icons.warning_amber_outlined,
    EyesStatusTone.error => Icons.error_outline,
  };

  ({Color background, Color foreground}) _colors(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final semantic = context.eyesColors;
    return switch (tone) {
      EyesStatusTone.info => (
        background: scheme.primaryContainer,
        foreground: scheme.onPrimaryContainer,
      ),
      EyesStatusTone.success => (
        background: semantic.success,
        foreground: semantic.onSuccess,
      ),
      EyesStatusTone.warning => (
        background: semantic.warning,
        foreground: semantic.onWarning,
      ),
      EyesStatusTone.error => (
        background: scheme.error,
        foreground: scheme.onError,
      ),
    };
  }
}
