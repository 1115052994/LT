import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/theme/tokens.dart';

// 统一空状态 / 错误状态组件——电商所有"没数据"场景走此组件
// 插画由设计交付后替换 _icon，路径统一放 assets/empty/
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionText;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionText,
    this.onAction,
  });

  // ── 预设场景工厂 ──────────────────────────────────────────────────

  factory EmptyState.products() => const EmptyState(
        icon: Icons.inventory_2_outlined,
        title: '暂无商品',
      );

  factory EmptyState.search() => const EmptyState(
        icon: Icons.search_off_outlined,
        title: '没有找到相关商品',
        subtitle: '换个关键词试试',
      );

  factory EmptyState.cart({VoidCallback? onGo}) => EmptyState(
        icon: Icons.shopping_cart_outlined,
        title: '购物车空空如也',
        subtitle: '快去挑选心仪的商品吧',
        actionText: '去逛逛',
        onAction: onGo,
      );

  factory EmptyState.order() => const EmptyState(
        icon: Icons.receipt_long_outlined,
        title: '暂无订单',
      );

  factory EmptyState.favorite() => const EmptyState(
        icon: Icons.favorite_border_outlined,
        title: '还没有收藏',
        subtitle: '收藏喜欢的商品，方便下次查看',
      );

  factory EmptyState.address({VoidCallback? onAdd}) => EmptyState(
        icon: Icons.location_on_outlined,
        title: '暂无收货地址',
        actionText: '去添加',
        onAction: onAdd,
      );

  factory EmptyState.message() => const EmptyState(
        icon: Icons.notifications_none_outlined,
        title: '暂无消息',
      );

  factory EmptyState.network({VoidCallback? onRetry}) => EmptyState(
        icon: Icons.wifi_off_outlined,
        title: '网络异常',
        subtitle: '请检查网络后重试',
        actionText: '点击重试',
        onAction: onRetry,
      );

  // ── 构建 ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 占位图标（设计交付插画后替换为 Image.asset）
            Icon(icon, size: 64.r, color: AppColors.textDisabled),
            SizedBox(height: 16.h),
            Text(
              title,
              style: TextStyle(
                fontSize: AppFontSize.subtitle.sp,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              SizedBox(height: 8.h),
              Text(
                subtitle!,
                style: TextStyle(
                  fontSize: AppFontSize.small.sp,
                  color: AppColors.textHint,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionText != null && onAction != null) ...[
              SizedBox(height: 24.h),
              TextButton(
                onPressed: onAction,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg.w, vertical: AppSpacing.sm.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.button.r),
                    side: const BorderSide(color: AppColors.primary),
                  ),
                ),
                child: Text(actionText!,
                    style: TextStyle(fontSize: AppFontSize.body.sp)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
