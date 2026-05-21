// Failure 密封类——所有业务错误的统一表示
// Repository 返回 Result<T, Failure>，UI 层通过 switch 匹配处理，禁止裸 try-catch
sealed class Failure {
  const Failure();
}

// 网络连接失败（无网络 / DNS 解析失败）
class NetworkFailure extends Failure {
  final String message;
  const NetworkFailure([this.message = '网络连接失败，请检查网络']);
}

// 请求超时
class TimeoutFailure extends Failure {
  const TimeoutFailure();
}

// HTTP 服务器错误（5xx）
class ServerFailure extends Failure {
  final int statusCode;
  const ServerFailure(this.statusCode);
}

// 业务逻辑错误（HTTP 200 + code != 0）
class BusinessFailure extends Failure {
  final int code;
  final String message;
  const BusinessFailure(this.code, this.message);
}

// Token 过期（需清 token 并跳登录页，不弹 Toast）
class TokenExpiredFailure extends Failure {
  const TokenExpiredFailure();
}

// HTTP 401 兜底（正常走业务 code，此处作为后备）
class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure();
}

// HTTP 403 无权限
class ForbiddenFailure extends Failure {
  const ForbiddenFailure();
}

// HTTP 404 资源不存在
class NotFoundFailure extends Failure {
  const NotFoundFailure();
}

// 未知错误（兜底）
class UnknownFailure extends Failure {
  final String? message;
  const UnknownFailure([this.message]);
}
