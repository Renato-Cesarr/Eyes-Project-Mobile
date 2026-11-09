import 'dart:async';

import 'package:eyes_mobile/app/routing/app_router.dart';
import 'package:eyes_mobile/core/design_system/eyes_design_system.dart';
import 'package:eyes_mobile/features/diagnostics/application/diagnostic_recorder.dart';
import 'package:eyes_mobile/features/diagnostics/application/diagnostics_controller.dart';
import 'package:eyes_mobile/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final class DiagnosticsPage extends ConsumerStatefulWidget {
  const DiagnosticsPage({super.key});
  @override
  ConsumerState<DiagnosticsPage> createState() => _DiagnosticsPageState();
}

final class _DiagnosticsPageState extends ConsumerState<DiagnosticsPage> {
  bool _consent = false;
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (!ref.watch(diagnosticsEnabledProvider)) return const SizedBox.shrink();
    final result = ref.watch(diagnosticsControllerProvider);
    return EyesPageScaffold(
      title: l10n.diagnosticsTitle,
      adaptiveTitle: true,
      maxContentWidth: context.eyesLayout.readingMaxWidth,
      child: result.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Text(l10n.diagnosticsError),
        data: (value) {
          final controller = ref.read(diagnosticsControllerProvider.notifier);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.diagnosticsIntro,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              SizedBox(height: context.eyesLayout.spaceLg),
              Semantics(
                liveRegion: true,
                child: Text(
                  value.active
                      ? l10n.diagnosticsActive
                      : value.hasReport
                      ? l10n.diagnosticsSaved
                      : l10n.diagnosticsInactive,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (value.failed)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(l10n.diagnosticsError),
                ),
              if (!value.active && !value.hasReport) ...[
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.diagnosticsConsent),
                  value: _consent,
                  onChanged: (value) =>
                      setState(() => _consent = value ?? false),
                ),
                EyesButton(
                  label: l10n.diagnosticsStart,
                  icon: Icons.play_arrow_outlined,
                  expand: true,
                  onPressed: _consent
                      ? () => unawaited(controller.start())
                      : null,
                ),
              ],
              if (value.active) ...[
                SizedBox(height: context.eyesLayout.spaceLg),
                EyesButton(
                  label: l10n.openCamera,
                  icon: Icons.camera_alt_outlined,
                  expand: true,
                  onPressed: () =>
                      unawaited(context.pushNamed(AppRoutes.camera)),
                ),
                EyesButton(
                  label: l10n.diagnosticsStop,
                  icon: Icons.stop_outlined,
                  expand: true,
                  variant: EyesButtonVariant.outlined,
                  onPressed: () => unawaited(controller.stop()),
                ),
              ],
              if (!value.active && value.hasReport) ...[
                SizedBox(height: context.eyesLayout.spaceLg),
                EyesButton(
                  label: l10n.diagnosticsShare,
                  icon: Icons.share_outlined,
                  expand: true,
                  onPressed: () => unawaited(controller.share()),
                ),
                EyesButton(
                  label: l10n.diagnosticsDelete,
                  icon: Icons.delete_outline,
                  expand: true,
                  variant: EyesButtonVariant.outlined,
                  onPressed: () => unawaited(controller.clear()),
                ),
              ],
              SizedBox(height: context.eyesLayout.spaceLg),
              Text(l10n.diagnosticsLimits),
            ],
          );
        },
      ),
    );
  }
}
