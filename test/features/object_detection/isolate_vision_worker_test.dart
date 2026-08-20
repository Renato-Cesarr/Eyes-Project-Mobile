import 'dart:isolate';
import 'dart:typed_data';

import 'package:eyes_mobile/features/object_detection/application/vision_frame.dart';
import 'package:eyes_mobile/features/object_detection/application/vision_worker.dart';
import 'package:eyes_mobile/features/object_detection/domain/detected_object.dart';
import 'package:eyes_mobile/features/object_detection/infrastructure/isolate_vision_worker.dart';
import 'package:eyes_mobile/features/object_detection/infrastructure/vision_worker_protocol.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('transfere os planos como recurso binário de uso único', () {
    final frame = _frame();
    final transferable = TransferableVisionFrame.fromFrame(frame);

    final restored = transferable.materialize();

    expect(restored.width, frame.width);
    expect(restored.format, VisionPixelFormat.nv21);
    expect(restored.rotation, VisionRotation.degrees90);
    expect(restored.planes.single.bytes, frame.planes.single.bytes);
    expect(() => transferable.materialize(), throwsA(anything));
  });

  test(
    'mantém um isolate persistente e rejeita inferência concorrente',
    () async {
      final worker = IsolateVisionWorker(
        entrypoint: _successfulWorkerMain,
        startTimeout: const Duration(seconds: 2),
        requestTimeout: const Duration(seconds: 2),
      );
      addTearDown(worker.dispose);

      await worker.start();
      final first = worker.detect(_frame());

      expect(
        () => worker.detect(_frame()),
        throwsA(
          isA<VisionWorkerException>().having(
            (error) => error.reason,
            'reason',
            VisionWorkerFailureReason.busy,
          ),
        ),
      );
      final result = await first;

      expect(result.capturedAt, DateTime.utc(2026, 8, 20));
      expect(result.detections.single.kind, DetectedObjectKind.person);
      expect(worker.snapshot.phase, VisionWorkerPhase.ready);
    },
  );

  test('dispose aguarda confirmação e permite um runtime novo', () async {
    final worker = IsolateVisionWorker(
      entrypoint: _successfulWorkerMain,
      startTimeout: const Duration(seconds: 2),
      disposeTimeout: const Duration(seconds: 2),
    );
    addTearDown(worker.dispose);

    await worker.start();
    await worker.dispose();
    expect(worker.snapshot.phase, VisionWorkerPhase.idle);

    await worker.start();
    expect(worker.snapshot.phase, VisionWorkerPhase.ready);
    await worker.dispose();
    expect(worker.snapshot.phase, VisionWorkerPhase.idle);
  });

  test(
    'background durante startup cancela e mata o isolate incompleto',
    () async {
      final worker = IsolateVisionWorker(
        entrypoint: _slowStartupWorkerMain,
        startTimeout: const Duration(seconds: 2),
      );
      addTearDown(worker.dispose);

      final startingExpectation = expectLater(
        worker.start(),
        throwsA(
          isA<VisionWorkerException>().having(
            (error) => error.technicalCode,
            'technicalCode',
            'vision-start-cancelled',
          ),
        ),
      );
      await Future<void>.delayed(Duration.zero);
      await worker.dispose();

      await startingExpectation;
      expect(worker.snapshot.phase, VisionWorkerPhase.idle);
    },
  );

  test(
    'timeout de inferência invalida o runtime em vez de acumular fila',
    () async {
      final worker = IsolateVisionWorker(
        entrypoint: _successfulWorkerMain,
        startTimeout: const Duration(seconds: 2),
        requestTimeout: const Duration(milliseconds: 1),
      );
      addTearDown(worker.dispose);
      await worker.start();

      await expectLater(
        worker.detect(_frame()),
        throwsA(
          isA<VisionWorkerException>().having(
            (error) => error.reason,
            'reason',
            VisionWorkerFailureReason.requestTimeout,
          ),
        ),
      );

      expect(worker.snapshot.phase, VisionWorkerPhase.failed);
    },
  );

  test('propaga falha de inicialização para a thread principal', () async {
    final worker = IsolateVisionWorker(
      entrypoint: _failingWorkerMain,
      startTimeout: const Duration(seconds: 2),
    );
    addTearDown(worker.dispose);

    await expectLater(
      worker.start(),
      throwsA(
        isA<VisionWorkerException>().having(
          (error) => error.reason,
          'reason',
          VisionWorkerFailureReason.initialization,
        ),
      ),
    );
    expect(worker.snapshot.phase, VisionWorkerPhase.failed);
  });

  test('queda não tratada do isolate publica estado failed', () async {
    final worker = IsolateVisionWorker(
      entrypoint: _crashingWorkerMain,
      startTimeout: const Duration(seconds: 2),
    );
    addTearDown(worker.dispose);
    await worker.start();

    final failed = await worker.snapshots.firstWhere(
      (snapshot) => snapshot.phase == VisionWorkerPhase.failed,
    );

    expect(failed.failure?.reason, VisionWorkerFailureReason.isolateCrashed);
  });
}

VisionFrame _frame() => VisionFrame(
  width: 2,
  height: 2,
  format: VisionPixelFormat.nv21,
  planes: [
    VisionFramePlane(
      bytes: Uint8List.fromList([16, 16, 16, 16, 128, 128]),
      bytesPerRow: 2,
      bytesPerPixel: 1,
    ),
  ],
  rotation: VisionRotation.degrees90,
  capturedAt: DateTime.utc(2026, 8, 20),
);

@pragma('vm:entry-point')
void _successfulWorkerMain(VisionWorkerBootstrap bootstrap) async {
  final commands = ReceivePort();
  bootstrap.responses.send(VisionWorkerReady(commands.sendPort));
  await for (final Object? message in commands) {
    if (message is VisionDisposeCommand) {
      commands.close();
      bootstrap.responses.send(const VisionWorkerDisposed());
      return;
    }
    if (message is VisionDetectCommand) {
      final frame = message.frame.materialize();
      await Future<void>.delayed(const Duration(milliseconds: 20));
      bootstrap.responses.send(
        VisionDetectionSucceeded(
          requestId: message.requestId,
          result: DetectionBatch(
            detections: [
              DetectedObject(
                kind: DetectedObjectKind.person,
                confidence: 0.9,
                boundingBox: NormalizedBoundingBox(
                  top: 0.1,
                  left: 0.1,
                  bottom: 0.9,
                  right: 0.9,
                ),
              ),
            ],
            capturedAt: frame.capturedAt,
            timings: const DetectionTimings(
              preprocessing: Duration(milliseconds: 1),
              inference: Duration(milliseconds: 10),
              postprocessing: Duration(milliseconds: 1),
            ),
          ),
        ),
      );
    }
  }
}

@pragma('vm:entry-point')
void _failingWorkerMain(VisionWorkerBootstrap bootstrap) async {
  bootstrap.responses.send(
    const VisionStartupFailed(
      technicalCode: 'fake-startup-failure',
      message: 'Falha controlada de inicialização.',
    ),
  );
  await Future<void>.delayed(const Duration(milliseconds: 20));
}

@pragma('vm:entry-point')
void _crashingWorkerMain(VisionWorkerBootstrap bootstrap) async {
  final commands = ReceivePort();
  bootstrap.responses.send(VisionWorkerReady(commands.sendPort));
  await Future<void>.delayed(const Duration(milliseconds: 20));
  commands.close();
  throw StateError('controlled isolate crash');
}

@pragma('vm:entry-point')
void _slowStartupWorkerMain(VisionWorkerBootstrap bootstrap) async {
  final commands = ReceivePort();
  await Future<void>.delayed(const Duration(seconds: 1));
  bootstrap.responses.send(VisionWorkerReady(commands.sendPort));
  await for (final Object? message in commands) {
    if (message is VisionDisposeCommand) {
      commands.close();
      bootstrap.responses.send(const VisionWorkerDisposed());
      return;
    }
  }
}
