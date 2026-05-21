import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/tokens.dart';
import 'app_scaffold.dart';
import 'empty_state.dart';

// 统一 H5 容器——活动页 / 协议页 / 帮助中心等纯展示 H5
// 本期不实现 JS Bridge，H5 与原生无业务交互
// 用法：context.push('/webview?url=xxx&title=活动')
class AppWebView extends StatefulWidget {
  final String url;
  final String? title;
  final bool showProgressBar;
  final bool pullToRefresh;

  const AppWebView({
    super.key,
    required this.url,
    this.title,
    this.showProgressBar = true,
    this.pullToRefresh = true,
  });

  @override
  State<AppWebView> createState() => _AppWebViewState();
}

class _AppWebViewState extends State<AppWebView> {
  InAppWebViewController? _controller;
  PullToRefreshController? _pullToRefreshController;
  String? _pageTitle;
  int _progress = 0;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _pageTitle = widget.title;

    if (widget.pullToRefresh) {
      _pullToRefreshController = PullToRefreshController(
        settings: PullToRefreshSettings(color: AppColors.primary),
        onRefresh: () async {
          await _controller?.reload();
          _pullToRefreshController?.endRefreshing();
        },
      );
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  // 安全校验白名单域（按项目实际域名补充）
  bool _isTrustedUrl(String? url) {
    if (url == null) return false;
    try {
      final uri = Uri.parse(url);
      // TODO: 替换为实际允许的域名列表
      const trustedHosts = ['example.com', 'api.example.com'];
      return trustedHosts.any((h) => uri.host.endsWith(h));
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _pageTitle ?? widget.title ?? 'H5';

    return AppScaffold(
      body: Column(
        children: [
          // 顶部标题栏
          _buildNavBar(context, title),
          // 进度条
          if (widget.showProgressBar && _progress < 100)
            LinearProgressIndicator(
              value: _progress / 100,
              backgroundColor: Colors.transparent,
              color: AppColors.primary,
              minHeight: 2,
            ),
          Expanded(
            child: _hasError
                ? EmptyState.network(onRetry: () {
                    setState(() => _hasError = false);
                    _controller?.reload();
                  })
                : InAppWebView(
                    initialUrlRequest:
                        URLRequest(url: WebUri(widget.url)),
                    pullToRefreshController: _pullToRefreshController,
                    initialSettings: InAppWebViewSettings(
                      // 安全
                      mixedContentMode:
                          MixedContentMode.MIXED_CONTENT_NEVER_ALLOW,
                      allowFileAccess: false,
                      allowUniversalAccessFromFileURLs: false,
                      // 不允许内容检视（release）
                      isInspectable: false,
                      useShouldOverrideUrlLoading: true,
                    ),
                    onWebViewCreated: (c) => _controller = c,
                    onProgressChanged: (c, p) =>
                        setState(() => _progress = p),
                    onTitleChanged: (c, t) {
                      if (widget.title == null && t != null) {
                        setState(() => _pageTitle = t);
                      }
                    },
                    onReceivedError: (c, req, err) =>
                        setState(() => _hasError = true),
                    // 拦截链接跳转
                    shouldOverrideUrlLoading: (c, action) async {
                      final url =
                          action.request.url?.toString() ?? '';
                      final scheme = Uri.tryParse(url)?.scheme ?? '';

                      // 系统协议（电话、邮件、短信）走系统
                      if (scheme == 'tel' ||
                          scheme == 'mailto' ||
                          scheme == 'sms') {
                        final uri = Uri.parse(url);
                        if (await canLaunchUrl(uri)) launchUrl(uri);
                        return NavigationActionPolicy.CANCEL;
                      }

                      // 非白名单外部链接用系统浏览器打开
                      if (scheme == 'http' || scheme == 'https') {
                        if (!_isTrustedUrl(url)) {
                          final uri = Uri.parse(url);
                          if (await canLaunchUrl(uri)) {
                            launchUrl(uri,
                                mode: LaunchMode.externalApplication);
                          }
                          return NavigationActionPolicy.CANCEL;
                        }
                      }

                      return NavigationActionPolicy.ALLOW;
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavBar(BuildContext context, String title) {
    return Container(
      height: kToolbarHeight,
      color: Colors.white,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(title,
              style: TextStyle(
                fontSize: AppFontSize.subtitle,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              )),
          Positioned(
            left: 4,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 20),
              color: AppColors.textPrimary,
              onPressed: () async {
                if (await _controller?.canGoBack() ?? false) {
                  _controller?.goBack();
                } else {
                  if (context.mounted) Navigator.of(context).pop();
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
