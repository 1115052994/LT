import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// 幂等 GET 请求自动重试——指数退避，最多 3 次。
/// 只重试：网络超时 / 连接错误 / 5xx；4xx 不重试（客户端错误，重试无意义）。
class RetryInterceptor extends Interceptor {
  RetryInterceptor(this.dio);

  final Dio dio;

  static const _maxAttempts = 3;
  static const _baseDelayMs = 500;
  static const _attemptKey = 'retry_attempt';

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (!_shouldRetry(err)) return handler.next(err);

    final attempt = (err.requestOptions.extra[_attemptKey] as int? ?? 0) + 1;
    if (attempt > _maxAttempts) return handler.next(err);

    err.requestOptions.extra[_attemptKey] = attempt;
    final delay = Duration(milliseconds: (_baseDelayMs * pow(2, attempt - 1)).round());
    debugPrint('[Retry] #$attempt/$_maxAttempts in ${delay.inMilliseconds}ms — ${err.requestOptions.uri}');

    await Future<void>.delayed(delay);
    try {
      final response = await dio.fetch<dynamic>(err.requestOptions);
      return handler.resolve(response);
    } on DioException catch (e) {
      return handler.next(e);
    }
  }

  bool _shouldRetry(DioException err) {
    if (err.requestOptions.method.toUpperCase() != 'GET') return false;
    return err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.connectionError ||
        (err.response?.statusCode != null && err.response!.statusCode! >= 500);
  }
}
