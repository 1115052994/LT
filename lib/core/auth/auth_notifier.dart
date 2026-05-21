import 'package:flutter/foundation.dart';

// GoRouter.refreshListenable 监听此对象
// token 保存或清除时调用 setAuthenticated，触发路由重新评估 redirect 函数
class AuthNotifier extends ChangeNotifier {
  bool _isAuthenticated = false;

  bool get isAuthenticated => _isAuthenticated;

  // 在 runApp 之前调用，同步设置初始状态（不触发通知，树还没建立）
  void preload(String? token) {
    _isAuthenticated = token != null && token.isNotEmpty;
  }

  // token 变化时调用，触发 GoRouter 重新跑 redirect
  void setAuthenticated(bool value) {
    if (_isAuthenticated == value) return;
    _isAuthenticated = value;
    notifyListeners();
  }
}

// 包级单例——main.dart 预加载、auth_service.dart 更新、app_router.dart 监听
final authNotifier = AuthNotifier();
