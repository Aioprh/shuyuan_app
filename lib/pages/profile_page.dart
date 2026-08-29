import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/session_store.dart';
import 'login_page.dart';
import 'my_publishes_page.dart';
import 'webview_page.dart';

/// 我的:登录状态、原站其它工具(应用内打开)、关于
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  void initState() {
    super.initState();
    _reloadSession();
  }

  Future<void> _reloadSession() async {
    await SessionStore.instance.load();
    if (mounted) setState(() {});
  }

  Future<void> _openInApp(String url, String title) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WebViewPage(url: url, title: title),
      ),
    );
  }

  Future<void> _login() async {
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
    if (ok == true) await _reloadSession();
  }

  Future<void> _logout() async {
    await SessionStore.instance.clear();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final logged = SessionStore.instance.loggedIn;
    final email = SessionStore.instance.email;
    return Scaffold(
      appBar: AppBar(title: const Text('我的')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 登录状态卡片
          Card(
            child: ListTile(
              leading: Icon(logged ? Icons.verified_user : Icons.login,
                  color: logged ? Colors.green : scheme.primary),
              title: Text(logged ? '已登录' : '登录 / 绑定站点帐号'),
              subtitle: Text(logged
                  ? (email.isNotEmpty ? email : '已同步站点会话,可在「新建」发布')
                  : '发布内容、管理你的书源需要登录'),
              trailing: logged
                  ? TextButton(onPressed: _logout, child: const Text('退出'))
                  : const Icon(Icons.chevron_right),
              onTap: logged ? null : _login,
            ),
          ),
          const SizedBox(height: 8),
          // 我的发布:本应用内成功提交的历史
          Card(
            child: ListTile(
              leading: Icon(Icons.published_with_changes, color: scheme.primary),
              title: const Text('我的发布'),
              subtitle: const Text('本应用内成功提交的书源 / 订阅源历史'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const MyPublishesPage()),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text('原站其它功能(应用内打开)',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          _LinkCard(
            icon: Icons.link,
            title: '地址发布页(防丢)',
            subtitle: ApiService.addressUrl,
            onTap: () => _openInApp(ApiService.addressUrl, '地址发布页'),
          ),
          _LinkCard(
            icon: Icons.palette_outlined,
            title: '主题相关',
            subtitle: '阅读 App 主题主页',
            onTap: () => _openInApp(ApiService.themeUrl, '主题相关'),
          ),
          _LinkCard(
            icon: Icons.menu_book_outlined,
            title: '教程:书源规则',
            subtitle: '学习如何编写书源规则',
            onTap: () => _openInApp(ApiService.shuyuanRuleUrl, '书源规则教程'),
          ),
          _LinkCard(
            icon: Icons.rss_feed,
            title: '教程:RSS 规则',
            subtitle: '学习如何编写订阅源规则',
            onTap: () => _openInApp(ApiService.rssRuleUrl, 'RSS 规则教程'),
          ),
          const SizedBox(height: 12),
          _LinkCard(
            icon: Icons.code,
            title: '开源地址',
            subtitle: ApiService.openSourceUrl,
            onTap: () => _openInApp(ApiService.openSourceUrl, '开源地址'),
          ),
          Card(
            child: ListTile(
              leading: Icon(Icons.info_outline, color: scheme.primary),
              title: const Text('书源仓库'),
              subtitle: Text('数据来自 ${ApiService.baseHost}\n书源 / 合集 / 订阅源一网打尽',
                  style: const TextStyle(fontSize: 12.5, height: 1.5)),
            ),
          ),
        ],
      ),
    );
  }
}

class _LinkCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _LinkCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}