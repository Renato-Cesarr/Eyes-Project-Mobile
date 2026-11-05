import 'dart:async';
import 'dart:convert';

import 'package:eyes_mobile/features/diagnostics/application/diagnostic_ports.dart';
import 'package:eyes_mobile/features/diagnostics/application/diagnostic_recorder.dart';
import 'package:eyes_mobile/features/scanning/application/scan_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final diagnosticsControllerProvider =
    AsyncNotifierProvider<DiagnosticsController, DiagnosticViewState>(
      DiagnosticsController.new,
    );

final class DiagnosticViewState {
  const DiagnosticViewState({
    this.active = false,
    this.hasReport = false,
    this.failed = false,
  });
  final bool active;
  final bool hasReport;
  final bool failed;
}

final class DiagnosticsController extends AsyncNotifier<DiagnosticViewState> {
  Timer? _timer;
  String? _saved;
  bool _busy = false;
  DiagnosticRecorder get _recorder => ref.read(diagnosticRecorderProvider);
  DiagnosticStore get _store => ref.read(diagnosticStoreProvider);

  @override
  Future<DiagnosticViewState> build() async {
    if (!ref.watch(diagnosticsEnabledProvider)) {
      return const DiagnosticViewState();
    }
    ref.listen(scanControllerProvider, (previous, next) {
      final status = next.asData?.value.status;
      if (status != null && status != previous?.asData?.value.status) {
        _recorder.recordStatus(status);
      }
    });
    final recorder = _recorder;
    ref.onDispose(() {
      _timer?.cancel();
      recorder.stop();
    });
    try {
      _saved = await _store.read();
      if (_saved != null) {
        final restored = jsonDecode(_saved!) as Map<String, dynamic>;
        if (restored['status'] == 'recording_snapshot') {
          restored['status'] = 'interrupted_after_last_checkpoint';
          _saved = jsonEncode(restored);
        }
      }
      return DiagnosticViewState(hasReport: _saved != null);
    } on Object {
      return const DiagnosticViewState(failed: true);
    }
  }

  Future<void> start() async {
    if (_busy || !ref.read(diagnosticsEnabledProvider) || _recorder.active) {
      return;
    }
    _busy = true;
    try {
      await _store.clear();
      await ref.read(diagnosticExportProvider).clear();
      _saved = null;
      _recorder.start();
      await _save();
      _timer = Timer.periodic(
        const Duration(seconds: 5),
        (_) => unawaited(_checkpoint()),
      );
      state = const AsyncData(DiagnosticViewState(active: true));
    } on Object {
      _recorder.stop();
      state = const AsyncData(DiagnosticViewState(failed: true));
    } finally {
      _busy = false;
    }
  }

  Future<void> _checkpoint() async {
    if (!_recorder.active || _busy) return;
    try {
      await _save();
    } on Object {
      _timer?.cancel();
      _recorder.stop();
      state = AsyncData(
        DiagnosticViewState(hasReport: _saved != null, failed: true),
      );
    }
  }

  Future<void> _save() async {
    final snapshot = _recorder.report();
    await _store.write(snapshot);
    _saved = snapshot;
  }

  Future<void> stop() async {
    if (_busy || !_recorder.active) return;
    _busy = true;
    _timer?.cancel();
    _recorder.stop();
    try {
      await _save();
      state = const AsyncData(DiagnosticViewState(hasReport: true));
    } on Object {
      state = AsyncData(
        DiagnosticViewState(hasReport: _saved != null, failed: true),
      );
    } finally {
      _busy = false;
    }
  }

  Future<void> share() async {
    if (_busy || _recorder.active || _saved == null) return;
    _busy = true;
    try {
      await ref.read(diagnosticExportProvider).share(_saved!);
      state = const AsyncData(DiagnosticViewState(hasReport: true));
    } on Object {
      state = const AsyncData(
        DiagnosticViewState(hasReport: true, failed: true),
      );
    } finally {
      _busy = false;
    }
  }

  Future<void> clear() async {
    if (_busy || _recorder.active) return;
    _busy = true;
    try {
      await _store.clear();
      await ref.read(diagnosticExportProvider).clear();
      _saved = null;
      _recorder.clear();
      state = const AsyncData(DiagnosticViewState());
    } on Object {
      state = AsyncData(
        DiagnosticViewState(hasReport: _saved != null, failed: true),
      );
    } finally {
      _busy = false;
    }
  }
}
