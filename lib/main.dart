import 'package:flutter/material.dart';

import 'models/source_item.dart';
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
  }
}

/// 底部导航主框架:固定 4 个 tab,索引与 IndexedStack 严格对应。
///   0 -> 资源(源类,内部 TabBar 切换)
///   1 -> 合集(合集类,内部 TabBar 切换)
///   2 -> 新建 / 发布
///   3 -> 我的
/// 资源/合集 tab 各自用 TabBar 展示当前 App 下可用的子模块(如订阅源、TTS、图源)。
class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  SrcApp _app = SrcApp.yuedu;
  int _navIndex = 0;

  @override
  Widget build(BuildContext context) {
    // 关键:用 ValueKey 让 app 变化时强制重建前两个页面,解决切换不刷新
    final sourcesPage = _MultiModulePage(
      key: ValueKey('sources-${_app.name}'),
      app: _app,
      modules: kAppSources[_app]!,
      enableBatchFirst: true,
    );
    final collectionsPage = _MultiModulePage(
      key: ValueKey('collections-${_app.name}'),
      app: _app,
      modules: kAppCollections[_app]!,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(_currentTitle()),
        actions: [
          _AppSwitcher(
            current: _app,
            onChanged: (a) {
              setState(() {
                _app = a;
                _navIndex = 0; // 切 App 时回到「资源」tab
              });
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _navIndex,
        children: [
          sourcesPage,      // index 0
          collectionsPage,  // index 1
          const PublishPage(), // index 2
          const ProfilePage(), // index 3
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _navIndex,
        onDestinationSelected: (i) => setState(() => _navIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.book_outlined),
            selectedIcon: Icon(Icons.book),
            label: '资源',
          ),
          NavigationDestination(
            icon: Icon(Icons.collections_bookmark_outlined),
            selectedIcon: Icon(Icons.collections_bookmark),
            label: '合集',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_box_outlined),
            selectedIcon: Icon(Icons.add_box),
            label: '新建',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: '我的',
          ),
        ],
      ),
    );
  }

  String _currentTitle() {
    switch (_navIndex) {
      case 0:
        return _app.label;
      case 1:
        return '合集';
      case 2:
        return '新建 / 发布';
      case 3:
        return '我的';
    }
    return '';
  }
}

/// 多子模块容器:AppBar 下方一个 TabBar,每个 tab 是一个 SourceListPage。
/// 当只有一个子模块时,不显示 TabBar(简洁美观)。
class _MultiModulePage extends StatefulWidget {
  final SrcApp app;
  final List<SrcModule> modules;
  final bool enableBatchFirst;
  const _MultiModulePage({
    super.key,
    required this.app,
    required this.modules,
    this.enableBatchFirst = false,
  });

  @override
  State<_MultiModulePage> createState() => _MultiModulePageState();
}

class _MultiModulePageState extends State<_MultiModulePage> {
  @override
  Widget build(BuildContext context) {
    final hasMultiple = widget.modules.length > 1;
    final tabs = widget.modules.map((m) => Tab(text: m.label)).toList();
    final pages = widget.modules.asMap().entries.map((e) {
      final idx = e.key;
      final m = e.value;
      return SourceListPage(
        key: ValueKey('${widget.app.name}-${m.path}'),
        app: widget.app,
        module: m,
        enableBatch: idx == 0 && widget.enableBatchFirst,
      );
    }).toList();

    return DefaultTabController(
      length: widget.modules.length,
      child: Column(
        children: [
          if (hasMultiple)
            TabBar(tabs: tabs),
          Expanded(child: TabBarView(children: pages)),
        ],
      ),
    );
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
