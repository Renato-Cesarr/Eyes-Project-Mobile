enum VoiceDetailLevel { concise, detailed }

enum AlertSensitivityPreset { conservative, balanced, fewerAlerts }

final class FeedbackPreferences {
  const FeedbackPreferences({
    this.speechRate = 0.50,
    this.volume = 1,
    this.detailLevel = VoiceDetailLevel.concise,
    this.announceAttention = true,
    this.sensitivity = AlertSensitivityPreset.balanced,
    this.hapticsEnabled = true,
  });

  static const FeedbackPreferences defaults = FeedbackPreferences();

  final double speechRate;
  final double volume;
  final VoiceDetailLevel detailLevel;
  final bool announceAttention;
  final AlertSensitivityPreset sensitivity;
  final bool hapticsEnabled;

  FeedbackPreferences copyWith({
    double? speechRate,
    double? volume,
    VoiceDetailLevel? detailLevel,
    bool? announceAttention,
    AlertSensitivityPreset? sensitivity,
    bool? hapticsEnabled,
  }) {
    return FeedbackPreferences(
      speechRate: (speechRate ?? this.speechRate).clamp(0.30, 0.70),
      volume: (volume ?? this.volume).clamp(0, 1),
      detailLevel: detailLevel ?? this.detailLevel,
      announceAttention: announceAttention ?? this.announceAttention,
      sensitivity: sensitivity ?? this.sensitivity,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
    );
  }
}
