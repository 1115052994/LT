import '../../../../core/auth/auth_service.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

// 认证 Repository 实现——调用数据源后将 token 保存至 AuthService
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _dataSource;
  final AuthService _authService;

  const AuthRepositoryImpl({
    required AuthRemoteDataSource dataSource,
    required AuthService authService,
  })  : _dataSource = dataSource,
        _authService = authService;

  @override
  Future<void> loginWithPassword(String phone, String password) async {
    final response = await _dataSource.loginWithPassword(phone, password);
    await _authService.saveToken(response.token);
  }

  @override
  Future<void> loginWithSms(String phone, String code) async {
    final response = await _dataSource.loginWithSms(phone, code);
    await _authService.saveToken(response.token);
  }
}
