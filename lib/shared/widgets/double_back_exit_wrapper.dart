import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

// Android 双击返回键退出 App——用于底部 Tab 主页
// 两次点击间隔 < 2s 才退出，超时重置计时
class DoubleBackExitWrapper extends StatefulWidget {
  final Widget child;
  const DoubleBackExitWrapper({super.key, required this.child});

  @override
  State<DoubleBackExitWrapper> createState() => _DoubleBackExitWrapperState();
}

class _DoubleBackExitWrapperState extends State<DoubleBackExitWrapper> {
  DateTime? _lastBackPressed;
  static const _exitWindow = Duration(seconds: 2);

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        final now = DateTime.now();
        if (_lastBackPressed == null ||
            now.difference(_lastBackPressed!) > _exitWindow) {
          _lastBackPressed = now;
          EasyLoading.showToast('再按一次退出');
          return;
        }
        SystemNavigator.pop();
      },
      child: widget.child,
    );
  }
}
