import 'package:dio/dio.dart';
import 'package:eyes_mobile/core/error/app_exception.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final request = RequestOptions(path: '/objects');

  test('preserves exceptions already mapped by the application', () {
    const exception = StorageException(
      code: 'storage_unavailable',
      technicalCause: 'disk',
    );

    expect(AppExceptionMapper.from(exception), same(exception));
  });

  test('maps Dio timeout and connectivity failures', () {
    for (final type in <DioExceptionType>[
      DioExceptionType.connectionTimeout,
      DioExceptionType.receiveTimeout,
      DioExceptionType.sendTimeout,
    ]) {
      final mapped = AppExceptionMapper.from(
        DioException(requestOptions: request, type: type),
      );
      expect(mapped, isA<NetworkException>());
      expect(mapped.code, 'network_timeout');
    }

    final unavailable = AppExceptionMapper.from(
      DioException(
        requestOptions: request,
        type: DioExceptionType.connectionError,
      ),
    );
    expect(unavailable.code, 'network_unavailable');

    final generic = AppExceptionMapper.from(
      DioException(requestOptions: request, type: DioExceptionType.badResponse),
    );
    expect(generic.code, 'network_error');
  });

  test('maps unknown errors without losing their technical cause', () {
    final error = StateError('unexpected');
    final mapped = AppExceptionMapper.from(error);

    expect(mapped, isA<UnexpectedException>());
    expect(mapped.code, 'unexpected_error');
    expect(mapped.technicalCause, same(error));
  });
}
