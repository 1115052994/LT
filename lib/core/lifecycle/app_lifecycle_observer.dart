import 'package:flutter/material.dart';

// App 级生命周期观察者——在 main.dart 注册到 WidgetsBinding
// 电商典型场景：后台回来刷新购物车 / 停掉倒计时 / 内存压力清图片缓存
class AppLifecycleObserver extends WidgetsBindingObserver {
  DateTime? _pausedAt;

  // 超过此时长从后台回来，视为"冷回来"，需要刷新关键数据
  static const _staleThreshold = Duration(minutes: 5);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _onResumed();
      case AppLifecycleState.paused:
        _pausedAt = DateTime.now();
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        break;
    }
  }

  void _onResumed() {
    final pausedAt = _pausedAt;
    if (pausedAt == null) return;
    final offline = DateTime.now().difference(pausedAt);
    if (offline > _staleThreshold) {
      // 后台超 5 分钟：业务层可监听此事件刷新首页 / 购物车
      debugPrint('[Lifecycle] resumed after ${offline.inSeconds}s — data may be stale');
    }
    _pausedAt = null;
  }

  // 系统内存压力回调——主动清图片缓存
  @override
  void didHaveMemoryPressure() {
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    debugPrint('[Lifecycle] memory pressure — image cache cleared');
  }
}
