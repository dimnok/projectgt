import 'package:flutter/material.dart';

/// Заглушка для платформ, отличных от Web.
class WebStatusBar {
  /// Устанавливает цвет статус-бара (заглушка).
  static void setColor(Color color, {bool isDark = false}) {}

  /// Устанавливает цвет поверхности (заглушка).
  static void setSurfaceColor(Color color) {}

  /// Синхронизирует с темой приложения (заглушка).
  static void syncWithTheme(ThemeData theme) {}

  /// Инициализирует статус-бар (заглушка).
  static void initialize() {}
}
