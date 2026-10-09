import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:eyes_mobile/app/config/app_environment.dart';
import 'package:eyes_mobile/core/logging/secure_logger.dart';
import 'package:eyes_mobile/core/network/safe_http_logging_interceptor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';

final class _Adapter implements HttpClientAdapter {
  const _Adapter(this.status);
  final int status;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? stream,
    Future<void>? cancel,
  ) async => ResponseBody.fromString('{}', status);
  @override
  void close({bool force = false}) {}
}

void main() {
  for (final status in [200, 500]) {
    test(
      'metadata request logs redact session identifiers and payload on $status',
      () async {
        final logger = SecureLogger(AppEnvironment.dev())..initialize();
        final records = <LogRecord>[];
        final subscription = Logger.root.onRecord.listen(records.add);
        final dio = Dio()..httpClientAdapter = _Adapter(status);
        dio.interceptors.add(SafeHttpLoggingInterceptor(logger));
        final request = dio.post<void>(
          'https://example.invalid/api/v1/scan-sessions/private-session-id/events',
          data: {'clientEventId': 'private-event-id', 'confidence': 0.9},
          options: Options(
            headers: {'Authorization': 'Bearer private-token'},
            extra: {'redactedPath': '/api/v1/scan-sessions'},
          ),
        );
        if (status == 200) {
          await request;
        } else {
          await expectLater(request, throwsA(isA<DioException>()));
        }
        final messages = records
            .map((record) => record.message.toString())
            .join('\n');
        expect(messages, contains('/api/v1/scan-sessions'));
        expect(messages, isNot(contains('private-')));
        expect(messages, isNot(contains('confidence')));
        await subscription.cancel();
        await logger.dispose();
      },
    );
  }
}
