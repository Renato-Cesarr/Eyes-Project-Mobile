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
    return Card(
      color: widget.blocking
          ? colorScheme.errorContainer
          : colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
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
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.title,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.message,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: widget.onPrimaryAction,
              child: Text(widget.primaryActionLabel),
            ),
            if (widget.secondaryActionLabel case final label?) ...<Widget>[
              const SizedBox(height: 8),
              TextButton(
                onPressed: widget.onSecondaryAction,
                child: Text(label),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
