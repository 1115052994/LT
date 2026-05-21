import 'package:dio/dio.dart';
import '../auth/auth_service.dart';
import '../constants/app_constants.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/error_interceptor.dart';
import 'interceptors/logger_interceptor.dart';
import 'interceptors/retry_interceptor.dart';
import 'interceptors/status_interceptor.dart';

// Dio 单例工厂——按 PLAN.md 拦截器链顺序装配：
// 请求方向：Auth → Logger → Status → Error → Retry → 网络
// 错误方向：网络 → Retry（先重试）→ Error → Status → Logger → Auth
class DioClient {
  DioClient._();

  // 调用 DioClient.create() 获取配置好的 Dio 实例
  static Dio create({
    required String baseUrl,
    required AuthService authService,
  }) {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(milliseconds: AppConstants.connectTimeout),
        receiveTimeout: const Duration(milliseconds: AppConstants.receiveTimeout),
        sendTimeout:    const Duration(milliseconds: AppConstants.sendTimeout),
        // 后端固定返回 JSON，统一声明
        contentType: 'application/json; charset=utf-8',
        responseType: ResponseType.json,
      ),
    );

    // 按顺序添加拦截器（Dio 内部是栈结构，后加的先执行响应，先加的先执行请求）
    dio.interceptors.addAll([
      AuthInterceptor(authService),      // 注入 Token
      AppLoggerInterceptor(),            // 打印日志（含耗时）
      StatusInterceptor(authService),    // 处理业务 code / HTTP 状态码
      ErrorInterceptor(),                // 统一转换为 Failure
      RetryInterceptor(dio),             // GET 自动重试（错误方向最先执行）
    ]);

    return dio;
  }
}
