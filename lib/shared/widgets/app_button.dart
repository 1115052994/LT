import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/theme/tokens.dart';

/// 全局按钮组件——内置防抖（默认 500ms），统一样式。
/// 业务层禁止裸用 [ElevatedButton]，统一走此组件。
class AppButton extends StatefulWidget {
  const AppButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.style,
    this.debounce = const Duration(milliseconds: 500),
    this.loading = false,
    this.width,
    this.height,
  });

  AppButton.primary({
    super.key,
    required this.onPressed,
    required String label,
    this.debounce = const Duration(milliseconds: 500),
    this.loading = false,
    this.width,
    this.height,
    this.style,
  }) : child = Text(label);

  AppButton.outline({
    super.key,
    required this.onPressed,
    required String label,
    this.debounce = const Duration(milliseconds: 500),
    this.loading = false,
    this.width,
    this.height,
  })  : child = Text(label),
        style = null; // resolved in build

  final VoidCallback? onPressed;
  final Widget child;
  final ButtonStyle? style;
  final Duration debounce;
  final bool loading;
  final double? width;
  final double? height;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _locked = false;

  Future<void> _handleTap() async {
    if (_locked || widget.loading || widget.onPressed == null) return;
    setState(() => _locked = true);
    try {
      widget.onPressed!();
    } finally {
      await Future<void>.delayed(widget.debounce);
      if (mounted) setState(() => _locked = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canTap = !_locked && !widget.loading && widget.onPressed != null;
    return SizedBox(
      width: widget.width,
      height: widget.height ?? 48.h,
      child: ElevatedButton(
        onPressed: canTap ? _handleTap : null,
        style: widget.style ??
            ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.textDisabled,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.button.r),
              ),
              elevation: 0,
            ),
        child: widget.loading
            ? SizedBox(
                width: 20.r,
                height: 20.r,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : widget.child,
      ),
    );
  }
}
