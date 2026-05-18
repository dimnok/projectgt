import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

// Константы стилей текста для кнопок больше не используются напрямую
// для обеспечения поддержки динамических шрифтов.
// const _kButtonTextStyle = ...
// const _kTextButtonTextStyle = ...

/// Подпись stadium-кнопки (иконка + текст) без [LayoutBuilder].
///
/// [LayoutBuilder] нельзя вкладывать под [IntrinsicWidth] (в т.ч. в разметке
/// [AlertDialog] для ряда действий): при расчёте intrinsic-размеров Flutter
/// падает с «does not support returning intrinsic dimensions».
class _GtStadiumButtonLabelRow extends StatelessWidget {
  const _GtStadiumButtonLabelRow({
    required this.text,
    required this.textStyle,
    this.icon,
  });

  final String text;
  final TextStyle? textStyle;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18),
          const SizedBox(width: 8),
        ],
        Flexible(
          fit: FlexFit.loose,
          child: Text(
            text,
            textAlign: icon != null ? TextAlign.start : TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: textStyle,
          ),
        ),
      ],
    );
  }
}

/// Основная кнопка действия (Primary).
///
/// Яркая, залитая цветом кнопка для главных действий на экране
/// (Сохранить, Войти, Подтвердить).
class GTPrimaryButton extends StatelessWidget {
  /// Текст на кнопке.
  final String text;

  /// Callback нажатия. Если null или [isLoading] = true, кнопка неактивна.
  final VoidCallback? onPressed;

  /// Флаг загрузки. Если true, вместо текста показывается индикатор.
  final bool isLoading;

  /// Опциональная иконка перед текстом.
  final IconData? icon;

  /// Цвет фона кнопки. Если null, используется [ColorScheme.primary].
  final Color? backgroundColor;

  /// Цвет текста/иконки. Если null, используется [ColorScheme.onPrimary].
  final Color? foregroundColor;

  /// Создает основную кнопку (Primary).
  ///
  /// [text] - Текст кнопки.
  /// [onPressed] - Callback нажатия.
  /// [isLoading] - Показать индикатор загрузки.
  /// [icon] - Опциональная иконка.
  /// [backgroundColor] - Цвет фона.
  /// [foregroundColor] - Цвет текста/иконки.
  const GTPrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = backgroundColor ?? theme.colorScheme.primary;
    final fgColor = foregroundColor ?? theme.colorScheme.onPrimary;

    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: bgColor,
        foregroundColor: fgColor,
        disabledBackgroundColor: bgColor.withValues(alpha: 0.6),
        disabledForegroundColor: fgColor.withValues(alpha: 0.6),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
        elevation: 0,
      ),
      child: isLoading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CupertinoActivityIndicator(color: fgColor),
            )
          : _GtStadiumButtonLabelRow(
              text: text,
              icon: icon,
              textStyle: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: fgColor,
              ),
            ),
    );
  }
}

/// Вторичная кнопка (Secondary).
///
/// Кнопка с обводкой (Outlined), используется для действий отмены,
/// "Назад" или второстепенных опций.
class GTSecondaryButton extends StatelessWidget {
  /// Текст на кнопке.
  final String text;

  /// Callback нажатия.
  final VoidCallback? onPressed;

  /// Флаг загрузки.
  final bool isLoading;

  /// Опциональная иконка.
  final IconData? icon;

  /// Цвет обводки и текста. Если null, используется цвет темы.
  final Color? color;

  /// Создает вторичную кнопку (Secondary).
  ///
  /// [text] - Текст кнопки.
  /// [onPressed] - Callback нажатия.
  /// [isLoading] - Показать индикатор загрузки.
  /// [icon] - Опциональная иконка.
  /// [color] - Основной цвет (обводка, текст).
  const GTSecondaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColor = color ?? theme.colorScheme.primary;

    return OutlinedButton(
      onPressed: isLoading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: effectiveColor,
        side: BorderSide(color: effectiveColor),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
      ).copyWith(
        side: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return BorderSide(color: effectiveColor.withValues(alpha: 0.3));
          }
          return BorderSide(color: effectiveColor);
        }),
      ),
      child: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CupertinoActivityIndicator(),
            )
          : _GtStadiumButtonLabelRow(
              text: text,
              icon: icon,
              textStyle: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: effectiveColor,
              ),
            ),
    );
  }
}

/// Текстовая кнопка (Ghost/Text).
///
/// Без фона и рамок. Используется для ссылок или действий в заголовках.
/// Размер шрифта по умолчанию 15; при необходимости задаётся [fontSize].
/// [dense] — уменьшенные отступы и плотная раскладка для вложенных действий в формах.
class GTTextButton extends StatelessWidget {
  /// Текст кнопки.
  final String text;

  /// Callback нажатия.
  final VoidCallback? onPressed;

  /// Цвет текста и иконки.
  final Color? color;

  /// Опциональная иконка перед текстом.
  final IconData? icon;

  /// Размер шрифта подписи; по умолчанию 15.
  final double? fontSize;

  /// Компактные отступы и [VisualDensity.compact] (второстепенные действия в плотных формах).
  final bool dense;

  /// Создает текстовую кнопку.
  const GTTextButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.color,
    this.icon,
    this.fontSize,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resolvedSize = fontSize ?? 15;
    final iconGap = dense ? 4.0 : 6.0;
    final iconSize = dense
        ? (resolvedSize * 1.05).clamp(13.0, 17.0)
        : (resolvedSize * 1.15).clamp(14.0, 22.0);

    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: color,
        padding: dense
            ? const EdgeInsets.symmetric(horizontal: 6, vertical: 2)
            : const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        visualDensity: dense ? VisualDensity.compact : VisualDensity.standard,
        minimumSize: dense ? Size.zero : null,
        tapTargetSize:
            dense ? MaterialTapTargetSize.shrinkWrap : MaterialTapTargetSize.padded,
        shape: const StadiumBorder(),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: iconSize),
            SizedBox(width: iconGap),
          ],
          Text(
            text,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: resolvedSize,
              color: color, // Указываем цвет явно, если передан
            ),
          ),
        ],
      ),
    );
  }
}
