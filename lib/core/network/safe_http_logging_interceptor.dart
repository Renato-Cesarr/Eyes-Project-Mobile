import 'package:dio/dio.dart';
import 'package:eyes_mobile/core/logging/secure_logger.dart';

final class SafeHttpLoggingInterceptor extends Interceptor {
  SafeHttpLoggingInterceptor(this._logger);

  final SecureLogger _logger;
  final Map<RequestOptions, Stopwatch> _timers = <RequestOptions, Stopwatch>{};

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _timers[options] = Stopwatch()..start();
    _logger.debug(
      'http-request',
      context: <String, Object?>{
        'method': options.method,
        'path': options.uri.path,
      },
    );
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    final elapsed = _timers.remove(response.requestOptions)?..stop();
    _logger.debug(
      'http-response',
      context: <String, Object?>{
        'durationMs': elapsed?.elapsedMilliseconds,
        'method': response.requestOptions.method,
        'path': response.requestOptions.uri.path,
        'statusCode': response.statusCode,
      },
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final elapsed = _timers.remove(err.requestOptions)?..stop();
    _logger.warning(
      'http-error',
      context: <String, Object?>{
        'durationMs': elapsed?.elapsedMilliseconds,
        'errorType': err.type.name,
        'method': err.requestOptions.method,
        'path': err.requestOptions.uri.path,
        'statusCode': err.response?.statusCode,
      },
    );
    handler.next(err);
  }
}
