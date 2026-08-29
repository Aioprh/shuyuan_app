import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../models/source_item.dart';
import '../services/api_service.dart';
import 'detail_page.dart';

/// 通用内容列表页:搜索 + 无限滚动 + 下拉刷新 + 详情跳转。
/// [enableBatch] 为 true 时支持多选批量导出 JSON(书源列表)。
class SourceListPage extends StatefulWidget {
  final SrcApp app;
  final SrcModule module;
  final bool enableBatch;
  const SourceListPage({
    super.key,
    this.app = SrcApp.yuedu,
    required this.module,
    this.enableBatch = false,
  });

  @override
  State<SourceListPage> createState() => _SourceListPageState();
}

class _SourceListPageState extends State<SourceListPage> {
  final _api = ApiService();
  final _scroll = ScrollController();
  final _searchCtrl = TextEditingController();

  final List<SourceItem> _all = [];
  List<SourceItem> _filtered = [];
  int _page = 1;
  bool _loading = false;
  bool _loadingMore = false;
  bool _hasMore = true;

  /// 搜索中,后台继续翻页补足匹配结果
  bool _searchLoading = false;
  String _searchKw = '';
  static const _autoSearchTarget = 30; // 至少攒够 30 条匹配结果
  static const _autoSearchMaxPages = 50; // 最多再翻 50 页,避免过载
  int _searchedPages = 0;

  // 多选批量导出状态
  bool _batchMode = false;
  final Set<String> _selected = {};

  @override
  void initState() {
    super.initState();
    _loadFirst();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      title: Text(widget.module.label),
      actions: [
        if (widget.enableBatch)
          IconButton(
            tooltip: _batchMode
                ? '取消多选'
                : '批量导出(勾选后导出 JSON)',
            onPressed: () {
              setState(() {
                _batchMode = !_batchMode;
                _selected.clear();
              });
            },
            icon: Icon(_batchMode ? Icons.close : Icons.library_add_check),
          ),
        if (_batchMode)
          TextButton(
            onPressed: _selected.isEmpty ? null : _exportSelected,
            child: Text('导出(${_selected.length})'),
          ),
      ],
      bottom: _batchMode
          ? PreferredSize(
              preferredSize: const Size.fromHeight(0),
              child: const SizedBox.shrink(),
            )
          : PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (_) {
                    setState(_applyFilter);
                    _maybeAutoSearch();
                  },
                  decoration: InputDecoration(
                    hintText: '搜索标题 / 作者 / 标签',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchCtrl.text.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() {
                                _searchKw = '';
                                _searchedPages = 0;
                                _applyFilter();
                              });
                            },
                          ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surfaceContainerHigh,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                ),
              ),
            ),
    );
  }

  Future<void> _loadFirst() async {
    setState(() {
      _loading = true;
      _searchKw = _searchCtrl.text.trim();
      _searchedPages = 0;
    });
    final list = await _api.fetchPage(widget.app, widget.module, 1);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _page = 1;
      _all
        ..clear()
        ..addAll(list);
      _hasMore = true;
      if (list.isEmpty) _hasMore = false;
      _applyFilter();
    });
    // 如果此时处于搜索态且结果稀疏,自动继续翻页补足
    _maybeAutoSearch();
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore || _loading) return;
    setState(() => _loadingMore = true);
    final next = _page + 1;
    final list = await _api.fetchPage(widget.app, widget.module, next);
    if (!mounted) return;
    setState(() {
      _loadingMore = false;
      if (list.isEmpty) {
        _hasMore = false;
      } else {
        _page = next;
        _all.addAll(list);
        _applyFilter();
      }
    });
  }

  /// 批量翻页,一次抓完 [target] 页,避免"一条条"加载
  Future<void> _loadPages(int count) async {
    for (var i = 0; i < count; i++) {
      if (!_hasMore || !mounted) break;
      await _loadMore();
    }
  }

  /// 搜索态下,大批量连续翻页补足匹配结果
  Future<void> _autoSearch() async {
    if (_searchKw.isEmpty || !_hasMore) return;
    if (_filtered.length >= _autoSearchTarget) {
      if (!mounted) return;
      setState(() => _searchLoading = false);
      return;
    }
    if (_searchedPages >= _autoSearchMaxPages) {
      if (!mounted) return;
      setState(() => _searchLoading = false);
      return;
    }
    // 一轮补足若干页(每页约 100 条),让结果尽快铺满,减少逐条闪烁
    const batch = 6;
    final targetCount =
        _searchedPages + batch > _autoSearchMaxPages
            ? _autoSearchMaxPages - _searchedPages
            : batch;
    _searchedPages += targetCount;
    await _loadPages(targetCount);
    if (!mounted) return;
    if (_searchKw.isNotEmpty && _hasMore && _filtered.length < _autoSearchTarget) {
      _autoSearch();
    } else if (mounted) {
      setState(() => _searchLoading = false);
    }
  }

  void _maybeAutoSearch() {
    final kw = _searchCtrl.text.trim();
    if (kw.isEmpty || !_hasMore) return;
    if (_filtered.length >= _autoSearchTarget) return;
    if (_searchLoading) return;
    // 用户一输入就立即后台翻页补足
    setState(() {
      _searchKw = kw;
      _searchedPages = 0;
      _searchLoading = true;
    });
    _autoSearch();
  }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 300) {
      _loadMore();
    }
  }

  void _applyFilter() {
    final kw = _searchCtrl.text.trim();
    _filtered = kw.isEmpty
        ? List.of(_all)
        : _all.where((e) => e.matches(kw)).toList();
  }

  Future<void> _exportSelected() async {
    final items = _all.where((e) => _selected.contains(e.id)).toList();
    final ids = items.map((e) => e.id).toList();
    setState(() => _batchMode = false);
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BatchExportPage(items: items, ids: ids),
      ),
    );
  }

  Future<void> _openDetail(SourceItem item) async {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => DetailPage(item: item)),
    );
  }

  void _toggleSelect(SourceItem item) {
    setState(() {
      if (_selected.contains(item.id)) {
        _selected.remove(item.id);
      } else {
        _selected.add(item.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: _buildBody(),
      floatingActionButton: _all.isEmpty || _batchMode
          ? null
          : FloatingActionButton.extended(
              heroTag: 'refresh${widget.module.path}',
              onPressed: _loadFirst,
              icon: const Icon(Icons.refresh),
              label: const Text('刷新'),
            ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_filtered.isEmpty) {
      // 搜索中结果暂空:展示自动翻页进度,别误报"无结果"
      if (_searchLoading) {
        return ListView(
          controller: _scroll,
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 200),
            Center(child: SearchProgressHint()),
          ],
        );
      }
      return RefreshIndicator(
        onRefresh: _loadFirst,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 120),
            Center(child: Text('没有匹配的内容,下拉刷新')),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadFirst,
      child: ListView.builder(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 90),
        itemCount: _filtered.length + 1,
        itemBuilder: (ctx, i) {
          if (i == _filtered.length) return _buildFooter();
          final item = _filtered[i];
          return _SourceCard(
            item: item,
            batch: _batchMode,
            selected: _selected.contains(item.id),
            onTap: () => _batchMode ? _toggleSelect(item) : _openDetail(item),
          );
        },
      ),
    );
  }

  Widget _buildFooter() {
    if (_searchLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(child: SearchProgressHint()),
      );
    }
    if (_hasMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: SizedBox(
            width: 26,
            height: 26,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        ),
      );
    }
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 20),
      child: Center(child: Text('已加载全部', style: TextStyle(color: Colors.grey))),
    );
  }
}

/// 搜索中自动翻页时的进度提示
class SearchProgressHint extends StatelessWidget {
  const SearchProgressHint({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularProgressIndicator(strokeWidth: 2.5),
        SizedBox(height: 8),
        Text('搜索中,正在自动加载更多匹配结果…', style: TextStyle(fontSize: 12.5)),
      ],
    );
  }
}

/// 单卡片
class _SourceCard extends StatelessWidget {
  final SourceItem item;
  final bool batch;
  final bool selected;
  final VoidCallback onTap;
  const _SourceCard({
    required this.item,
    required this.batch,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: batch && selected ? scheme.primary : scheme.outlineVariant,
          width: batch && selected ? 2 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (batch) ...[
                Checkbox(value: selected, onChanged: (_) => onTap()),
                const SizedBox(width: 4),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 14.5, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    if (item.tags.isNotEmpty ||
                        item.author.isNotEmpty)
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          for (final t in item.tags.take(4))
                            _Tag(text: t, color: const Color(0xFFFFF3E0), fg: const Color(0xFFE65100)),
                          if (item.author.isNotEmpty)
                            _Tag(text: '作者:$item.author',
                                color: const Color(0xFFFCE4EC), fg: const Color(0xFFAD1457)),
                          if (item.downloads.isNotEmpty)
                            _Tag(text: item.downloads,
                                color: const Color(0xFFEDE7F6), fg: const Color(0xFF4527A0)),
                        ],
                      ),
                    if (item.time.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          item.time,
                          style: TextStyle(
                              fontSize: 12, color: scheme.onSurfaceVariant),
                        ),
                      ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(left: 4, top: 6),
                child: Icon(Icons.chevron_right, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;
  final Color color;
  final Color fg;
  const _Tag({required this.text, required this.color, required this.fg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11.5, color: fg, height: 1.4),
      ),
    );
  }
}

/// 批量导出结果页:抓取所选书源 JSON 并支持复制/分享
class BatchExportPage extends StatefulWidget {
  final List<SourceItem> items;
  final List<String> ids;
  const BatchExportPage({super.key, required this.items, required this.ids});

  @override
  State<BatchExportPage> createState() => _BatchExportPageState();
}

class _BatchExportPageState extends State<BatchExportPage> {
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
      final app = widget.items.first.app;
      final json = await _api.fetchBatch(app, widget.ids);
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
    await Clipboard.setData(ClipboardData(text: _json ?? ''));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text('已复制 ${widget.ids.length} 条书源 JSON,可粘贴导入「阅读」'),
          duration: const Duration(seconds: 2)),
    );
  }

  void _share() => Share.share(_json ?? '', subject: '批量书源');

  /// 网络导入:复制批量导出的公开地址,供「阅读」网络导入。
  Future<void> _copyBatchUrl() async {
    final appPath = widget.items.first.app.path;
    final url =
        '${ApiService.baseHost}/$appPath/shuyuan/jsons?id=${widget.ids.join(',')}';
    await Clipboard.setData(ClipboardData(text: url));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('已复制导入地址,请在「阅读」用「网络导入」'),
          duration: Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('批量导出(${widget.ids.length})'),
        actions: [
          IconButton(
            tooltip: '网络导入(复制地址)',
            onPressed: _copyBatchUrl,
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
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 52, color: Colors.grey),
            const SizedBox(height: 12),
            Text('导出失败:\n$_error', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: _load, child: const Text('重试')),
          ],
        ),
      );
    }
    return Container(
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
    );
  }
}