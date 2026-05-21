// 基础冒烟测试：验证应用可正常启动并渲染登录页

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shop_blue/app.dart';

void main() {
  testWidgets('应用启动冒烟测试', (WidgetTester tester) async {
    // 初始化 ScreenUtil（测试环境需要）
    await tester.binding.setSurfaceSize(const Size(375, 812));

    // 构建应用并触发一帧渲染
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        child: const App(),
      ),
    );
    await tester.pumpAndSettle();

    // 验证登录页关键文字可见
    expect(find.text('Hi，欢迎回来'), findsOneWidget);
    expect(find.text('登录'), findsOneWidget);
  });
}
