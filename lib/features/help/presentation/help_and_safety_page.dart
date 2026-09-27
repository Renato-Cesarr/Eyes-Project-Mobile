import 'dart:async';

import 'package:eyes_mobile/app/routing/app_router.dart';
import 'package:eyes_mobile/core/design_system/eyes_design_system.dart';
import 'package:eyes_mobile/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

final class HelpAndSafetyPage extends StatelessWidget {
  const HelpAndSafetyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final layout = context.eyesLayout;
    return EyesPageScaffold(
      title: l10n.appName,
      maxContentWidth: layout.readingMaxWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          EyesPageHeader(
            title: l10n.helpAndSafetyTitle,
            description: l10n.helpAndSafetyIntro,
            leading: const ExcludeSemantics(
              child: Icon(Icons.help_outline, size: 40),
            ),
          ),
          SizedBox(height: layout.spaceXl),
          _HelpSection(
            title: l10n.helpSafetyHeading,
            body: l10n.helpSafetyBody,
            icon: Icons.health_and_safety_outlined,
          ),
          SizedBox(height: layout.spaceLg),
          _HelpSection(
            title: l10n.helpPrivacyHeading,
            body: l10n.helpPrivacyBody,
            icon: Icons.privacy_tip_outlined,
          ),
          SizedBox(height: layout.spaceLg),
          _HelpSection(
            title: l10n.helpScanningHeading,
            body: l10n.helpScanningBody,
            icon: Icons.center_focus_strong_outlined,
          ),
          SizedBox(height: layout.spaceLg),
          _HelpSection(
            title: l10n.helpPermissionHeading,
            body: l10n.helpPermissionBody,
            icon: Icons.camera_alt_outlined,
          ),
          SizedBox(height: layout.spaceXl),
          EyesButton(
            label: l10n.repeatOnboarding,
            onPressed: () => unawaited(
              context.pushNamed(
                AppRoutes.onboarding,
                queryParameters: const <String, String>{'replay': 'true'},
              ),
            ),
            icon: Icons.replay_outlined,
            expand: true,
          ),
          SizedBox(height: layout.spaceMd),
          EyesButton(
            label: l10n.repeatFeedbackTests,
            onPressed: () => unawaited(context.pushNamed(AppRoutes.settings)),
            icon: Icons.volume_up_outlined,
            variant: EyesButtonVariant.outlined,
            expand: true,
          ),
        ],
      ),
    );
  }
}

final class _HelpSection extends StatelessWidget {
  const _HelpSection({
    required this.title,
    required this.body,
    required this.icon,
  });

  final String title;
  final String body;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return EyesSection(
      title: title,
      description: body,
      icon: icon,
      children: const <Widget>[],
    );
  }
}
