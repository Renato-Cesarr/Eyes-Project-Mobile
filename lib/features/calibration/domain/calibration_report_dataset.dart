/// Validates provenance and measurement windows before descriptive analysis.
/// Does not certify a final experiment or change the runtime recorder.
final class CalibrationReportDataset {
  CalibrationReportDataset._(this.events, this.provenance);

  factory CalibrationReportDataset.validate({
    required List<Map<String, Object?>> events,
    required String purpose,
    Map<String, Object?>? manifest,
    String? protocolSha256,
  }) {
    const purposes = {
      'fixture',
      'pilot',
      'calibration',
      'evaluation',
      'negative',
      'stability',
    };
    if (!purposes.contains(purpose)) {
      _fail('Finalidade inválida.');
    }
    if (events.isEmpty) {
      _fail('Coleta vazia.');
    }
    if (manifest == null && purpose != 'fixture' && purpose != 'pilot') {
      _fail('Ensaio físico exige manifesto; legado só admite fixture/pilot.');
    }
    final sessions = <String, List<Map<String, Object?>>>{};
    final signatures = <String, String>{};
    final splits = <String>{};
    final identifiers = RegExp(r'^[a-zA-Z0-9][a-zA-Z0-9._-]{0,79}$');
    for (final event in events) {
      if (!const {
        'session_started',
        'frame_evaluated',
        'alert_queued',
        'speech_started',
      }.contains(event['type'])) {
        _fail('Tipo de evento não suportado.');
      }
      if (event['schema_version'] != 1) {
        _fail('Schema não suportado.');
      }
      final session = _string(event, 'session_id');
      if ((session == 'fixture' || session.startsWith('fixture-')) &&
          purpose != 'fixture') {
        _fail('Fixture identificada não pode alimentar piloto/ensaio físico.');
      }
      if (!identifiers.hasMatch(session)) {
        _fail('session_id inválido.');
      }
      final split = _string(event, 'dataset_split');
      if (split != 'calibration' && split != 'evaluation') {
        _fail('Split inválido.');
      }
      splits.add(split);
      final scenario = _string(event, 'scenario_id');
      if (!identifiers.hasMatch(scenario)) {
        _fail('scenario_id inválido.');
      }
      if (!const {
            'person',
            'chair',
            'table',
            'backpack',
          }.contains(event['expected_kind']) ||
          !const {
            'distant',
            'attention',
            'veryNear',
          }.contains(event['expected_band']) ||
          !const {'bright', 'dim', 'backlit'}.contains(event['lighting']) ||
          !const {'none', 'partial'}.contains(event['occlusion'])) {
        _fail('Cenário contém classe/faixa/luz/oclusão inválida.');
      }
      _time(event, 'emitted_at');
      final signature = [
        'scenario_id',
        'dataset_split',
        'expected_kind',
        'expected_band',
        'lighting',
        'occlusion',
      ].map((key) => event[key]).join('|');
      if (signatures.containsKey(session) && signatures[session] != signature) {
        _fail('Metadados divergentes na sessão $session.');
      }
      signatures[session] = signature;
      sessions.putIfAbsent(session, () => []).add(event);
      if (event['type'] == 'frame_evaluated') {
        if (!const {
          'distant',
          'attention',
          'veryNear',
          'missed',
        }.contains(event['predicted_band'])) {
          _fail('Faixa predita inválida.');
        }
        for (final key in [
          'camera_to_decision_us',
          'preprocessing_us',
          'inference_us',
          'vision_total_us',
        ]) {
          _metric(event, key);
        }
      }
    }
    if (splits.length != 1) {
      _fail('Não misturar calibração e avaliação.');
    }
    if (purpose == 'calibration' && splits.single != 'calibration' ||
        const {'evaluation', 'negative', 'stability'}.contains(purpose) &&
            splits.single != 'evaluation') {
      _fail('Finalidade incompatível com split.');
    }
    if (purpose == 'negative' &&
        events.any((e) => e['expected_band'] != 'distant')) {
      _fail('Controle negativo exige faixa esperada distant.');
    }
    for (final entries in sessions.values) {
      final starts = entries
          .where((e) => e['type'] == 'session_started')
          .toList();
      if (starts.length != 1) {
        _fail('Cada sessão exige exatamente um início.');
      }
      final alerts = <String, Map<String, Object?>>{};
      final paired = <String>{};
      for (final e in entries.where((e) => e['type'] == 'alert_queued')) {
        final id = _string(e, 'correlation_id');
        if (alerts.containsKey(id)) {
          _fail('Alerta correlacionado duplicado.');
        }
        final source = _time(e, 'source_at');
        if (_time(e, 'emitted_at').isBefore(source)) {
          _fail('Alerta anterior ao frame.');
        }
        alerts[id] = e;
      }
      for (final e in entries.where((e) => e['type'] == 'speech_started')) {
        if (e['matched_alert'] != true) continue;
        final id = _string(e, 'correlation_id');
        final alert = alerts[id];
        if (alert == null || !paired.add(id)) {
          _fail('TTS sem par único.');
        }
        final started = _time(e, 'started_at');
        if (started.isBefore(_time(alert, 'emitted_at'))) {
          _fail('TTS anterior à fila.');
        }
        final value = _metric(e, 'camera_to_speech_start_us');
        if (value !=
            started.difference(_time(alert, 'source_at')).inMicroseconds) {
          _fail('Latência TTS não corresponde aos timestamps do par.');
        }
      }
    }
    if (manifest == null) {
      return CalibrationReportDataset._(List.unmodifiable(events), {
        'purpose': purpose,
        'split': splits.single,
        'legacy': true,
        'measurementWindowVerified': false,
        'claim': 'descriptive_only',
      });
    }
    if (manifest['schemaVersion'] != 1 ||
        manifest['protocolId'] != 'eyes-assistive-evaluation-v1' ||
        manifest['protocolSha256'] != protocolSha256 ||
        protocolSha256 == null ||
        manifest['purpose'] != purpose ||
        manifest['split'] != splits.single) {
      _fail('Manifesto incompatível com protocolo/finalidade/split.');
    }
    final identity = _map(manifest['buildIdentity']);
    if (!RegExp(
          r'^[a-f0-9]{40}$',
        ).hasMatch(_string(identity, 'sourceCommit')) ||
        identity['flavor'] != 'dev' ||
        identity['buildMode'] != 'profile' ||
        identity['sourceDirty'] != false ||
        identity['calibrationEnabled'] != true) {
      _fail(
        'Identidade exige commit completo, árvore limpa e Profile/dev opt-in.',
      );
    }
    for (final key in ['apkSha256', 'modelSha256', 'policySha256']) {
      if (!RegExp(r'^[a-f0-9]{64}$').hasMatch(_string(identity, key))) {
        _fail('SHA-256 inválido.');
      }
    }
    final runtime = _map(manifest['runtimeConfiguration']);
    for (final key in ['inferenceThreads', 'targetFps']) {
      if (runtime[key] is! int || (runtime[key]! as int) <= 0) {
        _fail('Configuração $key não congelada.');
      }
    }
    final threshold = runtime['scoreThreshold'];
    if (threshold is! num ||
        !threshold.isFinite ||
        threshold <= 0 ||
        threshold > 1 ||
        runtime['camera'] != 'rear') {
      _fail('Threshold/câmera não congelados.');
    }
    final sources = manifest['sources'];
    if (sources is! List<Object?> || sources.isEmpty) {
      _fail('Fontes ausentes.');
    }
    final seen = <String>{};
    final selected = <Map<String, Object?>>[];
    final windows = <Map<String, Object?>>[];
    for (final raw in sources) {
      final descriptor = _map(raw);
      final id = _string(descriptor, 'sessionId');
      final session = sessions[id];
      if (session == null || !seen.add(id)) {
        _fail('Fonte/sessão ausente ou duplicada.');
      }
      if (session.first['scenario_id'] != descriptor['scenarioId']) {
        _fail('Cenário divergente.');
      }
      final start = _time(descriptor, 'operationalStartUtc');
      final measured = _time(descriptor, 'measurementStartUtc');
      final end = _time(descriptor, 'measurementEndUtc');
      if (measured.difference(start) < const Duration(seconds: 5) ||
          !end.isAfter(measured)) {
        _fail('Janela inválida ou aquecimento menor que 5 s.');
      }
      final minimumWindow = purpose == 'stability' ? 1200 : 20;
      if (end.difference(measured) < Duration(seconds: minimumWindow)) {
        _fail('Janela medida menor que o protocolo.');
      }
      final frames = session
          .where((e) => e['type'] == 'frame_evaluated')
          .toList();
      final warmFrames = frames.where((e) {
        final t = _time(e, 'captured_at');
        if (_time(e, 'observed_at').isBefore(t)) {
          _fail('Decisão anterior ao frame.');
        }
        return !t.isBefore(start) && t.isBefore(measured);
      }).length;
      if (warmFrames < 30) {
        _fail('Aquecimento exige 30 frames reais.');
      }
      final windowFrames = frames
          .where((e) => _inside(_time(e, 'captured_at'), measured, end))
          .toList();
      if (windowFrames.isEmpty) {
        _fail('Janela sem frames medidos.');
      }
      final sessionAlerts = session
          .where((e) => e['type'] == 'alert_queued')
          .where((e) => _inside(_time(e, 'source_at'), measured, end))
          .toList();
      final alertIds = sessionAlerts.map((e) => e['correlation_id']).toSet();
      selected.addAll([
        ...windowFrames,
        ...sessionAlerts,
        ...session.where(
          (e) =>
              e['type'] == 'speech_started' &&
              alertIds.contains(e['correlation_id']) &&
              !_time(e, 'started_at').isBefore(measured) &&
              _time(e, 'started_at').isBefore(end),
        ),
      ]);
      windows.add({
        'sessionId': id,
        'warmupFrames': warmFrames,
        'measurementStartUtc': measured.toIso8601String(),
        'measurementEndUtc': end.toIso8601String(),
        'measuredFrames': windowFrames.length,
      });
    }
    if (seen.length != sessions.length) {
      _fail('Eventos sem fonte no manifesto.');
    }
    return CalibrationReportDataset._(List.unmodifiable(selected), {
      'purpose': purpose,
      'split': splits.single,
      'legacy': false,
      'protocolId': manifest['protocolId'],
      'protocolSha256': protocolSha256,
      'buildIdentity': identity,
      'runtimeConfiguration': manifest['runtimeConfiguration'],
      'windows': windows,
      'measurementWindowVerified': true,
      'claim': 'descriptive_only',
    });
  }

  final List<Map<String, Object?>> events;
  final Map<String, Object?> provenance;
}

Never _fail(String message) => throw FormatException(message);
Map<String, Object?> _map(Object? raw) {
  if (raw is! Map<String, Object?>) {
    _fail('Objeto obrigatório ausente.');
  }
  return raw;
}

String _string(Map<String, Object?> source, String key) {
  final raw = source[key];
  if (raw is! String || raw.isEmpty) {
    _fail('Campo $key ausente.');
  }
  return raw;
}

DateTime _time(Map<String, Object?> source, String key) {
  final raw = _string(source, key);
  if (!RegExp(r'(Z|[+-]\d\d:\d\d)$').hasMatch(raw)) {
    _fail('Timestamp $key sem fuso.');
  }
  return DateTime.parse(raw).toUtc();
}

int _metric(Map<String, Object?> source, String key) {
  final raw = source[key];
  if (raw is! int || raw < 0) {
    _fail('Métrica $key inválida.');
  }
  return raw;
}

bool _inside(DateTime value, DateTime start, DateTime end) =>
    !value.isBefore(start) && value.isBefore(end);
