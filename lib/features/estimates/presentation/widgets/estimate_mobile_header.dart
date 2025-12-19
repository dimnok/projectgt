import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../domain/entities/estimate.dart';

/// Хедер для мобильной версии экрана сметы.
///
/// Содержит:
/// - Поисковую строку
class EstimateMobileHeader extends StatelessWidget {
  /// Контроллер поля поиска.
  final TextEditingController searchController;

  /// Список всех позиций сметы.
  final List<Estimate> items;

  /// Количество позиций после фильтрации.
  final int filteredCount;

  /// Создаёт хедер для мобильной версии сметы.
  const EstimateMobileHeader({
    super.key,
    required this.searchController,
    required this.items,
    required this.filteredCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Column(
        children: [
          // Поисковая строка (iOS стиль)
          CupertinoSearchTextField(
            controller: searchController,
            placeholder: 'Поиск по смете...',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
            placeholderStyle: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            decoration: BoxDecoration(
              color: theme.brightness == Brightness.dark
                  ? theme.colorScheme.surfaceContainerHighest
                  : theme.colorScheme.onSurface.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            itemColor: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),

          const SizedBox(height: 8),

          // Счетчик найденных позиций
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                'Найдено: $filteredCount из ${items.length}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
