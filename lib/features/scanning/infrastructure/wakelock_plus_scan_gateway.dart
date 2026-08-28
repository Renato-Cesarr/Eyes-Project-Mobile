import 'package:eyes_mobile/features/scanning/application/scan_wake_lock_gateway.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

final class WakelockPlusScanGateway implements ScanWakeLockGateway {
  const WakelockPlusScanGateway();

  @override
  Future<void> disable() => WakelockPlus.disable();

  @override
  Future<void> enable() => WakelockPlus.enable();
}
