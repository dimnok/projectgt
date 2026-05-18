import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Заглушка для платформ, отличных от Web.
class WebStatusBar {
  /// Устанавливает цвет статус-бара (заглушка).
  static void setColor(Color color, {bool isDark = false}) {}

  /// Устанавливает цвет поверхности (заглушка).
  static void setSurfaceColor(Color color) {}

  /// Синхронизирует с темой приложения (заглушка).
  static void syncWithTheme(ThemeData theme) {}

  /// Синхронизация по [ThemeMode] (заглушка).
  static void applyThemeMode(ThemeMode mode) {}

  /// Инициализирует статус-бар (заглушка).
  static void initialize() {}

  /// Подписка на системную тему (заглушка).
  static void listenToSystemColorScheme(VoidCallback onChanged) {}
}
