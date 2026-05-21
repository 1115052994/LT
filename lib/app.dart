import 'package:flutter/material.dart'; // Flutter 核心 UI 框架
import 'package:flutter_easyloading/flutter_easyloading.dart'; // 全局 Toast / Loading 浮层
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Riverpod 状态管理
import 'package:flutter_screenutil/flutter_screenutil.dart'; // 屏幕自适应工具
import 'core/di/navigation_holder.dart'; // 注册全局导航函数
import 'core/router/app_router.dart'; // 全局 GoRouter 单例
import 'core/theme/app_theme.dart'; // 全局主题配置

class App extends StatelessWidget { // 根组件，无状态
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    registerNavigateFn(appRouter.go); // 将 GoRouter 导航函数注入 AuthService

    return ProviderScope( // Riverpod 全局作用域，所有 Provider 必须在此节点下才能访问
      child: MaterialApp.router( // 使用 go_router 驱动的 Material 应用
        title: 'Shop', // 应用标题（任务管理器中显示）
        theme: AppTheme.light, // 应用浅色主题
        routerConfig: appRouter, // 注入路由配置
        debugShowCheckedModeBanner: false, // 隐藏右上角 debug 标签
        builder: EasyLoading.init( // 注入 EasyLoading 浮层，支持全局 Toast
          builder: (context, child) {
            // MaterialApp builder 内的 context 已有真实 MediaQuery，此时初始化 ScreenUtil 保证 .sp/.w/.h 单位正确
            ScreenUtil.init(
              context,
              designSize: const Size(375, 812), // 设计稿基准尺寸
              minTextAdapt: true, // 小屏设备文字保持最小可读性
              splitScreenMode: true, // 支持分屏模式
            );
            return MediaQuery( // 固定文字缩放比例，忽略系统字体大小设置
              data: MediaQuery.of(context).copyWith(
                textScaler: const TextScaler.linear(1.0),
              ),
              child: child!, // 渲染子树
            );
          },
        ),
      ),
    );
  }
}
