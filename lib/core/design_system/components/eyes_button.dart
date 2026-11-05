import 'package:eyes_mobile/core/design_system/tokens/eyes_layout_tokens.dart';
import 'package:flutter/material.dart';

enum EyesButtonVariant { filled, outlined, text }

final class EyesButton extends StatelessWidget {
  const EyesButton({
    required this.label,
    required this.onPressed,
    this.variant = EyesButtonVariant.filled,
    this.icon,
    this.iconAlignment = IconAlignment.start,
    this.semanticHint,
    this.loading = false,
    this.expand = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final EyesButtonVariant variant;
  final IconData? icon;
  final IconAlignment iconAlignment;
  final String? semanticHint;
  final bool loading;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final enabledAction = loading ? null : onPressed;
    final semanticsLabel = loading ? '$label. Carregando.' : label;
    final content = ExcludeSemantics(
      child: _ButtonContent(
        label: label,
        icon: icon,
        loading: loading,
        iconAlignment: iconAlignment,
        stretch: expand,
      ),
    );
    final button = switch (variant) {
      EyesButtonVariant.filled => FilledButton(
        onPressed: enabledAction,
        child: content,
      ),
      EyesButtonVariant.outlined => OutlinedButton(
        onPressed: enabledAction,
        child: content,
      ),
      EyesButtonVariant.text => TextButton(
        onPressed: enabledAction,
        child: content,
      ),
    };

    final accessibleButton = Semantics(
      button: true,
      enabled: enabledAction != null,
      excludeSemantics: true,
      label: semanticsLabel,
      hint: semanticHint,
      liveRegion: loading,
      onTap: enabledAction,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: context.eyesLayout.minimumTapTarget,
          minWidth: context.eyesLayout.minimumTapTarget,
        ),
        child: button,
      ),
    );

    return expand
        ? SizedBox(width: double.infinity, child: accessibleButton)
        : accessibleButton;
  }
}

final class _ButtonContent extends StatelessWidget {
  const _ButtonContent({
    required this.label,
    required this.icon,
    required this.loading,
    required this.iconAlignment,
    required this.stretch,
  });

  final String label;
  final IconData? icon;
  final bool loading;
  final IconAlignment iconAlignment;
  final bool stretch;

  @override
  Widget build(BuildContext context) {
    final layout = context.eyesLayout;
    final trailingIcon = iconAlignment == IconAlignment.end && !loading;
    final text = Flexible(child: Text(label, textAlign: TextAlign.center));
    return Row(
      mainAxisSize: stretch ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: trailingIcon && stretch
          ? MainAxisAlignment.spaceBetween
          : MainAxisAlignment.center,
      children: <Widget>[
        if (trailingIcon) text,
        if (trailingIcon && icon != null) SizedBox(width: layout.spaceSm),
        if (loading)
          SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(
              color: Theme.of(context).colorScheme.onPrimary,
              strokeWidth: 2.5,
            ),
          )
        else if (icon != null)
          Icon(icon),
        if (!trailingIcon && (loading || icon != null))
          SizedBox(width: layout.spaceSm),
        if (!trailingIcon) text,
      ],
    );
  }
}
