import 'package:dio/dio.dart';
import '../../error/failures.dart';

// 拦截器链最后一位：把所有 DioException 统一转换为 Failure
// Repository 层 catch 到的 error 类型一定是 Failure，UI 层无需关心 Dio 细节
class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // 已经是 Failure 的（StatusInterceptor reject 出来的）直接透传
    if (err.error is Failure) return handler.next(err);

    final failure = switch (err.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout =>
        const TimeoutFailure(),
      DioExceptionType.connectionError => const NetworkFailure(),
      DioExceptionType.badResponse => switch (err.response?.statusCode) {
          401 => const UnauthorizedFailure(),
          403 => const ForbiddenFailure(),
          404 => const NotFoundFailure(),
          int s when s >= 500 => ServerFailure(s),
          _ => UnknownFailure(err.message),
        },
      _ => UnknownFailure(err.message),
    };

    // 把原始 DioException 的 error 字段替换为 Failure，其余字段保留
    handler.next(DioException(
      requestOptions: err.requestOptions,
      response: err.response,
      type: err.type,
      error: failure,
    ));
  }
}
