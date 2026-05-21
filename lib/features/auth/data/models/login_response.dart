// 登录接口响应 data 字段的数据模型（手写，无需 build_runner）
class LoginResponse {
  final String token;
  final String? userId;

  const LoginResponse({required this.token, this.userId});

  factory LoginResponse.fromJson(Map<String, dynamic> json) => LoginResponse(
        token: json['token'] as String,
        userId: (json['userId'] ?? json['user_id'])?.toString(),
      );
}
