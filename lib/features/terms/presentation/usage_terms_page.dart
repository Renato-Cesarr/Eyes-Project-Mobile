import 'dart:async';

import 'package:eyes_mobile/app/routing/app_router.dart';
import 'package:eyes_mobile/core/design_system/eyes_design_system.dart';
import 'package:eyes_mobile/features/terms/application/usage_terms.dart';
import 'package:eyes_mobile/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final class UsageTermsPage extends ConsumerStatefulWidget {
  const UsageTermsPage({this.review = false, super.key});

  final bool review;

  @override
  ConsumerState<UsageTermsPage> createState() => _UsageTermsPageState();
}

final class _UsageTermsPageState extends ConsumerState<UsageTermsPage> {
  bool _saving = false;
  bool _declined = false;
  bool _failed = false;

  Future<void> _accept() async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _failed = false;
    });
    try {
      await ref.read(usageTermsProvider).accept();
      if (mounted) context.goNamed(AppRoutes.entry);
    } on Exception {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final gap = context.eyesLayout.spaceLg;
    final sections = [
      (l10n.termsPurposeTitle, l10n.termsPurposeBody),
      (l10n.termsSafetyTitle, l10n.termsSafetyBody),
      (l10n.termsCameraTitle, l10n.termsCameraBody),
      (l10n.termsAccountTitle, l10n.termsAccountBody),
      (l10n.termsChoiceTitle, l10n.termsChoiceBody),
    ];
    return EyesPageScaffold(
      title: l10n.termsTitle,
      adaptiveTitle: true,
      maxContentWidth: context.eyesLayout.readingMaxWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.termsVersion(UsageTerms.version)),
          if (_declined) ...[
            SizedBox(height: gap),
            Semantics(liveRegion: true, child: Text(l10n.termsDeclined)),
            SizedBox(height: gap),
            EyesButton(
              label: l10n.termsReview,
              onPressed: () => setState(() => _declined = false),
            ),
          ] else ...[
            for (final (title, body) in sections) ...[
              SizedBox(height: gap),
              Semantics(
                header: true,
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              Text(body, style: Theme.of(context).textTheme.bodyLarge),
            ],
            if (!widget.review) ...[
              SizedBox(height: gap),
              if (_failed)
                Semantics(liveRegion: true, child: Text(l10n.termsSaveError)),
              EyesButton(
                label: _saving ? l10n.loading : l10n.termsAccept,
                onPressed: _saving ? null : () => unawaited(_accept()),
              ),
              SizedBox(height: context.eyesLayout.spaceSm),
              EyesButton(
                label: l10n.termsDecline,
                variant: EyesButtonVariant.outlined,
                onPressed: _saving
                    ? null
                    : () => setState(() => _declined = true),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
