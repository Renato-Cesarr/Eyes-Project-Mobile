import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract interface class ScanWakeLockGateway {
  Future<void> enable();

  Future<void> disable();
}

final Provider<ScanWakeLockGateway> scanWakeLockGatewayProvider =
    Provider<ScanWakeLockGateway>(
      (Ref ref) => throw StateError(
        'ScanWakeLockGateway must be overridden at bootstrap.',
      ),
    );
