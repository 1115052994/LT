import 'package:flutter/foundation.dart';

// 四套环境枚举及配置——dev/test/pre/prod
// 启动前调用 FlavorConfig.setup()，所有模块通过 FlavorConfig.current 访问
enum Flavor { dev, test, pre, prod }

class FlavorConfig {
  final Flavor flavor;
  final String baseUrl;
  final String alipayAppId;

  static FlavorConfig? _current;

  const FlavorConfig._({
    required this.flavor,
    required this.baseUrl,
    required this.alipayAppId,
  });

  static void setup({
    required Flavor flavor,
    required String baseUrl,
    String alipayAppId = '',
  }) {
    _current = FlavorConfig._(
      flavor: flavor,
      baseUrl: baseUrl,
      alipayAppId: alipayAppId,
    );
  }

  static FlavorConfig get current {
    assert(_current != null, 'FlavorConfig.setup() must be called in bootstrap');
    return _current!;
  }

  // ── 快捷判断 ────────────────────────────────────────────────────────
  // bootstrap 还未调用时安全返回 null（用于 Provider 的 fallback）
  static String? get baseUrlOrNull => _current?.baseUrl;

  // 安全静态访问器——FlavorConfig 未初始化时 fallback 到 kDebugMode
  static bool get isLogEnabled => _current?.logEnabled ?? kDebugMode;
  static bool get isLogVerbose => _current?.logVerbose ?? kDebugMode;

  static bool get isProd => current.flavor == Flavor.prod;
  static bool get isDevOrTest =>
      current.flavor == Flavor.dev || current.flavor == Flavor.test;

  // App 名称（各端桌面图标显示不同名称以区分环境）
  String get appName => switch (flavor) {
        Flavor.dev  => 'Shop Dev',
        Flavor.test => 'Shop Test',
        Flavor.pre  => 'Shop Pre',
        Flavor.prod => 'Shop',
      };

  // 日志控制：dev/test 全量，pre 仅错误，prod 完全关闭
  bool get logEnabled => flavor != Flavor.prod;
  bool get logVerbose  => flavor == Flavor.dev || flavor == Flavor.test;
}
