import 'package:projectgt/domain/entities/estimate.dart';

/// Логика мультивыбора строк таблицы подрядчиков (в т.ч. цикл по заголовку группы в режиме выполнения).
abstract final class SubcontractorsEstimateTableSelection {
  /// Следующий набор id после клика по чекбоксу заголовка группы в режиме выполнения:
  /// все позиции → только с ненулевым фактом → снятие выбора.
  static Set<String> cycleExecutionGroup({
    required Set<String> selectedEstimateIds,
    required List<Estimate> groupEstimates,
    required double Function(Estimate estimate) completedQuantity,
  }) {
    final allIds = groupEstimates.map((e) => e.id).toSet();
    final executedIds = groupEstimates
        .where((e) => completedQuantity(e) > 0)
        .map((e) => e.id)
        .toSet();
    final selectedInGroup = selectedEstimateIds.where(allIds.contains).toSet();

    final nextSelectedIds = selectedEstimateIds.toSet()..removeAll(allIds);

    final isAllSelected =
        allIds.isNotEmpty &&
        selectedInGroup.length == allIds.length &&
        selectedInGroup.containsAll(allIds);
    final isExecutedOnlySelected =
        executedIds.isNotEmpty &&
        selectedInGroup.length == executedIds.length &&
        selectedInGroup.containsAll(executedIds);

    if (!isAllSelected && !isExecutedOnlySelected) {
      nextSelectedIds.addAll(allIds);
    } else if (isAllSelected && executedIds.length < allIds.length) {
      nextSelectedIds.addAll(executedIds);
    }

    return nextSelectedIds;
  }
}
