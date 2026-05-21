import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../auth/auth_notifier.dart';
import '../constants/app_constants.dart';
import '../lifecycle/app_lifecycle_observer.dart';
import '../privacy/privacy_gate.dart';
import 'flavor.dart';
import '../../app.dart';

// 统一启动入口——所有 main_*.dart 调用此函数，传入对应 Flavor 配置
Future<void> bootstrap({
  required Flavor flavor,
  required String baseUrl,
  String alipayAppId = '',
}) async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. 设置当前环境
  FlavorConfig.setup(
    flavor: flavor,
    baseUrl: baseUrl,
    alipayAppId: alipayAppId,
  );

  // 2. 全局异常兜底——避免单点崩溃白屏
  FlutterError.onError = (details) {
    debugPrint('[FlutterError] ${details.exception}\n${details.stack}');
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('[PlatformError] $error\n$stack');
    return true;
  };

  // 3. 启动前读取 Token，预置认证状态（避免路由首帧闪烁）
  try {
    final token = await const FlutterSecureStorage()
        .read(key: AppConstants.tokenKey);
    authNotifier.preload(token);
  } catch (_) {}

  // 4. 图片缓存上限（后端无 CDN 缩略图，单图大，缓存调小）
  PaintingBinding.instance.imageCache.maximumSize = 80;
  PaintingBinding.instance.imageCache.maximumSizeBytes = 60 * 1024 * 1024;

  // 5. 生命周期观察者（内存压力清缓存 / 后台回来刷新数据）
  WidgetsBinding.instance.addObserver(AppLifecycleObserver());

  // 6. 锁定竖屏
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // PrivacyGate 守门——未同意隐私协议前不渲染 App（不初始化任何 SDK）
  runApp(const PrivacyGate(child: App()));
}
