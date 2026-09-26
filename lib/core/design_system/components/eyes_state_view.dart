import 'package:eyes_mobile/core/design_system/components/eyes_button.dart';
import 'package:eyes_mobile/core/design_system/tokens/eyes_layout_tokens.dart';
import 'package:flutter/material.dart';

enum EyesStateKind { loading, empty, error }

final class EyesStateView extends StatelessWidget {
  const EyesStateView.loading({required this.title, this.message, super.key})
    : kind = EyesStateKind.loading,
      actionLabel = null,
      onAction = null;

  const EyesStateView.empty({
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    super.key,
  }) : kind = EyesStateKind.empty;

  const EyesStateView.error({
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    super.key,
  }) : kind = EyesStateKind.error;

  final EyesStateKind kind;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final layout = context.eyesLayout;
    final semanticsLabel = message == null ? title : '$title. $message';
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: layout.readingMaxWidth),
        child: Padding(
          padding: EdgeInsets.all(layout.spaceXl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Semantics(
                container: true,
                excludeSemantics: true,
                label: semanticsLabel,
                liveRegion: kind != EyesStateKind.empty,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    if (kind == EyesStateKind.loading)
                      const CircularProgressIndicator()
                    else
                      Icon(_icon, size: 48),
                    SizedBox(height: layout.spaceLg),
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    if (message != null) ...<Widget>[
                      SizedBox(height: layout.spaceSm),
                      Text(
                        message!,
                        style: Theme.of(context).textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
              if (actionLabel != null && onAction != null) ...<Widget>[
                SizedBox(height: layout.spaceXl),
                EyesButton(
                  label: actionLabel!,
                  onPressed: onAction,
                  variant: kind == EyesStateKind.error
                      ? EyesButtonVariant.filled
                      : EyesButtonVariant.outlined,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  IconData get _icon => switch (kind) {
    EyesStateKind.loading => Icons.hourglass_empty,
    EyesStateKind.empty => Icons.inbox_outlined,
    EyesStateKind.error => Icons.error_outline,
  };
}
