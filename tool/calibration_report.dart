import 'dart:convert';
import 'dart:io';

import 'package:eyes_mobile/features/calibration/domain/calibration_analysis.dart';

Future<void> main(List<String> arguments) async {
  final options = _parseArguments(arguments);
  final inputFiles = _inputFiles(options.input);
  if (inputFiles.isEmpty) {
    stderr.writeln('Arquivo de entrada não encontrado: ${options.input}');
    exitCode = 2;
    return;
  }

  final events = <Map<String, Object?>>[];
  for (final input in inputFiles) {
    await for (final line
        in input
            .openRead()
            .transform(utf8.decoder)
            .transform(const LineSplitter())) {
      if (line.trim().isEmpty) {
        continue;
      }
      final decoded = jsonDecode(line) as Map<String, Object?>;
      if (decoded['schema_version'] != 1) {
        throw const FormatException('Schema de calibração não suportado.');
      }
      events.add(decoded);
    }
  }

  final analysis = CalibrationAnalysis.fromEvents(events);
  if (analysis.frameCount == 0) {
    throw const FormatException('A coleta não contém frames avaliados.');
  }
  final device = options.deviceMetrics == null
      ? null
      : jsonDecode(File(options.deviceMetrics!).readAsStringSync())
            as Map<String, Object?>;
  final output = File(options.output);
  output.parent.createSync(recursive: true);
  output.writeAsStringSync(_markdown(analysis, device));
  final jsonOutput = File('${output.path}.json');
  jsonOutput.writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert({
      'generatedAt': DateTime.now().toUtc().toIso8601String(),
      'sources': inputFiles.map((item) => item.path).toList(growable: false),
      'analysis': analysis.toJson(),
      'device': ?device,
    }),
  );
  stdout.writeln('Relatório: ${output.path}');
  stdout.writeln('Resumo JSON: ${jsonOutput.path}');
}

String _markdown(CalibrationAnalysis analysis, Map<String, Object?>? device) {
  final json = analysis.toJson();
  final latency = json['latencyMs']! as Map<String, Object?>;
  final buffer = StringBuffer()
    ..writeln('# REN-37 — Relatório de calibração e validação')
    ..writeln()
    ..writeln('Gerado em ${DateTime.now().toUtc().toIso8601String()}.')
    ..writeln()
    ..writeln('## Escopo e interpretação')
    ..writeln()
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
    ..writeln('- Taxa de perigo perdido: ${_rate(analysis.missedHazardRate)}')
    ..writeln('- Taxa de falso alerta: ${_rate(analysis.falseAlertRate)}')
    ..writeln(
      '- Alertas repetidos antes de 6 s: ${analysis.repeatedAlertCount}',
    )
    ..writeln(
      '- Tempo para o primeiro alerta (p50/p95): '
      '${_ms(latency['firstAlertP50'])} / '
      '${_ms(latency['firstAlertP95'])}',
    );
  if (device != null) {
    buffer
      ..writeln()
      ..writeln('## Sessão prolongada e dispositivo')
      ..writeln()
      ..writeln('```json')
      ..writeln(const JsonEncoder.withIndent('  ').convert(device))
      ..writeln('```');
  }
  buffer
    ..writeln()
    ..writeln('## Limitações')
    ..writeln()
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
    stderr.writeln(
      'Uso: dart run tool/calibration_report.dart '
      '--input <coleta.jsonl> --output <relatorio.md> '
      '[--device-metrics <device.json>]',
    );
    exit(64);
  }
  return _Options(
    input: input,
    output: output,
    deviceMetrics: valueAfter('--device-metrics'),
  );
}

final class _Options {
  const _Options({
    required this.input,
    required this.output,
    required this.deviceMetrics,
  });

  final String input;
  final String output;
  final String? deviceMetrics;
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
