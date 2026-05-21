import 'dart:async';
import 'package:flutter/foundation.dart';

// 倒计时控制器——使用 wall clock 补算剩余时间，后台恢复后自动修正
// 用法：CountdownTimer(60) → start() → 监听 remaining → dispose()
class CountdownTimer extends ChangeNotifier {
  final int totalSeconds;
  int _remaining;
  Timer? _timer;
  DateTime? _endTime; // 终止时刻，用于后台回来后补算

  CountdownTimer(this.totalSeconds) : _remaining = totalSeconds;

  int get remaining => _remaining;
  bool get isRunning => _timer != null;
  bool get isFinished => _remaining <= 0;

  // 格式化为 mm:ss
  String get formatted {
    final m = (_remaining ~/ 60).toString().padLeft(2, '0');
    final s = (_remaining % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void start() {
    if (isRunning || isFinished) return;
    _endTime = DateTime.now().add(Duration(seconds: _remaining));
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void pause() {
    _timer?.cancel();
    _timer = null;
  }

  // 从后台回来时调用，用 wall clock 修正剩余时间后继续
  void resumeFromBackground() {
    if (_endTime == null || isFinished) return;
    _tick(); // 先补算一次
    if (!isFinished) start();
  }

  void reset() {
    _timer?.cancel();
    _timer = null;
    _remaining = totalSeconds;
    _endTime = null;
    notifyListeners();
  }

  void _tick() {
    final remaining = _endTime!.difference(DateTime.now()).inSeconds;
    _remaining = remaining.clamp(0, totalSeconds);
    notifyListeners();
    if (_remaining <= 0) {
      _timer?.cancel();
      _timer = null;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
