import 'package:eyes_mobile/features/scanning/application/scan_transition_feedback.dart';
import 'package:flutter/services.dart';

typedef ScanHapticsEnabled = bool Function();

final class SystemScanTransitionFeedback implements ScanTransitionFeedback {
  SystemScanTransitionFeedback({ScanHapticsEnabled? hapticsEnabled})
    : _hapticsEnabled = hapticsEnabled ?? _enabledByDefault;

  final ScanHapticsEnabled _hapticsEnabled;

  @override
  Future<void> deliver(ScanTransition transition) async {
    if (_hapticsEnabled()) {
      await switch (transition) {
        ScanTransition.started => HapticFeedback.lightImpact(),
        ScanTransition.paused => HapticFeedback.selectionClick(),
        ScanTransition.ended => HapticFeedback.mediumImpact(),
      };
    }
    await SystemSound.play(SystemSoundType.click);
  }
}

bool _enabledByDefault() => true;
