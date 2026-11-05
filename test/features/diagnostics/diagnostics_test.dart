import 'dart:convert';

import 'package:eyes_mobile/features/assistive_feedback/domain/assistive_alert_message.dart';
import 'package:eyes_mobile/features/diagnostics/application/diagnostic_ports.dart';
import 'package:eyes_mobile/features/diagnostics/application/diagnostic_recorder.dart';
import 'package:eyes_mobile/features/diagnostics/application/diagnostics_controller.dart';
import 'package:eyes_mobile/features/diagnostics/infrastructure/android_diagnostic_export.dart';
import 'package:eyes_mobile/features/diagnostics/infrastructure/local_diagnostic_store.dart';
import 'package:eyes_mobile/features/object_detection/domain/detected_object.dart';
import 'package:eyes_mobile/features/proximity/domain/proximity_models.dart';
import 'package:eyes_mobile/features/scanning/application/camera_gateway.dart';
import 'package:eyes_mobile/features/scanning/domain/camera_scan_status.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final time = DateTime.utc(2026, 11, 5, 12);
DetectionBatch frame({int inference = 30}) => DetectionBatch(
  detections: [
    DetectedObject(
      kind: DetectedObjectKind.chair,
      confidence: .8,
      boundingBox: NormalizedBoundingBox(
        top: .1,
        left: .1,
        bottom: .8,
        right: .8,
      ),
    ),
  ],
  capturedAt: time,
  timings: DetectionTimings(
    preprocessing: const Duration(milliseconds: 10),
    inference: Duration(milliseconds: inference),
    postprocessing: const Duration(milliseconds: 1),
  ),
);
const message = AssistiveAlertMessage(
  text: 'secret-private-message',
  deduplicationKey: 'chair',
  priority: 1,
  isCritical: false,
);
ProximityAlertEvent alert() => ProximityAlertEvent(
  trackId: 1,
  kind: DetectedObjectKind.chair,
  band: ProximityBand.attention,
  direction: ProximityDirection.right,
  score: .7,
  priority: 1,
  occurredAt: time,
);
Map<String, Object?> object(Object? value) =>
    Map<String, Object?>.from(value! as Map);
Map<String, Object?> report(DiagnosticRecorder recorder) =>
    object(jsonDecode(recorder.report()));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('inert until explicit start; end and erase remove pending speech', () {
    final recorder = DiagnosticRecorder(clock: () => time);
    recorder.recordFrame(frame());
    recorder.recordProblem();
    recorder.recordStatus(CameraScanStatus.streaming);
    recorder.onAlertQueued(alert(), message);
    recorder.recordSpeechStarted(message.text, time);
    expect(report(recorder)['frames_processed'], 0);
    expect(report(recorder)['events'], isEmpty);
    recorder.start();
    recorder.recordFrame(frame());
    recorder.onAlertQueued(alert(), message);
    recorder.stop();
    recorder.recordFrame(frame());
    recorder.recordSpeechStarted(message.text, time);
    expect(report(recorder)['frames_processed'], 1);
    expect(report(recorder)['matched_speech_starts'], 0);
    recorder.clear();
    expect(report(recorder)['started_at'], isNull);
    expect(report(recorder)['events'], isEmpty);
  });
  test('bounded event and timing history; counts are not object accuracy', () {
    final recorder = DiagnosticRecorder(clock: () => time)..start();
    for (var i = 0; i < 800; i++) {
      recorder.recordFrame(frame(inference: i));
      recorder.onAlertQueued(alert(), message);
    }
    recorder.recordProblem();
    recorder.recordStatus(CameraScanStatus.streaming);
    final data = report(recorder);
    expect(data['events'], hasLength(100));
    expect(data['older_events_omitted'], 703);
    expect(data['frames_processed'], 800);
    expect(data['frames_containing_class'], {'chair': 800});
    final stats = object(
      object(data['timings_last_up_to_512_samples'])['inference'],
    );
    expect(stats['samples'], 512);
    expect(stats['mean_ms'], 543.5);
    expect(stats['p50_ms'], 543);
    expect(stats['p95_ms'], 774);
    expect(recorder.report(), isNot(contains('secret-private-message')));
    expect(recorder.report(), isNot(contains('boundingBox')));
    expect(data['application_problems'], 1);
  });
  test(
    'matched callback timing excludes unrelated speech and negative samples',
    () {
      final recorder = DiagnosticRecorder(clock: () => time)..start();
      recorder.recordSpeechStarted('unknown', time);
      recorder.onAlertQueued(alert(), message);
      recorder.recordSpeechStarted(
        message.text,
        time.add(const Duration(milliseconds: 90)),
      );
      recorder.onAlertQueued(alert(), message);
      recorder.recordSpeechStarted(
        message.text,
        time.subtract(const Duration(seconds: 1)),
      );
      final data = report(recorder);
      expect(data['matched_speech_starts'], 2);
      expect(
        object(
          data['timings_last_up_to_512_samples'],
        )['source_to_matched_tts_callback'],
        {'samples': 1, 'mean_ms': 90.0, 'p50_ms': 90.0, 'p95_ms': 90.0},
      );
      expect(object(data['privacy'])['automatic_upload'], false);
    },
  );

  const channel = MethodChannel('diagnostic-test');
  final binding =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  tearDown(() => binding.setMockMethodCallHandler(channel, null));
  test(
    'native bridge retains valid report, expires/corrects corrupt records',
    () async {
      String? stored = (DiagnosticRecorder(
        clock: () => time,
      )..start()).report();
      final calls = <String>[];
      binding.setMockMethodCallHandler(channel, (call) async {
        calls.add(call.method);
        if (call.method == 'readReport') return stored;
        if (call.method == 'clearReport') stored = null;
        return null;
      });
      final store = LocalDiagnosticStore(channel: channel, clock: () => time);
      expect(await store.read(), stored);
      stored = 'broken';
      expect(await store.read(), isNull);
      expect(calls.last, 'clearReport');
      stored = (DiagnosticRecorder(
        clock: () => time.subtract(const Duration(days: 8)),
      )..start()).report();
      expect(await store.read(), isNull);
      stored = (DiagnosticRecorder(
        clock: () => time.add(const Duration(days: 1)),
      )..start()).report();
      expect(await store.read(), isNull);
    },
  );
  test(
    'oversize rejected before native IO; writes recover after channel failure',
    () async {
      var fail = true;
      final methods = <String>[];
      binding.setMockMethodCallHandler(channel, (call) async {
        methods.add(call.method);
        if (fail) throw PlatformException(code: 'failed');
        return null;
      });
      final store = LocalDiagnosticStore(channel: channel);
      await expectLater(store.write('x' * 100001), throwsStateError);
      expect(methods, isEmpty);
      await expectLater(store.write('{}'), throwsA(isA<PlatformException>()));
      fail = false;
      await store.write('{}');
      await store.clear();
      expect(methods, ['writeReport', 'writeReport', 'clearReport']);
    },
  );
  test(
    'export only requests Android chooser, without reporting delivery',
    () async {
      final methods = <String>[];
      binding.setMockMethodCallHandler(channel, (call) async {
        methods.add(call.method);
        return null;
      });
      final exporter = AndroidDiagnosticExport(channel: channel);
      await exporter.share('{}');
      await exporter.clear();
      expect(methods, ['shareReport', 'clearSharedReport']);
    },
  );

  ProviderContainer container(
    MemoryStore store,
    MemoryExport exporter, {
    bool enabled = true,
    DiagnosticRecorder? recorder,
  }) => ProviderContainer(
    overrides: [
      diagnosticsEnabledProvider.overrideWithValue(enabled),
      diagnosticStoreProvider.overrideWithValue(store),
      diagnosticExportProvider.overrideWithValue(exporter),
      diagnosticRecorderProvider.overrideWithValue(
        recorder ?? DiagnosticRecorder(clock: () => time),
      ),
      cameraGatewayProvider.overrideWithValue(IdleCamera()),
    ],
  );
  test('disabled flavor does no disk or export work', () async {
    final store = MemoryStore();
    final exporter = MemoryExport();
    final c = container(store, exporter, enabled: false);
    addTearDown(c.dispose);
    await c.read(diagnosticsControllerProvider.future);
    await c.read(diagnosticsControllerProvider.notifier).start();
    expect(store.reads, 0);
    expect(store.value, isNull);
    expect(c.read(diagnosticRecorderProvider).active, false);
  });
  test(
    'explicit start/stop/share/delete and restart without automatic collection',
    () async {
      final store = MemoryStore();
      final exporter = MemoryExport();
      final c = container(store, exporter);
      addTearDown(c.dispose);
      await c.read(diagnosticsControllerProvider.future);
      final controller = c.read(diagnosticsControllerProvider.notifier);
      await controller.share();
      expect(exporter.shared, isNull);
      await controller.start();
      await controller.share();
      expect(exporter.shared, isNull);
      expect(c.read(diagnosticsControllerProvider).requireValue.active, true);
      c.read(diagnosticRecorderProvider).recordFrame(frame());
      await controller.stop();
      await controller.share();
      expect(object(jsonDecode(exporter.shared!))['frames_processed'], 1);
      final restarted = container(store, exporter);
      addTearDown(restarted.dispose);
      expect(
        (await restarted.read(diagnosticsControllerProvider.future)).hasReport,
        true,
      );
      expect(restarted.read(diagnosticRecorderProvider).active, false);
      await controller.clear();
      expect(store.value, isNull);
      expect(
        c.read(diagnosticsControllerProvider).requireValue.hasReport,
        false,
      );
    },
  );
  test(
    'interrupted checkpoint can be shared, without inventing a clean stop',
    () async {
      final store = MemoryStore()
        ..value = (DiagnosticRecorder(clock: () => time)..start()).report();
      final exporter = MemoryExport();
      final c = container(store, exporter);
      addTearDown(c.dispose);
      await c.read(diagnosticsControllerProvider.future);
      await c.read(diagnosticsControllerProvider.notifier).share();
      expect(
        object(jsonDecode(exporter.shared!))['status'],
        'interrupted_after_last_checkpoint',
      );
      expect(object(jsonDecode(exporter.shared!))['ended_at'], null);
    },
  );
  test(
    'storage and export failures remain recoverable and sanitized',
    () async {
      final store = MemoryStore()..fail = true;
      final exporter = MemoryExport();
      final c = container(store, exporter);
      addTearDown(c.dispose);
      expect((await c.read(diagnosticsControllerProvider.future)).failed, true);
      final controller = c.read(diagnosticsControllerProvider.notifier);
      await controller.start();
      expect(c.read(diagnosticRecorderProvider).active, false);
      store.fail = false;
      await controller.start();
      await controller.stop();
      exporter.fail = true;
      await controller.share();
      expect(c.read(diagnosticsControllerProvider).requireValue.failed, true);
      expect(
        c.read(diagnosticsControllerProvider).requireValue.hasReport,
        true,
      );
      exporter.fail = false;
      await controller.clear();
      expect(c.read(diagnosticsControllerProvider).requireValue.failed, false);
    },
  );
  testWidgets(
    'periodic checkpoint is recovered after interruption; write failure stops collection',
    (tester) async {
      final store = MemoryStore();
      final exporter = MemoryExport();
      final c = container(store, exporter);
      addTearDown(c.dispose);
      await c.read(diagnosticsControllerProvider.future);
      await c.read(diagnosticsControllerProvider.notifier).start();
      c.read(diagnosticRecorderProvider).recordFrame(frame());
      await tester.pump(const Duration(seconds: 5));
      await tester.pump();
      expect(object(jsonDecode(store.value!))['frames_processed'], 1);
      store.fail = true;
      await tester.pump(const Duration(seconds: 5));
      await tester.pump();
      expect(c.read(diagnosticRecorderProvider).active, false);
      expect(c.read(diagnosticsControllerProvider).requireValue.failed, true);
    },
  );
}

final class MemoryStore implements DiagnosticStore {
  String? value;
  bool fail = false;
  int reads = 0;
  @override
  Future<String?> read() async {
    reads++;
    if (fail) throw StateError('private');
    return value;
  }

  @override
  Future<void> write(String report) async {
    if (fail) throw StateError('private');
    value = report;
  }

  @override
  Future<void> clear() async {
    if (fail) throw StateError('private');
    value = null;
  }
}

final class MemoryExport implements DiagnosticExport {
  String? shared;
  bool fail = false;
  @override
  Future<void> share(String report) async {
    if (fail) throw StateError('private');
    shared = report;
  }

  @override
  Future<void> clear() async {
    shared = null;
  }
}

final class IdleCamera implements CameraGateway {
  @override
  Future<void> release() async {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
