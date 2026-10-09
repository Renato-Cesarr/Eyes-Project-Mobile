import 'package:dio/dio.dart';
import 'package:eyes_mobile/core/session/remote_session_store.dart';

final class BearerSessionInterceptor extends Interceptor {
  BearerSessionInterceptor(this._sessionStore);

  final RemoteSessionStore _sessionStore;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.extra['skipAuthentication'] == true) {
      handler.next(options);
      return;
    }
    final session = await _sessionStore.read();
    if (session != null && !options.headers.containsKey('Authorization')) {
      options.headers['Authorization'] = 'Bearer ${session.accessToken}';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401 &&
        err.requestOptions.extra['skipAuthentication'] != true) {
      final current = await _sessionStore.read();
      if (current != null &&
          err.requestOptions.headers['Authorization'] ==
              'Bearer ${current.accessToken}') {
        await _sessionStore.clear(reason: RemoteSessionChangeReason.expired);
      }
    }
    handler.next(err);
  }
}
