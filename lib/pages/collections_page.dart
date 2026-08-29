import 'package:flutter/material.dart';

import '../models/source_item.dart';
import 'source_list_page.dart';

/// 合集页:在「书源合集 / 订阅源合集」之间切换
class CollectionsPage extends StatefulWidget {
  const CollectionsPage({super.key});

  @override
  State<CollectionsPage> createState() => _CollectionsPageState();
}

class _CollectionsPageState extends State<CollectionsPage> {
  SrcModule _module = SrcModule.shuyuans;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('合集'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: SegmentedButton<SrcModule>(
              style: const ButtonStyle(
                visualDensity: VisualDensity.compact,
              ),
              segments: const [
                ButtonSegment(
                  value: SrcModule.shuyuans,
                  label: Text('书源合集'),
                  icon: Icon(Icons.collections_bookmark_outlined),
                ),
                ButtonSegment(
                  value: SrcModule.rsss,
                  label: Text('订阅源合集'),
                  icon: Icon(Icons.library_books_outlined),
                ),
              ],
              selected: {_module},
              onSelectionChanged: (s) => setState(() => _module = s.first),
            ),
          ),
        ),
      ),
      body: IndexedStack(
        index: _module == SrcModule.shuyuans ? 0 : 1,
        children: const [
          SourceListPage(module: SrcModule.shuyuans),
          SourceListPage(module: SrcModule.rsss),
        ],
      ),
    );
  }
}