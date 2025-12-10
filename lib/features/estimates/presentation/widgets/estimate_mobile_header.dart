import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../domain/entities/estimate.dart';

/// Хедер для мобильной версии экрана сметы.
///
/// Содержит:
/// - Поисковую строку
/// - Кнопку сортировки
/// - Статистику (кол-во позиций, сумма)
/// - Быстрые фильтры (чипсы по системам)
class EstimateMobileHeader extends StatelessWidget {
  /// Контроллер поля поиска.
  final TextEditingController searchController;

  /// Список всех позиций сметы.
  final List<Estimate> items;

  /// Количество позиций после фильтрации.
  final int filteredCount;

  /// Текущий критерий сортировки.
  final String sortCriterion;

  /// Направление сортировки (по возрастанию).
  final bool sortAscending;

  /// Коллбек нажатия на кнопку сортировки.
  final VoidCallback onSortPressed;

  /// Коллбек выбора фильтра.
  final ValueChanged<String> onFilterSelected;

  /// Создаёт хедер для мобильной версии сметы.
  const EstimateMobileHeader({
    super.key,
    required this.searchController,
    required this.items,
    required this.filteredCount,
    required this.sortCriterion,
    required this.sortAscending,
    required this.onSortPressed,
    required this.onFilterSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final moneyFormat = NumberFormat('###,##0.00', 'ru_RU');
    final isLargeScreen = MediaQuery.of(context).size.width > 900;

    return Column(
      children: [
        // Поисковая строка и кнопка сортировки
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 30),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: searchController,
                    decoration: const InputDecoration(
                      hintText: 'Поиск по смете...',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 8),
                      prefixIcon: Icon(CupertinoIcons.search, size: 20),
                    ),
                    // При изменении текста мы не перестраиваем виджет сами,
                    // это делает родитель через onChanged контроллера,
                    // но здесь onChanged не обязателен, если родитель слушает контроллер.
                    // Оставим пустым или добавим колбэк, если нужно.
                  ),
                ),
                IconButton(
                  icon: Icon(
                    sortAscending
                        ? CupertinoIcons.arrow_up
                        : CupertinoIcons.arrow_down,
                    size: 18,
                  ),
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Сортировка',
                  onPressed: onSortPressed,
                ),
                // Используем ValueListenableBuilder для кнопки очистки, чтобы не перерисовывать весь виджет
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: searchController,
                  builder: (context, value, child) {
                    if (value.text.isNotEmpty) {
                      return IconButton(
                        icon: const Icon(CupertinoIcons.clear_circled,
                            size: 18),
                        visualDensity: VisualDensity.compact,
                        tooltip: 'Очистить',
                        onPressed: () {
                          searchController.clear();
                          // Необходимо уведомить родителя, если он слушает изменения
                          // В данном случае searchController очищается, listener сработает.
                        },
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),
        ),

        // Статистика по смете
        Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: theme.colorScheme.outline.withValues(alpha: 30),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Статистика по смете',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                // Основные параметры
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Позиций:',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color:
                                  theme.colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                          Text(
                            '${items.length}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Итого:',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color:
                                  theme.colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                          Text(
                            '${moneyFormat.format(items.fold(0.0, (sum, item) => sum + item.total))} ₽',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Быстрые фильтры (системы)
        if (!isLargeScreen)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 4),
                  child: Text(
                    'Быстрые фильтры:',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ValueListenableBuilder<TextEditingValue>(
                    valueListenable: searchController,
                    builder: (context, value, _) {
                      return Row(
                        children: _getUniqueSystems(items).map((system) {
                          final isSelected =
                              value.text.toLowerCase() == system.toLowerCase();
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: FilterChip(
                              label: Text(system, style: const TextStyle(fontSize: 12)),
                              selected: isSelected,
                              showCheckmark: false,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              backgroundColor: theme.colorScheme.surface,
                              selectedColor:
                                  theme.colorScheme.primary.withValues(alpha: 0.2),
                              side: BorderSide(
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.outline.withValues(alpha: 50),
                                width: 1,
                              ),
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurface,
                                fontWeight: isSelected ? FontWeight.bold : null,
                              ),
                              onSelected: (selected) {
                                if (selected && !isSelected) {
                                  onFilterSelected(system);
                                } else {
                                  onFilterSelected(''); // Сброс фильтра
                                }
                              },
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

        // Счетчик найденных позиций и информация о сортировке
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Найдено: $filteredCount из ${items.length}',
                style: theme.textTheme.bodySmall,
              ),
              Row(
                children: [
                  Text(
                    'Сортировка: ',
                    style: theme.textTheme.bodySmall,
                  ),
                  Text(
                    {
                          'number': 'По номеру',
                          'name': 'По наименованию',
                          'system': 'По системе',
                          'price': 'По цене',
                          'total': 'По сумме',
                        }[sortCriterion] ??
                        'По номеру',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Icon(
                    sortAscending
                        ? CupertinoIcons.arrow_up
                        : CupertinoIcons.arrow_down,
                    size: 12,
                    color: theme.colorScheme.primary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Возвращает список уникальных систем из списка позиций
  List<String> _getUniqueSystems(List<Estimate> items) {
    final systems = <String>{};
    for (final item in items) {
      if (item.system.isNotEmpty) {
        systems.add(item.system);
      }
    }
    return systems.toList()..sort();
  }
}

