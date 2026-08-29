/// 站点内容模块:书源 / 书源合集 / 订阅源 / 订阅源合集
enum SrcModule {
  shuyuan('shuyuan', '书源'),
  shuyuans('shuyuans', '书源合集'),
  rss('rss', '订阅源'),
  rsss('rsss', '订阅源合集');

  final String path; // URL 路径段,如 /yuedu/{path}/...
  final String label;
  const SrcModule(this.path, this.label);
}

/// 通用条目:列表页 `div.ylist` 卡片解析出的统一对象。
/// 各模块字段略有差异,不存在的字段为空字符串/空列表。
class SourceItem {
  final SrcModule module;
  final String id;
  final String title;
  final String time;

  /// 附加标签,如 版本 / 功能(发搜图声)/ 源数量 / 其它 layui-font-* 文本
  final List<String> tags;
  final String author; // 发布者
  final String downloads; // 下载量文本
  final String detailUrl;
  final String jsonUrl;

  SourceItem({
    required this.module,
    required this.id,
    required this.title,
    required this.time,
    required this.tags,
    required this.author,
    required this.downloads,
    required this.detailUrl,
    required this.jsonUrl,
  });

  /// 搜索匹配:标题、作者、附加标签
  bool matches(String kw) {
    if (kw.isEmpty) return true;
    final k = kw.toLowerCase();
    if (title.toLowerCase().contains(k)) return true;
    if (author.toLowerCase().contains(k)) return true;
    for (final t in tags) {
      if (t.toLowerCase().contains(k)) return true;
    }
    return false;
  }
}