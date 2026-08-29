import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;

import '../models/source_item.dart';
import 'session_store.dart';

/// 数据访问层。数据来源:https://www.yckceo.com
/// 站点按 App 板块分 URL 前缀,每个板块下又按模块分资源类型:
///   ${baseHost}/${SrcApp.path}/${SrcModule.path}/...
/// 各模块列表页采用相同的 `div.ylist` 卡片结构;
/// 单条 JSON 取 /${app}/${module}/json/id/${id}.json 。
class ApiService {
  static const String baseHost = 'https://www.yckceo.com';
  static const String loginUrl = '$baseHost/index/login/login.html';
  static const String openSourceUrl = 'https://github.com/Aioprh/shuyuan_app';
  static const String addressUrl = 'https://yckceo.vip';
  static const String themeUrl = '$baseHost/yuedu/theme/index.html';
  static const String shuyuanRuleUrl = '$baseHost/yuedu/tools/index/id/shuyuan.html';
  static const String rssRuleUrl = '$baseHost/yuedu/tools/index/id/rss.html';

  static const _timeout = Duration(seconds: 25);
  static const _ua =
      'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/120.0 Mobile Safari/537.36';

  /// 抓取某 App + 模块 的列表页。
  Future<List<SourceItem>> fetchPage(SrcApp app, SrcModule module, int page) async {
    final uri = Uri.parse(
        '$baseHost/${app.path}/${module.path}/index.html?page=$page');
    final res = await httpGet(uri);
    if (res == null) return const [];
    return _parseList(app, module, res);
  }

  /// 解析列表页 HTML(通用 ylist 卡片)
  List<SourceItem> _parseList(SrcApp app, SrcModule module, String html) {
    final doc = html_parser.parse(html);
    final cards = doc.querySelectorAll('div.ylist');
    final items = <SourceItem>[];

    for (final card in cards) {
      final id = _attr(card, 'input.class_one', 'value');
      final link = card.querySelector('h2 a');
      final href = link?.attributes['href'] ?? '';
      final idFromHref = RegExp(r'content/id/(\d+)\.html')
          .firstMatch(href)
          ?.group(1);
      final realId = (id.isNotEmpty ? id : (idFromHref ?? ''));
      if (realId.isEmpty) continue;

      final title = _text(link).trim();
      final time = _text(card.querySelector('p.m-right')).trim();

      final tags = <String>[];
      String user = '';
      String download = '';
      for (final s in card.querySelectorAll('span')) {
        final cls = s.classes.join(' ');
        final txt = s.text.trim();
        if (txt.isEmpty) continue;
        if (!cls.contains('layui-font-')) continue;
        if (txt.startsWith('用户')) {
          user = txt.split(RegExp(r'[:：]')).skip(1).join('').trim();
          continue;
        }
        if (txt.startsWith('下载')) {
          download = txt.split(RegExp(r'[:：]')).skip(1).join('').trim();
          continue;
        }
        tags.add(txt);
      }

      items.add(SourceItem(
        app: app,
        module: module,
        id: realId,
        title: title,
        time: time,
        tags: tags,
        author: user,
        downloads: download,
        detailUrl:
            '$baseHost/${app.path}/${module.path}/content/id/$realId.html',
        jsonUrl: '$baseHost/${app.path}/${module.path}/json/id/$realId.json',
      ));
    }
    return items;
  }

  /// 抓取单条内容 JSON 原文,并做格式化。
  Future<String> fetchJson(SourceItem item) async {
    final uri = Uri.parse(item.jsonUrl);
    final res = await httpGet(uri);
    if (res == null) throw Exception('抓取失败,请检查网络');
    final trimmed = res.trim();
    if (trimmed.isEmpty) throw Exception('内容为空');
    if (trimmed.startsWith('[') || trimmed.startsWith('{')) {
      jsonDecode(trimmed); // 校验可解析
      const encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(jsonDecode(trimmed));
    }
    throw Exception('返回内容异常(可能需要登录后查看)');
  }

  /// 批量导出 JSON(仅书源模块支持),接口: /yuedu/shuyuan/jsons?id=a,b,c
  Future<String> fetchBatch(SrcApp app, List<String> ids) async {
    if (ids.isEmpty) throw Exception('未选择条目');
    final uri = Uri.parse(
        '$baseHost/${app.path}/shuyuan/jsons?id=${ids.join(',')}');
    final res = await httpGet(uri);
    if (res == null) throw Exception('批量导出失败,请检查网络');
    final trimmed = res.trim();
    if (trimmed.isEmpty || !trimmed.startsWith('[')) {
      throw Exception('批量导出返回异常');
    }
    final decoded = jsonDecode(trimmed);
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(decoded);
  }

  /// 发布/新建:向 /{app}/{module}/add.html 提交 JSON 代码。
  /// 需已登录站点帐号,否则服务器返回的是登录页 HTML,此处统一转为登录提示。
  /// 返回 (是否成功, 提示信息)。
  Future<(bool, String)> publish(SrcApp app, SrcModule module,
      {required String code, bool isManga = false, bool isAudio = false}) async {
    final uri = Uri.parse('$baseHost/${app.path}/${module.path}/add.html');
    final body = <String, String>{
      'code': code,
      'content': '',
      if (isManga) 'tu': '漫画',
      if (isAudio) 'shengyin': '有声',
    };
    final headers = <String, String>{
      'User-Agent': _ua,
      'Referer': '$baseHost/${app.path}/${module.path}/add',
      'Origin': baseHost,
      'X-Requested-With': 'XMLHttpRequest',
    };
    if (SessionStore.instance.cookieHeader.isNotEmpty) {
      headers['Cookie'] = SessionStore.instance.cookieHeader;
    }
    final client = http.Client();
    try {
      final res = await client
          .post(uri, headers: headers, body: body)
          .timeout(_timeout);
      final t = utf8.decode(res.bodyBytes).trim();
      if (t.startsWith('{') || t.startsWith('[')) {
        final obj = jsonDecode(t);
        if (obj is Map) {
          final ok = obj['code']?.toString() == '1';
          final msg = obj['msg']?.toString() ?? '提交失败(HTTP ${res.statusCode})';
          return (ok, msg);
        }
        return (false, t);
      }
      return (false, '需要登录站点帐号');
    } catch (e) {
      return (false, '提交失败:$e');
    } finally {
      client.close();
    }
  }

  String _attr(dom.Element parent, String selector, String name) {
    return parent.querySelector(selector)?.attributes[name] ?? '';
  }

  String _text(dom.Element? el) => el?.text ?? '';

  Future<String?> httpGet(Uri uri) async {
    try {
      final res = await (await _getClient())
          .get(uri, headers: {'User-Agent': _ua})
          .timeout(_timeout);
      if (res.statusCode == 200) {
        return utf8.decode(res.bodyBytes);
      }
    } catch (_) {}
    return null;
  }

  Future<http.Client> _getClient() async => http.Client();
}
