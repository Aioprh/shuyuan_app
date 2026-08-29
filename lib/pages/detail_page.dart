import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../models/source_item.dart';
import '../services/api_service.dart';

/// 内容详情:抓取单条 JSON(书源 / 合集 / 订阅源通用),支持复制 / 分享。
class DetailPage extends StatefulWidget {
  final SourceItem item;
  const DetailPage({super.key, required this.item});

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  final _api = ApiService();
  String? _json;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final json = await _api.fetchJson(widget.item);
      if (!mounted) return;
      setState(() {
        _json = json;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _copy() async {
    final json = _json ?? '';
    await Clipboard.setData(ClipboardData(text: json));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已复制 JSON,可粘贴到「阅读」App'),
          duration: Duration(seconds: 2)),
    );
  }

  /// 「网络导入」:复制公开 JSON 地址,供「阅读」→ 网络导入使用。
  /// 比系统分享更可靠,兼容更多设备。
  Future<void> _copyImportUrl() async {
    await Clipboard.setData(ClipboardData(text: widget.item.jsonUrl));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('已复制导入地址,请在「阅读」用「网络导入」'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _share() => Share.share(_json ?? '', subject: widget.item.title);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text(widget.item.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            tooltip: '网络导入(复制地址)',
            onPressed: _copyImportUrl,
            icon: const Icon(Icons.link),
          ),
          IconButton(
            tooltip: '复制 JSON',
            onPressed: (_json == null) ? null : _copy,
            icon: const Icon(Icons.copy),
          ),
          IconButton(
            tooltip: '分享',
            onPressed: (_json == null) ? null : _share,
            icon: const Icon(Icons.share),
          ),
        ],
      ),
      body: _buildBody(context, Theme.of(context).colorScheme),
    );
  }

  Widget _buildBody(BuildContext context, ColorScheme scheme) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 52, color: Colors.grey),
            const SizedBox(height: 12),
            Text('获取失败:\n$_error', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: _load, child: const Text('重试')),
          ],
        ),
      );
    }
    return Column(
      children: [
        _InfoBar(item: widget.item),
        const Divider(height: 1),
        Expanded(
          child: Container(
            width: double.infinity,
            color: const Color(0xFF0D1117),
            padding: const EdgeInsets.all(12),
            child: SingleChildScrollView(
              child: SelectableText(
                _json ?? '',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: Color(0xFFE6EDF3),
                  height: 1.5,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// 顶部信息与导入指引
class _InfoBar extends StatelessWidget {
  final SourceItem item;
  const _InfoBar({required this.item});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      color: scheme.surfaceContainerLow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📖 如何导入「阅读」App',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          const Text(
            '方式一(推荐)·网络导入:点右上角链接⚓复制导入地址\n'
            '   → 「阅读」书源/订阅源管理 → ⋮ → 网络导入 → 粘贴地址导入\n'
            '方式二·粘贴导入:点「复制」复制下方 JSON 后粘贴导入\n'
            '方式三·分享:通过系统分享发给「阅读」(部分设备不支持此方式)',
            style: TextStyle(fontSize: 12.5, height: 1.6),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              Chip(label: Text('ID:${item.id}'), visualDensity: VisualDensity.compact),
              Chip(
                label: Text('类型:${item.module.label}'),
                visualDensity: VisualDensity.compact,
              ),
              if (item.downloads.isNotEmpty)
                Chip(
                  label: Text('下载:${item.downloads}'),
                  visualDensity: VisualDensity.compact,
                ),
              for (final t in item.tags.take(4))
                Chip(
                  label: Text(t),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
        ],
      ),
    );
  }
}