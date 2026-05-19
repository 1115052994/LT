import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_nav_bar.dart';

/// 统一 Scaffold 封装，业务页面禁止裸用 [Scaffold]
///
/// - 有 [appBar] 时：body 从 AppBar 底部开始，SafeArea 只处理底部
/// - 无 [appBar] 时：body 从状态栏底部开始（SafeArea top）
/// - 沉浸式页面（如商品详情大图）：[extendBodyBehindAppBar] = true，
///   AppBar 叠在 body 上层，body 自行处理顶部 padding
class AppScaffold extends StatelessWidget {
  final Widget body;
  final AppNavBar? appBar;
  final bool extendBodyBehindAppBar;
  final Color? backgroundColor;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final bool resizeToAvoidBottomInset;

  const AppScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.extendBodyBehindAppBar = false,
    this.backgroundColor,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.resizeToAvoidBottomInset = true,
  });

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: appBar,
        extendBodyBehindAppBar: extendBodyBehindAppBar,
        bottomNavigationBar: bottomNavigationBar,
        floatingActionButton: floatingActionButton,
        resizeToAvoidBottomInset: resizeToAvoidBottomInset,
        body: SafeArea(
          // 有 AppBar 时 Scaffold 已自动空出 AppBar 高度，无需重复避让顶部
          top: appBar == null && !extendBodyBehindAppBar,
          bottom: true,
          child: body,
        ),
      ),
    );
  }
}
