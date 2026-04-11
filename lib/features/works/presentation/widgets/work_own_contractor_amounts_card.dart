import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/features/contractors/presentation/state/contractor_state.dart';
import 'package:projectgt/features/works/domain/entities/work_item.dart';

/// Карточка с разбивкой суммы выполненных работ по исполнителю.
///
/// Считает суммы по [WorkItem.total]: без [WorkItem.contractorId] — в блок
/// **«Собственное выполнение»**; с привязкой к контрагенту — по каждому
/// подрядчику отдельно (краткое наименование из справочника).
class WorkOwnContractorAmountsCard extends ConsumerWidget {
  /// Строки работ смены (уже загруженные).
  final List<WorkItem> items;

  /// Создаёт карточку разбивки сумм.
  const WorkOwnContractorAmountsCard({super.key, required this.items});

  /// Сумма работ в **собственном выполнении** (без привязки к субподрядчику).
  static double ownExecutionTotal(List<WorkItem> items) {
    var own = 0.0;
    for (final item in items) {
      final cid = item.contractorId;
      if (cid != null && cid.isNotEmpty) {
        continue;
      }
      own += (item.total ?? 0).toDouble();
    }
    return own;
  }

  /// Суммы по идентификатору контрагента-подрядчика.
  static Map<String, double> totalsByContractorId(List<WorkItem> items) {
    final map = <String, double>{};
    for (final item in items) {
      final cid = item.contractorId;
      if (cid == null || cid.isEmpty) {
        continue;
      }
      final t = (item.total ?? 0).toDouble();
      map[cid] = (map[cid] ?? 0) + t;
    }
    return map;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final ownTotal = ownExecutionTotal(items);
    final byContractor = totalsByContractorId(items);
    final contractors = ref.watch(contractorNotifierProvider).contractors;

    final contractorEntries = byContractor.entries.toList()
      ..sort((a, b) {
        final na =
            contractors.firstWhereOrNull((c) => c.id == a.key)?.shortName ??
                '';
        final nb =
            contractors.firstWhereOrNull((c) => c.id == b.key)?.shortName ??
                '';
        return na.toLowerCase().compareTo(nb.toLowerCase());
      });

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      color: theme.cardColor,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'По исполнителю',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            _row(theme, 'Собственное выполнение', formatCurrency(ownTotal)),
            ...contractorEntries.expand((e) {
              final shortName =
                  contractors.firstWhereOrNull((c) => c.id == e.key)?.shortName;
              final label = (shortName != null && shortName.isNotEmpty)
                  ? shortName
                  : 'Контрагент';
              return [
                const SizedBox(height: 12),
                _row(theme, label, formatCurrency(e.value)),
              ];
            }),
          ],
        ),
      ),
    );
  }

  Widget _row(ThemeData theme, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
