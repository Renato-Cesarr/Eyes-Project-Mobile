import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:eyes_mobile/features/calibration/domain/calibration_analysis.dart';
import 'package:eyes_mobile/features/calibration/domain/calibration_report_dataset.dart';

Future<void> main(List<String> arguments) async {
  try {
    await generateCalibrationReport(arguments);
  } on FormatException catch (error) {
    stderr.writeln('Relatório rejeitado: ${error.message}');
    exitCode = 65;
  } on FileSystemException catch (error) {
    stderr.writeln('Falha de arquivo: ${error.message}');
    exitCode = 66;
  }
}

/// Validates all input before writing output; callable by integration tests.
Future<void> generateCalibrationReport(List<String> arguments) async {
  final options = _parseArguments(arguments);
  final inputFiles = _inputFiles(options.input);
  if (inputFiles.isEmpty) {
    throw const FormatException('Nenhum JSONL encontrado.');
  }

  if ((options.manifest == null) == (options.legacyPurpose == null)) {
    throw const FormatException(
      'Usar --manifest ou --legacy-purpose fixture|pilot.',
    );
  }
  if (options.legacyPurpose != null &&
      (inputFiles.length != 1 ||
          FileSystemEntity.typeSync(options.input) !=
              FileSystemEntityType.file)) {
    throw const FormatException(
      'Legado exige arquivo exato; não agregar pasta.',
    );
  }
  final manifest = options.manifest == null
      ? null
      : _readObject(File(options.manifest!));
  final purpose = manifest == null
      ? options.legacyPurpose
      : manifest['purpose'];
  if (purpose is! String) throw const FormatException('Finalidade ausente.');
  final protocolText = File(
    'config/assistive-evaluation.v1.json',
  ).readAsStringSync().replaceAll('\r\n', '\n');
  final protocol = jsonDecode(protocolText) as Map<String, Object?>;
  if (protocol['protocol_id'] != 'eyes-assistive-evaluation-v1') {
    throw const FormatException('Protocolo incompatível.');
  }
  final protocolHash = sha256.convert(utf8.encode(protocolText)).toString();
  if (protocolHash !=
      File('config/assistive-evaluation.v1.sha256').readAsStringSync().trim()) {
    throw const FormatException('Digest do protocolo mobile divergente.');
  }
  final descriptors = <String, Map<String, Object?>>{};
  if (manifest != null) {
    final raw = manifest['sources'];
    if (raw is! List<Object?>) throw const FormatException('Fontes ausentes.');
    for (final item in raw) {
      if (item is! Map<String, Object?> || item['file'] is! String) {
        throw const FormatException('Descrição de fonte inválida.');
      }
      final name = item['file']! as String;
      if (name.contains('/') ||
          name.contains('\\') ||
          descriptors.containsKey(name)) {
        throw const FormatException('Arquivo deve ser basename único.');
      }
      descriptors[name] = item;
    }
    if (descriptors.length != inputFiles.length) {
      throw const FormatException(
        'Manifesto não cobre os arquivos selecionados.',
      );
    }
  }
  final receipts = <Map<String, Object?>>[];
  final events = <Map<String, Object?>>[];
  for (final input in inputFiles) {
    final bytes = input.readAsBytesSync();
    final digest = sha256.convert(bytes).toString();
    final name = input.uri.pathSegments.last;
    final descriptor = descriptors[name];
    if (manifest != null &&
        (descriptor == null || descriptor['sha256'] != digest)) {
      throw const FormatException(
        'Fonte sem identidade ou SHA-256 divergente.',
      );
    }
    if (manifest != null && descriptor != null) {
      final metadataName = descriptor['metadataFile'];
      if (metadataName is! String ||
          metadataName.isEmpty ||
          metadataName.contains('/') ||
          metadataName.contains('\\')) {
        throw const FormatException('Metadados físicos exigem basename.');
      }
      final metadataFile = File.fromUri(input.parent.uri.resolve(metadataName));
      if (sha256.convert(metadataFile.readAsBytesSync()).toString() !=
          descriptor['metadataSha256']) {
        throw const FormatException('SHA-256 dos metadados divergente.');
      }
      final metadata = _readObject(metadataFile);
      final identity = metadata['buildIdentity'];
      final frozen = manifest['buildIdentity'];
      if (identity is! Map<String, Object?> ||
          frozen is! Map<String, Object?> ||
          metadata['sessionId'] != descriptor['sessionId'] ||
          metadata['scenarioId'] != descriptor['scenarioId']) {
        throw const FormatException(
          'Metadados sem identidade ou sessão correspondente.',
        );
      }
      for (final key in [
        'sourceCommit',
        'sourceDirty',
        'flavor',
        'buildMode',
        'calibrationEnabled',
        'apkSha256',
        'modelSha256',
        'policySha256',
      ]) {
        if (identity[key] != frozen[key]) {
          throw const FormatException('Não misturar versões/builds de coleta.');
        }
      }
    }
    final text = utf8.decode(bytes).replaceFirst(RegExp(r'^\uFEFF'), '');
    var sourceCount = 0;
    for (final line in const LineSplitter().convert(text)) {
      if (line.trim().isEmpty) {
        continue;
      }
      final decoded = jsonDecode(line);
      if (decoded is! Map<String, Object?>) {
        throw const FormatException('Linha JSONL inválida.');
      }
      if (descriptor != null &&
          decoded['session_id'] != descriptor['sessionId']) {
        throw const FormatException(
          'Sessão não pertence ao arquivo declarado.',
        );
      }
      events.add(decoded);
      sourceCount++;
    }
    if (sourceCount == 0) throw const FormatException('Fonte JSONL vazia.');
    receipts.add({'file': name, 'sha256': digest, 'bytes': bytes.length});
  }

  final dataset = CalibrationReportDataset.validate(
    events: events,
    purpose: purpose,
    manifest: manifest,
    protocolSha256: protocolHash,
  );
  final analysis = CalibrationAnalysis.fromEvents(dataset.events);
  if (analysis.frameCount == 0) {
    throw const FormatException('A coleta não contém frames avaliados.');
  }
  final device = options.deviceMetrics == null
      ? null
      : _readObject(File(options.deviceMetrics!));
  if (device != null &&
      (inputFiles.length != 1 ||
          device['sessionId'] != events.first['session_id'])) {
    throw const FormatException('Métricas de aparelho não pertencem à sessão.');
  }
  final groups = <String, List<Map<String, Object?>>>{};
  for (final event in dataset.events) {
    final key = [
      'expected_kind',
      'expected_band',
      'lighting',
      'occlusion',
    ].map((field) => event[field]).join('/');
    groups.putIfAbsent(key, () => []).add(event);
  }
  final output = File(options.output);
  output.parent.createSync(recursive: true);
  output.writeAsStringSync(_markdown(analysis, dataset.provenance));
  final jsonOutput = File('${output.path}.json');
  jsonOutput.writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert({
      'generatedAt': DateTime.now().toUtc().toIso8601String(),
      'analysisSoftware': _analysisSoftwareIdentity(),
      'protocolSha256': protocolHash,
      'sources': receipts,
      'provenance': dataset.provenance,
      'analysis': analysis.toJson(),
      'groups': {
        for (final entry in groups.entries)
          entry.key: CalibrationAnalysis.fromEvents(entry.value).toJson(),
      },
      'claim': 'descriptive_only',
      'device': ?device,
    }),
  );
  stdout.writeln('Relatório: ${output.path}');
  stdout.writeln('Resumo JSON: ${jsonOutput.path}');
}

String _markdown(
  CalibrationAnalysis analysis,
  Map<String, Object?> provenance,
) {
  final json = analysis.toJson();
  final latency = json['latencyMs']! as Map<String, Object?>;
  final buffer = StringBuffer()
    ..writeln('# REN-37 — Relatório descritivo')
    ..writeln()
    ..writeln('Gerado em ${DateTime.now().toUtc().toIso8601String()}.')
    ..writeln()
    ..writeln('## Escopo e interpretação')
    ..writeln()
    ..writeln(
      'Finalidade: ${provenance['purpose']}; split: ${provenance['split']}.',
    )
    ..writeln(
      'Janela/aquecimento verificados: ${provenance['measurementWindowVerified']}.',
    )
    ..writeln(
      'Este relatório não constitui aceite final; recibos SHA-256, proveniência e grupos por condição estão no JSON.',
    )
    ..writeln(
      'As faixas são relativas e categóricas. Este ensaio não estima nem '
      'anuncia metros ou centímetros.',
    )
    ..writeln()
    ..writeln('## Amostra')
    ..writeln()
    ..writeln('- Frames avaliados: ${analysis.frameCount}')
    ..writeln('- Alertas emitidos: ${analysis.alertCount}')
    ..writeln(
      '- Inícios de TTS correlacionados: ${analysis.matchedSpeechCount}',
    )
    ..writeln()
    ..writeln('## Matriz de confusão das faixas')
    ..writeln()
    ..writeln(
      '| Esperado \\ Predito | distante | atenção | muito próximo | perdido |',
    )
    ..writeln('| --- | ---: | ---: | ---: | ---: |');
  for (final expected in const ['distant', 'attention', 'veryNear']) {
    final row = analysis.confusionMatrix[expected] ?? const <String, int>{};
    buffer.writeln(
      '| ${_bandLabel(expected)} | ${row['distant'] ?? 0} | '
      '${row['attention'] ?? 0} | ${row['veryNear'] ?? 0} | '
      '${row['missed'] ?? 0} |',
    );
  }
  buffer
    ..writeln()
    ..writeln('## Latência')
    ..writeln()
    ..writeln('| Métrica | p50 | p95/meta |')
    ..writeln('| --- | ---: | ---: |')
    ..writeln(
      '| Câmera → decisão | ${_ms(latency['cameraToDecisionP50'])} | '
      '${_ms(latency['cameraToDecisionP95'])} |',
    )
    ..writeln(
      '| Câmera → início do TTS | '
      '${_ms(latency['cameraToSpeechStartP50'])} | '
      '${_ms(latency['cameraToSpeechStartP95'])} / meta ≤ 300 ms |',
    )
    ..writeln('| Pipeline de visão | ${_ms(latency['visionTotalP50'])} | — |')
    ..writeln('| Pré-processamento | ${_ms(latency['preprocessingP50'])} | — |')
    ..writeln('| Inferência | ${_ms(latency['inferenceP50'])} | — |')
    ..writeln()
    ..writeln('## Qualidade dos alertas')
    ..writeln()
    ..writeln(
      '- Perigo perdido por frame: ${analysis.missedHazardFrameCount}/${analysis.hazardFrameCount} = ${_rate(analysis.missedHazardRate)}',
    )
    ..writeln(
      '- Falso alerta por frame distante: ${analysis.falseAlertFrameCount}/${analysis.distantFrameCount} = ${_rate(analysis.falseAlertRate)}',
    )
    ..writeln(
      '- Alertas repetidos antes de 6 s: ${analysis.repeatedAlertCount}',
    )
    ..writeln(
      '- Primeiro frame medido → primeiro alerta (p50/p95): '
      '${_ms(latency['firstAlertP50'])} / '
      '${_ms(latency['firstAlertP95'])}',
    );
  final stats = json['latencyStatistics']! as Map<String, Object?>;
  buffer
    ..writeln()
    ..writeln('## Marcos e amostras válidas')
    ..writeln()
    ..writeln('| Métrica | n | p50 | p95 |')
    ..writeln('| --- | ---: | ---: | ---: |');
  for (final entry in stats.entries) {
    final metric = entry.value! as Map<String, Object?>;
    buffer.writeln(
      '| ${entry.key} | ${metric['n']} | ${_ms(metric['p50Ms'])} | ${_ms(metric['p95Ms'])} |',
    );
  }
  buffer
    ..writeln()
    ..writeln('## Limitações')
    ..writeln()
    ..writeln(
      '- Sem nova coleta física. Fixture é sintética; piloto não comprova avaliação final.',
    )
    ..writeln(
      '- Gates preservados: inferência p95 ≤250 ms; frame→fila p95 ≤500 ms; frame→TTS p95 ≤300 ms. São marcos distintos.',
    )
    ..writeln(
      '- Percentil: interpolação linear, rank=(n−1)×p/100; inferência exige pelo menos 300 amostras por configuração após aquecimento.',
    )
    ..writeln(
      '- TTS: plano de engenharia proposto de 100 pares válidos por configuração, a congelar antes da coleta final; não é garantia estatística de segurança.',
    )
    ..writeln(
      '- Estágios usam Stopwatch; deltas UTC não comprovam relógio monotônico ponta a ponta.',
    )
    ..writeln(
      '- Taxas por frame não equivalem a eventos anotados, mAP ou alertas falsos/minuto.',
    )
    ..writeln(
      '- Primeiro frame e abertura da sessão são origens distintas; ausência do marco permanece indisponível.',
    )
    ..writeln(
      '- Estabilidade exige 20 minutos; consumo de bateria exige ausência de carregamento documentada.',
    )
    ..writeln(
      '- Legado não verifica janela, aquecimento ou identidade do build.',
    )
    ..writeln(
      '- Caixas monoculares são uma aproximação e variam com pose, oclusão '
      'e enquadramento.',
    )
    ..writeln(
      '- Resultados só podem ser generalizados às classes, iluminação e '
      'aparelho efetivamente ensaiados.',
    )
    ..writeln(
      '- O conjunto de avaliação deve permanecer separado do conjunto usado '
      'para ajustar os parâmetros.',
    );
  return buffer.toString();
}

String _bandLabel(String value) => switch (value) {
  'distant' => 'distante',
  'attention' => 'atenção',
  'veryNear' => 'muito próximo',
  _ => value,
};

String _ms(Object? value) =>
    value is num ? '${value.toStringAsFixed(2)} ms' : 'indisponível';

String _rate(double? value) =>
    value == null ? 'indisponível' : '${(value * 100).toStringAsFixed(2)}%';

_Options _parseArguments(List<String> arguments) {
  const allowed = {
    '--input',
    '--output',
    '--device-metrics',
    '--manifest',
    '--legacy-purpose',
  };
  final seen = <String>{};
  for (var i = 0; i < arguments.length; i += 2) {
    if (!allowed.contains(arguments[i]) ||
        !seen.add(arguments[i]) ||
        i + 1 >= arguments.length ||
        arguments[i + 1].startsWith('--')) {
      throw const FormatException(
        'Argumentos desconhecidos, repetidos ou sem valor.',
      );
    }
  }
  String? valueAfter(String option) {
    final index = arguments.indexOf(option);
    if (index < 0 || index + 1 >= arguments.length) {
      return null;
    }
    return arguments[index + 1];
  }

  final input = valueAfter('--input');
  final output = valueAfter('--output');
  if (input == null || output == null) {
    throw const FormatException(
      'Uso: --input <jsonl|pasta> --output <md> '
      '--manifest <json> OU --legacy-purpose fixture|pilot; [--device-metrics <json>]',
    );
  }
  return _Options(
    input: input,
    output: output,
    deviceMetrics: valueAfter('--device-metrics'),
    manifest: valueAfter('--manifest'),
    legacyPurpose: valueAfter('--legacy-purpose'),
  );
}

final class _Options {
  const _Options({
    required this.input,
    required this.output,
    required this.deviceMetrics,
    required this.manifest,
    required this.legacyPurpose,
  });

  final String input;
  final String output;
  final String? deviceMetrics;
  final String? manifest;
  final String? legacyPurpose;
}

Map<String, Object?> _readObject(File file) {
  final raw = jsonDecode(
    file.readAsStringSync().replaceFirst(RegExp(r'^\uFEFF'), ''),
  );
  if (raw is! Map<String, Object?>) {
    throw const FormatException('Objeto JSON obrigatório.');
  }
  return raw;
}

Map<String, Object?> _analysisSoftwareIdentity() {
  String? commit;
  bool? dirty;
  try {
    final revision = Process.runSync('git', ['rev-parse', 'HEAD']);
    final status = Process.runSync('git', ['status', '--porcelain']);
    if (revision.exitCode == 0 && status.exitCode == 0) {
      commit = (revision.stdout as String).trim();
      dirty = (status.stdout as String).trim().isNotEmpty;
    }
  } on ProcessException {
    // Unknown provenance remains explicit when the CLI is used outside Git.
  }
  return {
    'sourceCommit': commit,
    'sourceDirty': dirty,
    'hashEncoding': 'UTF-8 LF',
    'sourceSha256': {
      for (final path in [
        'tool/calibration_report.dart',
        'lib/features/calibration/domain/calibration_analysis.dart',
        'lib/features/calibration/domain/calibration_report_dataset.dart',
      ])
        path: sha256
            .convert(
              utf8.encode(
                File(path).readAsStringSync().replaceAll('\r\n', '\n'),
              ),
            )
            .toString(),
    },
  };
}

List<File> _inputFiles(String path) {
  final type = FileSystemEntity.typeSync(path);
  if (type == FileSystemEntityType.file) {
    return [File(path)];
  }
  if (type != FileSystemEntityType.directory) {
    return const [];
  }
  final files =
      Directory(path)
          .listSync()
          .whereType<File>()
          .where((file) => file.path.toLowerCase().endsWith('.jsonl'))
          .toList(growable: false)
        ..sort((a, b) => a.path.compareTo(b.path));
  return files;
}
