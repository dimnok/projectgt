import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

/// Виджет для ограничения ширины контента на больших экранах.
///
/// Используется для центрирования контента на Desktop/Web, чтобы он не растягивался
/// на всю ширину экрана. Максимальная ширина соответствует дизайну профиля (880px).
class ContentConstrainedBox extends StatelessWidget {
  /// Дочерний виджет.
  final Widget child;

  /// Максимальная ширина контента (по умолчанию 880).
  final double maxWidth;

  /// Создаёт контейнер с ограниченной шириной.
  const ContentConstrainedBox({
    super.key,
    required this.child,
    this.maxWidth = 880,
  });

  @override
  Widget build(BuildContext context) {
    // Проверяем, является ли устройство десктопным/веб
    final bool isDesktop = kIsWeb ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux;

    if (!isDesktop) return child;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

