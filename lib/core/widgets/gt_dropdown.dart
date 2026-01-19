import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

// Константы для улучшения читаемости и переиспользования
const double _kDropdownBorderRadius = 8.0;
const double _kDialogBorderRadius = 16.0;
const double _kDropdownElevation = 4.0;
const double _kDropdownOffset = 5.0;
const EdgeInsets _kDropdownItemPadding = EdgeInsets.symmetric(
  horizontal: 16,
  vertical: 12,
);
const EdgeInsets _kEmptyStatePadding = EdgeInsets.all(16);

/// Кастомный выпадающий список для проекта GT.
///
/// Поддерживает одинарный выбор, множественный выбор, ручной ввод
/// и полностью соответствует дизайн-системе проекта.
class GTDropdown<T> extends StatefulWidget {
  /// Список доступных элементов
  final List<T> items;

  /// Функция для отображения элемента
  final String Function(T item) itemDisplayBuilder;

  /// Текущие выбранные значения (для множественного выбора)
  final List<T> selectedItems;

  /// Текущее выбранное значение (для одинарного выбора)
  final T? selectedItem;

  /// Callback для изменения выбора (множественный)
  final Function(List<T> items)? onMultiSelectionChanged;

  /// Callback для изменения выбора (одинарный)
  final Function(T? item)? onSelectionChanged;

  /// Заголовок поля
  final String labelText;

  /// Подсказка
  final String hintText;

  /// Разрешить множественный выбор
  final bool allowMultipleSelection;

  /// Разрешить ручной ввод новых значений
  final bool allowCustomInput;

  /// Показывать поле для добавления нового элемента
  final bool showAddNewOption;

  /// Разрешить очистку поля
  final bool allowClear;

  /// Функция валидации
  final String? Function(String?)? validator;

  /// Только для чтения
  final bool readOnly;

  /// Показывать ли индикатор загрузки
  final bool isLoading;

  /// Максимальная высота выпадающего списка
  final double maxDropdownHeight;

  /// Отступы внутри поля
  final EdgeInsets? contentPadding;

  /// Плотный режим отображения
  final bool isDense;

  /// Стиль текста в поле
  final TextStyle? style;

  /// Радиус скругления углов.
  final double borderRadius;

  /// Цвет и стиль границы.
  final BorderSide? borderSide;

  /// Иконка в начале поля.
  final IconData? prefixIcon;

  /// Функция для создания нового элемента из строки (для allowCustomInput).
  final T Function(String input)? customInputBuilder;

  /// Создает кастомный выпадающий список GTDropdown.
  ///
  /// [items] — список элементов для выбора.
  /// [itemDisplayBuilder] — преобразует элемент [T] в строку для отображения.
  /// [labelText] — заголовок поля.
  /// [hintText] — подсказка внутри поля.
  /// [borderRadius] — скругление углов (по умолчанию 16.0).
  /// [allowClear] — разрешить очистку выбранного значения.
  const GTDropdown({
    super.key,
    required this.items,
    required this.itemDisplayBuilder,
    required this.labelText,
    required this.hintText,
    this.selectedItems = const [],
    this.selectedItem,
    this.onMultiSelectionChanged,
    this.onSelectionChanged,
    this.allowMultipleSelection = false,
    this.allowCustomInput = false,
    this.showAddNewOption = false,
    this.allowClear = true,
    this.validator,
    this.readOnly = false,
    this.isLoading = false,
    this.maxDropdownHeight = 200,
    this.contentPadding,
    this.isDense = false,
    this.style,
    this.borderRadius = 16.0,
    this.borderSide,
    this.prefixIcon,
    this.customInputBuilder,
  }) : assert(
         !allowMultipleSelection || onMultiSelectionChanged != null,
         'onMultiSelectionChanged required for multiple selection',
       ),
       assert(
         allowMultipleSelection || onSelectionChanged != null,
         'onSelectionChanged required for single selection',
       );

  @override
  State<GTDropdown<T>> createState() => _GTDropdownState<T>();
}

class _GTDropdownState<T> extends State<GTDropdown<T>> {
  final LayerLink _layerLink = LayerLink();
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _addNewController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  OverlayEntry? _overlayEntry;
  bool _isDropdownOpen = false;

  @override
  void initState() {
    super.initState();
    // Устанавливаем начальный текст синхронно в initState
    _setInitialDisplayText();
  }

  void _setInitialDisplayText() {
    if (widget.allowMultipleSelection) {
      if (widget.selectedItems.isEmpty) {
        _textController.text = '';
      } else if (widget.selectedItems.length == 1) {
        _textController.text = widget.itemDisplayBuilder(
          widget.selectedItems.first,
        );
      } else {
        _textController.text = '${widget.selectedItems.length} выбрано';
      }
    } else {
      _textController.text = widget.selectedItem != null
          ? widget.itemDisplayBuilder(widget.selectedItem as T)
          : '';
    }
  }

  @override
  void didUpdateWidget(GTDropdown<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final hasSelectionChanged = _hasSelectionChanged(oldWidget);
    final hasItemsChanged =
        widget.items.length != oldWidget.items.length ||
        !_areItemsEqual(widget.items, oldWidget.items);

    if (hasSelectionChanged) {
      _updateDisplayText();
      _updateOverlayIfNeeded();
    }

    // Если список элементов изменился, обновляем overlay
    if (hasItemsChanged && _isDropdownOpen) {
      _updateOverlayIfNeeded();
    }
  }

  bool _areItemsEqual(List<T> list1, List<T> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i] != list2[i]) return false;
    }
    return true;
  }

  bool _hasSelectionChanged(GTDropdown<T> oldWidget) {
    return widget.selectedItems != oldWidget.selectedItems ||
        widget.selectedItem != oldWidget.selectedItem;
  }

  void _updateOverlayIfNeeded() {
    if (mounted && _isDropdownOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _overlayEntry?.markNeedsBuild();
      });
    }
  }

  @override
  void dispose() {
    _closeDropdown();
    _textController.dispose();
    _addNewController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  bool _isItemSelected(T item) {
    if (widget.selectedItem == null) return false;
    // Для enum используем сравнение через name для надёжности
    if (item is Enum && widget.selectedItem is Enum) {
      return (item as Enum).name == (widget.selectedItem as Enum).name &&
          item.runtimeType == widget.selectedItem.runtimeType;
    }
    return widget.selectedItem == item;
  }

  void _updateDisplayText() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      if (widget.allowMultipleSelection) {
        if (widget.selectedItems.isEmpty) {
          _textController.text = '';
        } else if (widget.selectedItems.length == 1) {
          _textController.text = widget.itemDisplayBuilder(
            widget.selectedItems.first,
          );
        } else {
          _textController.text = '${widget.selectedItems.length} выбрано';
        }
      } else {
        _textController.text = widget.selectedItem != null
            ? widget.itemDisplayBuilder(widget.selectedItem as T)
            : '';
      }
    });
  }

  void _openDropdown() {
    if (_isDropdownOpen || widget.isLoading) return;

    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    setState(() {
      _isDropdownOpen = true;
    });
  }

  void _closeDropdown() {
    if (!_isDropdownOpen) return;

    _overlayEntry?.remove();
    _overlayEntry = null;
    setState(() {
      _isDropdownOpen = false;
    });
    _updateDisplayText();
  }

  OverlayEntry _createOverlayEntry() {
    final RenderBox renderBox = context.findRenderObject()! as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);
    final media = MediaQuery.of(context);
    final screenHeight = media.size.height;
    final topInset = media.padding.top;
    final keyboardInset = media.viewInsets.bottom;
    const double margin = 8.0;

    // Доступные области сверху/снизу с учётом клавиатуры и отступов
    final double availableBelow =
        (screenHeight - keyboardInset) - (offset.dy + size.height) - margin;
    final double availableAbove = (offset.dy - topInset) - margin;

    // Решаем, куда открывать: вверх, если снизу мало места и сверху его больше
    final bool openUpwards =
        availableBelow < 180 && availableAbove > availableBelow;
    final double desired = widget.maxDropdownHeight;
    final double computedMaxHeight = () {
      final double space = openUpwards ? availableAbove : availableBelow;
      final double safeSpace = space.isFinite ? space : desired;
      // Ограничиваем в разумных пределах
      return safeSpace.clamp(120.0, desired);
    }();
    final double followerDy = openUpwards
        ? -(computedMaxHeight + _kDropdownOffset)
        : (size.height + _kDropdownOffset);

    return OverlayEntry(
      builder: (context) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _closeDropdown, // Закрываем при клике в любом месте
        child: Stack(
          children: [
            // Невидимый слой на весь экран для перехвата кликов
            Positioned.fill(child: Container(color: Colors.transparent)),
            // Сам dropdown
            Positioned(
              width: size.width,
              child: CompositedTransformFollower(
                link: _layerLink,
                showWhenUnlinked: false,
                offset: Offset(0.0, followerDy),
                child: GestureDetector(
                  onTap: () {}, // Предотвращаем закрытие при клике на dropdown
                  child: Material(
                    elevation: _kDropdownElevation,
                    borderRadius: BorderRadius.circular(_kDropdownBorderRadius),
                    clipBehavior: Clip.antiAlias,
                    child: _buildDropdownContent(maxHeight: computedMaxHeight),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownContent({double? maxHeight}) {
    final theme = Theme.of(context);
    final shouldShowAddButton =
        widget.showAddNewOption && widget.allowCustomInput && !widget.readOnly;

    return Container(
      constraints: BoxConstraints(
        maxHeight: maxHeight ?? widget.maxDropdownHeight,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(_kDropdownBorderRadius),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Список элементов
          Flexible(
            child: widget.items.isEmpty
                ? _buildEmptyStateWithAdd()
                : _buildItemsList(shouldShowAddButton),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsList(bool shouldShowAddButton) {
    final itemCount = widget.items.length + (shouldShowAddButton ? 1 : 0);

    return ListView.builder(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      itemCount: itemCount,
      itemBuilder: (context, index) {
        // Последний элемент - кнопка добавления
        if (shouldShowAddButton && index == widget.items.length) {
          return _buildAddNewButton();
        }

        final item = widget.items[index];
        return _buildDropdownItem(item);
      },
    );
  }

  Widget _buildDropdownItem(T item) {
    final theme = Theme.of(context);
    final isSelected = widget.allowMultipleSelection
        ? widget.selectedItems.contains(item)
        : _isItemSelected(item);

    return InkWell(
      onTap: () => _onItemTap(item),
      child: Container(
        padding: _kDropdownItemPadding,
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primaryContainer.withValues(alpha: 0.1)
              : null,
        ),
        child: Row(
          children: [
            // Чекбокс для множественного выбора
            if (widget.allowMultipleSelection) ...[
              Icon(
                isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                size: 20,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline,
              ),
              const SizedBox(width: 12),
            ],

            // Текст элемента
            Expanded(
              child: Text(
                widget.itemDisplayBuilder(item),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface,
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
            ),

            // Иконка выбора для одинарного выбора
            if (!widget.allowMultipleSelection && isSelected)
              Icon(Icons.check, size: 20, color: theme.colorScheme.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyStateWithAdd() {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: _kEmptyStatePadding,
          child: Text(
            'Нет элементов для отображения',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.outline,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        if (widget.showAddNewOption &&
            widget.allowCustomInput &&
            !widget.readOnly)
          _buildAddNewButton(),
      ],
    );
  }

  Widget _buildAddNewButton() {
    final theme = Theme.of(context);

    return InkWell(
      onTap: _showAddNewDialog,
      child: Container(
        padding: _kDropdownItemPadding,
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.add_circle_outline,
              size: 20,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Добавить новый элемент',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddNewDialog() {
    if (!mounted) return;

    final theme = Theme.of(context);
    _addNewController.clear();

    // Закрываем dropdown перед открытием модального окна
    _closeDropdown();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_kDialogBorderRadius),
        ),
        title: Center(
          child: Text(
            'Добавить новый элемент',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _addNewController,
              autofocus: true,
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: 'Введите название...',
                hintStyle: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onSubmitted: (value) {
                if (value.trim().isNotEmpty) {
                  _addNewItemFromDialog(value.trim());
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        ),
        actions: [
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      shape: const StadiumBorder(), // Полностью круглые края
                      side: BorderSide(
                        color: theme.colorScheme.outline,
                        width: 1.5,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      'Отмена',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final value = _addNewController.text.trim();
                      if (value.isNotEmpty) {
                        _addNewItemFromDialog(value);
                        Navigator.of(context).pop();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      shape: const StadiumBorder(), // Полностью круглые края
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      side: BorderSide(
                        color: theme.colorScheme.primary,
                        width: 1.5,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 2,
                    ),
                    child: Text(
                      'Добавить',
                      style: TextStyle(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      ),
    );
  }

  void _addNewItemFromDialog(String value) {
    if (widget.customInputBuilder == null || !mounted) return;

    final trimmedValue = value.trim();
    if (trimmedValue.isEmpty) return;

    HapticFeedback.selectionClick();

    try {
      final newItem = widget.customInputBuilder!(trimmedValue);

      if (widget.allowMultipleSelection) {
        _handleMultipleSelectionAdd(newItem);
      } else {
        _handleSingleSelectionAdd(newItem);
      }
    } catch (e) {
      // Обработка ошибки создания элемента
      debugPrint('Error creating new item: $e');
    }
  }

  void _handleMultipleSelectionAdd(T newItem) {
    final newSelection = List<T>.from(widget.selectedItems);
    if (!newSelection.contains(newItem)) {
      newSelection.add(newItem);
      widget.onMultiSelectionChanged!(newSelection);

      // Обновляем overlay только для множественного выбора
      if (mounted && _isDropdownOpen) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _overlayEntry?.markNeedsBuild();
        });
      }
    }
  }

  void _handleSingleSelectionAdd(T newItem) {
    widget.onSelectionChanged!(newItem);
    _closeDropdown();
    _focusNode.unfocus();
    // Для одинарного выбора overlay уже закрыт, обновление не нужно
  }

  void _onItemTap(T item) {
    if (!mounted) return;

    HapticFeedback.selectionClick();

    if (widget.allowMultipleSelection) {
      _handleMultipleSelectionToggle(item);
    } else {
      _handleSingleSelectionTap(item);
    }
  }

  void _handleMultipleSelectionToggle(T item) {
    final newSelection = List<T>.from(widget.selectedItems);
    if (newSelection.contains(item)) {
      newSelection.remove(item);
    } else {
      newSelection.add(item);
    }

    widget.onMultiSelectionChanged!(newSelection);

    // Обновляем overlay для отображения изменений чекбоксов
    if (mounted && _isDropdownOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _overlayEntry?.markNeedsBuild();
      });
    }
  }

  void _handleSingleSelectionTap(T item) {
    widget.onSelectionChanged!(item);
    _closeDropdown();
    _focusNode.unfocus();
  }

  void _clearSelection() {
    if (!mounted) return;

    HapticFeedback.selectionClick();

    if (widget.allowMultipleSelection) {
      widget.onMultiSelectionChanged!([]);
    } else {
      widget.onSelectionChanged!(null);
    }

    _closeDropdown();
  }

  bool _hasSelection() {
    if (widget.allowMultipleSelection) {
      return widget.selectedItems.isNotEmpty;
    } else {
      return widget.selectedItem != null;
    }
  }

  Widget _buildSuffixIcon() {
    final theme = Theme.of(context);

    // Показываем иконку очистки если есть выбранные элементы и разрешена очистка
    if (widget.allowClear && _hasSelection() && !widget.readOnly) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Иконка очистки
          InkWell(
            onTap: _clearSelection,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(4),
              child: Icon(
                Icons.clear,
                size: 18,
                color: theme.colorScheme.outline,
              ),
            ),
          ),
          const SizedBox(width: 4),
          // Стрелка dropdown
          Icon(
            _isDropdownOpen
                ? Icons.keyboard_arrow_up
                : Icons.keyboard_arrow_down,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(width: 8),
        ],
      );
    }

    // Только стрелка dropdown
    return Icon(
      _isDropdownOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
      color: theme.colorScheme.outline,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return CompositedTransformTarget(
      link: _layerLink,
      child: TextFormField(
        controller: _textController,
        focusNode: _focusNode,
        style: widget.style ?? const TextStyle(fontSize: 15),
        readOnly:
            true, // Всегда только для чтения, чтобы не открывалась клавиатура
        validator: widget.validator,
        decoration: InputDecoration(
          labelText: widget.labelText.isEmpty ? null : widget.labelText,
          hintText: widget.hintText,
          isDense: widget.isDense,
          prefixIcon: widget.prefixIcon != null
              ? Icon(widget.prefixIcon, size: 20)
              : null,
          contentPadding:
              widget.contentPadding ??
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          suffixIconConstraints: widget.isDense
              ? const BoxConstraints(minWidth: 32, minHeight: 20)
              : null,
          suffixIcon: widget.isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CupertinoActivityIndicator(radius: 8),
                )
              : _buildSuffixIcon(),
          filled: true,
          fillColor: !widget.readOnly
              ? (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white)
              : (isDark
                    ? Colors.white.withValues(alpha: 0.02)
                    : Colors.grey.withValues(alpha: 0.05)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            borderSide:
                widget.borderSide ??
                BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black12,
                ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            borderSide:
                widget.borderSide ??
                BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black12,
                ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            borderSide:
                widget.borderSide?.copyWith(
                  color: isDark ? Colors.white : Colors.black,
                  width: 1.5,
                ) ??
                BorderSide(
                  color: isDark ? Colors.white : Colors.black,
                  width: 1.5,
                ),
          ),
        ),
        onTap: () {
          // Проверяем, можно ли открыть dropdown
          if (widget.readOnly || widget.isLoading) return;

          if (!_isDropdownOpen) {
            _openDropdown();
          } else {
            _closeDropdown();
          }
        },
      ),
    );
  }
}

/// Упрощенный dropdown для enum значений.
///
/// Предоставляет удобный интерфейс для работы с enum типами.
class GTEnumDropdown<T extends Enum> extends StatelessWidget {
  /// Список доступных enum значений.
  final List<T> values;

  /// Текущее выбранное значение.
  final T? selectedValue;

  /// Callback при изменении выбора.
  final Function(T?) onChanged;

  /// Текст метки для поля.
  final String labelText;

  /// Подсказка для поля.
  final String hintText;

  /// Функция преобразования enum в строку для отображения.
  final String Function(T) enumToString;

  /// Функция валидации поля.
  final String? Function(String?)? validator;

  /// Поле только для чтения.
  final bool readOnly;

  /// Разрешить очистку выбора.
  final bool allowClear;

  /// Отступы внутри поля.
  final EdgeInsets? contentPadding;

  /// Плотный режим отображения.
  final bool isDense;

  /// Стиль текста в поле.
  final TextStyle? style;

  /// Радиус скругления углов.
  final double borderRadius;

  /// Создает dropdown для enum значений.
  ///
  /// [values] — список доступных вариантов enum.
  /// [selectedValue] — текущее выбранное значение.
  /// [onChanged] — callback при изменении выбора.
  /// [enumToString] — функция преобразования enum в человекочитаемую строку.
  /// [borderRadius] — скругление углов (по умолчанию 16.0).
  const GTEnumDropdown({
    super.key,
    required this.values,
    required this.selectedValue,
    required this.onChanged,
    required this.labelText,
    required this.hintText,
    required this.enumToString,
    this.validator,
    this.readOnly = false,
    this.allowClear = true,
    this.contentPadding,
    this.isDense = false,
    this.style,
    this.borderRadius = 16.0,
  });

  @override
  Widget build(BuildContext context) {
    // Всегда передаём не-null callback, даже если readOnly
    final effectiveOnChanged = readOnly ? (T? value) {} : onChanged;

    return GTDropdown<T>(
      items: values,
      itemDisplayBuilder: enumToString,
      selectedItem: selectedValue,
      onSelectionChanged: effectiveOnChanged,
      labelText: labelText,
      hintText: hintText,
      allowMultipleSelection: false,
      allowCustomInput: false,
      allowClear: allowClear,
      validator: validator,
      readOnly: readOnly,
      contentPadding: contentPadding,
      isDense: isDense,
      style: style,
      borderRadius: borderRadius,
    );
  }
}

/// Dropdown для строк с возможностью добавления новых.
///
/// Специализированный dropdown для работы со строками с поддержкой
/// множественного выбора и добавления новых элементов.
class GTStringDropdown extends StatelessWidget {
  /// Список доступных строковых элементов.
  final List<String> items;

  /// Текущий выбранный элемент для одинарного выбора.
  final String? selectedItem;

  /// Список выбранных элементов для множественного выбора.
  final List<String> selectedItems;

  /// Callback при изменении одинарного выбора.
  final Function(String?)? onSelectionChanged;

  /// Callback при изменении множественного выбора.
  final Function(List<String>)? onMultiSelectionChanged;

  /// Текст метки для поля.
  final String labelText;

  /// Подсказка для поля.
  final String hintText;

  /// Разрешить множественный выбор.
  final bool allowMultipleSelection;

  /// Разрешить ручной ввод новых значений.
  final bool allowCustomInput;

  /// Показывать кнопку добавления нового элемента.
  final bool showAddNewOption;

  /// Разрешить очистку выбора.
  final bool allowClear;

  /// Функция валидации поля.
  final String? Function(String?)? validator;

  /// Поле только для чтения.
  final bool readOnly;

  /// Показывать ли индикатор загрузки.
  final bool isLoading;

  /// Отступы внутри поля.
  final EdgeInsets? contentPadding;

  /// Плотный режим отображения.
  final bool isDense;

  /// Стиль текста в поле.
  final TextStyle? style;

  /// Радиус скругления углов.
  final double borderRadius;

  /// Создает dropdown для строковых значений.
  ///
  /// [items] — список строк для выбора.
  /// [selectedItem] — текущая выбранная строка.
  /// [onSelectionChanged] — callback при изменении выбора.
  /// [allowCustomInput] — разрешить ручной ввод произвольных строк.
  /// [borderRadius] — скругление углов (по умолчанию 16.0).
  const GTStringDropdown({
    super.key,
    required this.items,
    required this.labelText,
    required this.hintText,
    this.selectedItem,
    this.selectedItems = const [],
    this.onSelectionChanged,
    this.onMultiSelectionChanged,
    this.allowMultipleSelection = false,
    this.allowCustomInput = true,
    this.showAddNewOption = false,
    this.allowClear = true,
    this.validator,
    this.readOnly = false,
    this.isLoading = false,
    this.contentPadding,
    this.isDense = false,
    this.style,
    this.borderRadius = 16.0,
  });

  @override
  Widget build(BuildContext context) {
    return GTDropdown<String>(
      items: items,
      itemDisplayBuilder: (item) => item,
      selectedItem: selectedItem,
      selectedItems: selectedItems,
      onSelectionChanged: onSelectionChanged,
      onMultiSelectionChanged: onMultiSelectionChanged,
      labelText: labelText,
      hintText: hintText,
      allowMultipleSelection: allowMultipleSelection,
      allowCustomInput: allowCustomInput,
      showAddNewOption: showAddNewOption,
      allowClear: allowClear,
      customInputBuilder: (input) => input,
      validator: validator,
      readOnly: readOnly,
      isLoading: isLoading,
      contentPadding: contentPadding,
      isDense: isDense,
      style: style,
      borderRadius: borderRadius,
    );
  }
}
