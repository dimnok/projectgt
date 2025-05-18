import 'package:flutter/material.dart';

/// Виджет бейджа для отображения текста и/или иконки с цветовой индикацией.
class AppBadge extends StatelessWidget {
  /// Текст, отображаемый внутри бейджа.
  final String text;

  /// Основной цвет бейджа и иконки.
  final Color color;

  /// Иконка, отображаемая слева от текста (опционально).
  final IconData? icon;

  /// Создаёт [AppBadge] с заданным текстом, цветом и (опционально) иконкой.
  const AppBadge({
    super.key,
    required this.text,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 24),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha((0.15 * 255).toInt()),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
          ],
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 13,
              letterSpacing: 0.1,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
} 