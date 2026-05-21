import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../providers/login_provider.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  int _tabIndex = 0; // 0=密码登录  1=验证码登录
  bool _obscurePassword = true;

  final _phoneCtrl = TextEditingController();
  final _pwdCtrl   = TextEditingController();
  final _smsCtrl   = TextEditingController();

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _pwdCtrl.dispose();
    _smsCtrl.dispose();
    super.dispose();
  }

  void _onLoginTap() {
    final phone    = _phoneCtrl.text.trim();
    final notifier = ref.read(loginNotifierProvider.notifier);

    if (_tabIndex == 0) {
      final pwd = _pwdCtrl.text;
      if (phone.isEmpty || pwd.isEmpty) {
        EasyLoading.showToast('请填写手机号和密码');
        return;
      }
      notifier.loginWithPassword(phone, pwd);
    } else {
      final code = _smsCtrl.text.trim();
      if (phone.isEmpty || code.isEmpty) {
        EasyLoading.showToast('请填写手机号和验证码');
        return;
      }
      notifier.loginWithSms(phone, code);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 登录成功后由 GoRouter.refreshListenable 自动跳转首页，无需手动 context.go
    return AppScaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildTopNav(),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLogo(),
                  _buildBody(),
                ],
              ),
            ),
          ),
          // 底部留白（对齐设计稿 loginFoot padding-bottom 40）
          SizedBox(height: 40.h),
        ],
      ),
    );
  }

  // ── 顶部导航 ──────────────────────────────────────────────────────────

  Widget _buildTopNav() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: SizedBox(
        height: 48.h,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            GestureDetector(
              onTap: () => context.push(AppRoutes.register),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: EdgeInsets.all(4.r),
                child: Text(
                  '注册',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.normal,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Logo ──────────────────────────────────────────────────────────────

  Widget _buildLogo() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 24.h),
        child: Container(
          width: 72.r,
          height: 72.r,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFFFF7800), Color(0xFFFF3000)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 36.r),
        ),
      ),
    );
  }

  // ── 主体表单（gap 统一 24px，对齐设计稿 b3vJAu gap:24）─────────────

  Widget _buildBody() {
    return Padding(
      padding: EdgeInsets.fromLTRB(32.w, 8.h, 32.w, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hi，欢迎回来',
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 24.h),
          _buildTabs(),
          SizedBox(height: 24.h),
          _buildPhoneField(),
          SizedBox(height: 24.h),
          if (_tabIndex == 0) ...[
            _buildPasswordField(),
            SizedBox(height: 24.h),
            _buildExtras(),
          ] else ...[
            _buildSmsField(),
          ],
          SizedBox(height: 24.h),
          _buildLoginButton(),
        ],
      ),
    );
  }

  // ── Tab ───────────────────────────────────────────────────────────────

  Widget _buildTabs() {
    return Row(
      children: [
        _buildTab('密码登录', 0),
        SizedBox(width: 24.w),
        _buildTab('验证码登录', 1),
      ],
    );
  }

  Widget _buildTab(String label, int index) {
    final active = _tabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _tabIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: active ? FontWeight.w600 : FontWeight.normal,
              color: active ? AppColors.textPrimary : AppColors.textHint,
            ),
          ),
          SizedBox(height: 6.h),
          Container(
            width: 24.w,
            height: 3.h,
            decoration: BoxDecoration(
              color: active ? AppColors.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
        ],
      ),
    );
  }

  // ── 输入框样式（下划线 border，无其他边框）──────────────────────────

  InputDecoration _inputDeco({
    required IconData prefix,
    Widget? suffix,
    String? hint,
  }) =>
      InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: AppColors.textHint, fontSize: 16.sp),
        prefixIcon: Icon(prefix, color: AppColors.textSecondary, size: 18.r),
        suffixIcon: suffix,
        isDense: true,
        contentPadding: EdgeInsets.only(bottom: 12.h),
        border: const UnderlineInputBorder(
            borderSide: BorderSide(color: AppColors.divider)),
        enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: AppColors.divider)),
        focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: AppColors.primary)),
      );

  Widget _buildPhoneField() {
    return SizedBox(
      height: 48.h,
      child: TextField(
        controller: _phoneCtrl,
        keyboardType: TextInputType.phone,
        style: TextStyle(fontSize: 16.sp, color: AppColors.textPrimary),
        decoration: _inputDeco(prefix: Icons.smartphone_outlined, hint: '138 0000 0000'),
      ),
    );
  }

  Widget _buildPasswordField() {
    return SizedBox(
      height: 48.h,
      child: TextField(
        controller: _pwdCtrl,
        obscureText: _obscurePassword,
        style: TextStyle(fontSize: 18.sp, color: AppColors.textPrimary, letterSpacing: 3),
        decoration: _inputDeco(
          prefix: Icons.lock_outline,
          suffix: GestureDetector(
            onTap: () => setState(() => _obscurePassword = !_obscurePassword),
            child: Icon(
              _obscurePassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: AppColors.textHint,
              size: 18.r,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSmsField() {
    return SizedBox(
      height: 48.h,
      child: TextField(
        controller: _smsCtrl,
        keyboardType: TextInputType.number,
        style: TextStyle(fontSize: 16.sp, color: AppColors.textPrimary),
        decoration: _inputDeco(
          prefix: Icons.chat_bubble_outline,
          hint: '请输入验证码',
          suffix: GestureDetector(
            onTap: () {},
            child: Padding(
              padding: EdgeInsets.only(right: 4.w),
              child: Text(
                '获取验证码',
                style: TextStyle(color: AppColors.primary, fontSize: 14.sp),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── 忘记密码 ───────────────────────────────────────────────────────────

  Widget _buildExtras() {
    return Align(
      alignment: Alignment.centerRight,
      child: GestureDetector(
        onTap: () {},
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 4.h),
          child: Text(
            '忘记密码？',
            style: TextStyle(fontSize: 12.sp, color: AppColors.primary),
          ),
        ),
      ),
    );
  }

  // ── 登录按钮（loading 时禁用 + 显示菊花圈）──────────────────────────

  Widget _buildLoginButton() {
    final isLoading = ref.watch(loginNotifierProvider) is AsyncLoading;

    return Container(
      height: 48.h,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isLoading
              ? [Colors.grey.shade400, Colors.grey.shade300]
              : [const Color(0xFFFF7800), const Color(0xFFFF5000)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(24.r),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24.r),
          onTap: isLoading ? null : _onLoginTap,
          child: Center(
            child: isLoading
                ? SizedBox(
                    width: 20.r,
                    height: 20.r,
                    child: const CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    '登录',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
