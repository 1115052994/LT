import 'package:shared_preferences/shared_preferences.dart';

/// 隐私协议状态——SharedPreferences 持久化，无需加密（仅布尔值）。
class PrivacyService {
  static const _key = 'privacy_agreed_v1';

  static Future<bool> hasAgreed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? false;
  }

  static Future<void> setAgreed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
  }

  /// 开发者面板"重置协议"入口使用，重启后会再次弹出协议框
  static Future<void> clearAgreement() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
