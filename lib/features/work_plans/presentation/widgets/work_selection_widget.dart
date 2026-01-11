import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:projectgt/core/widgets/gt_text_field.dart';
import 'package:projectgt/domain/entities/estimate.dart';
import 'package:projectgt/core/utils/formatters.dart';

/// Модель для выбранной работы с объемом
class SelectedWork {
  /// Работа из сметы, для которой выбирается объём.
  final Estimate estimate;

  /// Запланированное количество по выбранной работе.
  final double quantity;

  /// Создаёт экземпляр [SelectedWork] с указанной работой [estimate]
  /// и количеством [quantity].
  const SelectedWork({
    required this.estimate,
    required this.quantity,
  });

  /// Возвращает копию объекта с возможностью переопределить отдельные поля.
  SelectedWork copyWith({
    Estimate? estimate,
    double? quantity,
  }) {
    return SelectedWork(
      estimate: estimate ?? this.estimate,
      quantity: quantity ?? this.quantity,
    );
  }

  /// Рассчитывает общую стоимость работы
  double get totalCost => estimate.price * quantity;
}

/// Виджет для выбора работ с указанием объемов
/// Виджет выбора работ с указанием объёмов для выбранной системы.
class WorkSelectionWidget extends StatefulWidget {
  /// Список доступных работ
  final List<Estimate> availableWorks;

  /// Список выбранных работ с объемами
  final List<SelectedWork> selectedWorks;

  /// Колбэк при изменении выбранных работ
  final void Function(List<SelectedWork>) onSelectionChanged;

  /// Заголовок виджета
  final String title;

  /// Флаг состояния загрузки
  final bool isLoading;

  /// Флаг только для чтения
  final bool readOnly;

  /// Создаёт виджет выбора работ.
  const WorkSelectionWidget({
    super.key,
    required this.availableWorks,
    required this.selectedWorks,
    required this.onSelectionChanged,
    this.title = 'Работы',
    this.isLoading = false,
    this.readOnly = false,
  });

  @override
  State<WorkSelectionWidget> createState() => _WorkSelectionWidgetState();
}

class _WorkSelectionWidgetState extends State<WorkSelectionWidget> {
  late List<SelectedWork> _selectedWorks;
  final Map<String, TextEditingController> _controllers = {};
  final TextEditingController _searchController = TextEditingController();
  List<Estimate> _filteredWorks = [];

  @override
  void initState() {
    super.initState();
    _selectedWorks = List.from(widget.selectedWorks);
    _filteredWorks = List.from(widget.availableWorks);
    _initControllers();
    _searchController.addListener(_filterWorks);
  }

  @override
  void didUpdateWidget(WorkSelectionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedWorks != widget.selectedWorks) {
      _selectedWorks = List.from(widget.selectedWorks);
      _updateControllers();
    }
    if (oldWidget.availableWorks != widget.availableWorks) {
      _filterWorks();
    }
  }

  void _initControllers() {
    _controllers.clear();
    for (final work in _selectedWorks) {
      _controllers[work.estimate.id] = TextEditingController(
        text: work.quantity == 0.0 ? '' : work.quantity.toString(),
      );
    }
  }

  void _updateControllers() {
    // Удаляем контроллеры для работ, которых больше нет
    _controllers.removeWhere((id, controller) {
      final exists = _selectedWorks.any((work) => work.estimate.id == id);
      if (!exists) {
        controller.dispose();
      }
      return !exists;
    });

    // Добавляем контроллеры для новых работ
    for (final work in _selectedWorks) {
      if (!_controllers.containsKey(work.estimate.id)) {
        _controllers[work.estimate.id] = TextEditingController(
          text: work.quantity == 0.0 ? '' : work.quantity.toString(),
        );
      }
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _searchController.dispose();
    super.dispose();
  }

  /// Фильтрует список работ по поисковому запросу
  void _filterWorks() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        _filteredWorks = List.from(widget.availableWorks);
      } else {
        _filteredWorks = widget.availableWorks
            .where((work) => work.name.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  bool _isWorkSelected(Estimate work) {
    return _selectedWorks.any((selected) => selected.estimate.id == work.id);
  }

  // Удалён метод получения количества — отображение суммы/количества справа упрощено

  void _toggleWork(Estimate work, bool isSelected) {
    if (widget.readOnly || widget.isLoading) return;

    setState(() {
      if (isSelected) {
        _selectedWorks.add(SelectedWork(estimate: work, quantity: 0.0));
        _controllers[work.id] = TextEditingController(text: '');
      } else {
        _selectedWorks
            .removeWhere((selected) => selected.estimate.id == work.id);
        _controllers[work.id]?.dispose();
        _controllers.remove(work.id);
      }
    });

    widget.onSelectionChanged(_selectedWorks);
  }

  void _updateQuantity(Estimate work, double quantity) {
    if (widget.readOnly || widget.isLoading) return;

    setState(() {
      final index = _selectedWorks.indexWhere(
        (selected) => selected.estimate.id == work.id,
      );
      if (index != -1) {
        _selectedWorks[index] =
            _selectedWorks[index].copyWith(quantity: quantity);
      }
    });

    widget.onSelectionChanged(_selectedWorks);
  }

  double get _totalCost {
    return _selectedWorks.fold(0.0, (sum, work) => sum + work.totalCost);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (widget.availableWorks.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.availableWorks.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: GTTextField(
              controller: _searchController,
              enabled: !widget.readOnly && !widget.isLoading,
              hintText: 'Поиск работ по названию...',
              prefixIcon: CupertinoIcons.search,
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(CupertinoIcons.clear),
                      onPressed: () {
                        _searchController.clear();
                        FocusScope.of(context).unfocus();
                      },
                    )
                  : null,
            ),
          ),

        // Список работ
        Container(
          constraints: const BoxConstraints(maxHeight: 400),
          child: _filteredWorks.isEmpty && _searchController.text.isNotEmpty
              ? Container(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(
                        CupertinoIcons.search,
                        size: 48,
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Работы не найдены',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Попробуйте изменить поисковый запрос',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  itemCount: _filteredWorks.length,
                  itemBuilder: (context, index) {
                    final work = _filteredWorks[index];
                    final isSelected = _isWorkSelected(work);
                    // quantity отображение суммы удалено

                    final isDark = theme.brightness == Brightness.dark;
                    return Card(
                      color: isSelected
                          ? (isDark
                              ? theme.colorScheme.primaryContainer
                                  .withValues(alpha: 0.15)
                              : Colors.green.shade50)
                          : null,
                      elevation: isSelected ? 2 : 0,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: Theme(
                        data: Theme.of(context).copyWith(
                          splashFactory: NoSplash.splashFactory,
                          highlightColor: Colors.transparent,
                          splashColor: Colors.transparent,
                        ),
                        child: ListTile(
                          onTap: widget.readOnly || widget.isLoading
                              ? null
                              : () => _toggleWork(work, !isSelected),
                          hoverColor: Colors.transparent,
                          enableFeedback: false,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          title: Text(
                            work.name,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: isSelected
                                  ? (isDark
                                      ? theme.colorScheme.primary
                                      : Colors.green.shade700)
                                  : null,
                            ),
                          ),
                          subtitle: Text(
                            '${work.unit} • ${formatCurrency(work.price)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isSelected
                                  ? (isDark
                                      ? theme.colorScheme.primary
                                          .withValues(alpha: 0.8)
                                      : Colors.green.shade600)
                                  : theme.colorScheme.onSurface
                                      .withValues(alpha: 0.7),
                            ),
                          ),
                          trailing: isSelected
                              ? SizedBox(
                                  width: 64,
                                  child: GTTextField(
                                    controller: _controllers[work.id],
                                    enabled:
                                        !widget.readOnly && !widget.isLoading,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                        // ignore: deprecated_member_use
                                        RegExp(r'^\d*\.?\d*'),
                                      ),
                                    ],
                                    hintText: '0',
                                    onChanged: (value) {
                                      final parsedValue =
                                          double.tryParse(value);
                                      if (parsedValue != null &&
                                          parsedValue > 0) {
                                        _updateQuantity(work, parsedValue);
                                      } else if (value.isEmpty) {
                                        _updateQuantity(work, 0.0);
                                      }
                                    },
                                  ),
                                )
                              : null,
                        ),
                      ),
                    );
                  },
                ),
        ),

        // Итоговая сумма
        if (_selectedWorks.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Общая стоимость:',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  formatCurrency(_totalCost),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
