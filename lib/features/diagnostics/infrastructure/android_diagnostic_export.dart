import 'package:eyes_mobile/features/diagnostics/application/diagnostic_ports.dart';
import 'package:flutter/services.dart';

final class AndroidDiagnosticExport implements DiagnosticExport {
  const AndroidDiagnosticExport({MethodChannel? channel})
    : _channel =
          channel ??
          const MethodChannel('br.com.eyesproject.mobile/diagnostics');
  final MethodChannel _channel;
  @override
  Future<void> share(String report) async {
    await _channel.invokeMethod<void>('shareReport', {'report': report});
  }

  @override
  Future<void> clear() async =>
      _channel.invokeMethod<void>('clearSharedReport');
}
