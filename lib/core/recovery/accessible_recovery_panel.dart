import 'package:eyes_mobile/core/design_system/components/eyes_button.dart';
import 'package:eyes_mobile/core/design_system/components/eyes_card.dart';
import 'package:eyes_mobile/core/design_system/tokens/eyes_layout_tokens.dart';
import 'package:flutter/material.dart';

final class AccessibleRecoveryPanel extends StatefulWidget {
  const AccessibleRecoveryPanel({
    required this.announcementKey,
    required this.title,
    required this.message,
    required this.primaryActionLabel,
    required this.onPrimaryAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.blocking = true,
    super.key,
  });

  final Object announcementKey;
  final String title;
  final String message;
  final String primaryActionLabel;
  final VoidCallback onPrimaryAction;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;
  final bool blocking;

  @override
  State<AccessibleRecoveryPanel> createState() =>
      _AccessibleRecoveryPanelState();
}

final class _AccessibleRecoveryPanelState
    extends State<AccessibleRecoveryPanel> {
  final FocusNode _summaryFocus = FocusNode(debugLabel: 'recovery-summary');

  @override
  void initState() {
    super.initState();
    _requestSummaryFocus();
  }

  @override
  void didUpdateWidget(covariant AccessibleRecoveryPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.announcementKey != widget.announcementKey) {
      _requestSummaryFocus();
    }
  }

  @override
  void dispose() {
    _summaryFocus.dispose();
    super.dispose();
  }

  void _requestSummaryFocus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _summaryFocus.requestFocus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final layout = context.eyesLayout;
    return EyesCard(
      backgroundColor: widget.blocking
          ? colorScheme.errorContainer
          : colorScheme.secondaryContainer,
      padding: EdgeInsets.all(layout.spaceXl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Focus(
            focusNode: _summaryFocus,
            child: Semantics(
              container: true,
              header: true,
              liveRegion: true,
              label: '${widget.title}. ${widget.message}',
              excludeSemantics: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Icon(
                        widget.blocking
                            ? Icons.error_outline
                            : Icons.info_outline,
                        color: widget.blocking
                            ? colorScheme.onErrorContainer
                            : colorScheme.onSecondaryContainer,
                      ),
                      SizedBox(width: layout.spaceMd),
                      Expanded(
                        child: Text(
                          widget.title,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: layout.spaceSm),
                  Text(
                    widget.message,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: layout.spaceXl),
          EyesButton(
            label: widget.primaryActionLabel,
            onPressed: widget.onPrimaryAction,
            expand: true,
          ),
          if (widget.secondaryActionLabel case final label?) ...<Widget>[
            SizedBox(height: layout.spaceSm),
            EyesButton(
              label: label,
              onPressed: widget.onSecondaryAction,
              variant: EyesButtonVariant.text,
              expand: true,
            ),
          ],
        ],
      ),
    );
  }
}
