import 'package:flutter/material.dart';

import 'models/source_item.dart';
import 'pages/detail_page.dart';
import 'pages/my_publishes_page.dart';
import 'pages/profile_page.dart';
import 'pages/publish_page.dart';
import 'pages/source_list_page.dart';
import 'services/session_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SessionStore.instance.load();
  runApp(const ShuYuanApp());
}

class ShuYuanApp extends StatelessWidget {
  const ShuYuanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '书源仓库',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4E6EF2),
          brightness: Brightness.light,
        ),
      ),
      home: const RootShell(),
    );
  }
}

/// App 图标映射(UI 层定义,避免 models 层依赖 Flutter)
IconData iconFor(SrcApp app) {
  switch (app) {
    case SrcApp.yuedu:
      return Icons.menu_book;
    case SrcApp.legadotauri:
      return Icons.laptop;
    case SrcApp.qysg:
      return Icons.wb_sunny;
    case SrcApp.yiciyuan:
      return Icons.extension;
    case SrcApp.maofan:
      return Icons.collections_bookmark;
  }
}

/// 底部导航主框架:顶部 App 切换 + 书源 / 合集 / 附加 / 新建 / 我的
class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  SrcApp _app = SrcApp.yuedu;
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final tabs = kAppTabs[_app]!;

    // 构造 4 个资源 tab 的页面,enableBatch 仅对「书源」模块开启
    final resourcePages = <Widget>[
      SourceListPage(
          app: _app, module: tabs[0], enableBatch: true),
      SourceListPage(app: _app, module: tabs[1]),
      SourceListPage(app: _app, module: tabs[2]),
      SourceListPage(app: _app, module: tabs[3]),
    ];

    // 顶部 AppBar 的标题(显示当前模块)
    final currentLabel = tabLabelFor(_app, _index);

    return Scaffold(
      appBar: AppBar(
        title: Text(currentLabel),
        actions: [
          _AppSwitcher(
            current: _app,
            onChanged: (a) {
              setState(() {
                _app = a;
                _index = 0; // 切 App 时回到「书源」tab
              });
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _index,
        children: [
          ...resourcePages,
          const PublishPage(),
          const ProfilePage(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.book_outlined),
            selectedIcon: const Icon(Icons.book),
            label: tabLabelFor(_app, 0),
          ),
          NavigationDestination(
            icon: const Icon(Icons.collections_bookmark_outlined),
            selectedIcon: const Icon(Icons.collections_bookmark),
            label: tabLabelFor(_app, 1),
          ),
          // 某些 App 有 4 个资源模块,某些只有 2 个。此处对「补充 tab」
          // 做条件显示:如果和上一个模块是同路径(占位重复),就仍然放着但文案显示为空。
          if (_hasExtraTab(_app, 2))
            NavigationDestination(
              icon: const Icon(Icons.tune_outlined),
              selectedIcon: const Icon(Icons.tune),
              label: tabLabelFor(_app, 2),
            ),
          if (_hasExtraTab(_app, 3))
            NavigationDestination(
              icon: const Icon(Icons.format_list_bulleted_add),
              selectedIcon: const Icon(Icons.format_list_bulleted_add),
              label: tabLabelFor(_app, 3),
            ),
          const NavigationDestination(
            icon: Icon(Icons.add_box_outlined),
            selectedIcon: Icon(Icons.add_box),
            label: '新建',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: '我的',
          ),
        ],
      ),
    );
  }

  bool _hasExtraTab(SrcApp app, int index) {
    final tabs = kAppTabs[app]!;
    if (index >= tabs.length) return false;
    // 同一个 module 被重复用作占位(如 legadotauri 只有 shuyuan,tab2/3 也是 shuyuan),
    // 就不再显示额外 tab
    final prev = index >= 2 ? tabs[1] : tabs[0];
    return tabs[index] != prev;
  }
}

/// App 切换下拉菜单(放在 AppBar 右侧)
class _AppSwitcher extends StatelessWidget {
  final SrcApp current;
  final ValueChanged<SrcApp> onChanged;
  const _AppSwitcher({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: PopupMenuButton<SrcApp>(
        tooltip: '切换 App 板块',
        icon: Icon(iconFor(current)),
        onSelected: onChanged,
        itemBuilder: (_) => SrcApp.values
            .map(
              (a) => PopupMenuItem<SrcApp>(
                value: a,
                child: Row(
                  children: [
                    Icon(iconFor(a), size: 18),
                    const SizedBox(width: 8),
                    Text(a.label),
                    if (a == current) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.check, size: 16, color: Colors.blue),
                    ],
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

/// 占位:保留 collection_page / rss_page 编译通过,但 main.dart 不再引用它们。
/// (可后续按需删除)
class Placeholder {
  static void keep() {
    // ignore: unused_element
    void _p() {}
  }
}
