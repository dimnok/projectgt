import 'package:flutter/material.dart';

/// Заглушка: safe area только из [MediaQuery].
class WebSafeArea {
  /// Верхний inset для контента под status bar.
  static double topOf(BuildContext context) {
    return MediaQuery.viewPaddingOf(context).top;
  }

  /// Дополняет [MediaQueryData] на Web (на других платформах без изменений).
  static MediaQueryData resolveMediaQuery(MediaQueryData data) => data;
}
