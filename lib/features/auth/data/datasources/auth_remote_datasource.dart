import 'package:dio/dio.dart';
import '../../../../core/network/api_response.dart';
import '../models/login_response.dart';

// 认证远程数据源——Dio 直接调用，错误由拦截器链统一处理后以 Failure 上抛
class AuthRemoteDataSource {
  final Dio _dio;
  const AuthRemoteDataSource(this._dio);

  Future<LoginResponse> loginWithPassword(String phone, String password) async {
    final resp = await _dio.post<Map<String, dynamic>>(
      '/auth/login',
      data: {'phone': phone, 'password': password, 'type': 'password'},
    );
    return ApiResponse.of(resp).dataAs(LoginResponse.fromJson);
  }

  Future<LoginResponse> loginWithSms(String phone, String code) async {
    final resp = await _dio.post<Map<String, dynamic>>(
      '/auth/login',
      data: {'phone': phone, 'code': code, 'type': 'sms'},
    );
    return ApiResponse.of(resp).dataAs(LoginResponse.fromJson);
  }
}
