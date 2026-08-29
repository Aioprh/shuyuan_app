import 'package:flutter/material.dart';

import 'models/source_item.dart';
import 'pages/collections_page.dart';
import 'pages/profile_page.dart';
import 'pages/publish_page.dart';
import 'pages/rss_page.dart';
import 'pages/source_list_page.dart';
import 'services/session_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SessionStore.instance.load(); // 恢复本地登录会话
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

/// 底部导航主框架:书源 / 合集 / 订阅源 / 新建 / 我的
class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;

  static const _pages = <Widget>[
    SourceListPage(module: SrcModule.shuyuan, enableBatch: true),
    CollectionsPage(),
    RssPage(),
    PublishPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.book_outlined), selectedIcon: Icon(Icons.book), label: '书源'),
          NavigationDestination(icon: Icon(Icons.collections_bookmark_outlined), selectedIcon: Icon(Icons.collections_bookmark), label: '合集'),
          NavigationDestination(icon: Icon(Icons.rss_feed), label: '订阅源'),
          NavigationDestination(icon: Icon(Icons.add_box_outlined), selectedIcon: Icon(Icons.add_box), label: '新建'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: '我的'),
        ],
      ),
    );
  }
}