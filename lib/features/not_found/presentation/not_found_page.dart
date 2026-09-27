import 'package:eyes_mobile/app/routing/app_router.dart';
import 'package:eyes_mobile/core/design_system/eyes_design_system.dart';
import 'package:eyes_mobile/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

final class NotFoundPage extends StatelessWidget {
  const NotFoundPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return EyesPageScaffold(
      title: l10n.appName,
      maxContentWidth: context.eyesLayout.readingMaxWidth,
      child: EyesStateView.empty(
        title: l10n.notFoundTitle,
        message: l10n.notFoundMessage,
        actionLabel: l10n.goHome,
        onAction: () => context.goNamed(AppRoutes.home),
      ),
    );
  }
}
