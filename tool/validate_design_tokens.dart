import 'dart:io';

final RegExp _literalColor = RegExp(r'\bColor\s*\(\s*0x[0-9a-fA-F]{8}\s*\)');
final RegExp _namedColor = RegExp(r'\bColors\.([A-Za-z0-9_]+)');

const Set<String> _globalNamedColors = <String>{'transparent'};
const Map<String, Set<String>> _cameraSurfaceExceptions =
    <String, Set<String>>{
      'lib/features/scanning/presentation/assistive_scan_page.dart': <String>{
        'black',
        'black54',
        'black87',
      },
      'lib/features/scanning/infrastructure/camera_preview_surface.dart':
          <String>{'black', 'white'},
    };

void main() {
  final failures = <String>[];
  final files = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((File file) => file.path.endsWith('.dart'));

  for (final file in files) {
    final path = file.path.replaceAll('\\', '/');
    if (path.startsWith('lib/core/design_system/tokens/')) continue;

    final source = file.readAsStringSync();
    if (_literalColor.hasMatch(source)) {
      failures.add('$path declara Color(0x...). Use um token do Eyes Design System.');
    }

    final allowed = <String>{
      ..._globalNamedColors,
      ...?_cameraSurfaceExceptions[path],
    };
    for (final match in _namedColor.allMatches(source)) {
      final colorName = match.group(1)!;
      if (!allowed.contains(colorName)) {
        failures.add(
          '$path usa Colors.$colorName fora dos tokens canônicos.',
        );
      }
    }
  }

  if (failures.isNotEmpty) {
    stderr.writeln('Uso inválido de cores no Mobile:');
    for (final failure in failures) {
      stderr.writeln('- $failure');
    }
    exitCode = 1;
    return;
  }

  stdout.writeln(
    'Tokens visuais válidos: cores literais permanecem isoladas no Design System; '
    'preto/branco da câmera estão limitados às superfícies documentadas.',
  );
}
