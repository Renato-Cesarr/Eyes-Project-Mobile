import 'package:eyes_mobile/features/assistive_feedback/application/assistive_haptics.dart';
import 'package:flutter/services.dart';

final class SystemAssistiveHaptics implements AssistiveHaptics {
  SystemAssistiveHaptics({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(_channelName);

  static const String _channelName =
      'br.com.eyesproject.mobile/assistive_haptics';
  final MethodChannel _channel;

  @override
  Future<bool> isAvailable() async =>
      await _channel.invokeMethod<bool>('isAvailable') ?? false;

  @override
  Future<void> confirm() => _vibrate('confirm');

  @override
  Future<void> warning() => _vibrate('warning');

  @override
  Future<void> criticalAlert() => _vibrate('critical');

  Future<void> _vibrate(String pattern) async {
    final delivered =
        await _channel.invokeMethod<bool>('vibrate', <String, Object>{
          'pattern': pattern,
        }) ??
        false;
    if (!delivered) {
      throw const HapticsUnavailableException();
    }
  }
}

final class HapticsUnavailableException implements Exception {
  const HapticsUnavailableException();

  @override
  String toString() => 'HapticsUnavailableException';
}
