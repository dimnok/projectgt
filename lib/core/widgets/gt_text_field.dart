import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Базовый текстовый ввод в стиле проекта.
///
/// Минималистичный дизайн с поддержкой иконок, валидации и адаптивности.
class GTTextField extends StatelessWidget {
  /// Контроллер текста.
  final TextEditingController? controller;

  /// Текст метки (Label).
  final String? labelText;

  /// Подсказка (Hint).
  final String? hintText;

  /// Иконка в начале поля.
  final IconData? prefixIcon;

  /// Виджет в конце поля (например, кнопка).
  final Widget? suffixIcon;

  /// Флаг доступности поля.
  final bool enabled;

  /// Функция валидации.
  final String? Function(String?)? validator;

  /// Тип клавиатуры.
  final TextInputType? keyboardType;

  /// Максимальное количество строк.
  final int? maxLines;

  /// Флаг только для чтения.
  final bool readOnly;

  /// Форматтеры ввода.
  final List<TextInputFormatter>? inputFormatters;

  /// Callback при изменении текста.
  final ValueChanged<String>? onChanged;

  /// Callback при завершении ввода.
  final ValueChanged<String>? onSubmitted;

  /// Callback при клике на поле.
  final VoidCallback? onTap;

  /// Отступы внутри поля.
  final EdgeInsets? contentPadding;

  /// Ограничения области [prefixIcon] (по умолчанию у [InputDecoration] часто
  /// minHeight 48 — из‑за этого поле не становится ниже при уменьшении [contentPadding]).
  final BoxConstraints? prefixIconConstraints;

  /// Ограничения области [suffixIcon] (аналогично [prefixIconConstraints]).
  final BoxConstraints? suffixIconConstraints;

  /// Размер иконки [prefixIcon] (если задана).
  final double prefixIconSize;

  /// Стиль вводимого текста и подсказки (hint наследует [fontSize]).
  final TextStyle? style;

  /// Радиус скругления границ.
  final double borderRadius;

  /// Выравнивание текста.
  final TextAlign textAlign;

  /// Текст в конце поля (например, единица измерения).
  final String? suffixText;

  /// Текст-подсказка под полем.
  final String? helperText;

  /// Тип капитализации текста.
  final TextCapitalization textCapitalization;

  /// Автофокус на поле.
  final bool autofocus;

  /// Узел фокуса (для связки с [FocusScope] и прокруткой к полю).
  final FocusNode? focusNode;

  /// Кнопка на клавиатуре (например [TextInputAction.done] для числового ввода).
  final TextInputAction? textInputAction;

  /// Вызывается при нажатии действия на клавиатуре (часто — скрыть клавиатуру).
  final VoidCallback? onEditingComplete;

  /// Отступ при автоскролле к полю при фокусе (запас над клавиатурой).
  final EdgeInsets scrollPadding;

  /// Тап вне поля (по умолчанию снимает фокус и закрывает клавиатуру).
  final TapRegionCallback? onTapOutside;

  /// Создаёт текстовое поле ввода в стиле проекта.
  ///
  /// - [controller] — контроллер для управления текстом.
  /// - [labelText] — текст над полем или внутри него (placeholder).
  /// - [hintText] — текст-подсказка, отображаемый при пустом поле.
  /// - [prefixIcon] — иконка в начале поля.
  /// - [suffixIcon] — виджет в конце поля (например, кнопка очистки).
  /// - [suffixText] — текст в конце поля (например, "₽" или "кг").
  /// - [helperText] — текст-подсказка под полем.
  /// - [enabled] — активность поля.
  /// - [validator] — функция проверки введенных данных.
  /// - [keyboardType] — тип вызываемой экранной клавиатуры.
  /// - [textCapitalization] — тип капитализации текста (по умолчанию none).
  /// - [maxLines] — максимальное количество строк (по умолчанию 1).
  /// - [readOnly] — запрет на ручной ввод текста.
  /// - [inputFormatters] — список форматтеров (например, для масок ввода).
  /// - [onChanged] — вызов при каждом изменении текста.
  /// - [onSubmitted] — вызов при подтверждении ввода (Enter).
  /// - [onTap] — вызов при нажатии на область поля.
  /// - [contentPadding] — пользовательские отступы.
  /// - [prefixIconConstraints] / [suffixIconConstraints] — компактные поля в панелях инструментов.
  /// - [prefixIconSize] — размер [prefixIcon].
  /// - [style] — стиль текста поля.
  /// - [borderRadius] — радиус скругления (по умолчанию 16).
  /// - [textAlign] — выравнивание текста (по умолчанию start).
  /// - [autofocus] — автоматический фокус при появлении поля.
  /// - [focusNode] — внешний [FocusNode], если нужен контроль фокуса.
  /// - [textInputAction] / [onEditingComplete] — кнопка «Готово» и скрытие клавиатуры.
  /// - [scrollPadding] — запас при прокрутке к полю в [ScrollView].
  /// - [onTapOutside] — если null, по тапу вне поля фокус снимается.
  const GTTextField({
    super.key,
    this.controller,
    this.labelText,
    this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.suffixText,
    this.helperText,
    this.enabled = true,
    this.validator,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.maxLines = 1,
    this.readOnly = false,
    this.inputFormatters,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.contentPadding,
    this.prefixIconConstraints,
    this.suffixIconConstraints,
    this.prefixIconSize = 20,
    this.style,
    this.borderRadius = 16,
    this.textAlign = TextAlign.start,
    this.autofocus = false,
    this.focusNode,
    this.textInputAction,
    this.onEditingComplete,
    this.scrollPadding = const EdgeInsets.fromLTRB(20, 20, 20, 120),
    this.onTapOutside,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Явно опираемся на body из темы, чтобы шрифт совпадал с остальным UI
    // (иначе частичный TextStyle даёт другой fallback, чем заголовки листа).
    final body = theme.textTheme.bodyMedium;
    final effectiveStyle =
        style ?? (body != null ? body.copyWith(fontSize: 15) : const TextStyle(fontSize: 15));

    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      enabled: enabled,
      validator: validator,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      maxLines: maxLines,
      readOnly: readOnly,
      autofocus: autofocus,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      onTap: onTap,
      textAlign: textAlign,
      style: effectiveStyle,
      textInputAction: textInputAction,
      onEditingComplete: onEditingComplete,
      scrollPadding: scrollPadding,
      onTapOutside: onTapOutside ??
          (PointerDownEvent event) {
            FocusManager.instance.primaryFocus?.unfocus();
          },
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        hintStyle: effectiveStyle.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
        ),
        helperText: helperText,
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, size: prefixIconSize)
            : null,
        prefixIconConstraints: prefixIconConstraints,
        suffixIcon: suffixIcon,
        suffixIconConstraints: suffixIconConstraints,
        suffixText: suffixText,
        isDense: true,
        contentPadding:
            contentPadding ??
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black12,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black12,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(
            color: isDark ? Colors.white : Colors.black,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        filled: true,
        fillColor: enabled
            ? (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white)
            : (isDark
                  ? Colors.white.withValues(alpha: 0.02)
                  : Colors.grey.withValues(alpha: 0.05)),
      ),
    );
  }
}
