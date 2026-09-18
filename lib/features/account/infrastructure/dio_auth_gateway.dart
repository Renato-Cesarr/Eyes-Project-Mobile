import 'package:dio/dio.dart';
import 'package:eyes_mobile/core/session/remote_session.dart';
import 'package:eyes_mobile/features/account/application/auth_gateway.dart';

final class DioAuthGateway implements AuthGateway {
  const DioAuthGateway(this._dio);

  final Dio _dio;

  @override
  Future<RemoteSession> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post<Object?>(
        '/api/v1/auth/login',
        data: <String, Object?>{'email': email, 'password': password},
        options: Options(extra: <String, Object?>{'skipAuthentication': true}),
      );
      final body = response.data;
      if (body is! Map<String, Object?>) {
        throw const AuthenticationFailure(
          AuthenticationFailureKind.invalidResponse,
        );
      }
      final token = body['token'];
      final user = body['user'];
      if (token is! String ||
          token.trim().isEmpty ||
          user is! Map<String, Object?>) {
        throw const AuthenticationFailure(
          AuthenticationFailureKind.invalidResponse,
        );
      }
      return RemoteSession(accessToken: token, user: RemoteUser.fromJson(user));
    } on AuthenticationFailure {
      rethrow;
    } on DioException catch (error) {
      final statusCode = error.response?.statusCode;
      if (statusCode == 400 || statusCode == 401 || statusCode == 403) {
        throw const AuthenticationFailure(
          AuthenticationFailureKind.invalidCredentials,
        );
      }
      if (error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout) {
        throw const AuthenticationFailure(
          AuthenticationFailureKind.networkUnavailable,
        );
      }
      throw const AuthenticationFailure(
        AuthenticationFailureKind.serviceUnavailable,
      );
    } on FormatException {
      throw const AuthenticationFailure(
        AuthenticationFailureKind.invalidResponse,
      );
    }
  }
}
