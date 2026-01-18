import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/gt_adaptive_table.dart';
import '../../data/models/grouped_material_item.dart';
import '../providers/materials_providers.dart';

/// Таблица сгруппированных материалов по смете.
/// 
/// Группирует все приходы из разных накладных под одно каноническое
/// наименование из сметы.
class MaterialsGroupedTableView extends ConsumerWidget {
  /// Список сгруппированных материалов.
  final List<GroupedMaterialItem> items;

  /// Флаг загрузки.
  final bool isLoading;

  /// Ошибка, если есть.
  final Object? error;

  /// Создаёт экземпляр [MaterialsGroupedTableView].
  const MaterialsGroupedTableView({
    super.key,
    required this.items,
    this.isLoading = false,
    this.error,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (error != null) {
      return Center(child: Text('Ошибка: $error'));
    }

    if (isLoading && items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    Color? getStatusColor(GroupedMaterialItem item) {
      final r = item.totalRemaining;
      if (r < 0) return Colors.red[700];
      if (r == 0) return Colors.green[700];
      return null;
    }

    final columns = [
      GTColumnConfig<GroupedMaterialItem>(
        title: '№',
        headerAlign: TextAlign.center,
        cellAlignment: Alignment.center,
        minWidth: 40,
        builder: (item, index, _) => Text(
          (index + 1).toString(),
          style: TextStyle(color: getStatusColor(item)),
        ),
      ),
      GTColumnConfig<GroupedMaterialItem>(
        title: 'Система',
        headerAlign: TextAlign.center,
        cellAlignment: Alignment.center,
        minWidth: 70,
        builder: (item, _, __) => Text(
          item.system,
          style: TextStyle(color: getStatusColor(item)),
        ),
      ),
      GTColumnConfig<GroupedMaterialItem>(
        title: 'Сметное наименование (Группа)',
        headerAlign: TextAlign.center,
        isFlexible: true,
        minWidth: 300,
        measureText: (item) => item.estimateName,
        builder: (item, _, __) => Text(
          item.estimateName,
          style: TextStyle(
            color: getStatusColor(item),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      GTColumnConfig<GroupedMaterialItem>(
        title: 'Ед. изм.',
        headerAlign: TextAlign.center,
        cellAlignment: Alignment.center,
        minWidth: 70,
        builder: (item, _, __) => Text(
          item.estimateUnit,
          style: TextStyle(color: getStatusColor(item)),
        ),
      ),
      GTColumnConfig<GroupedMaterialItem>(
        title: 'Всего приход',
        headerAlign: TextAlign.center,
        cellAlignment: Alignment.center,
        minWidth: 100,
        builder: (item, _, __) => Text(
          item.totalIncoming.toStringAsFixed(2),
          style: TextStyle(color: getStatusColor(item)),
        ),
      ),
      GTColumnConfig<GroupedMaterialItem>(
        title: 'Всего расход',
        headerAlign: TextAlign.center,
        cellAlignment: Alignment.center,
        minWidth: 100,
        builder: (item, _, __) => Text(
          item.totalUsed.toStringAsFixed(2),
          style: TextStyle(color: getStatusColor(item)),
        ),
      ),
      GTColumnConfig<GroupedMaterialItem>(
        title: 'Общий остаток',
        headerAlign: TextAlign.center,
        cellAlignment: Alignment.center,
        minWidth: 110,
        builder: (item, _, __) {
          final color = getStatusColor(item);
          return Text(
            item.totalRemaining.toStringAsFixed(2),
            style: TextStyle(
              color: color,
              fontWeight: color != null ? FontWeight.bold : null,
            ),
          );
        },
      ),
      GTColumnConfig<GroupedMaterialItem>(
        title: 'Партий',
        headerAlign: TextAlign.center,
        cellAlignment: Alignment.center,
        minWidth: 70,
        builder: (item, _, __) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            item.batchCount.toString(),
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ),
    ];

    return GTAdaptiveTable<GroupedMaterialItem>(
      items: items,
      columns: columns,
    );
  }
}

/// Виджет-обертка для отображения сгруппированной таблицы.
class MaterialsGroupedTableWidget extends ConsumerWidget {
  /// Создаёт экземпляр [MaterialsGroupedTableWidget].
  const MaterialsGroupedTableWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupedState = ref.watch(materialsGroupedListProvider);

    return groupedState.when(
      loading: () =>
          const MaterialsGroupedTableView(items: <GroupedMaterialItem>[], isLoading: true),
      error: (e, _) =>
          MaterialsGroupedTableView(items: const <GroupedMaterialItem>[], error: e),
      data: (items) => MaterialsGroupedTableView(items: items),
    );
  }
}
