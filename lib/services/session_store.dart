import 'package:shared_preferences/shared_preferences.dart';

/// 站点登录会话:在应用内 WebView 完成登录后,
/// 把 yckceo.com 的 Cookie 同步到本仓库,并持久化,
/// 使「新建/发布」接口以已登录身份提交。
class SessionStore {
  SessionStore._();
  static final SessionStore instance = SessionStore._();

  static const _kCookie = 'session_cookie';
  static const _kEmail = 'session_email';
  static const _kLogged = 'logged_in';

  String cookieHeader = '';
  String email = '';
  bool loggedIn = false;

  /// 从本地存储恢复会话。
  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    cookieHeader = p.getString(_kCookie) ?? '';
    email = p.getString(_kEmail) ?? '';
    loggedIn = p.getBool(_kLogged) ?? false;
    if (loggedIn && cookieHeader.isEmpty) loggedIn = false;
  }

  /// 保存登录会话(仅当 cookie 非空视为已登录)。
  Future<void> save({required String cookieHeader, String email = ''}) async {
    this.cookieHeader = cookieHeader.trim();
    this.email = email.trim();
    loggedIn = this.cookieHeader.isNotEmpty;
    final p = await SharedPreferences.getInstance();
    await p.setString(_kCookie, this.cookieHeader);
    await p.setString(_kEmail, this.email);
    await p.setBool(_kLogged, loggedIn);
  }

  Future<void> clear() async {
    cookieHeader = '';
    email = '';
    loggedIn = false;
    final p = await SharedPreferences.getInstance();
    await p.remove(_kCookie);
    await p.remove(_kEmail);
    await p.setBool(_kLogged, false);
  }
}