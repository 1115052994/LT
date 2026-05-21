import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../core/theme/tokens.dart';

// 统一网络图片组件——业务层禁止直接用 CachedNetworkImage / Image.network
// 强制按 width × dpr 推算解码尺寸，防止裸 PNG 原图撑爆内存
class AppNetworkImage extends StatelessWidget {
  final String url;
  final double width;
  final double height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const AppNetworkImage({
    super.key,
    required this.url,
    required this.width,
    required this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.of(context).devicePixelRatio;
    // 按逻辑宽 × dpr 计算解码宽，上限 1080px，下限 100px
    final cacheWidth = (width * dpr).round().clamp(100, 1080);

    Widget image = CachedNetworkImage(
      imageUrl: url,
      width: width,
      height: height,
      fit: fit,
      memCacheWidth: cacheWidth,
      fadeInDuration: const Duration(milliseconds: 100),
      placeholder: (ctx, url) => _Placeholder(width: width, height: height),
      errorWidget:  (ctx, url, err) => _ErrorImage(width: width, height: height),
    );

    if (borderRadius != null) {
      image = ClipRRect(borderRadius: borderRadius!, child: image);
    }
    return image;
  }
}

class _Placeholder extends StatelessWidget {
  final double width;
  final double height;
  const _Placeholder({required this.width, required this.height});

  @override
  Widget build(BuildContext context) => Container(
        width: width,
        height: height,
        color: AppColors.background,
        child: const Center(
          child: CircularProgressIndicator(strokeWidth: 1.5),
        ),
      );
}

class _ErrorImage extends StatelessWidget {
  final double width;
  final double height;
  const _ErrorImage({required this.width, required this.height});

  @override
  Widget build(BuildContext context) => Container(
        width: width,
        height: height,
        color: AppColors.background,
        child: Icon(Icons.image_not_supported_outlined,
            color: AppColors.textHint, size: (width * 0.3).clamp(16, 48)),
      );
}
