import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:universal_html/html.dart' as web;
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

/// Утилита для управления статус баром на веб-платформе.
class WebStatusBar {
  static const String _jsFunction = 'flutterStatusBar';

  /// Устанавливает цвет статус-бара на веб-платформе.
  static void setColor(Color color, {bool isDark = false}) {
    if (!kIsWeb) return;
    try {
      final colorHex =
          '#${(0xFF000000 | (((color.r * 255.0).round() & 0xff) << 16) | (((color.g * 255.0).round() & 0xff) << 8) | ((color.b * 255.0).round() & 0xff)).toRadixString(16).substring(2)}';

      if (globalContext.has(_jsFunction)) {
        final statusBarObj = globalContext[_jsFunction];
        if (statusBarObj != null) {
          try {
            final jsObj = statusBarObj as JSObject;
            if (jsObj.has('setColor')) {
              final setColorMethod = jsObj['setColor'] as JSFunction?;
              if (setColorMethod != null) {
                setColorMethod.callAsFunction(jsObj, colorHex.toJS);
              }
            }
          } catch (_) {}
        }
      }

      _updateMetaTags(colorHex, isDark);
      _setCSSVariable('--app-surface-color', colorHex);
      _setCSSVariable('--app-status-bar-color', colorHex);
    } catch (_) {}
  }

  /// Устанавливает цвет поверхности на веб-платформе.
  static void setSurfaceColor(Color color) {
    if (!kIsWeb) return;
    try {
      final colorHex =
          '#${(0xFF000000 | (((color.r * 255.0).round() & 0xff) << 16) | (((color.g * 255.0).round() & 0xff) << 8) | ((color.b * 255.0).round() & 0xff)).toRadixString(16).substring(2)}';
      web.document.body?.style.backgroundColor = colorHex;
      _setCSSVariable('--app-surface-color', colorHex);
    } catch (_) {}
  }

  /// Синхронизирует статус-бар с темой приложения.
  static void syncWithTheme(ThemeData theme) {
    if (!kIsWeb) return;
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor = theme.colorScheme.surface;
    setColor(surfaceColor, isDark: isDark);
    setSurfaceColor(surfaceColor);
  }

  static void _updateMetaTags(String colorHex, bool isDark) {
    try {
      final themeMeta = web.document.querySelector('meta[name="theme-color"]');
      themeMeta?.setAttribute('content', colorHex);
      final appleMeta = web.document
          .querySelector('meta[name="apple-mobile-web-app-status-bar-style"]');
      if (appleMeta != null) {
        appleMeta.setAttribute(
            'content', isDark ? 'black-translucent' : 'default');
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

  /// Инициализирует статус-бар для веб-платформы.
  static void initialize() {
    if (!kIsWeb) return;
    try {
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
      body { -ms-overflow-style: none; scrollbar-width: none; transition: background-color 0.3s ease; }
    ''';
    web.document.head?.append(style);
  }
}
