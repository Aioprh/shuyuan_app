import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// 一条本地发布记录。
class PublishRecord {
  final String title; // 从源码中提取的名称(如 bookSourceName),取不到则用时间占位
  final String moduleLabel; // 书源 / 订阅源 等
  final String code; // 提交的完整 JSON 源码
  final int createdAt; // 毫秒时间戳
  final String? serverMsg; // 发布成功时的接口返回提示(若有)

  PublishRecord({
    required this.title,
    required this.moduleLabel,
    required this.code,
    required this.createdAt,
    this.serverMsg,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'moduleLabel': moduleLabel,
        'code': code,
        'createdAt': createdAt,
        'serverMsg': serverMsg,
      };

  factory PublishRecord.fromJson(Map<String, dynamic> json) => PublishRecord(
        title: json['title'] as String? ?? '',
        moduleLabel: json['moduleLabel'] as String? ?? '',
        code: json['code'] as String? ?? '',
        createdAt: (json['createdAt'] as num?)?.toInt() ?? 0,
        serverMsg: json['serverMsg'] as String?,
      );
}

/// 本地发布历史:记录用户在「新建/发布」中成功提交的内容,
/// 「我的-我的发布」可回看、复制源码或删除。
class PublishStore {
  PublishStore._();
  static final PublishStore instance = PublishStore._();

  static const _kList = 'publish_history';
  List<PublishRecord> records = [];

  /// 从本地存储恢复列表。
  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_kList);
    if (raw == null || raw.isEmpty) {
      records = [];
      return;
    }
    try {
      final list = (jsonDecode(raw) as List).cast<dynamic>();
      records = list
          .map((e) => PublishRecord.fromJson((e as Map).cast<String, dynamic>()))
          .toList();
    } catch (_) {
      records = [];
    }
  }

  /// 新增一条到头部并持久化(内部自动 load,确保不覆盖旧数据)。
  Future<void> add(PublishRecord record) async {
    await load();
    records.insert(0, record);
    await _persist();
  }

  /// 按时间戳删除某条并持久化。
  Future<void> removeAt(int createdAt) async {
    records.removeWhere((r) => r.createdAt == createdAt);
    await _persist();
  }

  Future<void> _persist() async {
    final p = await SharedPreferences.getInstance();
    await p.setString(
      _kList,
      jsonEncode([for (final r in records) r.toJson()]),
    );
  }
}