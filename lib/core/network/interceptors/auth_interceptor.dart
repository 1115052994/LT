import 'package:dio/dio.dart';
import '../../auth/auth_service.dart';

// 拦截器链第 1 位：请求出发前注入 Authorization Token
// 响应回来后检查是否需要重试（本项目无 refresh token，过期直接交给 StatusInterceptor 处理）
class AuthInterceptor extends Interceptor {
  final AuthService _authService;

  AuthInterceptor(this._authService);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _authService.getToken();
    if (token != null && token.isNotEmpty) {
      // 按后端约定注入 Token，格式视后端要求调整（Bearer / 裸 token）
      options.headers['Authorization'] = token;
    }
    handler.next(options);
  }
}
