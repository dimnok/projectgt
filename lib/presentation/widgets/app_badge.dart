import 'package:flutter/material.dart';

/// Виджет бейджа для отображения текста и/или иконки с цветовой индикацией.
class AppBadge extends StatelessWidget {
  /// Текст, отображаемый внутри бейджа.
  final String text;

  /// Основной цвет бейджа и иконки.
  final Color color;

  /// Иконка, отображаемая слева от текста (опционально).
  final IconData? icon;

  /// Размер шрифта текста.
  final double fontSize;

  /// Создаёт [AppBadge] с заданным текстом, цветом и (опционально) иконкой.
  const AppBadge({
    super.key,
    required this.text,
    required this.color,
    this.icon,
    this.fontSize = 11,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 20),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha((0.15 * 255).toInt()),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: fontSize + 3, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: fontSize,
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
