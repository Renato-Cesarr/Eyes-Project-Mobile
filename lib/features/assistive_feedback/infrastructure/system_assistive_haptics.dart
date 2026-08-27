import 'dart:async';

import 'package:eyes_mobile/features/assistive_feedback/application/assistive_haptics.dart';
import 'package:flutter/services.dart';

typedef HapticDelay = Future<void> Function(Duration duration);

final class SystemAssistiveHaptics implements AssistiveHaptics {
  SystemAssistiveHaptics({HapticDelay? delay})
    : _delay = delay ?? Future<void>.delayed;

  final HapticDelay _delay;

  @override
  Future<void> confirm() => HapticFeedback.lightImpact();

  @override
  Future<void> warning() => HapticFeedback.mediumImpact();

  @override
  Future<void> criticalAlert() async {
    await HapticFeedback.heavyImpact();
    await _delay(const Duration(milliseconds: 100));
    await HapticFeedback.heavyImpact();
  }
}
