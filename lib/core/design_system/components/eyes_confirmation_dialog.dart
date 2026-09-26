import 'package:eyes_mobile/core/design_system/components/eyes_button.dart';
import 'package:eyes_mobile/core/design_system/tokens/eyes_layout_tokens.dart';
import 'package:flutter/material.dart';

final class EyesConfirmationDialog extends StatelessWidget {
  const EyesConfirmationDialog({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.cancelLabel,
    this.destructive = false,
    super.key,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final bool destructive;

  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
    required String cancelLabel,
    bool destructive = false,
  }) => showDialog<bool>(
    context: context,
    builder: (BuildContext context) => EyesConfirmationDialog(
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      destructive: destructive,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final layout = context.eyesLayout;
    final scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      semanticLabel: '$title. $message',
      title: Text(title),
      content: Text(message),
      actions: <Widget>[
        EyesButton(
          label: cancelLabel,
          onPressed: () => Navigator.of(context).pop(false),
          variant: EyesButtonVariant.text,
        ),
        Theme(
          data: destructive
              ? Theme.of(context).copyWith(
                  filledButtonTheme: FilledButtonThemeData(
                    style: FilledButton.styleFrom(
                      backgroundColor: scheme.error,
                      foregroundColor: scheme.onError,
                      minimumSize: Size(
                        layout.minimumTapTarget,
                        layout.minimumTapTarget,
                      ),
                    ),
                  ),
                )
              : Theme.of(context),
          child: EyesButton(
            label: confirmLabel,
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ),
      ],
    );
  }
}
