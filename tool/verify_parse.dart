// 手动验证列表页解析逻辑(非正式)
// ignore_for_file: avoid_print
import 'dart:io';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;

String _text(dom.Element? el) => el?.text ?? '';
String _attr(dom.Element parent, String selector, String name) {
  return parent.querySelector(selector)?.attributes[name] ?? '';
}
String _classText(dom.Element parent, String cls) {
  final spans = parent.querySelectorAll('span');
  for (final s in spans) {
    if (s.classes.any((e) => e.contains(cls))) return s.text;
  }
  return '';
}

void main() {
  final html = File('/data/user/work/list.html').readAsStringSync();
  final doc = html_parser.parse(html);
  final cards = doc.querySelectorAll('div.ylist');
  print('共解析到条目: ${cards.length}');
  int n = 0;
  for (final card in cards) {
    if (n++ >= 3) break;
    final id = _attr(card, 'input.class_one', 'value');
    final link = card.querySelector('h2 a');
    final href = link?.attributes['href'] ?? '';
    final idFromHref =
        RegExp(r'content/id/(\d+)\.html').firstMatch(href)?.group(1);
    final title = _text(link).trim();
    final time = _text(card.querySelector('p.m-right')).trim();
    final version = _classText(card, 'layui-font-black').trim();
    final features = _classText(card, 'layui-font-orange').trim();
    final author =
        _classText(card, 'layui-font-red').replaceAll('用户:', '').trim();
    final downloads = _classText(card, 'layui-font-purple').trim();
    print(
        'id=$id idHref=$idFromHref 标题="$title" 版本="$version" 功能="$features" 作者="$author" 下载="$downloads" 时间="$time"');
  }
}