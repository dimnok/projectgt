import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:universal_html/html.dart' as web;

/// Утилита для цвета «оболочки» страницы на Web: `theme-color`, фон `html`/`body`,
/// CSS-переменная для канваса Flutter. Один источник правды — без дублирования в JS.
class WebStatusBar {
  /// Тот же базовый фон, что [MobileAtmosphereAppearance.atmosphereBase] в тёмной теме.
  static const Color kDarkShell = Color(0xFF0E0E10);

  /// Базовый фон светлой темы (совпадает с [ColorScheme.surface] монохромной темы).
  static const Color kLightShell = Color(0xFFFFFFFF);

  static bool? _lastIsDark;
  static String? _lastHex;

  /// Устанавливает цвет оболочки (meta + документ). [isDark] — стиль строки состояния iOS.
  static void setColor(Color color, {bool isDark = false}) {
    if (!kIsWeb) return;
    try {
      _applyShellColor(_toHex(color), isDark: isDark);
    } catch (_) {}
  }

  /// Только фон `body` и переменная `--app-surface-color` (без `theme-color` / Apple-meta).
  static void setSurfaceColor(Color color) {
    if (!kIsWeb) return;
    try {
      final colorHex = _toHex(color);
      web.document.body?.style.backgroundColor = colorHex;
      web.document.documentElement?.style.backgroundColor = colorHex;
      _setCSSVariable('--app-surface-color', colorHex);
    } catch (_) {}
  }

  /// Синхронизирует оболочку браузера с темой приложения.
  static void syncWithTheme(ThemeData theme) {
    if (!kIsWeb) return;
    final isDark = theme.brightness == Brightness.dark;
    final shell = shellColorForTheme(theme);
    _applyShellColor(_toHex(shell), isDark: isDark);
  }

  /// Цвет оболочки под [MobileAtmosphereAppearance.atmosphereBase].
  static Color shellColorForTheme(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    if (isDark) return kDarkShell;
    return theme.colorScheme.surface;
  }

  /// Подписка на смену системной темы (для [ThemeMode.system]).
  static void listenToSystemColorScheme(VoidCallback onChanged) {
    if (!kIsWeb) return;
    try {
      final mq = web.window.matchMedia('(prefers-color-scheme: dark)');
      void handler(web.Event _) => onChanged();
      mq.addEventListener('change', handler);
    } catch (_) {}
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
    if (_lastHex == colorHex && _lastIsDark == isDark) return;
    _lastHex = colorHex;
    _lastIsDark = isDark;

    _updateMetaTags(colorHex, isDark);
    web.document.body?.style.backgroundColor = colorHex;
    web.document.documentElement?.style.backgroundColor = colorHex;
    _setCSSVariable('--app-surface-color', colorHex);
  }

  /// iOS PWA: `theme-color` (#FFFFFF и т.п.) рисует **непрозрачную** полосу status bar
  /// поверх `black-translucent`. На iOS обновляем только фон документа.
  static bool _isIosStandalonePwa() {
    try {
      final ua = web.window.navigator.userAgent.toLowerCase();
      final isIos =
          ua.contains('iphone') || ua.contains('ipad') || ua.contains('ipod');
      if (!isIos) return false;
      if (web.window.matchMedia('(display-mode: standalone)').matches) {
        return true;
      }
      // Safari iOS: `navigator.standalone` (не в типах universal_html).
      final nav = web.window.navigator as dynamic;
      return nav.standalone == true;
    } catch (_) {
      return false;
    }
  }

  static void _updateMetaTags(String colorHex, bool isDark) {
    try {
      final iosPwa = _isIosStandalonePwa();

      if (iosPwa) {
        web.document.querySelectorAll('meta[name="theme-color"]').forEach((m) {
          m.remove();
        });
      } else {
        final metas = web.document.querySelectorAll('meta[name="theme-color"]');
        if (metas.isEmpty) {
          final metaTheme = web.document.createElement('meta');
          metaTheme.setAttribute('name', 'theme-color');
          metaTheme.setAttribute('content', colorHex);
          web.document.head?.append(metaTheme);
        } else {
          for (final meta in metas) {
            meta.setAttribute('content', colorHex);
            meta.removeAttribute('media');
          }
        }
      }

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
          web.window.matchMedia('(prefers-color-scheme: dark)').matches;
      final initial = isDark ? _toHex(kDarkShell) : _toHex(kLightShell);
      _applyShellColor(initial, isDark: isDark);
      _addEdgeToEdgeStyles();
    } catch (_) {}
  }

  static void _addEdgeToEdgeStyles() {
    if (web.document.getElementById('gt-web-shell-style') != null) return;

    final iosPwa = _isIosStandalonePwa();
    final style = web.StyleElement();
    style.id = 'gt-web-shell-style';
    style.text = '''
      html, body {
        margin: 0;
        padding: 0;
        height: 100%;
        width: 100%;
        overflow: hidden;
        background-color: var(--app-surface-color, #FFFFFF);
      }
      ${iosPwa ? '''
      flt-glass-pane, flt-scene-host, flt-scene {
        background-color: transparent !important;
      }
      ''' : ''}
      body::-webkit-scrollbar { display: none; }
      body { -ms-overflow-style: none; scrollbar-width: none; transition: background-color 0.2s ease; }
    ''';
    web.document.head?.append(style);
  }
}
