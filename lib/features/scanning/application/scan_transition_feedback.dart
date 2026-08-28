import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ScanTransition { started, paused, ended }

abstract interface class ScanTransitionFeedback {
  Future<void> deliver(ScanTransition transition);
}

final Provider<ScanTransitionFeedback> scanTransitionFeedbackProvider =
    Provider<ScanTransitionFeedback>(
      (Ref ref) => throw StateError(
        'ScanTransitionFeedback must be overridden at bootstrap.',
      ),
    );
