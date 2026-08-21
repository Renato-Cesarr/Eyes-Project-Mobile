import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract interface class AccessibleFeedbackService {
  Future<void> confirm();
  Future<void> warn();
}

final class SystemAccessibleFeedbackService
    implements AccessibleFeedbackService {
  SystemAccessibleFeedbackService({FeedbackDelay? delay})
    : _delay = delay ?? _defaultFeedbackDelay;

  final FeedbackDelay _delay;

  @override
  Future<void> confirm() async {
    await HapticFeedback.lightImpact();
    await SystemSound.play(SystemSoundType.click);
  }

  @override
  Future<void> warn() async {
    await HapticFeedback.mediumImpact();
    await _delay(const Duration(milliseconds: 120));
    await HapticFeedback.mediumImpact();
    await SystemSound.play(SystemSoundType.alert);
  }
}

final Provider<AccessibleFeedbackService> accessibleFeedbackServiceProvider =
    Provider<AccessibleFeedbackService>(
      (Ref ref) => SystemAccessibleFeedbackService(),
    );

typedef FeedbackDelay = Future<void> Function(Duration duration);

Future<void> _defaultFeedbackDelay(Duration duration) =>
    Future<void>.delayed(duration);
