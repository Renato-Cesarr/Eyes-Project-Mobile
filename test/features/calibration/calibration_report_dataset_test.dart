import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:eyes_mobile/features/calibration/domain/calibration_analysis.dart';
import 'package:eyes_mobile/features/calibration/domain/calibration_report_dataset.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../tool/calibration_report.dart' as cli;

void main() {
  test(
    'shared contract preserves digest, gates and inference sample scope',
    () {
      expect(
        _protocolHash(),
        File('config/assistive-evaluation.v1.sha256').readAsStringSync().trim(),
      );
      final contract =
          jsonDecode(
                File('config/assistive-evaluation.v1.json').readAsStringSync(),
              )
              as Map<String, Object?>;
      final latency = contract['latency']! as Map<String, Object?>;
      expect(latency['gates_ms'], {
        'inference_p95': 250,
        'camera_to_queue_p95': 500,
        'camera_to_tts_p95': 300,
      });
      expect(latency['minimum_samples_scope'], 'inference_only');
      expect(latency['measured_values'], isNull);
    },
  );
  final manifestMutations = <String, void Function(Map<String, Object?>)>{
    'dirty build': (m) =>
        (m['buildIdentity']! as Map<String, Object?>)['sourceDirty'] = true,
    'wrong mode': (m) =>
        (m['buildIdentity']! as Map<String, Object?>)['buildMode'] = 'debug',
    'identity absent': (m) => m.remove('buildIdentity'),
    'invalid model digest': (m) =>
        (m['buildIdentity']! as Map<String, Object?>)['modelSha256'] =
            'unknown',
    'runtime absent': (m) => m['runtimeConfiguration'] = {},
    'short measurement': (m) =>
        ((m['sources']! as List<Object?>).single!
            as Map<String, Object?>)['measurementEndUtc'] = _time(
          5100,
        ),
    'short time warmup': (m) =>
        ((m['sources']! as List<Object?>).single!
            as Map<String, Object?>)['measurementStartUtc'] = _time(
          100,
        ),
  };
  for (final entry in manifestMutations.entries) {
    test('rejects manifest ${entry.key}', () {
      final manifest = _manifest();
      entry.value(manifest);
      expect(
        () => _validate(_events(), manifest: manifest),
        throwsFormatException,
      );
    });
  }
  test('measurement excludes warmup and reports first operational frame', () {
    final dataset = _validate(_events(), manifest: _manifest());
    final analysis = CalibrationAnalysis.fromEvents(dataset.events);
    expect(analysis.frameCount, 1);
    expect(analysis.firstAlertLatency, const Duration(milliseconds: 110));
    expect(analysis.sessionToFirstAlertMicroseconds, isEmpty);
    expect(analysis.cameraToQueueMicroseconds, [110000]);
    expect(analysis.queueToSpeechMicroseconds, [170000]);
    expect(analysis.cameraToSpeechStartMicroseconds, [280000]);
    expect(dataset.provenance['claim'], 'descriptive_only');
  });

  for (final purpose in ['fixture', 'pilot']) {
    test('legacy $purpose keeps unknown readiness separate', () {
      final dataset = _validate(_events(), purpose: purpose);
      expect(dataset.provenance['measurementWindowVerified'], isFalse);
      expect(
        CalibrationAnalysis.fromEvents(dataset.events).matchedSpeechCount,
        1,
      );
    });
  }
  test('legacy cannot claim evaluation', () {
    expect(
      () => _validate(_events(), purpose: 'evaluation'),
      throwsFormatException,
    );
  });
  test('identified fixture cannot be reclassified as a physical pilot', () {
    final events = _events();
    for (final e in events) {
      e['session_id'] = 'fixture';
    }
    expect(() => _validate(events), throwsFormatException);
    expect(
      _validate(events, purpose: 'fixture').provenance['purpose'],
      'fixture',
    );
  });
  final mutations = <String, void Function(List<Map<String, Object?>>)>{
    'mixed split': (e) => e.last['dataset_split'] = 'calibration',
    'scenario changed within session': (e) => e.last['scenario_id'] = 'other',
    'wrong schema': (e) => e.last['schema_version'] = 2,
    'unknown event': (e) => e.last['type'] = 'unknown',
    'negative duration': (e) => e[1]['inference_us'] = -1,
    'unknown band': (e) => e[1]['predicted_band'] = 'door',
    'unpaired speech': (e) => e.last['correlation_id'] = 'missing',
    'duplicate speech': (e) => e.add(Map.of(e.last)),
    'inconsistent paired latency': (e) =>
        e.last['camera_to_speech_start_us'] = 10,
    'clock reversal': (e) => e.last['started_at'] = _time(4900),
    'timestamp without zone': (e) => e[0]['emitted_at'] = '2026-10-05T12:00:00',
    'no session origin': (e) => e.removeAt(0),
    'duplicate session origin': (e) => e.add(Map.of(e.first)),
  };
  for (final entry in mutations.entries) {
    test('rejects ${entry.key}', () {
      final events = _events();
      entry.value(events);
      expect(() => _validate(events), throwsFormatException);
    });
  }
  test('manifest cannot certify missing warmup', () {
    expect(
      () => _validate(_events()..removeAt(1), manifest: _manifest()),
      throwsFormatException,
    );
  });
  test('manifest cannot change purpose or protocol', () {
    final manifest = _manifest()..['protocolSha256'] = 'bad';
    expect(
      () => _validate(_events(), manifest: manifest),
      throwsFormatException,
    );
  });
  test('negative controls require expected distant', () {
    expect(
      () => _validate(_events(), purpose: 'negative'),
      throwsFormatException,
    );
  });
  test('missing first frame timestamp does not invent a latency', () {
    final events = _events();
    for (final e in events) {
      e.remove('captured_at');
    }
    final analysis = CalibrationAnalysis.fromEvents(events);
    expect(analysis.firstAlertLatency, isNull);
    expect(analysis.sessionToFirstAlertMicroseconds, [5110000]);
  });

  test(
    'CLI verifies source and metadata hashes; fails before overwriting report',
    () async {
      final directory = Directory.systemTemp.createTempSync('eyes-ren68-');
      addTearDown(() => directory.deleteSync(recursive: true));
      final capture = File('${directory.path}/capture.jsonl')
        ..writeAsStringSync(_events().map(jsonEncode).join('\n'));
      final manifest = _manifest();
      final source =
          (manifest['sources']! as List<Object?>).single!
              as Map<String, Object?>;
      source['file'] = 'capture.jsonl';
      source['sha256'] = sha256.convert(capture.readAsBytesSync()).toString();
      final metadata = File('${directory.path}/capture.device.json')
        ..writeAsStringSync(
          jsonEncode({
            'sessionId': 'session-01',
            'scenarioId': 'chair-attention',
            'buildIdentity': manifest['buildIdentity'],
          }),
        );
      source['metadataFile'] = 'capture.device.json';
      source['metadataSha256'] = sha256
          .convert(metadata.readAsBytesSync())
          .toString();
      final file = File('${directory.path}/manifest.json')
        ..writeAsStringSync(jsonEncode(manifest));
      final output = File('${directory.path}/report.md');
      final args = [
        '--input',
        capture.path,
        '--output',
        output.path,
        '--manifest',
        file.path,
      ];
      await cli.generateCalibrationReport(args);
      final result =
          jsonDecode(File('${output.path}.json').readAsStringSync())
              as Map<String, Object?>;
      expect((result['analysis']! as Map<String, Object?>)['frameCount'], 1);
      final saved = output.readAsStringSync();
      capture.writeAsStringSync('corrupted');
      await expectLater(
        cli.generateCalibrationReport(args),
        throwsFormatException,
      );
      expect(output.readAsStringSync(), saved);
      capture.writeAsStringSync(_events().map(jsonEncode).join('\n'));
      final changedMetadata =
          jsonDecode(metadata.readAsStringSync()) as Map<String, Object?>;
      (changedMetadata['buildIdentity']!
              as Map<String, Object?>)['sourceCommit'] =
          'b' * 40;
      metadata.writeAsStringSync(jsonEncode(changedMetadata));
      source['metadataSha256'] = sha256
          .convert(metadata.readAsBytesSync())
          .toString();
      file.writeAsStringSync(jsonEncode(manifest));
      await expectLater(
        cli.generateCalibrationReport(args),
        throwsFormatException,
      );
      expect(output.readAsStringSync(), saved);
    },
  );
  test('CLI cannot aggregate a legacy folder', () async {
    final directory = Directory.systemTemp.createTempSync('eyes-ren68-folder-');
    addTearDown(() => directory.deleteSync(recursive: true));
    File(
      '${directory.path}/single.jsonl',
    ).writeAsStringSync(_events().map(jsonEncode).join('\n'));
    await expectLater(
      cli.generateCalibrationReport([
        '--input',
        directory.path,
        '--output',
        'unused.md',
        '--legacy-purpose',
        'pilot',
      ]),
      throwsFormatException,
    );
  });
}

CalibrationReportDataset _validate(
  List<Map<String, Object?>> events, {
  String purpose = 'pilot',
  Map<String, Object?>? manifest,
}) => CalibrationReportDataset.validate(
  events: events,
  purpose: manifest == null ? purpose : 'evaluation',
  manifest: manifest,
  protocolSha256: _protocolHash(),
);
String _protocolHash() => sha256
    .convert(
      utf8.encode(
        File(
          'config/assistive-evaluation.v1.json',
        ).readAsStringSync().replaceAll('\r\n', '\n'),
      ),
    )
    .toString();
String _time(int milliseconds) => DateTime.utc(
  2026,
  10,
  5,
  12,
).add(Duration(milliseconds: milliseconds)).toIso8601String();
Map<String, Object?> _event(String type, int at) => {
  'schema_version': 1,
  'type': type,
  'session_id': 'session-01',
  'scenario_id': 'chair-attention',
  'dataset_split': 'evaluation',
  'expected_kind': 'chair',
  'expected_band': 'attention',
  'lighting': 'bright',
  'occlusion': 'none',
  'emitted_at': _time(at),
};
List<Map<String, Object?>> _events() => [
  _event('session_started', 0),
  for (final t in [for (var i = 0; i < 30; i++) i * 100, 5000])
    {
      ..._event('frame_evaluated', t + 110),
      'captured_at': _time(t),
      'observed_at': _time(t + 110),
      'predicted_band': 'attention',
      'camera_to_decision_us': 110000,
      'preprocessing_us': 30000,
      'inference_us': 60000,
      'vision_total_us': 91000,
    },
  {
    ..._event('alert_queued', 5110),
    'source_at': _time(5000),
    'correlation_id': 'alert-1',
    'kind': 'chair',
    'band': 'attention',
    'direction': 'ahead',
  },
  {
    ..._event('speech_started', 5300),
    'started_at': _time(5280),
    'correlation_id': 'alert-1',
    'matched_alert': true,
    'camera_to_speech_start_us': 280000,
  },
];
Map<String, Object?> _manifest() => {
  'schemaVersion': 1,
  'protocolId': 'eyes-assistive-evaluation-v1',
  'protocolSha256': _protocolHash(),
  'purpose': 'evaluation',
  'split': 'evaluation',
  'buildIdentity': {
    'sourceCommit': 'a' * 40,
    'sourceDirty': false,
    'flavor': 'dev',
    'buildMode': 'profile',
    'calibrationEnabled': true,
    'apkSha256': 'a' * 64,
    'modelSha256': 'a' * 64,
    'policySha256': 'a' * 64,
  },
  'runtimeConfiguration': {
    'inferenceThreads': 4,
    'targetFps': 12,
    'scoreThreshold': 0.4,
    'camera': 'rear',
  },
  'sources': [
    {
      'sessionId': 'session-01',
      'scenarioId': 'chair-attention',
      'operationalStartUtc': _time(0),
      'measurementStartUtc': _time(5000),
      'measurementEndUtc': _time(25000),
    },
  ],
};
