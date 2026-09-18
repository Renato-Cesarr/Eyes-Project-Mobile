import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:eyes_mobile/features/account/application/auth_gateway.dart';
import 'package:eyes_mobile/features/account/infrastructure/dio_auth_gateway.dart';
import 'package:flutter_test/flutter_test.dart';

final class _AuthAdapter implements HttpClientAdapter {
  _AuthAdapter({required this.statusCode, required this.body});

  final int statusCode;
  final String body;
  RequestOptions? request;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    request = options;
    return ResponseBody.fromString(
      body,
      statusCode,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>['application/json'],
      },
    );
  }
}

void main() {
  test(
    'uses the backend login contract and parses the remote session',
    () async {
      final adapter = _AuthAdapter(
        statusCode: 200,
        body: jsonEncode(<String, Object?>{
          'token': 'jwt-value',
          'user': <String, Object?>{
            'id': 'user-id',
            'name': 'Pessoa Teste',
            'email': 'pessoa@example.com',
          },
        }),
      );
      final dio = Dio(BaseOptions(baseUrl: 'https://example.invalid'))
        ..httpClientAdapter = adapter;
      final gateway = DioAuthGateway(dio);

      final session = await gateway.login(
        email: 'pessoa@example.com',
        password: 'secret-value',
      );

      expect(adapter.request?.path, '/api/v1/auth/login');
      expect(adapter.request?.data, <String, Object?>{
        'email': 'pessoa@example.com',
        'password': 'secret-value',
      });
      expect(adapter.request?.extra['skipAuthentication'], isTrue);
      expect(session.accessToken, 'jwt-value');
      expect(session.user.name, 'Pessoa Teste');
    },
  );

  test(
    'maps authentication and service failures without leaking payloads',
    () async {
      final unauthorized = Dio(BaseOptions(baseUrl: 'https://example.invalid'))
        ..httpClientAdapter = _AuthAdapter(statusCode: 401, body: '{}');
      final unavailable = Dio(BaseOptions(baseUrl: 'https://example.invalid'))
        ..httpClientAdapter = _AuthAdapter(statusCode: 503, body: '{}');

      await expectLater(
        DioAuthGateway(
          unauthorized,
        ).login(email: 'a@b.com', password: 'secret'),
        throwsA(
          isA<AuthenticationFailure>().having(
            (error) => error.kind,
            'kind',
            AuthenticationFailureKind.invalidCredentials,
          ),
        ),
      );
      await expectLater(
        DioAuthGateway(unavailable).login(email: 'a@b.com', password: 'secret'),
        throwsA(
          isA<AuthenticationFailure>().having(
            (error) => error.kind,
            'kind',
            AuthenticationFailureKind.serviceUnavailable,
          ),
        ),
      );
    },
  );
}
