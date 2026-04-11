import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Строка «метка — значение» с опциональным inline-редактированием текста.
///
/// В режиме просмотра отображает обычный текст.
/// В режиме редактирования показывает компактный [TextField].
class EditableInlineTextRow extends StatelessWidget {
  /// Подпись поля в левой колонке.
  final String label;

  /// Текущее отображаемое значение.
  final String value;

  /// Флаг режима редактирования.
  final bool isEditing;

  /// Контроллер текстового поля.
  final TextEditingController? controller;

  /// Текст-подсказка внутри поля ввода.
  final String? hintText;

  /// Тип клавиатуры для текстового поля.
  final TextInputType? keyboardType;

  /// Коллбек изменения текста.
  final void Function(String)? onChanged;

  /// Форматтеры ввода для поля.
  final List<TextInputFormatter>? inputFormatters;

  /// Создаёт строку для inline-редактирования текста.
  const EditableInlineTextRow({
    super.key,
    required this.label,
    required this.value,
    required this.isEditing,
    this.controller,
    this.hintText,
    this.keyboardType,
    this.onChanged,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: isEditing
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: isEditing
                ? SizedBox(
                    height: 32,
                    child: TextField(
                      controller: controller,
                      keyboardType: keyboardType,
                      inputFormatters: inputFormatters,
                      onChanged: onChanged,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        hintText: hintText,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: BorderSide(
                            color: Theme.of(context)
                                .colorScheme
                                .outline
                                .withValues(alpha: 0.5),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: BorderSide(
                            color: Theme.of(context)
                                .colorScheme
                                .outline
                                .withValues(alpha: 0.5),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                  )
                : Text(
                    value,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
          ),
        ],
      ),
    );
  }
}
