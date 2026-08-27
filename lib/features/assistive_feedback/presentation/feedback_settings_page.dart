import 'dart:async';

import 'package:eyes_mobile/features/assistive_feedback/application/assistive_feedback_controller.dart';
import 'package:eyes_mobile/features/assistive_feedback/application/assistive_feedback_state.dart';
import 'package:eyes_mobile/features/assistive_feedback/domain/feedback_preferences.dart';
import 'package:eyes_mobile/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final class FeedbackSettingsPage extends ConsumerWidget {
  const FeedbackSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(assistiveFeedbackControllerProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.feedbackSettingsTitle)),
      body: SafeArea(
        child: state.when(
          data: (settings) => _SettingsContent(settings: settings),
          error: (error, stackTrace) => _SettingsError(
            onRetry: () => ref.invalidate(assistiveFeedbackControllerProvider),
          ),
          loading: () => Center(
            child: Semantics(
              liveRegion: true,
              label: l10n.loadingFeedbackSettings,
              child: const CircularProgressIndicator(),
            ),
          ),
        ),
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

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.feedbackSettingsIntro,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 28),
                _SectionTitle(l10n.voiceSectionTitle),
                const SizedBox(height: 12),
                _AccessibleSlider(
                  label: l10n.speechRateLabel,
                  value: preferences.speechRate,
                  min: 0.30,
                  max: 0.70,
                  divisions: 8,
                  valueText: l10n.speechRateValue(
                    (preferences.speechRate * 100).round(),
                  ),
                  rangeHint: l10n.speechRateRange,
                  onChanged: (value) => controller.updatePreferences(
                    preferences.copyWith(speechRate: value),
                  ),
                ),
                const SizedBox(height: 20),
                _AccessibleSlider(
                  label: l10n.speechVolumeLabel,
                  value: preferences.volume,
                  min: 0,
                  max: 1,
                  divisions: 10,
                  valueText: l10n.percentValue(
                    (preferences.volume * 100).round(),
                  ),
                  rangeHint: l10n.speechVolumeRange,
                  onChanged: (value) => controller.updatePreferences(
                    preferences.copyWith(volume: value),
                  ),
                ),
                const SizedBox(height: 20),
                _AccessibleDropdown<VoiceDetailLevel>(
                  label: l10n.voiceDetailLabel,
                  value: preferences.detailLevel,
                  items: {
                    VoiceDetailLevel.concise: l10n.voiceDetailConcise,
                    VoiceDetailLevel.detailed: l10n.voiceDetailDetailed,
                  },
                  onChanged: (value) => controller.updatePreferences(
                    preferences.copyWith(detailLevel: value),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => controller.testVoice(l10n.voiceTestPhrase),
                  icon: const ExcludeSemantics(
                    child: Icon(Icons.record_voice_over_outlined),
                  ),
                  label: Text(l10n.testVoice),
                ),
                const SizedBox(height: 32),
                _SectionTitle(l10n.alertsSectionTitle),
                const SizedBox(height: 12),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.announceAttentionLabel),
                  subtitle: Text(l10n.announceAttentionDescription),
                  value: preferences.announceAttention,
                  onChanged: (value) => controller.updatePreferences(
                    preferences.copyWith(announceAttention: value),
                  ),
                ),
                const SizedBox(height: 12),
                _AccessibleDropdown<AlertSensitivityPreset>(
                  label: l10n.sensitivityLabel,
                  value: preferences.sensitivity,
                  items: {
                    AlertSensitivityPreset.conservative:
                        l10n.sensitivityConservative,
                    AlertSensitivityPreset.balanced: l10n.sensitivityBalanced,
                    AlertSensitivityPreset.fewerAlerts:
                        l10n.sensitivityFewerAlerts,
                  },
                  onChanged: (value) => controller.updatePreferences(
                    preferences.copyWith(sensitivity: value),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _sensitivityDescription(l10n, preferences.sensitivity),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 32),
                _SectionTitle(l10n.hapticsSectionTitle),
                const SizedBox(height: 12),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.hapticsEnabledLabel),
                  subtitle: Text(l10n.hapticsDescription),
                  value: preferences.hapticsEnabled,
                  onChanged: (value) => controller.updatePreferences(
                    preferences.copyWith(hapticsEnabled: value),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: preferences.hapticsEnabled
                      ? controller.testHaptics
                      : null,
                  icon: const ExcludeSemantics(child: Icon(Icons.vibration)),
                  label: Text(l10n.testHaptics),
                ),
                const SizedBox(height: 32),
                _SectionTitle(l10n.privacySectionTitle),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      l10n.feedbackPrivacyDescription,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                OutlinedButton(
                  onPressed: () => _confirmRestore(context, controller),
                  child: Text(l10n.restoreDefaults),
                ),
                if (notice != null) ...[
                  const SizedBox(height: 20),
                  Semantics(
                    container: true,
                    liveRegion: true,
                    child: Text(
                      notice,
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmRestore(
    BuildContext context,
    AssistiveFeedbackController controller,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.restoreDefaultsTitle),
        content: Text(l10n.restoreDefaultsDescription),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.confirmRestore),
          ),
        ],
      ),
    );
    if (confirmed ?? false) {
      await controller.restoreDefaults();
    }
  }
}

final class _AccessibleSlider extends StatefulWidget {
  const _AccessibleSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.valueText,
    required this.rangeHint,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String valueText;
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
      value: widget.valueText,
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
          Text(widget.label, style: Theme.of(context).textTheme.titleMedium),
          Text(widget.valueText),
          Slider(
            value: _value,
            min: widget.min,
            max: widget.max,
            divisions: widget.divisions,
            label: widget.valueText,
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
    required this.onChanged,
  });

  final String label;
  final T value;
  final Map<T, String> items;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
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

final class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Text(text, style: Theme.of(context).textTheme.titleLarge),
    );
  }
}

final class _SettingsError extends StatelessWidget {
  const _SettingsError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Semantics(
          liveRegion: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.feedbackSettingsLoadError),
              const SizedBox(height: 16),
              FilledButton(onPressed: onRetry, child: Text(l10n.tryAgain)),
            ],
          ),
        ),
      ),
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
