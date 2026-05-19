// 这是一个基础的 Flutter Widget 测试。
//
// 要在测试中与 Widget 交互，请使用 flutter_test 包中的 WidgetTester 工具。
// 例如，可以模拟点击和滚动手势，也可以用 WidgetTester 查找子 Widget、
// 读取文本，以及验证 Widget 属性的值是否正确。

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shop_blue/main.dart';

void main() {
  testWidgets('计数器递增冒烟测试', (WidgetTester tester) async {
    // 构建应用并触发一帧渲染。
    await tester.pumpWidget(const MyApp());

    // 验证计数器初始值为 0。
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // 点击 '+' 图标并触发一帧渲染。
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // 验证计数器已递增。
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}
