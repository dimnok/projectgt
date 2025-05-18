import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';

/// Универсальный виджет выпадающего списка с автодополнением.
///
/// Позволяет выбирать значения из списка с фильтрацией по вводу пользователя.
/// Также поддерживает добавление новых значений, если они отсутствуют в списке.
class DropdownTypeAheadField<T> extends StatefulWidget {
  /// Контроллер для текстового поля.
  final TextEditingController controller;

  /// Заголовок поля.
  final String labelText;

  /// Подсказка в пустом поле.
  final String hintText;

  /// Список доступных значений.
  final List<T> items;

  /// Функция для отображения элементов (либо строковое представление, либо поле объекта).
  final String Function(T) displayStringForOption;

  /// Обработчик выбора значения.
  final Function(T) onSelected;

  /// Функция валидации.
  final String? Function(String?)? validator;

  /// Можно ли добавлять новые значения.
  final bool allowCustomValues;

  /// Сообщение для добавления нового значения.
  final String? addNewItemText;

  /// Отображать ли индикатор загрузки.
  final bool isLoading;

  /// Флаг только для чтения.
  final bool readOnly;

  /// Необязательные стили для настройки внешнего вида.
  final InputDecoration? decoration;

  /// Функция для поиска/фильтрации элементов.
  /// По умолчанию использует displayStringForOption для сравнения.
  final List<T> Function(String pattern, List<T> items)? filterFn;
  
  /// Иконка в конце поля ввода (по умолчанию стрелка вниз)
  final IconData? suffixIcon;
  
  /// Текст для пустого списка
  final String emptyText;

  /// Создает универсальное поле с автодополнением.
  const DropdownTypeAheadField({
    super.key,
    required this.controller,
    required this.labelText,
    required this.hintText,
    required this.items,
    required this.displayStringForOption,
    required this.onSelected,
    this.validator,
    this.allowCustomValues = true,
    this.addNewItemText,
    this.isLoading = false,
    this.readOnly = false,
    this.decoration,
    this.filterFn,
    this.suffixIcon = Icons.arrow_drop_down,
    this.emptyText = 'Нет совпадений',
  });

  @override
  State<DropdownTypeAheadField<T>> createState() => _DropdownTypeAheadFieldState<T>();
}

class _DropdownTypeAheadFieldState<T> extends State<DropdownTypeAheadField<T>> {
  // FocusNode для управления фокусом ввода
  late FocusNode _focusNode;
  
  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
  }
  
  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (widget.isLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.labelText.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  widget.labelText,
                  style: theme.textTheme.titleSmall,
                ),
              ),
            const Center(child: CircularProgressIndicator()),
          ],
        ),
      );
    }

    return TypeAheadField<T>(
      controller: widget.controller,
      focusNode: _focusNode,
      suggestionsCallback: (pattern) {
        // Получаем все предложения при пустом запросе (клик на поле)
        if (pattern.isEmpty || pattern == ' ') {
          return widget.items;
        }
        
        if (widget.filterFn != null) {
          return widget.filterFn!(pattern, widget.items);
        }
        
        return widget.items.where((item) => 
          widget.displayStringForOption(item).toLowerCase().contains(pattern.toLowerCase())
        ).toList();
      },
      builder: (context, controller, focusNode) {
        return Stack(
          children: [
            TextFormField(
              controller: controller,
              focusNode: focusNode,
              readOnly: widget.readOnly,
              decoration: widget.decoration ?? InputDecoration(
                labelText: widget.labelText,
                hintText: widget.hintText,
                border: const OutlineInputBorder(),
                suffixIcon: Icon(widget.suffixIcon),
              ),
              validator: widget.validator,
            ),
            // Прозрачный слой поверх TextFormField для открытия списка при нажатии
            if (!widget.readOnly)
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () {
                    // При клике на любую часть поля открываем выпадающий список
                    // Для этого достаточно установить фокус на поле ввода
                    focusNode.requestFocus();
                    
                    // Если поле пустое или заполнено, очищаем его и ставим пробел
                    // чтобы появился весь список вариантов
                    controller.clear();
                    controller.text = ' ';
                    
                    // Сохраняем позицию курсора в конце
                    controller.selection = TextSelection.fromPosition(
                      TextPosition(offset: controller.text.length),
                    );
                  },
                  child: const SizedBox(),
                ),
              ),
          ],
        );
      },
      itemBuilder: (context, suggestion) {
        return ListTile(
          title: Text(widget.displayStringForOption(suggestion)),
        );
      },
      onSelected: (suggestion) {
        widget.onSelected(suggestion);
        widget.controller.text = widget.displayStringForOption(suggestion);
      },
      hideOnEmpty: false,
      hideOnError: false,
      hideOnLoading: false,
      emptyBuilder: (context) {
        // Если это пустой запрос (клик) и нет результатов, показываем все элементы
        final input = widget.controller.text.trim();
        
        if (!widget.allowCustomValues || (input.isEmpty && widget.items.isEmpty)) {
          return ListTile(
            title: Text(widget.emptyText),
          );
        }

        // Для кастомных значений даем возможность добавить новое
        if (input.isNotEmpty && widget.allowCustomValues) {
          return ListTile(
            title: Text(widget.addNewItemText ?? 'Добавить: "$input"'),
            onTap: () {
              // Для строковых типов можно добавить новое значение
              if (T == String) {
                final newValue = input as T;
                widget.onSelected(newValue);
                widget.controller.text = input;
              }
              FocusScope.of(context).unfocus();
            },
          );
        }
        
        return const SizedBox();
      },
    );
  }
}

/// Специализированная версия выпадающего списка для работы с Enum.
///
/// Упрощает создание списков для выбора из перечислений.
class EnumDropdownTypeAheadField<T> extends StatelessWidget {
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
  final Function(T) onSelected;
  
  /// Функция валидации.
  final String? Function(String?)? validator;

  /// Отображать ли индикатор загрузки.
  final bool isLoading;

  /// Флаг только для чтения.
  final bool readOnly;
  
  /// Иконка в конце поля ввода (по умолчанию стрелка вниз)
  final IconData? suffixIcon;

  /// Создает поле с автодополнением для значений Enum.
  const EnumDropdownTypeAheadField({
    super.key,
    required this.controller,
    required this.values,
    required this.textConverter,
    required this.labelText,
    required this.hintText,
    required this.onSelected,
    this.validator,
    this.isLoading = false,
    this.readOnly = false,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownTypeAheadField<T>(
      controller: controller,
      labelText: labelText,
      hintText: hintText,
      items: values,
      displayStringForOption: textConverter,
      onSelected: onSelected,
      validator: validator,
      isLoading: isLoading,
      readOnly: readOnly,
      suffixIcon: suffixIcon,
      allowCustomValues: false, // для Enum не позволяем создавать новые значения
    );
  }
}

/// Специализированная версия выпадающего списка для строк.
///
/// Упрощает создание строковых списков с возможностью добавления новых значений.
class StringDropdownTypeAheadField extends StatelessWidget {
  /// Контроллер для текстового поля.
  final TextEditingController controller;
  
  /// Список строковых значений для выбора.
  final List<String> values;
  
  /// Заголовок поля.
  final String labelText;
  
  /// Подсказка в пустом поле.
  final String hintText;
  
  /// Обработчик выбора значения.
  final Function(String) onSelected;
  
  /// Функция валидации.
  final String? Function(String?)? validator;
  
  /// Можно ли добавлять новые значения.
  final bool allowCustomValues;
  
  /// Текст для добавления нового значения.
  final String? addNewItemText;

  /// Отображать ли индикатор загрузки.
  final bool isLoading;
  
  /// Иконка в конце поля ввода (по умолчанию стрелка вниз)
  final IconData? suffixIcon;

  /// Создает строковое поле с автодополнением.
  const StringDropdownTypeAheadField({
    super.key,
    required this.controller,
    required this.values,
    required this.labelText,
    required this.hintText,
    required this.onSelected,
    this.validator,
    this.allowCustomValues = true,
    this.addNewItemText,
    this.isLoading = false,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownTypeAheadField<String>(
      controller: controller,
      labelText: labelText,
      hintText: hintText,
      items: values,
      displayStringForOption: (value) => value,
      onSelected: onSelected,
      validator: validator,
      allowCustomValues: allowCustomValues,
      addNewItemText: addNewItemText,
      isLoading: isLoading,
      suffixIcon: suffixIcon,
    );
  }
} 