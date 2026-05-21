class AppConstants {
  // 后端 API 根地址，上线前替换为真实域名
  static const String baseUrl = 'https://api.example.com';

  // Token 过期业务错误码，需与后端确认具体值后修改此处（单点定义，禁止散落）
  static const int tokenExpiredCode = 401001;

  // flutter_secure_storage 存储 Token 的 key
  static const String tokenKey = 'auth_token';

  // 网络请求超时时间（毫秒）
  static const int connectTimeout = 15000;
  static const int receiveTimeout = 15000;
  static const int sendTimeout    = 15000;

  // 请求 / 响应 Body 日志截断阈值
  static const int logBodyMaxBytes = 10240;  // 请求 Body 超过 10KB 截断
  static const int logRespMaxBytes = 51200;  // 响应 Body 超过 50KB 截断
}
