import 'package:dio/dio.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import '../../auth/auth_service.dart';
import '../../constants/app_constants.dart';
import '../../error/failures.dart';

// 拦截器链第 3 位：统一处理 HTTP 状态码 + 业务 code
// 后端响应外壳约定：{ "code": 0, "msg": "ok", "data": {...} }
class StatusInterceptor extends Interceptor {
  final AuthService _authService;

  StatusInterceptor(this._authService);

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final httpCode = response.statusCode ?? 0;

    if (httpCode == 200) {
      final body = response.data;

      // 响应体不是 Map（如下载文件场景），直接透传
      if (body is! Map<String, dynamic>) return handler.next(response);

      final bizCode = (body['code'] as num?)?.toInt() ?? 0;

      // 1. 业务成功
      if (bizCode == 0) return handler.next(response);

      // 2. Token 过期：清 token + 跳登录，不弹 Toast
      if (bizCode == AppConstants.tokenExpiredCode) {
        _authService.handleTokenExpired();
        return handler.reject(DioException(
          requestOptions: response.requestOptions,
          response: response,
          error: const TokenExpiredFailure(),
        ));
      }

      // 3. 其他业务错误：Toast 提示 + 抛 BusinessFailure
      final msg = body['msg'] as String? ?? '操作失败';
      EasyLoading.showToast(msg);
      return handler.reject(DioException(
        requestOptions: response.requestOptions,
        response: response,
        error: BusinessFailure(bizCode, msg),
      ));
    }

    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final statusCode = err.response?.statusCode;

    // 已经是 Failure 类型（上面 reject 出来的）不重复处理
    if (err.error is Failure) return handler.next(err);

    final msg = switch (statusCode) {
      401 => null,                          // 兜底：清 token 跳登录，不弹 Toast
      403 => '无权限访问',
      404 => '请求的资源不存在',
      int s when s >= 500 && s < 600 => '服务器开小差了，请稍后重试',
      _ => switch (err.type) {
          DioExceptionType.connectionTimeout ||
          DioExceptionType.sendTimeout ||
          DioExceptionType.receiveTimeout =>
            '网络连接超时',
          DioExceptionType.connectionError => '网络连接失败，请检查网络',
          _ => null,
        },
    };

    // HTTP 401 兜底：清 token 跳登录
    if (statusCode == 401) _authService.handleTokenExpired();

    if (msg != null) EasyLoading.showToast(msg);
    handler.next(err);
  }
}
