import 'package:flutter/material.dart';

/// Виджет бейджа для отображения текста и/или иконки с цветовой индикацией.
class AppBadge extends StatelessWidget {
  /// Текст, отображаемый внутри бейджа.
  final String text;

  /// Основной цвет бейджа и текста (при отсутствии [fillColor] — основа для подложки).
  final Color color;

  /// Иконка, отображаемая слева от текста (опционально).
  final IconData? icon;

  /// Размер шрифта текста.
  final double fontSize;

  /// Фон карточки (если `null`, подложка `color · 15%`).
  final Color? fillColor;

  /// Цвет контура (`null` — без обводки).
  final Color? borderColor;

  /// Скругление (пилюля если ≥ 999).
  final double borderRadius;

  /// Внутренние отступы (`null` — стандарт для компактного бейджа).
  final EdgeInsetsGeometry? padding;

  /// Создаёт [AppBadge] с заданным текстом, цветом и (опционально) иконкой.
  const AppBadge({
    super.key,
    required this.text,
    required this.color,
    this.icon,
    this.fontSize = 11,
    this.fillColor,
    this.borderColor,
    this.borderRadius = 999,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final EdgeInsetsGeometry effectivePadding =
        padding ?? const EdgeInsets.symmetric(horizontal: 8, vertical: 2);
    final Color effectiveFill =
        fillColor ?? color.withAlpha((0.15 * 255).toInt());

    return Container(
      constraints: const BoxConstraints(minHeight: 20),
      padding: effectivePadding,
      decoration: BoxDecoration(
        color: effectiveFill,
        borderRadius: BorderRadius.circular(borderRadius),
        border: borderColor != null
            ? Border.all(color: borderColor!)
            : null,
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
              height: 1.15,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
