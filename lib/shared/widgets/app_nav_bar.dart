import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/theme/tokens.dart';

/// 统一顶部导航栏
///
/// - [title] 中间文字，不传则不显示标题
/// - [titleWidget] 自定义标题 widget，优先级高于 [title]
/// - [onBack] 自定义返回逻辑；为 null 时自动 pop
/// - [showBack] 强制显示/隐藏返回键；不传则自动判断（有路由可 pop 就显示）
/// - [actions] 右侧操作区
/// - [backgroundColor] 导航栏背景色，默认白色
/// - [foregroundColor] 图标和文字颜色
/// - [statusBarDark] true = 状态栏深色图标（浅色背景用），false = 浅色图标（深色背景用）
class AppNavBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? titleWidget;
  final VoidCallback? onBack;
  final List<Widget>? actions;
  final Color backgroundColor;
  final Color foregroundColor;
  final bool? showBack;
  final bool statusBarDark;

  const AppNavBar({
    super.key,
    this.title,
    this.titleWidget,
    this.onBack,
    this.actions,
    this.backgroundColor = AppColors.cardBg,
    this.foregroundColor = AppColors.textPrimary,
    this.showBack,
    this.statusBarDark = true,
  });

  @override
  Size get preferredSize => Size.fromHeight(44.h);

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.canPop(context);
    final shouldShowBack = showBack ?? (canPop || onBack != null);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            statusBarDark ? Brightness.dark : Brightness.light,
        statusBarBrightness:
            statusBarDark ? Brightness.light : Brightness.dark,
      ),
      child: AppBar(
        toolbarHeight: 44.h,
        backgroundColor: backgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        automaticallyImplyLeading: false,
        centerTitle: true,
        leading: shouldShowBack
            ? GestureDetector(
                onTap: onBack ?? () => Navigator.maybePop(context),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: EdgeInsets.only(left: 4.w),
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: foregroundColor,
                    size: 20.r,
                  ),
                ),
              )
            : null,
        title: titleWidget ??
            (title != null
                ? Text(
                    title!,
                    style: TextStyle(
                      color: foregroundColor,
                      fontSize: AppFontSize.subtitle.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                : null),
        actions: actions,
      ),
    );
  }
}
