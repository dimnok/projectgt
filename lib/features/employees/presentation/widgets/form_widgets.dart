import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:intl/intl.dart';

/// Виджет секции формы.
///
/// Содержит заголовок и набор полей в карточке с единым стилем.
class FormSectionCard extends StatelessWidget {
  /// Заголовок секции.
  final String title;
  
  /// Список виджетов-полей.
  final List<Widget> children;

  /// Создает секцию формы с заголовком [title] и полями [children].
  const FormSectionCard({
    super.key,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}

/// Виджет для выбора даты.
///
/// Отображает поле с выбранной датой и открывает датапикер при нажатии.
class DatePickerField extends StatelessWidget {
  /// Текущая выбранная дата.
  final DateTime? date;
  
  /// Заголовок поля.
  final String labelText;
  
  /// Подсказка в пустом поле.
  final String hintText;
  
  /// Обработчик изменения даты.
  final Function(DateTime?) onDateSelected;

  /// Создает поле для выбора даты с заголовком [labelText] и подсказкой [hintText].
  const DatePickerField({
    super.key,
    required this.date,
    required this.labelText,
    required this.hintText,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _selectDate(context),
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: labelText,
          hintText: hintText,
          suffixIcon: const Icon(Icons.calendar_today),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(_formatDate(date)),
      ),
    );
  }

  /// Открывает датапикер и вызывает onDateSelected при выборе.
  Future<void> _selectDate(BuildContext context) async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: date ?? now,
      firstDate: DateTime(1900),
      lastDate: now,
    );
    
    if (picked != null && picked != date) {
      onDateSelected(picked);
    }
  }

  /// Форматирует дату для отображения.
  String _formatDate(DateTime? date) {
    if (date == null) return 'Не указана';
    return DateFormat('dd.MM.yyyy').format(date);
  }
}

/// Поле с автодополнением для Enum.
///
/// Используется для выбора значений из Enum с переводом их в текст через конвертер.
class EnumTypeAheadField<T> extends StatelessWidget {
  /// Контроллер для текстового поля.
  final TextEditingController controller;
  
  /// Список значений Enum для выбора.
  final List<T> values;
  
  /// Функция для получения текстового представления значения Enum.
  final String Function(T value) textConverter;
  
  /// Заголовок поля.
  final String labelText;
  
  /// Подсказка в пустом поле.
  final String hintText;
  
  /// Обработчик выбора значения.
  final Function(T value) onSelected;

  /// Создает поле с автодополнением для значений Enum.
  const EnumTypeAheadField({
    super.key,
    required this.controller,
    required this.values,
    required this.textConverter,
    required this.labelText,
    required this.hintText,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return TypeAheadField<T>(
      controller: controller,
      suggestionsCallback: (pattern) {
        return values.where((e) => 
          textConverter(e).toLowerCase().contains(pattern.toLowerCase())
        ).toList();
      },
      builder: (context, controller, focusNode) {
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          readOnly: true,
          decoration: InputDecoration(
            labelText: labelText,
            hintText: hintText,
            border: const OutlineInputBorder(),
          ),
          onTap: () {
            controller.clear();
            focusNode.requestFocus();
          },
        );
      },
      itemBuilder: (context, suggestion) {
        return ListTile(
          title: Text(textConverter(suggestion)),
        );
      },
      onSelected: onSelected,
      emptyBuilder: (context) => const ListTile(
        title: Text('Нет совпадений'),
      ),
    );
  }
}

/// Стандартное текстовое поле формы.
///
/// Обертка вокруг TextFormField с единым стилем для всего приложения.
class FormTextField extends StatelessWidget {
  /// Контроллер для текстового поля.
  final TextEditingController controller;
  
  /// Заголовок поля.
  final String labelText;
  
  /// Подсказка в пустом поле.
  final String hintText;
  
  /// Функция валидации (может быть null).
  final String? Function(String?)? validator;
  
  /// Тип клавиатуры.
  final TextInputType? keyboardType;
  
  /// Доступно ли поле для редактирования.
  final bool readOnly;

  /// Создает стандартное текстовое поле формы.
  const FormTextField({
    super.key,
    required this.controller,
    required this.labelText,
    required this.hintText,
    this.validator,
    this.keyboardType,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
      ),
      validator: validator,
      keyboardType: keyboardType,
      readOnly: readOnly,
    );
  }
}

/// Стандартные кнопки формы (отмена и сохранение).
///
/// Отображает кнопки внизу формы.
class FormButtons extends StatelessWidget {
  /// Обработчик нажатия на кнопку сохранения.
  final VoidCallback onSave;
  
  /// Обработчик нажатия на кнопку отмены.
  final VoidCallback onCancel;
  
  /// Флаг загрузки, отключает кнопку и показывает индикатор.
  final bool isLoading;
  
  /// Текст на кнопке сохранения.
  final String saveText;

  /// Создает стандартные кнопки формы.
  const FormButtons({
    super.key,
    required this.onSave,
    required this.onCancel,
    required this.isLoading,
    required this.saveText,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: onCancel,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            child: const Text('Отмена'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: isLoading ? null : onSave,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            child: isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(saveText),
          ),
        ),
      ],
    );
  }
} 