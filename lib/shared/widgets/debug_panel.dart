import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../core/di/app_providers.dart';
import '../../core/flavor/flavor.dart';
import '../../core/privacy/privacy_service.dart';

/// 开发者面板——仅在 dev/test 环境渲染，prod/pre 返回空组件。
/// 路由：context.push(AppRoutes.debug)
class DebugPanel extends ConsumerStatefulWidget {
  const DebugPanel({super.key});

  @override
  ConsumerState<DebugPanel> createState() => _DebugPanelState();
}

class _DebugPanelState extends ConsumerState<DebugPanel> {
  PackageInfo? _info;
  String? _token;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final info = await PackageInfo.fromPlatform();
    final token = await ref.read(authServiceProvider).getToken();
    if (!mounted) return;
    setState(() {
      _info = info;
      _token = token;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!FlavorConfig.isDevOrTest) return const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Developer Panel'),
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
      ),
      backgroundColor: const Color(0xFF1A1A1A),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: EdgeInsets.all(16.w),
              children: [
                _section('Environment'),
                _tile('Flavor', FlavorConfig.current.flavor.name.toUpperCase()),
                _tile('Base URL', FlavorConfig.current.baseUrl),
                _tile('App ID (Alipay)', FlavorConfig.current.alipayAppId.isEmpty
                    ? '(not set)'
                    : FlavorConfig.current.alipayAppId),
                _section('Build'),
                _tile('Version', '${_info?.version ?? '--'} (${_info?.buildNumber ?? '--'})'),
                _tile('Package', _info?.packageName ?? '--'),
                _section('Auth'),
                _tile(
                  'Token',
                  _token != null
                      ? '${_token!.substring(0, math.min(24, _token!.length))}…'
                      : '(none)',
                ),
                const SizedBox(height: 8),
                _action('Copy Token', Icons.copy_outlined, _copyToken),
                _action('Clear Token (Logout)', Icons.logout, _clearToken),
                _section('Privacy'),
                _action('Reset Privacy Agreement', Icons.privacy_tip_outlined, _resetPrivacy),
              ],
            ),
    );
  }

  Widget _section(String title) => Padding(
        padding: EdgeInsets.fromLTRB(0, 16.h, 0, 4.h),
        child: Text(
          title.toUpperCase(),
          style: TextStyle(fontSize: 11.sp, color: Colors.grey, letterSpacing: 1.2),
        ),
      );

  Widget _tile(String label, String value) => Container(
        margin: EdgeInsets.only(bottom: 1.h),
        color: const Color(0xFF2A2A2A),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        child: Row(
          children: [
            Text(label, style: TextStyle(fontSize: 13.sp, color: Colors.grey[400])),
            const Spacer(),
            Flexible(
              child: Text(
                value,
                style: TextStyle(fontSize: 13.sp, color: Colors.white),
                textAlign: TextAlign.right,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );

  Widget _action(String label, IconData icon, VoidCallback onTap) => ListTile(
        tileColor: const Color(0xFF2A2A2A),
        leading: Icon(icon, color: const Color(0xFFFF5000), size: 20.r),
        title: Text(label, style: TextStyle(fontSize: 14.sp, color: Colors.white)),
        trailing: Icon(Icons.chevron_right, color: Colors.grey, size: 18.r),
        onTap: onTap,
      );

  Future<void> _copyToken() async {
    if (_token == null) {
      _showSnack('No token to copy');
      return;
    }
    await Clipboard.setData(ClipboardData(text: _token!));
    _showSnack('Token copied to clipboard');
  }

  Future<void> _clearToken() async {
    await ref.read(authServiceProvider).clearToken();
    _showSnack('Token cleared — router will redirect to login');
    await _load();
  }

  Future<void> _resetPrivacy() async {
    await PrivacyService.clearAgreement();
    _showSnack('Privacy agreement reset — will show consent on next cold start');
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), duration: const Duration(seconds: 2)));
  }
}
