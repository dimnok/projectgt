import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../core/utils/formatters.dart';

/// Заголовок группы смет по объекту в мобильном реестре.
///
/// Показывает название объекта, число смет и общую сумму.
/// Нажатие раскрывает или сворачивает список смет объекта.
class EstimateMobileObjectHeader extends StatelessWidget {
  /// Название объекта.
  final String name;

  /// Количество смет в группе.
  final int estimatesCount;

  /// Сумма всех смет объекта.
  final double total;

  /// Раскрыта ли группа.
  final bool isExpanded;

  /// Обработчик нажатия (раскрыть / свернуть).
  final VoidCallback onTap;

  /// Создаёт заголовок группы объекта.
  const EstimateMobileObjectHeader({
    super.key,
    required this.name,
    required this.estimatesCount,
    required this.total,
    required this.isExpanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitle =
        '$estimatesCount ${_pluralizeEstimates(estimatesCount)} • ${formatCurrency(total)}';

    return Semantics(
      button: true,
      expanded: isExpanded,
      label: '$name, $subtitle',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedRotation(
                  turns: isExpanded ? 0.25 : 0,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  child: Icon(
                    CupertinoIcons.chevron_right,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Возвращает форму слова «смета» по числу.
  static String _pluralizeEstimates(int count) {
    if (count % 10 == 1 && count % 100 != 11) {
      return 'смета';
    }
    if ([2, 3, 4].contains(count % 10) && ![12, 13, 14].contains(count % 100)) {
      return 'сметы';
    }
    return 'смет';
  }
}
