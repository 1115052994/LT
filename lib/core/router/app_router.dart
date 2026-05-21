import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import '../auth/auth_notifier.dart';
import '../flavor/flavor.dart';
import 'app_routes.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../shared/widgets/app_webview.dart';
import '../../shared/widgets/debug_panel.dart';

// 路由守卫——同步读取内存中的认证状态（已在 main 里预加载，无闪烁）
String? _authRedirect(BuildContext context, GoRouterState state) {
  final hasToken = authNotifier.isAuthenticated;
  final loc = state.matchedLocation;

  // 未登录：登录页 / 注册页允许通行，其他所有页面拦截跳登录
  if (!hasToken) {
    final isAuthPage = loc == AppRoutes.login || loc == AppRoutes.register;
    return isAuthPage ? null : AppRoutes.login;
  }

  // 已登录：停在登录页没意义，直接跳首页
  if (loc == AppRoutes.login) return AppRoutes.home;

  return null; // 无需跳转
}

// 包级 GoRouter 单例——Widget 树外也可访问（AuthService token 过期跳转使用）
final appRouter = GoRouter(
  refreshListenable: authNotifier, // token 变化时自动重跑 _authRedirect
  redirect: _authRedirect,
  routes: [
    GoRoute(
      path: AppRoutes.login,
      builder: (ctx, s) => const LoginPage(),
      routes: [
        GoRoute(
          path: 'register',
          builder: (ctx, s) => const RegisterPage(),
        ),
      ],
    ),
    GoRoute(
      path: AppRoutes.home,
      builder: (ctx, s) => const HomePage(),
    ),
    // 通用 H5 路由：context.push('/webview?url=xxx&title=活动')
    GoRoute(
      path: AppRoutes.webview,
      builder: (ctx, s) => AppWebView(
        url: s.uri.queryParameters['url'] ?? '',
        title: s.uri.queryParameters['title'],
      ),
    ),
    // 开发者面板——仅 dev/test 可用，prod/pre 重定向到首页
    GoRoute(
      path: AppRoutes.debug,
      redirect: (ctx, s) => FlavorConfig.isDevOrTest ? null : AppRoutes.home,
      builder: (ctx, s) => const DebugPanel(),
    ),
  ],
);
