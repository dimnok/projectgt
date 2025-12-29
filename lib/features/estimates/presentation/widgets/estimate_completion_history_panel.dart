import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/formatters.dart';
import '../../../../domain/entities/estimate.dart';
import '../../../../domain/entities/estimate_completion_history.dart';
import '../providers/estimate_providers.dart';

/// Типы фильтрации истории выполнения.
enum _HistoryFilterType { all, summary }

/// Модель фильтра для истории выполнения.
class _HistoryFilter {
  final _HistoryFilterType type;
  final String label;
  final double total;

  const _HistoryFilter({
    required this.type,
    required this.label,
    required this.total,
  });
}

/// Модель агрегированных данных по участку (для общей сводки).
class _AggregatedSection {
  final String section;
  final double total;
  final List<_AggregatedFloor> floors;

  const _AggregatedSection({
    required this.section,
    required this.total,
    required this.floors,
  });
}

/// Модель агрегированных данных по этажу.
class _AggregatedFloor {
  final String floor;
  final double quantity;

  const _AggregatedFloor({
    required this.floor,
    required this.quantity,
  });
}

/// Боковая панель для отображения истории выполнения позиции сметы (заменяет список смет).
class EstimateCompletionHistoryPanel extends ConsumerStatefulWidget {
  /// Создает панель истории выполнения.
  const EstimateCompletionHistoryPanel({
    super.key,
    required this.estimate,
    required this.onClose,
    this.completedQuantity,
  });

  /// Позиция сметы, для которой отображается история.
  final Estimate estimate;

  /// Коллбэк для закрытия панели и возврата к списку смет.
  final VoidCallback onClose;

  /// Общее количество выполненных работ по данной позиции.
  final double? completedQuantity;

  @override
  ConsumerState<EstimateCompletionHistoryPanel> createState() =>
      _EstimateCompletionHistoryPanelState();
}

class _EstimateCompletionHistoryPanelState
    extends ConsumerState<EstimateCompletionHistoryPanel> {
  _HistoryFilterType _selectedType = _HistoryFilterType.all;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final historyAsync =
        ref.watch(estimateCompletionHistoryProvider(widget.estimate.id));
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: 350,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Заголовок панели
          _buildHeader(context, theme),

          const Divider(height: 1),

          // Информация о позиции
          _buildEstimateInfo(theme),

          const Divider(height: 1),

          // Фильтры
          historyAsync.when(
            data: (history) => _buildFilters(theme, history),
            loading: () => const SizedBox(height: 48),
            error: (_, __) => const SizedBox.shrink(),
          ),

          const Divider(height: 1),

          // Список истории
          Expanded(
            child: historyAsync.when(
              data: (history) {
                if (history.isEmpty) {
                  return const Center(
                    child: Text('История выполнения пуста'),
                  );
                }

                if (_selectedType == _HistoryFilterType.all) {
                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: history.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = history[index];
                      return _HistoryItemCard(
                        date: formatRuDate(item.date),
                        quantity: formatQuantity(item.quantity),
                        unit: widget.estimate.unit,
                        section: item.section,
                        floor: item.floor,
                      );
                    },
                  );
                } else {
                  // Общая сводка (иерархия: Участок -> Этажи)
                  final summary = _aggregateAll(history);
                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: summary.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 24),
                    itemBuilder: (context, index) {
                      final section = summary[index];
                      return _SummarySectionWidget(
                        section: section,
                        unit: widget.estimate.unit,
                      );
                    },
                  );
                }
              },
              loading: () => const Center(
                child: CupertinoActivityIndicator(),
              ),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Ошибка: $err',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<_AggregatedSection> _aggregateAll(
      List<EstimateCompletionHistory> history) {
    final sectionMap = <String, Map<String, double>>{};

    for (final item in history) {
      final s = item.section.isEmpty ? 'Без участка' : item.section;
      final f = item.floor.isEmpty ? '—' : item.floor;
      sectionMap.putIfAbsent(s, () => {});
      sectionMap[s]![f] = (sectionMap[s]![f] ?? 0) + item.quantity;
    }

    return sectionMap.entries.map((se) {
      final floorList = se.value.entries
          .map((fe) => _AggregatedFloor(floor: fe.key, quantity: fe.value))
          .toList();

      // Сортировка этажей
      floorList.sort((a, b) {
        final fa = double.tryParse(a.floor) ?? 0;
        final fb = double.tryParse(b.floor) ?? 0;
        if (fa != 0 || fb != 0) return fa.compareTo(fb);
        return a.floor.compareTo(b.floor);
      });

      return _AggregatedSection(
        section: se.key,
        total: se.value.values.fold(0.0, (sum, q) => sum + q),
        floors: floorList,
      );
    }).toList()
      ..sort((a, b) => a.section.compareTo(b.section));
  }

  Widget _buildFilters(
      ThemeData theme, List<EstimateCompletionHistory> history) {
    final totalQty = history.fold(0.0, (sum, item) => sum + item.quantity);

    final filters = <_HistoryFilter>[
      _HistoryFilter(
        type: _HistoryFilterType.all,
        label: 'История',
        total: totalQty,
      ),
      _HistoryFilter(
        type: _HistoryFilterType.summary,
        label: 'Сводка',
        total: totalQty,
      ),
    ];

    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = _selectedType == filter.type;

          return ChoiceChip(
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(width: 4),
                Text(
                  filter.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.bold : null,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '(${formatQuantity(filter.total)})',
                  style: TextStyle(
                    fontSize: 10,
                    color: isSelected
                        ? theme.colorScheme.onPrimaryContainer
                            .withValues(alpha: 0.7)
                        : theme.colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(width: 4),
              ],
            ),
            selected: isSelected,
            onSelected: (selected) {
              if (selected) {
                setState(() {
                  _selectedType = filter.type;
                });
              }
            },
            padding: EdgeInsets.zero,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Исполнение',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          TextButton(
            onPressed: widget.onClose,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'К списку',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEstimateInfo(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '№${widget.estimate.number}',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.outline,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.estimate.name,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Смета: ${formatQuantity(widget.estimate.quantity)} ${widget.estimate.unit}',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (widget.completedQuantity != null)
                Text(
                  'Вып: ${formatQuantity(widget.completedQuantity!)} ${widget.estimate.unit}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummarySectionWidget extends StatelessWidget {
  const _SummarySectionWidget({
    required this.section,
    required this.unit,
  });

  final _AggregatedSection section;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Заголовок участка
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                section.section,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              Text(
                '${formatQuantity(section.total)} $unit',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Список этажей
        Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Column(
            children: section.floors.map((floor) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'этаж — ${floor.floor}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      '${formatQuantity(floor.quantity)} $unit',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _HistoryItemCard extends StatelessWidget {
  const _HistoryItemCard({
    required this.date,
    required this.quantity,
    required this.unit,
    required this.section,
    required this.floor,
  });

  final String date;
  final String quantity;
  final String unit;
  final String section;
  final String floor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outlineVariant,
        ),
      ),
      child: Row(
        children: [
          // Дата
          Text(
            date,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),

          // Участок и этаж (без подписей)
          Expanded(
            child: Row(
              children: [
                if (section.isNotEmpty) ...[
                  Flexible(
                    child: Text(
                      section,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                if (section.isNotEmpty && floor.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      '/',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outlineVariant,
                      ),
                    ),
                  ),
                if (floor.isNotEmpty) ...[
                  Flexible(
                    child: Text(
                      floor,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Количество
          Text(
            '$quantity $unit',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
