import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:projectgt/core/common/app_router.dart';
import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/core/widgets/gt_dropdown.dart';
import 'package:projectgt/core/widgets/gt_text_field.dart';
import 'package:projectgt/features/tmc/domain/entities/tmc_stock_balance.dart';
import 'package:projectgt/features/tmc/domain/entities/tmc_warehouse.dart';
import 'package:projectgt/features/tmc/presentation/state/tmc_providers.dart';
import 'package:projectgt/features/tmc/presentation/utils/tmc_ui_labels.dart';
import 'package:projectgt/presentation/widgets/app_bar_widget.dart';

/// Экран остатков ТМЦ по складам.
class TmcStockScreen extends ConsumerStatefulWidget {
  /// Создаёт экран.
  const TmcStockScreen({super.key});

  @override
  ConsumerState<TmcStockScreen> createState() => _TmcStockScreenState();
}

class _TmcStockScreenState extends ConsumerState<TmcStockScreen> {
  String? _warehouseId;
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final warehousesAsync = ref.watch(tmcWarehousesProvider);
    final stockAsync = ref.watch(
      tmcStockProvider((warehouseId: _warehouseId, search: _search)),
    );
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBarWidget(
        title: TmcUiLabels.stockBalances,
        leading: BackButton(onPressed: () => context.go(AppRoutes.tmc)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: warehousesAsync.when(
                    data: (warehouses) {
                      TmcWarehouse? selected;
                      for (final w in warehouses) {
                        if (w.id == _warehouseId) selected = w;
                      }
                      return GTDropdown<TmcWarehouse>(
                        labelText: 'Склад',
                        hintText: 'Все склады',
                        items: warehouses,
                        selectedItem: selected,
                        itemDisplayBuilder: (w) => w.name,
                        onSelectionChanged: (w) =>
                            setState(() => _warehouseId = w?.id),
                        allowClear: true,
                      );
                    },
                    loading: () => const LinearProgressIndicator(),
                    error: (e, _) => Text(e.toString()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: GTTextField(
                    labelText: 'Поиск',
                    onChanged: (v) => setState(() => _search = v.trim()),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: stockAsync.when(
              loading: () =>
                  const Center(child: CupertinoActivityIndicator()),
              error: (e, _) => Center(child: Text(e.toString())),
              data: (rows) {
                if (rows.isEmpty) {
                  return Center(
                    child: Text(
                      TmcUiLabels.emptyStock,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.55),
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: rows.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final row = rows[index];
                    return _StockTile(row: row);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StockTile extends StatelessWidget {
  final TmcStockBalance row;

  const _StockTile({required this.row});

  @override
  Widget build(BuildContext context) {
    final subtitle = [
      row.warehouseName ?? 'Склад не указан',
      if (row.inventoryNumber != null) 'Инв. ${row.inventoryNumber}',
      '${formatQuantity(row.quantity)} ${row.unitOfMeasure}',
    ].join(' · ');

    return ListTile(
      title: Text(row.itemName),
      subtitle: Text(subtitle),
      trailing: const Icon(CupertinoIcons.chevron_right),
      onTap: () => context.push('${AppRoutes.tmc}/items/${row.itemId}'),
    );
  }
}
