import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../shared/widgets/app_scaffold.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  bool _agreed = false;

  final _phoneCtrl = TextEditingController();
  final _smsCtrl = TextEditingController();

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _smsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildTopNav(),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.fromLTRB(32.w, 24.h, 32.w, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 标题 + 副标题（gap:24 对齐 Body 列间距）
                    Text(
                      '欢迎注册',
                      style: TextStyle(
                        fontSize: 28.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 24.h),
                    Text(
                      '开启你的购物之旅',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: AppColors.textHint,
                      ),
                    ),
                    SizedBox(height: 40.h),
                    _buildPhoneField(),
                    SizedBox(height: 24.h),
                    _buildSmsField(),
                    SizedBox(height: 32.h),
                    _buildAgreement(),
                    SizedBox(height: 24.h),
                    _buildRegisterButton(),
                    SizedBox(height: 32.h),
                    _buildHint(),
                  ],
                ),
              ),
            ),
          ),
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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: () => Navigator.maybePop(context),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: EdgeInsets.all(4.r),
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: AppColors.textPrimary,
                  size: 20.r,
                ),
              ),
            ),
            GestureDetector(
              onTap: () => Navigator.maybePop(context),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: EdgeInsets.all(4.r),
                child: Text(
                  '密码登录',
                  style: TextStyle(fontSize: 14.sp, color: AppColors.textHint),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 手机号输入 ────────────────────────────────────────────────────────

  Widget _buildPhoneField() {
    return _labeledField(
      label: '手机号',
      child: TextField(
        controller: _phoneCtrl,
        keyboardType: TextInputType.phone,
        style: TextStyle(fontSize: 16.sp, color: AppColors.textPrimary),
        decoration: _inputDeco(hint: '请输入手机号'),
      ),
    );
  }

  // ── 验证码输入 ────────────────────────────────────────────────────────

  Widget _buildSmsField() {
    return _labeledField(
      label: '验证码',
      child: TextField(
        controller: _smsCtrl,
        keyboardType: TextInputType.number,
        style: TextStyle(fontSize: 16.sp, color: AppColors.textPrimary),
        decoration: _inputDeco(
          hint: '请输入验证码',
          suffix: GestureDetector(
            onTap: () {},
            child: Padding(
              padding: EdgeInsets.only(right: 4.w),
              child: Text(
                '获取验证码',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _labeledField({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 13.sp, color: AppColors.textSecondary),
        ),
        SizedBox(height: 8.h),
        SizedBox(height: 48.h, child: child),
      ],
    );
  }

  InputDecoration _inputDeco({String? hint, Widget? suffix}) => InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: const Color(0xFFBBBBBB), fontSize: 16.sp),
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

  // ── 协议勾选（圆形 checkbox，16×16，cornerRadius 8）──────────────────

  Widget _buildAgreement() {
    return GestureDetector(
      onTap: () => setState(() => _agreed = !_agreed),
      behavior: HitTestBehavior.opaque,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 16.r,
            height: 16.r,
            decoration: BoxDecoration(
              color: _agreed ? AppColors.primary : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: _agreed ? AppColors.primary : AppColors.textDisabled,
                width: 1.5,
              ),
            ),
            child: _agreed
                ? Icon(Icons.check, size: 11.r, color: Colors.white)
                : null,
          ),
          SizedBox(width: 8.w),
          Flexible(
            child: Wrap(
              children: [
                Text('我已阅读并同意',
                    style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary)),
                GestureDetector(
                  onTap: () {},
                  child: Text('《用户协议》',
                      style: TextStyle(fontSize: 12.sp, color: AppColors.primary)),
                ),
                Text('和',
                    style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary)),
                GestureDetector(
                  onTap: () {},
                  child: Text('《隐私政策》',
                      style: TextStyle(fontSize: 12.sp, color: AppColors.primary)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 注册按钮 ──────────────────────────────────────────────────────────

  Widget _buildRegisterButton() {
    return Container(
      height: 48.h,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF7800), Color(0xFFFF5000)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(24.r),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24.r),
          onTap: _agreed ? () {} : null,
          child: Center(
            child: Text(
              '注册',
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

  // ── 底部提示 ──────────────────────────────────────────────────────────

  Widget _buildHint() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('注册即跳转',
            style: TextStyle(fontSize: 12.sp, color: AppColors.textHint)),
        Text('实名认证',
            style: TextStyle(fontSize: 12.sp, color: AppColors.primary)),
        Text('页面',
            style: TextStyle(fontSize: 12.sp, color: AppColors.textHint)),
      ],
    );
  }
}
