import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:eyes_mobile/app/config/app_environment.dart';
import 'package:eyes_mobile/core/logging/secure_logger.dart';
import 'package:eyes_mobile/core/network/dio_provider.dart';
import 'package:eyes_mobile/core/network/safe_http_logging_interceptor.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final class _StaticAdapter implements HttpClientAdapter {
  _StaticAdapter(this.statusCode);

  final int statusCode;
  var closed = false;

  @override
  void close({bool force = false}) => closed = true;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      '{"ok":true}',
      statusCode,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>['application/json'],
      },
    );
  }
}

void main() {
  test('Dio provider applies safe defaults and logging interceptor', () {
    final environment = AppEnvironment.dev();
    final logger = SecureLogger(environment);
    final container = ProviderContainer(
      overrides: [
        appEnvironmentProvider.overrideWithValue(environment),
        secureLoggerProvider.overrideWithValue(logger),
      ],
    );

    final dio = container.read(dioProvider);

    expect(dio.options.baseUrl, environment.apiBaseUrl.toString());
    expect(dio.options.connectTimeout, const Duration(seconds: 10));
    expect(dio.options.receiveTimeout, const Duration(seconds: 15));
    expect(dio.options.sendTimeout, const Duration(seconds: 10));
    expect(dio.options.headers[Headers.acceptHeader], 'application/json');
    expect(
      dio.interceptors.whereType<SafeHttpLoggingInterceptor>(),
      hasLength(1),
    );

    container.dispose();
  });

  test('safe interceptor handles successful and failed requests', () async {
    final logger = SecureLogger(AppEnvironment.dev())..initialize();
    final successAdapter = _StaticAdapter(200);
    final successDio = Dio()..httpClientAdapter = successAdapter;
    successDio.interceptors.add(SafeHttpLoggingInterceptor(logger));

    final response = await successDio.get<Map<String, dynamic>>(
      'https://example.invalid/objects?token=secret',
    );

    expect(response.statusCode, 200);
    expect(response.data, <String, dynamic>{'ok': true});
    successDio.close(force: true);
    expect(successAdapter.closed, isTrue);

    final errorAdapter = _StaticAdapter(500);
    final errorDio = Dio()..httpClientAdapter = errorAdapter;
    errorDio.interceptors.add(SafeHttpLoggingInterceptor(logger));

    await expectLater(
      errorDio.get<void>('https://example.invalid/failure'),
      throwsA(isA<DioException>()),
    );
    errorDio.close(force: true);
    expect(errorAdapter.closed, isTrue);

    await logger.dispose();
  });
}
