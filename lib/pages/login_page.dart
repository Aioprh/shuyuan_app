import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../services/api_service.dart';
import '../services/session_store.dart';

/// 应用内登录:在 WebView 中完成 Gitee OAuth 后,
/// 把 yckceo.com 的会话 Cookie 同步到 SessionStore,
/// 使「新建/发布」能以已登录身份提交。
/// 登录成功并保存后,以 `Navigator.pop(true)` 返回。
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late final WebViewController _controller;
  bool _loading = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) {
              setState(() {
                _loading = true;
                _error = false;
              });
            }
          },
          onPageFinished: (url) {
            if (mounted) {
              setState(() => _loading = false);
            }
            _trySync(fromAutoDetect: true, currentUrl: url);
          },
          onWebResourceError: (_) {
            if (mounted) setState(() => _error = true);
          },
        ),
      )
      ..loadRequest(Uri.parse(ApiService.loginUrl));
  }

  /// 从 WebView 读取并同步 Cookie。cookie 非空即视为登录成功。
  Future<String> _trySync({required bool fromAutoDetect, String currentUrl = ''}) async {
    final isBackOnSite = currentUrl.startsWith(ApiService.baseHost) &&
        !currentUrl.contains('/login');
    if (fromAutoDetect && !isBackOnSite) {
      return ''; // 还在登录/授权页,不自动同步
    }
    final list =
        await WebViewCookieManager().getCookies(domain: Uri.parse(ApiService.baseHost));
    if (list.isEmpty) return '';
    final parts = <String>[];
    for (final c in list) {
      if (c.name.isEmpty || c.value.isEmpty) continue;
      parts.add('${c.name}=${c.value}');
    }
    if (parts.isEmpty) return '';
    final header = parts.join('; ');
    await SessionStore.instance.save(cookieHeader: header);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('登录成功,已可在「新建」发布'), duration: Duration(seconds: 2)),
      );
      Navigator.of(context).pop(true);
    }
    return header;
  }

  Future<void> _finish() async {
    final saved = await _trySync(fromAutoDetect: false);
    if (saved.isEmpty && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('未检测到登录,请先在页面内登录后重试')),
      );
    }
  }

  Future<void> _reload() async {
    setState(() {
      _error = false;
      _loading = true;
    });
    await _controller.reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('登录站点帐号'),
        actions: [
          TextButton(onPressed: _finish, child: const Text('完成登录')),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_loading && !_error)
            const Positioned(top: 0, left: 0, right: 0, child: LinearProgressIndicator()),
          if (_error)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('页面加载失败,请检查网络'),
                  const SizedBox(height: 8),
                  FilledButton(onPressed: _reload, child: const Text('重试')),
                ],
              ),
            ),
        ],
      ),
    );
  }
}