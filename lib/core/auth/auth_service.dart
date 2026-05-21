import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';
import '../router/app_routes.dart';
import 'auth_notifier.dart';

// AuthService 抽象接口——拦截器依赖此接口，具体实现在 feature/auth 层
abstract class AuthService {
  Future<String?> getToken();
  Future<void> saveToken(String token);
  Future<void> clearToken();
  void handleTokenExpired();
}

// AuthService 默认实现——flutter_secure_storage 加密存储 + AuthNotifier 同步状态
class DefaultAuthService implements AuthService {
  final FlutterSecureStorage _storage;
  final void Function(String path) _navigateTo;

  const DefaultAuthService({
    required FlutterSecureStorage storage,
    required void Function(String path) navigateTo,
  })  : _storage = storage,
        _navigateTo = navigateTo;

  @override
  Future<String?> getToken() => _storage.read(key: AppConstants.tokenKey);

  @override
  Future<void> saveToken(String token) async {
    await _storage.write(key: AppConstants.tokenKey, value: token);
    authNotifier.setAuthenticated(true); // 通知 GoRouter 重新跑 redirect → 跳首页
  }

  @override
  Future<void> clearToken() async {
    await _storage.delete(key: AppConstants.tokenKey);
    authNotifier.setAuthenticated(false); // 通知 GoRouter 重新跑 redirect → 跳登录页
  }

  @override
  void handleTokenExpired() {
    clearToken(); // clearToken 内已通知 authNotifier，GoRouter 会自动跳登录页
    _navigateTo(AppRoutes.login); // 双重保险：直接导航，防止 refreshListenable 延迟
  }
}
