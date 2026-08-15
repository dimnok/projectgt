import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/core/widgets/gt_dropdown.dart';
import 'package:projectgt/core/widgets/gt_text_field.dart';
import 'package:projectgt/features/tmc/domain/entities/tmc_stock_balance.dart';
import 'package:projectgt/features/tmc/domain/entities/tmc_warehouse.dart';
import 'package:projectgt/features/tmc/presentation/state/tmc_providers.dart';
import 'package:projectgt/features/tmc/presentation/utils/tmc_ui_labels.dart';

/// Остатки ТМЦ по складам внутри модуля.
class TmcStockPanel extends ConsumerStatefulWidget {
  /// Открыть карточку позиции.
  final ValueChanged<String> onOpenItem;

  /// Создаёт панель остатков.
  const TmcStockPanel({super.key, required this.onOpenItem});

  @override
  ConsumerState<TmcStockPanel> createState() => _TmcStockPanelState();
}

class _TmcStockPanelState extends ConsumerState<TmcStockPanel> {
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
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
        const SizedBox(height: 8),
        Expanded(
          child: stockAsync.when(
            loading: () => const Center(child: CupertinoActivityIndicator()),
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
                itemCount: rows.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final row = rows[index];
                  return _StockTile(
                    row: row,
                    onTap: () => widget.onOpenItem(row.itemId),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _StockTile extends StatelessWidget {
  final TmcStockBalance row;
  final VoidCallback onTap;

  const _StockTile({required this.row, required this.onTap});

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
      onTap: onTap,
    );
  }
}
