import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/publish_store.dart';

/// 我的发布:查看本应用内成功提交过的书源 / 订阅源历史。
/// 数据仅保存在本地,可回看源码、复制到剪贴板或删除。
class MyPublishesPage extends StatefulWidget {
  const MyPublishesPage({super.key});

  @override
  State<MyPublishesPage> createState() => _MyPublishesPageState();
}

class _MyPublishesPageState extends State<MyPublishesPage> {
  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    await PublishStore.instance.load();
    if (mounted) setState(() {});
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
    );
  }

  Future<void> _copy(PublishRecord r) async {
    await Clipboard.setData(ClipboardData(text: r.code));
    _toast('已复制到剪贴板');
  }

  Future<void> _confirmDelete(PublishRecord r) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除这条发布记录?'),
        content: Text(r.title.isEmpty ? '该记录' : '「${r.title}」'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await PublishStore.instance.removeAt(r.createdAt);
      if (!mounted) return;
      setState(() {});
      _toast('已删除');
    }
  }

  @override
  Widget build(BuildContext context) {
    final records = PublishStore.instance.records;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('我的发布')),
      body: records.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.inbox_outlined,
                      size: 56, color: scheme.outline),
                  const SizedBox(height: 12),
                  Text('暂无发布记录',
                      style: TextStyle(color: scheme.onSurfaceVariant)),
                  const SizedBox(height: 6),
                  Text('在「新建 / 发布」成功提交后会记录在这里',
                      style: TextStyle(fontSize: 12, color: scheme.outline)),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: records.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, i) => _recordTile(records[i]),
            ),
    );
  }

  Widget _recordTile(PublishRecord r) {
    final scheme = Theme.of(context).colorScheme;
    final t = DateTime.fromMillisecondsSinceEpoch(r.createdAt);
    final time =
        '${t.year}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')} '
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: scheme.primaryContainer,
          child: Icon(
            r.moduleLabel.contains('订阅') ? Icons.rss_feed : Icons.book_outlined,
            size: 20,
            color: scheme.onPrimaryContainer,
          ),
        ),
        title: Text(r.title.isEmpty ? '(未命名)' : r.title,
            maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          r.moduleLabel.isEmpty ? time : '$time · ${r.moduleLabel}',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (v) {
            switch (v) {
              case 'view':
                _showCode(r);
              case 'copy':
                _copy(r);
              case 'del':
                _confirmDelete(r);
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'view', child: Text('查看源码')),
            PopupMenuItem(value: 'copy', child: Text('复制源码')),
            PopupMenuItem(value: 'del', child: Text('删除')),
          ],
        ),
        onTap: () => _showCode(r),
      ),
    );
  }

  void _showCode(PublishRecord r) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _CodeViewPage(record: r),
      ),
    );
  }
}

/// 全屏查看单条发布源码,可复制。
class _CodeViewPage extends StatelessWidget {
  final PublishRecord record;
  const _CodeViewPage({required this.record});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('源码'),
        actions: [
          IconButton(
            tooltip: '复制',
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: record.code));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('已复制到剪贴板'),
                      duration: Duration(seconds: 2)),
                );
              }
            },
            icon: const Icon(Icons.copy),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SelectableText(
          record.code,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 12, height: 1.6),
        ),
      ),
    );
  }
}