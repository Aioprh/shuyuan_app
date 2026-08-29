/// 站点的 App 板块:一个板块对应一款阅读/影视 App 的资源分区。
/// URL 前缀都是 `$baseHost/${path}/...`,详见 ApiService。
enum SrcApp {
  yuedu('yuedu', '开源阅读'),
  legadotauri('legadotauri', 'Legado-Tauri'),
  qysg('qysg', '轻悦时光'),
  yiciyuan('yiciyuan', '异次元');

  final String path; // URL 路径段,如 /yuedu/
  final String label;
  const SrcApp(this.path, this.label);
}

/// 内容模块:书源 / 合集 / 图源 / TTS / 订阅源 等。
/// 同一个 module 可以被多个 App 共享。
/// URL 拼接规则:
///   - 默认 `${SrcApp.path}/${SrcModule.path}`;
///   - 当 [apiPath] 非空时覆盖 App 前缀(如猫番漫画源挂在 /maofan/ 下,
///     但作为子模块归入「开源阅读 / 漫画」)。完整前缀由 [ApiService.urlBase] 计算。
enum SrcModule {
  shuyuan('shuyuan', '书源'),
  shuyuans('shuyuans', '书源合集'),
  rss('rss', '订阅源'),
  rsss('rsss', '订阅源合集'),
  tts('tts', 'TTS 语音源'),
  ttss('ttss', 'TTS 合集'),
  tuyuan('tuyuan', '图源'),
  tuyuans('tuyuans', '图源合集'),
  yuan('yuan', '漫画', apiPath: 'maofan'),
  yuans('yuans', '漫画合集', apiPath: 'maofan');

  final String path;
  final String label;

  /// 覆盖 App 前缀的 API 路径段(如 'maofan'),为空则用 App.path
  final String? apiPath;
  const SrcModule(this.path, this.label, {this.apiPath});
}

/// 每个 App 下有哪些 源类 模块(底部 nav 的第一个 tab 内部 TabBar 切换)
final Map<SrcApp, List<SrcModule>> kAppSources = {
  SrcApp.yuedu:       [SrcModule.shuyuan, SrcModule.rss, SrcModule.yuan],
  SrcApp.legadotauri: [SrcModule.shuyuan],
  SrcApp.qysg:        [SrcModule.shuyuan, SrcModule.tts],
  SrcApp.yiciyuan:    [SrcModule.tuyuan],
};

/// 每个 App 下有哪些 合集类 模块(底部 nav 的第二个 tab 内部 TabBar 切换)
final Map<SrcApp, List<SrcModule>> kAppCollections = {
  SrcApp.yuedu:       [SrcModule.shuyuans, SrcModule.rsss, SrcModule.yuans],
  SrcApp.legadotauri: [SrcModule.shuyuans],
  SrcApp.qysg:        [SrcModule.shuyuans, SrcModule.ttss],
  SrcApp.yiciyuan:    [SrcModule.tuyuans],
};

/// 每个 App 下所有可用模块(源类 + 合集类),用于发布页选择
List<SrcModule> allModulesFor(SrcApp app) {
  return [...kAppSources[app]!, ...kAppCollections[app]!];
}

/// 通用条目:列表页 `div.ylist` 卡片解析出的统一对象。
/// 各模块字段略有差异,不存在的字段为空字符串/空列表。
class SourceItem {
  final SrcApp app; // 所属 App 板块
  final SrcModule module; // 所属模块
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
    required this.app,
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
