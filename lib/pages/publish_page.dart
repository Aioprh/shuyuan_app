import 'dart:convert';

import 'package:flutter/material.dart';

import '../models/source_item.dart';
import '../services/api_service.dart';
import '../services/publish_store.dart';
import 'login_page.dart';

/// 新建 / 发布:向站点提交 JSON 代码。
/// App 板块 + 资源类型都在页面内选择,兼容 yuedu / qysg / yiciyuan / legadotauri。
/// 需登录站点帐号。
class PublishPage extends StatefulWidget {
  const PublishPage({super.key});

  @override
  State<PublishPage> createState() => _PublishPageState();
}

class _PublishPageState extends State<PublishPage> {
  final _api = ApiService();
  final _codeCtrl = TextEditingController();
  SrcApp _app = SrcApp.yuedu;
  SrcModule _module = SrcModule.shuyuan;
  bool _manga = false;
  bool _audio = false;
  bool _submitting = false;

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  /// 切换 App 时,自动把 module 重置为该 App 的第一个可用模块
  void _setApp(SrcApp a) {
    setState(() {
      _app = a;
      _module = kAppSources[a]!.first;
    });
  }

  /// 当前 App 下可用的资源模块(去重,源类优先)
  List<SrcModule> get _availableModules {
    final seen = <SrcModule>{};
    final list = <SrcModule>[];
    for (final m in allModulesFor(_app)) {
      if (seen.add(m)) list.add(m);
    }
    return list;
  }

  Future<void> _submit() async {
    final code = _codeCtrl.text.trim();
    if (code.isEmpty) {
      _toast('请输入 JSON 源代码');
      return;
    }
    setState(() => _submitting = true);
    final (ok, msg) = await _api
        .publish(_app, _module, code: code, isManga: _manga, isAudio: _audio);
    if (!mounted) return;
    setState(() => _submitting = false);
    _toast(msg.isEmpty ? '已提交' : msg);
    if (ok) {
      await PublishStore.instance.add(PublishRecord(
        title: _extractName(code),
        appLabel: _app.label,
        moduleLabel: _module.label,
        code: code,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        serverMsg: msg,
      ));
      return;
    }
    if (msg.contains('登录')) {
      _askLogin();
    }
  }

  void _askLogin() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('需要登录'),
        content: const Text('发布内容需要登录站点帐号。是否在应用内登录?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _openLogin();
            },
            child: const Text('去登录'),
          ),
        ],
      ),
    );
  }

  Future<void> _openLogin() async {
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
    if (ok == true && mounted) {
      _toast('登录成功,请重新提交');
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 3)),
    );
  }

  /// 从 JSON 中提取展示名(bookSourceName),取不到则返回时间占位。
  String _extractName(String code) {
    try {
      final raw = code.trim().isEmpty ? null : jsonDecode(code);
      if (raw is List && raw.isNotEmpty) {
        final first = raw.first;
        if (first is Map && first['bookSourceName'] != null) {
          return first['bookSourceName'].toString();
        }
      } else if (raw is Map && raw['bookSourceName'] != null) {
        return raw['bookSourceName'].toString();
      }
    } catch (_) {}
    final t = DateTime.now();
    return '${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')} '
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('新建 / 发布'),
        actions: [
          IconButton(
            tooltip: '登录',
            onPressed: _openLogin,
            icon: const Icon(Icons.login),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('App 板块', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          SegmentedButton<SrcApp>(
            segments: const [
              ButtonSegment(value: SrcApp.yuedu, label: Text('开源阅读')),
              ButtonSegment(value: SrcApp.legadotauri, label: Text('Tauri')),
              ButtonSegment(value: SrcApp.qysg, label: Text('轻悦时光')),
              ButtonSegment(value: SrcApp.yiciyuan, label: Text('异次元')),
            ],
            selected: {_app},
            onSelectionChanged: (s) => _setApp(s.first),
          ),
          const SizedBox(height: 16),
          const Text('发布类型', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          SegmentedButton<SrcModule>(
            segments: _availableModules
                .map((m) => ButtonSegment<SrcModule>(
                      value: m,
                      label: Text(m.label),
                    ))
                .toList(),
            selected: {_module},
            onSelectionChanged: (s) => setState(() => _module = s.first),
          ),
          const SizedBox(height: 16),
          const Text('JSON 源代码(必填)',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: _codeCtrl,
            maxLines: 12,
            decoration: const InputDecoration(
              hintText: '粘贴 JSON 代码',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                value: _manga,
                onChanged: (v) => setState(() => _manga = v == true),
                title: const Text('标记为漫画', style: TextStyle(fontSize: 13)),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                value: _audio,
                onChanged: (v) => setState(() => _audio = v == true),
                title: const Text('标记为有声', style: TextStyle(fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _submitting ? null : _submit,
            icon: _submitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.send),
            label: Text(_submitting ? '提交中…' : '发布到 ${_app.label}'),
          ),
        ],
      ),
    );
  }
}
