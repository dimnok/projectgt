import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:universal_html/html.dart' as web;

/// Утилита для цвета «оболочки» страницы на Web: `theme-color`, фон `html`/`body`,
/// CSS-переменная для канваса Flutter. Один источник правды — без дублирования в JS.
class WebStatusBar {
  /// Устанавливает цвет оболочки (meta + документ). [isDark] — стиль строки состояния iOS.
  static void setColor(Color color, {bool isDark = false}) {
    if (!kIsWeb) return;
    try {
      final colorHex = _toHex(color);
      _applyShellColor(colorHex, isDark: isDark);
    } catch (_) {}
  }

  /// Только фон `body` и переменная `--app-surface-color` (без `theme-color` / Apple-meta).
  static void setSurfaceColor(Color color) {
    if (!kIsWeb) return;
    try {
      final colorHex = _toHex(color);
      web.document.body?.style.backgroundColor = colorHex;
      _setCSSVariable('--app-surface-color', colorHex);
    } catch (_) {}
  }

  /// Синхронизирует оболочку браузера с темой приложения.
  static void syncWithTheme(ThemeData theme) {
    if (!kIsWeb) return;
    final isDark = theme.brightness == Brightness.dark;
    final Color shell = theme.colorScheme.surface;
    final hex = _toHex(shell);
    _applyShellColor(hex, isDark: isDark);
  }

  static String _toHex(Color color) {
    return '#${(0xFF000000 |
            (((color.r * 255.0).round() & 0xff) << 16) |
            (((color.g * 255.0).round() & 0xff) << 8) |
            ((color.b * 255.0).round() & 0xff))
        .toRadixString(16)
        .substring(2)}';
  }

  static void _applyShellColor(String colorHex, {required bool isDark}) {
    _updateMetaTags(colorHex, isDark);
    web.document.body?.style.backgroundColor = colorHex;
    web.document.documentElement?.style.backgroundColor = colorHex;
    _setCSSVariable('--app-surface-color', colorHex);
  }

  static void _updateMetaTags(String colorHex, bool isDark) {
    try {
      // Динамически создаем или обновляем theme-color для Android Chrome
      var metaTheme = web.document.querySelector('meta[name="theme-color"]');
      if (metaTheme == null) {
        metaTheme = web.document.createElement('meta');
        metaTheme.setAttribute('name', 'theme-color');
        web.document.head?.append(metaTheme);
      }
      metaTheme.setAttribute('content', colorHex);
      metaTheme.removeAttribute('media');

      // Для PWA-режима (когда приложение добавлено "На экран Домой")
      // мы всегда используем black-translucent, чтобы контент заходил под статус-бар.
      final appleMeta = web.document
          .querySelector('meta[name="apple-mobile-web-app-status-bar-style"]');
      if (appleMeta != null) {
        appleMeta.setAttribute('content', 'black-translucent');
      }
    } catch (_) {}
  }

  static void _setCSSVariable(String name, String value) {
    try {
      (web.document.documentElement as web.HtmlElement?)
          ?.style
          .setProperty(name, value);
    } catch (_) {}
  }

  /// Инициализация: стартовый фон по системной теме до первого кадра Flutter.
  static void initialize() {
    if (!kIsWeb) return;
    try {
      final isDark =
          PlatformDispatcher.instance.platformBrightness == Brightness.dark;
      // Используем стартовые цвета до загрузки Flutter
      final initial = isDark ? '#0E0E10' : '#FFFFFF';
      _setCSSVariable('--app-surface-color', initial);
      _addEdgeToEdgeStyles();
    } catch (_) {}
  }

  static void _addEdgeToEdgeStyles() {
    final style = web.StyleElement();
    style.text = '''
      html, body {
        margin: 0;
        padding: 0;
        height: 100vh;
        overflow: hidden;
        background-color: var(--app-surface-color, #ffffff);
      }
      @media (display-mode: standalone) {
        body {
          padding-top: env(safe-area-inset-top, 0);
          padding-bottom: env(safe-area-inset-bottom, 0);
          padding-left: env(safe-area-inset-left, 0);
          padding-right: env(safe-area-inset-right, 0);
        }
        flt-glass-pane { height: 100vh !important; }
      }
      body::-webkit-scrollbar { display: none; }
      body { -ms-overflow-style: none; scrollbar-width: none; transition: background-color 0.2s ease; }
    ''';
    web.document.head?.append(style);
  }
}
