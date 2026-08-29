import 'package:flutter/material.dart';

import '../models/source_item.dart';
import 'source_list_page.dart';

/// 订阅源页(RSS)
class RssPage extends StatelessWidget {
  const RssPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const SourceListPage(module: SrcModule.rss);
  }
}