import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract interface class DiagnosticStore {
  Future<String?> read();
  Future<void> write(String report);
  Future<void> clear();
}

abstract interface class DiagnosticExport {
  Future<void> share(String report);
  Future<void> clear();
}

final diagnosticStoreProvider = Provider<DiagnosticStore>(
  (ref) => throw StateError('DiagnosticStore must be provided at bootstrap.'),
);
final diagnosticExportProvider = Provider<DiagnosticExport>(
  (ref) => throw StateError('DiagnosticExport must be provided at bootstrap.'),
);
