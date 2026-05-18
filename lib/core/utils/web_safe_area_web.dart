import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:universal_html/html.dart' as web;

/// Safe area для Flutter Web на iOS PWA: [MediaQuery] часто отдаёт 0, читаем `env(safe-area-inset-*)`.
class WebSafeArea {
  static double? _cachedTop;

  /// Верхний отступ: viewPadding Flutter или CSS env на iOS PWA.
  static double topOf(BuildContext context) {
    final fromMq = MediaQuery.viewPaddingOf(context).top;
    if (fromMq > 0) return fromMq;
    return _readCssSafeAreaTop();
  }

  static MediaQueryData resolveMediaQuery(MediaQueryData data) {
    if (!kIsWeb) return data;
    final top = _readCssSafeAreaTop();
    if (top <= 0) return data;

    return data.copyWith(
      padding: data.padding.copyWith(
        top: top > data.padding.top ? top : data.padding.top,
      ),
      viewPadding: data.viewPadding.copyWith(
        top: top > data.viewPadding.top ? top : data.viewPadding.top,
      ),
    );
  }

  static double _readCssSafeAreaTop() {
    if (_cachedTop != null) return _cachedTop!;
    try {
      final probe = web.document.getElementById('gt-safe-area-probe');
      if (probe == null) return 0;

      final view = web.window as dynamic;
      final paddingTop =
          (view.getComputedStyle(probe) as dynamic).paddingTop as String;
      final parsedTop = paddingTop.replaceAll('px', '');
      final parsed = double.tryParse(parsedTop) ?? 0;
      _cachedTop = parsed > 0 ? parsed : 0;
      return _cachedTop!;
    } catch (_) {
      return 0;
    }
  }

  /// Сброс кэша (поворот экрана / смена режима).
  static void invalidateCache() {
    _cachedTop = null;
  }
}
