import 'package:dio/dio.dart';

sealed class AppException implements Exception {
  const AppException({required this.code, required this.technicalCause});

  final String code;
  final Object? technicalCause;
}

final class NetworkException extends AppException {
  const NetworkException({required super.code, super.technicalCause});
}

final class StorageException extends AppException {
  const StorageException({required super.code, super.technicalCause});
}

final class UnexpectedException extends AppException {
  const UnexpectedException({required super.code, super.technicalCause});
}

abstract final class AppExceptionMapper {
  static AppException from(Object error) {
    if (error is AppException) {
      return error;
    }
    if (error is DioException) {
      return NetworkException(
        code: _networkCode(error.type),
        technicalCause: error,
      );
    }
    return UnexpectedException(code: 'unexpected_error', technicalCause: error);
  }

  static String _networkCode(DioExceptionType type) => switch (type) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.receiveTimeout ||
    DioExceptionType.sendTimeout => 'network_timeout',
    DioExceptionType.connectionError => 'network_unavailable',
    _ => 'network_error',
  };
}
