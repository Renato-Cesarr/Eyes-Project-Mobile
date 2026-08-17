import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract interface class AccessibleFeedbackService {
  Future<void> confirm();
  Future<void> warn();
}

final class SystemAccessibleFeedbackService
    implements AccessibleFeedbackService {
  const SystemAccessibleFeedbackService();

  @override
  Future<void> confirm() async {
    await HapticFeedback.mediumImpact();
    await SystemSound.play(SystemSoundType.click);
  }

  @override
  Future<void> warn() async {
    await HapticFeedback.heavyImpact();
    await SystemSound.play(SystemSoundType.alert);
  }
}

final Provider<AccessibleFeedbackService> accessibleFeedbackServiceProvider =
    Provider<AccessibleFeedbackService>(
      (Ref ref) => const SystemAccessibleFeedbackService(),
    );
