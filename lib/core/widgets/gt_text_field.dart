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

  /// Создаёт текстовое поле ввода в стиле проекта.
  ///
  /// - [controller] — контроллер для управления текстом.
  /// - [labelText] — текст над полем или внутри него (placeholder).
  /// - [hintText] — текст-подсказка, отображаемый при пустом поле.
  /// - [prefixIcon] — иконка в начале поля.
  /// - [suffixIcon] — виджет в конце поля (например, кнопка очистки).
  /// - [enabled] — активность поля.
  /// - [validator] — функция проверки введенных данных.
  /// - [keyboardType] — тип вызываемой экранной клавиатуры.
  /// - [maxLines] — максимальное количество строк (по умолчанию 1).
  /// - [readOnly] — запрет на ручной ввод текста.
  /// - [inputFormatters] — список форматтеров (например, для масок ввода).
  /// - [onChanged] — вызов при каждом изменении текста.
  /// - [onSubmitted] — вызов при подтверждении ввода (Enter).
  /// - [onTap] — вызов при нажатии на область поля.
  const GTTextField({
    super.key,
    this.controller,
    this.labelText,
    this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.enabled = true,
    this.validator,
    this.keyboardType,
    this.maxLines = 1,
    this.readOnly = false,
    this.inputFormatters,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return TextFormField(
      controller: controller,
      enabled: enabled,
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
      readOnly: readOnly,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      onTap: onTap,
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 20) : null,
        suffixIcon: suffixIcon,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black12,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black12,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark ? Colors.white : Colors.black,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
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
