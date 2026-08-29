/// 站点的 App 板块:一个板块对应一款阅读/影视 App 的资源分区。
/// URL 前缀都是 `$baseHost/${path}/...`,详见 ApiService。
enum SrcApp {
  yuedu('yuedu', '开源阅读 (Legado)'),
  legadotauri('legadotauri', 'Legado-Tauri'),
  qysg('qysg', '轻悦时光'),
  yiciyuan('yiciyuan', '异次元'),
  maofan('maofan', '猫番阅读');

  final String path; // URL 路径段,如 /yuedu/
  final String label;
  const SrcApp(this.path, this.label);
}

/// 内容模块:书源 / 合集 / 图源 / TTS / 订阅源 等。
/// 同一个 module 可以被多个 App 共享(如 shuyuan 在 4 个 App 下都有),
/// 实际访问 URL 组合是 `${SrcApp.path}/${SrcModule.path}/...`。
enum SrcModule {
  shuyuan('shuyuan', '书源'),
  shuyuans('shuyuans', '书源合集'),
  rss('rss', '订阅源'),
  rsss('rsss', '订阅源合集'),
  tts('tts', 'TTS 语音源'),
  ttss('ttss', 'TTS 合集'),
  tuyuan('tuyuan', '图源'),
  tuyuans('tuyuans', '图源合集'),
  yuan('yuan', '图源(猫番)'),
  yuans('yuans', '图源合集(猫番)');

  final String path;
  final String label;
  const SrcModule(this.path, this.label);
}

/// 各 App 下可用的「主板块」列表(底部导航 4 个 tab 对应的模块)。
/// 顺序即为 tab 顺序:书源 / 合集 / 补充1 / 补充2 / (新建 / 我的 在主框架)
final Map<SrcApp, List<SrcModule>> kAppTabs = {
  SrcApp.yuedu:      [SrcModule.shuyuan, SrcModule.shuyuans, SrcModule.rss,   SrcModule.rsss],
  SrcApp.legadotauri:[SrcModule.shuyuan, SrcModule.shuyuans, SrcModule.shuyuan, SrcModule.shuyuan],
  SrcApp.qysg:       [SrcModule.shuyuan, SrcModule.shuyuans, SrcModule.tts,   SrcModule.ttss],
  SrcApp.yiciyuan:   [SrcModule.tuyuan,  SrcModule.tuyuans,  SrcModule.tuyuan, SrcModule.tuyuan],
  SrcApp.maofan:     [SrcModule.yuan,    SrcModule.yuans,    SrcModule.yuan,   SrcModule.yuan],
};

/// tab 文案:固定 4 个位置,对某些 App 后半两个 tab 可能没资源,此时隐藏。
const List<String> kTabLabels = ['书源', '合集', '补充 1', '补充 2'];

/// 哪些 App 有订阅源 / TTS / 图源 等特殊模块,用于在 UI 里动态切换 tab 文案。
String tabLabelFor(SrcApp app, int index) {
  if (index == 0) return '书源';
  if (index == 1) return '合集';
  final mods = kAppTabs[app]!;
  if (mods[index].label.contains('TTS')) return mods[index].label;
  if (mods[index].label.contains('订阅')) return mods[index].label;
  if (mods[index].label.contains('图源')) return mods[index].label;
  return mods[index].label;
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