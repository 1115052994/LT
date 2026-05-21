import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'privacy_service.dart';

/// 隐私合规守门组件。
/// 首次启动弹出《用户协议》《隐私政策》同意框；未同意前不渲染子组件（即不初始化任何 SDK）。
/// 用法：runApp(PrivacyGate(child: App()))
class PrivacyGate extends StatefulWidget {
  const PrivacyGate({super.key, required this.child});

  final Widget child;

  @override
  State<PrivacyGate> createState() => _PrivacyGateState();
}

class _PrivacyGateState extends State<PrivacyGate> {
  // null = 检查中，true = 已同意，false = 未同意
  bool? _agreed;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final agreed = await PrivacyService.hasAgreed();
    setState(() => _agreed = agreed);
  }

  Future<void> _onAgree() async {
    await PrivacyService.setAgreed();
    setState(() => _agreed = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_agreed == null) {
      // 检查中：纯白闪屏，避免内容闪烁
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(backgroundColor: Colors.white),
      );
    }
    if (_agreed!) return widget.child;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: _PrivacyConsentPage(onAgree: _onAgree),
    );
  }
}

class _PrivacyConsentPage extends StatelessWidget {
  const _PrivacyConsentPage({required this.onAgree});

  final VoidCallback onAgree;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            children: [
              const Spacer(),
              // App 图标占位
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF5000),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.shopping_bag, color: Colors.white, size: 40),
              ),
              const SizedBox(height: 24),
              const Text(
                '欢迎使用 Shop',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
              ),
              const SizedBox(height: 16),
              const Text(
                '在使用前，请阅读并同意以下协议，我们将严格依据协议保护您的个人信息安全。',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Color(0xFF666666), height: 1.6),
              ),
              const SizedBox(height: 16),
              _AgreementLinks(),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: onAgree,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF5000),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    elevation: 0,
                  ),
                  child: const Text('同意并继续', style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => SystemNavigator.pop(),
                child: const Text('不同意，退出', style: TextStyle(color: Color(0xFF999999), fontSize: 13)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AgreementLinks extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      children: [
        const Text('《', style: TextStyle(fontSize: 13, color: Color(0xFF666666))),
        GestureDetector(
          onTap: () {
            // TODO: 跳转隐私政策 H5（context.push('/webview?url=...&title=隐私政策')）
          },
          child: const Text('隐私政策', style: TextStyle(fontSize: 13, color: Color(0xFFFF5000))),
        ),
        const Text('》和《', style: TextStyle(fontSize: 13, color: Color(0xFF666666))),
        GestureDetector(
          onTap: () {
            // TODO: 跳转用户协议 H5
          },
          child: const Text('用户协议', style: TextStyle(fontSize: 13, color: Color(0xFFFF5000))),
        ),
        const Text('》', style: TextStyle(fontSize: 13, color: Color(0xFF666666))),
      ],
    );
  }
}
