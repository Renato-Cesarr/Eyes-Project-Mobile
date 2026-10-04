import 'dart:async';

import 'package:eyes_mobile/app/routing/app_router.dart';
import 'package:eyes_mobile/core/design_system/eyes_design_system.dart';
import 'package:eyes_mobile/features/appearance/application/appearance_controller.dart';
import 'package:eyes_mobile/features/appearance/application/appearance_state.dart';
import 'package:eyes_mobile/features/appearance/domain/appearance_preference.dart';
import 'package:eyes_mobile/features/assistive_feedback/application/assistive_feedback_controller.dart';
import 'package:eyes_mobile/features/assistive_feedback/application/assistive_feedback_state.dart';
import 'package:eyes_mobile/features/assistive_feedback/domain/feedback_preferences.dart';
import 'package:eyes_mobile/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final class FeedbackSettingsPage extends ConsumerWidget {
  const FeedbackSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(assistiveFeedbackControllerProvider);
    return EyesPageScaffold(
      title: l10n.feedbackSettingsTitle,
      maxContentWidth: 720,
      adaptiveTitle: true,
      contentPadding: EdgeInsets.all(
        MediaQuery.sizeOf(context).width < 360 ? 20 : 24,
      ),
      child: state.when(
        data: (settings) => _SettingsContent(settings: settings),
        error: (error, stackTrace) => EyesStateView.error(
          title: l10n.feedbackSettingsLoadError,
          actionLabel: l10n.tryAgain,
          onAction: () => ref.invalidate(assistiveFeedbackControllerProvider),
        ),
        loading: () =>
            EyesStateView.loading(title: l10n.loadingFeedbackSettings),
      ),
    );
  }
}

final class _SettingsContent extends ConsumerWidget {
  const _SettingsContent({required this.settings});

  final AssistiveFeedbackState settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final preferences = settings.preferences;
    final controller = ref.read(assistiveFeedbackControllerProvider.notifier);
    final notice = _noticeText(l10n, settings.notice);
    final appearance = ref.watch(appearanceControllerProvider);
    final appearanceState = appearance.asData?.value;
    final appearanceNotice = appearanceState == null
        ? null
        : _appearanceNoticeText(l10n, appearanceState.notice);
    final layout = context.eyesLayout;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          l10n.feedbackSettingsIntro,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        SizedBox(height: layout.spaceLg),
        _SettingsGroup(
          title: l10n.voiceSectionTitle,
          first: true,
          icon: Icons.record_voice_over_outlined,
          children: <Widget>[
            _AccessibleSlider(
              label: l10n.speechRateLabel,
              value: preferences.speechRate,
              min: 0.30,
              max: 0.70,
              divisions: 8,
              rangeHint: l10n.speechRateRange,
              onChanged: (value) => controller.updatePreferences(
                preferences.copyWith(speechRate: value),
              ),
            ),
            _AccessibleSlider(
              label: l10n.speechVolumeLabel,
              value: preferences.volume,
              min: 0,
              max: 1,
              divisions: 10,
              rangeHint: l10n.speechVolumeRange,
              onChanged: (value) => controller.updatePreferences(
                preferences.copyWith(volume: value),
              ),
            ),
            _AccessibleDropdown<VoiceDetailLevel>(
              label: l10n.voiceDetailLabel,
              value: preferences.detailLevel,
              items: <VoiceDetailLevel, String>{
                VoiceDetailLevel.concise: l10n.voiceDetailConcise,
                VoiceDetailLevel.detailed: l10n.voiceDetailDetailed,
              },
              onChanged: (value) => controller.updatePreferences(
                preferences.copyWith(detailLevel: value),
              ),
            ),
            EyesButton(
              label: l10n.testVoice,
              onPressed: () => controller.testVoice(l10n.voiceTestPhrase),
              icon: Icons.record_voice_over_outlined,
              variant: EyesButtonVariant.outlined,
              expand: true,
            ),
          ],
        ),
        _SettingsGroup(
          title: l10n.alertsSectionTitle,
          icon: Icons.notifications_active_outlined,
          children: <Widget>[
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.announceAttentionLabel),
              subtitle: Text(l10n.announceAttentionDescription),
              value: preferences.announceAttention,
              onChanged: (value) => controller.updatePreferences(
                preferences.copyWith(announceAttention: value),
              ),
            ),
            _AccessibleDropdown<AlertSensitivityPreset>(
              label: l10n.sensitivityLabel,
              value: preferences.sensitivity,
              items: <AlertSensitivityPreset, String>{
                AlertSensitivityPreset.conservative:
                    l10n.sensitivityConservative,
                AlertSensitivityPreset.balanced: l10n.sensitivityBalanced,
                AlertSensitivityPreset.fewerAlerts: l10n.sensitivityFewerAlerts,
              },
              onChanged: (value) => controller.updatePreferences(
                preferences.copyWith(sensitivity: value),
              ),
            ),
            Text(
              _sensitivityDescription(l10n, preferences.sensitivity),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
        _SettingsGroup(
          title: l10n.hapticsSectionTitle,
          icon: Icons.vibration_outlined,
          children: <Widget>[
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.hapticsEnabledLabel),
              subtitle: Text(l10n.hapticsDescription),
              value: preferences.hapticsEnabled,
              onChanged: (value) => controller.updatePreferences(
                preferences.copyWith(hapticsEnabled: value),
              ),
            ),
            EyesButton(
              label: l10n.testHaptics,
              onPressed: preferences.hapticsEnabled
                  ? controller.testHaptics
                  : null,
              icon: Icons.vibration,
              variant: EyesButtonVariant.outlined,
              expand: true,
            ),
          ],
        ),
        _SettingsGroup(
          title: l10n.appearanceSectionTitle,
          icon: Icons.contrast_outlined,
          children: <Widget>[
            if (appearanceState == null)
              Semantics(
                liveRegion: true,
                label: l10n.loading,
                child: const LinearProgressIndicator(),
              )
            else
              _AccessibleDropdown<AppearancePreference>(
                label: l10n.appearanceLabel,
                value: appearanceState.preference,
                items: <AppearancePreference, String>{
                  AppearancePreference.system: l10n.appearanceSystem,
                  AppearancePreference.light: l10n.appearanceLight,
                  AppearancePreference.dark: l10n.appearanceDark,
                  AppearancePreference.highContrastLight:
                      l10n.appearanceHighContrastLight,
                  AppearancePreference.highContrastDark:
                      l10n.appearanceHighContrastDark,
                },
                selectedLabels: <AppearancePreference, String>{
                  AppearancePreference.system: l10n.appearanceSystemShort,
                },
                onChanged: ref
                    .read(appearanceControllerProvider.notifier)
                    .select,
              ),
          ],
        ),
        _SettingsGroup(
          title: l10n.privacySectionTitle,
          description: l10n.feedbackPrivacyDescription,
          icon: Icons.privacy_tip_outlined,
          children: <Widget>[
            EyesButton(
              label: l10n.openAccountSettings,
              onPressed: () => context.pushNamed(AppRoutes.account),
              icon: Icons.account_circle_outlined,
              variant: EyesButtonVariant.outlined,
              expand: true,
            ),
          ],
        ),
        SizedBox(height: layout.spaceXl),
        EyesButton(
          label: l10n.restoreDefaults,
          onPressed: () => _confirmRestore(context, controller),
          variant: EyesButtonVariant.text,
          expand: true,
        ),
        if (notice != null || appearanceNotice != null) ...<Widget>[
          SizedBox(height: layout.spaceLg),
          EyesStatusBanner(
            title: l10n.feedbackSettingsTitle,
            message: appearanceNotice ?? notice!,
            tone:
                appearanceState?.notice == AppearanceNotice.saveFailed ||
                    settings.notice == FeedbackNotice.persistenceFailed
                ? EyesStatusTone.error
                : EyesStatusTone.success,
            liveRegion: true,
          ),
        ],
      ],
    );
  }

  Future<void> _confirmRestore(
    BuildContext context,
    AssistiveFeedbackController controller,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await EyesConfirmationDialog.show(
      context,
      title: l10n.restoreDefaultsTitle,
      message: l10n.restoreDefaultsDescription,
      confirmLabel: l10n.confirmRestore,
      cancelLabel: l10n.cancel,
    );
    if (confirmed ?? false) {
      await controller.restoreDefaults();
    }
  }
}

/// Keeps settings in one continuous reading flow instead of stacking large cards.
final class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({
    required this.title,
    required this.children,
    this.description,
    this.icon,
    this.first = false,
  });

  final String title;
  final String? description;
  final IconData? icon;
  final bool first;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final layout = context.eyesLayout;
    return Padding(
      padding: EdgeInsets.only(bottom: layout.spaceXl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (!first) ...[const Divider(), SizedBox(height: layout.spaceLg)],
          Row(
            children: <Widget>[
              if (icon != null) ...<Widget>[
                ExcludeSemantics(child: Icon(icon, size: 24)),
                SizedBox(width: layout.spaceMd),
              ],
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ),
            ],
          ),
          if (description != null) ...<Widget>[
            SizedBox(height: layout.spaceSm),
            Text(description!, style: Theme.of(context).textTheme.bodyMedium),
          ],
          SizedBox(height: layout.spaceLg),
          for (var index = 0; index < children.length; index++) ...<Widget>[
            children[index],
            if (index < children.length - 1) SizedBox(height: layout.spaceMd),
          ],
        ],
      ),
    );
  }
}

final class _AccessibleSlider extends StatefulWidget {
  const _AccessibleSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.rangeHint,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String rangeHint;
  final ValueChanged<double> onChanged;

  @override
  State<_AccessibleSlider> createState() => _AccessibleSliderState();
}

final class _AccessibleSliderState extends State<_AccessibleSlider> {
  late double _value = widget.value;

  @override
  void didUpdateWidget(_AccessibleSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _value = widget.value;
    }
  }

  @override
  Widget build(BuildContext context) {
    final step = (widget.max - widget.min) / widget.divisions;
    void change(double value) {
      setState(() => _value = value.clamp(widget.min, widget.max));
    }

    return Semantics(
      container: true,
      slider: true,
      label: widget.label,
      value: AppLocalizations.of(context).percentValue((_value * 100).round()),
      increasedValue:
          '${((_value + step).clamp(widget.min, widget.max) * 100).round()} por cento',
      decreasedValue:
          '${((_value - step).clamp(widget.min, widget.max) * 100).round()} por cento',
      hint: widget.rangeHint,
      onIncrease: () {
        change(_value + step);
        widget.onChanged(_value);
      },
      onDecrease: () {
        change(_value - step);
        widget.onChanged(_value);
      },
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  widget.label,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              SizedBox(width: context.eyesLayout.spaceSm),
              Text(
                '${(_value * 100).round()}%',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          Slider(
            value: _value,
            min: widget.min,
            max: widget.max,
            divisions: widget.divisions,
            label: '${(_value * 100).round()}%',
            onChanged: change,
            onChangeEnd: widget.onChanged,
          ),
        ],
      ),
    );
  }
}

final class _AccessibleDropdown<T extends Enum> extends StatelessWidget {
  const _AccessibleDropdown({
    required this.label,
    required this.value,
    required this.items,
    this.selectedLabels,
    required this.onChanged,
  });

  final String label;
  final T value;
  final Map<T, String> items;
  final Map<T, String>? selectedLabels;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
      itemHeight: null,
      selectedItemBuilder: (context) => items.entries
          .map(
            (entry) => Align(
              alignment: Alignment.centerLeft,
              child: Text(
                selectedLabels?[entry.key] ?? entry.value,
                overflow: TextOverflow.visible,
                semanticsLabel: entry.value,
              ),
            ),
          )
          .toList(growable: false),
      decoration: InputDecoration(
        border: const OutlineInputBorder(),
        labelText: label,
      ),
      items: items.entries
          .map(
            (entry) => DropdownMenuItem<T>(
              value: entry.key,
              child: Text(entry.value, overflow: TextOverflow.visible),
            ),
          )
          .toList(growable: false),
      onChanged: (selected) {
        if (selected != null) {
          onChanged(selected);
        }
      },
    );
  }
}

String? _noticeText(AppLocalizations l10n, FeedbackNotice notice) {
  return switch (notice) {
    FeedbackNotice.none => null,
    FeedbackNotice.preferencesSaved => l10n.preferencesSaved,
    FeedbackNotice.defaultsRestored => l10n.defaultsRestored,
    FeedbackNotice.voiceTestSucceeded => l10n.voiceTestSucceeded,
    FeedbackNotice.hapticTestSucceeded => l10n.hapticTestSucceeded,
    FeedbackNotice.speechUnavailable => l10n.speechUnavailable,
    FeedbackNotice.hapticsUnavailable => l10n.hapticsUnavailable,
    FeedbackNotice.persistenceFailed => l10n.preferencesSaveFailed,
  };
}

String? _appearanceNoticeText(AppLocalizations l10n, AppearanceNotice notice) =>
    switch (notice) {
      AppearanceNotice.none => null,
      AppearanceNotice.saved => l10n.appearanceSaved,
      AppearanceNotice.saveFailed => l10n.appearanceSaveFailed,
    };

String _sensitivityDescription(
  AppLocalizations l10n,
  AlertSensitivityPreset preset,
) {
  return switch (preset) {
    AlertSensitivityPreset.conservative =>
      l10n.sensitivityConservativeDescription,
    AlertSensitivityPreset.balanced => l10n.sensitivityBalancedDescription,
    AlertSensitivityPreset.fewerAlerts =>
      l10n.sensitivityFewerAlertsDescription,
  };
}
