import 'dart:async';

import 'package:eyes_mobile/app/routing/app_router.dart';
import 'package:eyes_mobile/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

final class HelpAndSafetyPage extends StatelessWidget {
  const HelpAndSafetyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.helpAndSafetyTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: <Widget>[
            _HelpSection(
              title: l10n.helpSafetyHeading,
              body: l10n.helpSafetyBody,
              icon: Icons.health_and_safety_outlined,
            ),
            const SizedBox(height: 16),
            _HelpSection(
              title: l10n.helpPrivacyHeading,
              body: l10n.helpPrivacyBody,
              icon: Icons.privacy_tip_outlined,
            ),
            const SizedBox(height: 16),
            _HelpSection(
              title: l10n.helpScanningHeading,
              body: l10n.helpScanningBody,
              icon: Icons.center_focus_strong_outlined,
            ),
            const SizedBox(height: 16),
            _HelpSection(
              title: l10n.helpPermissionHeading,
              body: l10n.helpPermissionBody,
              icon: Icons.camera_alt_outlined,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => unawaited(
                context.pushNamed(
                  AppRoutes.onboarding,
                  queryParameters: const <String, String>{'replay': 'true'},
                ),
              ),
              icon: const ExcludeSemantics(child: Icon(Icons.replay_outlined)),
              label: Text(l10n.repeatOnboarding),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => unawaited(context.pushNamed(AppRoutes.settings)),
              icon: const ExcludeSemantics(
                child: Icon(Icons.volume_up_outlined),
              ),
              label: Text(l10n.repeatFeedbackTests),
            ),
          ],
        ),
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                ExcludeSemantics(child: Icon(icon)),
                const SizedBox(width: 12),
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
            const SizedBox(height: 12),
            Text(body, style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }
}
