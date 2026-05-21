import 'dart:io';
import 'package:flutter/foundation.dart';

/// 平台判断工具——业务层禁止散写 [Platform.isIOS]，统一走此类。
abstract final class PlatformAware {
  static bool get isIOS => !kIsWeb && Platform.isIOS;
  static bool get isAndroid => !kIsWeb && Platform.isAndroid;
  static bool get isMacOS => !kIsWeb && Platform.isMacOS;
  static bool get isWeb => kIsWeb;

  /// iOS 或 Android 真机/模拟器（非桌面端）
  static bool get isMobile => isIOS || isAndroid;
}
