import 'dart:async';

import 'package:eyes_mobile/features/scanning/application/latest_frame_processor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('keeps only the newest pending frame while processing', () async {
    final firstFrameGate = Completer<void>();
    final processed = <int>[];
    final processor = LatestFrameProcessor<int>(
      minimumInterval: Duration.zero,
      onFrame: (int frame) async {
        processed.add(frame);
        if (frame == 1) {
          await firstFrameGate.future;
        }
      },
    );

    processor.add(1);
    await Future<void>.delayed(Duration.zero);
    processor.add(2);
    processor.add(3);
    firstFrameGate.complete();
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    await processor.close();

    expect(processed, <int>[1, 3]);
    expect(processor.snapshot.received, 3);
    expect(processor.snapshot.processed, 2);
    expect(processor.snapshot.dropped, 1);
  });

  test(
    'close discards the pending frame and waits for in-flight work',
    () async {
      final firstFrameGate = Completer<void>();
      final processed = <int>[];
      final processor = LatestFrameProcessor<int>(
        minimumInterval: Duration.zero,
        onFrame: (int frame) async {
          processed.add(frame);
          await firstFrameGate.future;
        },
      );

      processor.add(1);
      await Future<void>.delayed(Duration.zero);
      processor.add(2);
      final closeFuture = processor.close();
      var closeCompleted = false;
      unawaited(closeFuture.then((_) => closeCompleted = true));
      await Future<void>.delayed(Duration.zero);

      expect(closeCompleted, isFalse);
      firstFrameGate.complete();
      await closeFuture;

      expect(processed, <int>[1]);
      expect(processor.snapshot.dropped, 1);
    },
  );

  test('honors the configured minimum processing interval', () async {
    var now = DateTime.utc(2026);
    final requestedDelays = <Duration>[];
    final processed = <int>[];
    final processor = LatestFrameProcessor<int>(
      minimumInterval: const Duration(milliseconds: 100),
      clock: () => now,
      delay: (Duration duration) async {
        requestedDelays.add(duration);
        now = now.add(duration);
      },
      onFrame: (int frame) async => processed.add(frame),
    );

    processor.add(1);
    await Future<void>.delayed(Duration.zero);
    processor.add(2);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    await processor.close();

    expect(processed, <int>[1, 2]);
    expect(requestedDelays, <Duration>[const Duration(milliseconds: 100)]);
  });
}
