import 'package:flutter/foundation.dart';

/// Константы приложения.
///
/// Содержит версию приложения и определение платформы для системы версионирования.
class AppConstants {
  /// Текущая версия приложения (синхронизирована с pubspec.yaml).
  ///
  /// Формат: major.minor.patch (например, 1.0.1).
  static const String appVersion = '1.0.1';

  /// Платформа приложения для проверки версии.
  ///
  /// Значения: 'web', 'ios', 'android'.
  static String get appPlatform {
    if (kIsWeb) {
      return 'web';
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return 'ios';
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      return 'android';
    } else {
      // Для других платформ (macOS, Windows, Linux) используем web
      return 'web';
    }
  }
}
