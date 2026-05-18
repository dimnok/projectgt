import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:universal_html/html.dart' as web;

/// Оболочка страницы на Web.
///
/// **iOS PWA:** только `black-translucent` и прозрачный `html`/`body` — цвет status bar
/// задаёт фон Flutter под ним, без `theme-color` и без заливки документа.
///
/// **Android / desktop Web:** `theme-color` и фон документа синхронизируются с темой.
class WebStatusBar {
  static const Color kDarkShell = Color(0xFF0E0E10);
  static const Color kLightShell = Color(0xFFFFFFFF);
  static const String _kDarkShellHex = '#0E0E10';

  static bool? _lastIsDark;
  static String? _lastHex;

  /// На iOS PWA цвет оболочки не задаём — только Flutter.
  static bool get managesShellColors => kIsWeb && !_isIosStandalonePwa();

  /// Устанавливает цвет оболочки (не используется на iOS PWA).
  static void setColor(Color color, {bool isDark = false}) {
    if (!managesShellColors) return;
    try {
      _applyShellColor(_toHex(color), isDark: isDark, force: true);
    } catch (_) {}
  }

  /// Только фон `body` (не используется на iOS PWA).
  static void setSurfaceColor(Color color) {
    if (!managesShellColors) return;
    try {
      final colorHex = _toHex(color);
      web.document.body?.style.backgroundColor = colorHex;
      web.document.documentElement?.style.backgroundColor = colorHex;
      _setCSSVariable('--app-surface-color', colorHex);
    } catch (_) {}
  }

  /// Синхронизирует оболочку с темой (на iOS PWA — только прозрачная подложка).
  static void syncWithTheme(ThemeData theme) {
    if (!kIsWeb) return;
    if (_isIosStandalonePwa()) {
      _applyIosPwaTransparentShell();
      return;
    }
    final isDark = theme.brightness == Brightness.dark;
    final shell = shellColorForTheme(theme);
    _applyShellColor(_toHex(shell), isDark: isDark);
  }

  /// Синхронизация по [ThemeMode] (на iOS PWA — no-op для цветов).
  static void applyThemeMode(ThemeMode mode) {
    if (!kIsWeb) return;
    if (_isIosStandalonePwa()) {
      _applyIosPwaTransparentShell();
      return;
    }
    final isDark = _isDarkForThemeMode(mode);
    final shell = isDark ? kDarkShell : kLightShell;
    _applyShellColor(_toHex(shell), isDark: isDark, force: true);
  }

  /// Цвет оболочки вне iOS PWA.
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

  static void _applyShellColor(
    String colorHex, {
    required bool isDark,
    bool force = false,
  }) {
    if (!force && _lastHex == colorHex && _lastIsDark == isDark) return;
    _lastHex = colorHex;
    _lastIsDark = isDark;

    _updateThemeColorMeta(colorHex);
    web.document.body?.style.backgroundColor = colorHex;
    web.document.documentElement?.style.backgroundColor = colorHex;
    _setCSSVariable('--app-surface-color', colorHex);
  }

  static bool _isIosStandalonePwa() {
    try {
      final ua = web.window.navigator.userAgent.toLowerCase();
      final isIos =
          ua.contains('iphone') || ua.contains('ipad') || ua.contains('ipod');
      if (!isIos) return false;
      if (web.window.matchMedia('(display-mode: standalone)').matches) {
        return true;
      }
      final nav = web.window.navigator as dynamic;
      return nav.standalone == true;
    } catch (_) {
      return false;
    }
  }

  /// Прозрачный документ + `black-translucent`; цвет — только из Flutter.
  static void _applyIosPwaTransparentShell() {
    try {
      web.document.documentElement?.setAttribute('data-ios-pwa', 'true');
      _removeThemeColorMetas();
      _ensureBlackTranslucentMeta();

      web.document.documentElement?.style.backgroundColor = 'transparent';
      web.document.body?.style.backgroundColor = 'transparent';
      _setCSSVariable('--app-surface-color', 'transparent');
    } catch (_) {}
  }

  static void _removeThemeColorMetas() {
    web.document.querySelectorAll('meta[name="theme-color"]').forEach((m) {
      m.remove();
    });
  }

  static void _ensureBlackTranslucentMeta() {
    var appleMeta = web.document
        .querySelector('meta[name="apple-mobile-web-app-status-bar-style"]');
    if (appleMeta == null) {
      appleMeta = web.document.createElement('meta');
      appleMeta.setAttribute('name', 'apple-mobile-web-app-status-bar-style');
      web.document.head?.append(appleMeta);
    }
    appleMeta.setAttribute('content', 'black-translucent');
  }

  static void _updateThemeColorMeta(String colorHex) {
    try {
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
    } catch (_) {}
  }

  static void _setCSSVariable(String name, String value) {
    try {
      (web.document.documentElement as web.HtmlElement?)
          ?.style
          .setProperty(name, value);
    } catch (_) {}
  }

  static void initialize() {
    if (!kIsWeb) return;
    try {
      _addEdgeToEdgeStyles();
      if (_isIosStandalonePwa()) {
        _applyIosPwaTransparentShell();
        return;
      }
      final isDark = _resolveInitialIsDark();
      final initial = isDark ? _kDarkShellHex : _toHex(kLightShell);
      _applyShellColor(initial, isDark: isDark, force: true);
    } catch (_) {}
  }

  static bool _resolveInitialIsDark() {
    final stored = _readStoredThemeIsDark();
    if (stored != null) return stored;
    return web.window.matchMedia('(prefers-color-scheme: dark)').matches;
  }

  static bool _isDarkForThemeMode(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.dark => true,
      ThemeMode.light => false,
      ThemeMode.system =>
        WidgetsBinding.instance.platformDispatcher.platformBrightness ==
            Brightness.dark,
    };
  }

  static bool? _readStoredThemeIsDark() {
    try {
      final storage = web.window.localStorage;
      final blob = storage['flutter.shared_preferences'];
      if (blob != null && blob.isNotEmpty) {
        final decoded = jsonDecode(blob);
        if (decoded is Map) {
          final mode = _parseThemeModeIndex(decoded['theme_mode']);
          if (mode != null) {
            return _isDarkForStoredMode(mode);
          }
        }
      }
      final legacy = storage['flutter.theme_mode'];
      if (legacy != null && legacy.isNotEmpty) {
        final mode = int.tryParse(legacy);
        if (mode != null) {
          return _isDarkForStoredMode(mode);
        }
      }
    } catch (_) {}
    return null;
  }

  static int? _parseThemeModeIndex(Object? raw) {
    if (raw is int) return raw;
    if (raw is String) return int.tryParse(raw);
    return null;
  }

  static bool _isDarkForStoredMode(int modeIndex) {
    return switch (modeIndex) {
      2 => true,
      1 => false,
      _ => web.window.matchMedia('(prefers-color-scheme: dark)').matches,
    };
  }

  static void _addEdgeToEdgeStyles() {
    if (web.document.getElementById('gt-web-shell-style') != null) return;

    final iosPwa = _isIosStandalonePwa();
    final style = web.StyleElement();
    style.id = 'gt-web-shell-style';
    style.text = iosPwa
        ? '''
      html, body {
        margin: 0;
        padding: 0;
        height: 100%;
        width: 100%;
        overflow: hidden;
        background-color: transparent !important;
      }
      flt-glass-pane, flt-scene-host, flt-scene {
        background-color: transparent !important;
      }
      body::-webkit-scrollbar { display: none; }
      body { -ms-overflow-style: none; scrollbar-width: none; }
    '''
        : '''
      html, body {
        margin: 0;
        padding: 0;
        height: 100%;
        width: 100%;
        overflow: hidden;
        background-color: var(--app-surface-color, $_kDarkShellHex);
      }
      body::-webkit-scrollbar { display: none; }
      body { -ms-overflow-style: none; scrollbar-width: none; transition: background-color 0.2s ease; }
    ''';
    web.document.head?.append(style);
  }
}
