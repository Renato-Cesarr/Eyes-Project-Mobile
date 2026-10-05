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
      title: l10n.helpAndSafetyTitle,
      adaptiveTitle: true,
      maxContentWidth: layout.readingMaxWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            l10n.helpAndSafetyIntro,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          SizedBox(height: layout.spaceLg),
          EyesButton(
            label: l10n.repeatFeedbackTests,
            onPressed: () => unawaited(context.pushNamed(AppRoutes.settings)),
            icon: Icons.volume_up_outlined,
            expand: true,
          ),
          SizedBox(height: layout.spaceXl),
          _HelpSection(
            title: l10n.helpSafetyHeading,
            body: l10n.helpSafetyBody,
            icon: Icons.health_and_safety_outlined,
          ),
          const Divider(),
          _HelpSection(
            title: l10n.helpPrivacyHeading,
            body: l10n.helpPrivacyBody,
            icon: Icons.privacy_tip_outlined,
          ),
          const Divider(),
          _HelpSection(
            title: l10n.helpScanningHeading,
            body: l10n.helpScanningBody,
            icon: Icons.center_focus_strong_outlined,
          ),
          const Divider(),
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
    final layout = context.eyesLayout;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: layout.spaceLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              ExcludeSemantics(
                child: Icon(icon, color: Theme.of(context).colorScheme.primary),
              ),
              SizedBox(width: layout.spaceMd),
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: layout.spaceSm),
          Text(body, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}
