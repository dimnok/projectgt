import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/features/roles/presentation/widgets/permission_guard.dart';
import 'package:projectgt/features/tmc/domain/entities/tmc_item.dart';
import 'package:projectgt/features/tmc/presentation/utils/tmc_ui_labels.dart';

/// Таблица реестра позиций ТМЦ.
class TmcItemsTable extends StatelessWidget {
  /// Позиции.
  final List<TmcItem> items;

  /// Тап по строке.
  final void Function(TmcItem item) onRowTap;

  /// Выдача.
  final void Function(TmcItem item)? onIssue;

  /// Возврат.
  final void Function(TmcItem item)? onReturn;

  /// Перемещение.
  final void Function(TmcItem item)? onMove;

  /// Показывать стоимость.
  final bool showCost;

  /// Создаёт таблицу.
  const TmcItemsTable({
    super.key,
    required this.items,
    required this.onRowTap,
    this.onIssue,
    this.onReturn,
    this.onMove,
    this.showCost = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final hasActions = onIssue != null || onReturn != null || onMove != null;
    final columns = _columns(showCost: showCost, hasActions: hasActions);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _HeaderRow(columns: columns, scheme: scheme, theme: theme),
        Expanded(
          child: items.isEmpty
              ? Center(
                  child: Text(
                    TmcUiLabels.emptyItems,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _DataRow(
                      item: item,
                      columns: columns,
                      index: index,
                      theme: theme,
                      scheme: scheme,
                      showCost: showCost,
                      onTap: () => onRowTap(item),
                      onIssue: onIssue,
                      onReturn: onReturn,
                      onMove: onMove,
                    );
                  },
                ),
        ),
      ],
    );
  }
}

enum _ColId {
  name,
  category,
  accounting,
  qtyInStock,
  qtyIssued,
  location,
  unitPrice,
  totalCost,
  status,
  actions,
}

class _ColDef {
  final _ColId id;
  final String title;
  final int flex;
  final Alignment align;

  const _ColDef({
    required this.id,
    required this.title,
    required this.flex,
    this.align = Alignment.centerLeft,
  });
}

List<_ColDef> _columns({required bool showCost, required bool hasActions}) {
  final cols = <_ColDef>[
    const _ColDef(id: _ColId.name, title: 'Наименование', flex: 3),
    const _ColDef(id: _ColId.category, title: 'Категория', flex: 2),
    const _ColDef(id: _ColId.accounting, title: 'Учёт', flex: 2),
    const _ColDef(id: _ColId.qtyInStock, title: 'На складе', flex: 1),
    const _ColDef(id: _ColId.qtyIssued, title: 'Выдано', flex: 1),
    const _ColDef(id: _ColId.location, title: 'Где лежит', flex: 3),
  ];
  if (showCost) {
    cols.addAll([
      const _ColDef(id: _ColId.unitPrice, title: 'Цена', flex: 1),
      const _ColDef(id: _ColId.totalCost, title: 'Стоимость', flex: 1),
    ]);
  }
  cols.add(const _ColDef(id: _ColId.status, title: 'Статус', flex: 1));
  if (hasActions) {
    cols.add(
      const _ColDef(
        id: _ColId.actions,
        title: '',
        flex: 2,
        align: Alignment.centerRight,
      ),
    );
  }
  return cols;
}

class _HeaderRow extends StatelessWidget {
  final List<_ColDef> columns;
  final ColorScheme scheme;
  final ThemeData theme;

  const _HeaderRow({
    required this.columns,
    required this.scheme,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: scheme.outline.withValues(alpha: 0.25)),
        ),
      ),
      child: Row(
        children: columns
            .map(
              (col) => Expanded(
                flex: col.flex,
                child: Align(
                  alignment: col.align,
                  child: Text(
                    col.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.55),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _DataRow extends StatelessWidget {
  final TmcItem item;
  final List<_ColDef> columns;
  final int index;
  final ThemeData theme;
  final ColorScheme scheme;
  final bool showCost;
  final VoidCallback onTap;
  final void Function(TmcItem item)? onIssue;
  final void Function(TmcItem item)? onReturn;
  final void Function(TmcItem item)? onMove;

  const _DataRow({
    required this.item,
    required this.columns,
    required this.index,
    required this.theme,
    required this.scheme,
    required this.showCost,
    required this.onTap,
    this.onIssue,
    this.onReturn,
    this.onMove,
  });

  String _cellText(_ColId id) {
    switch (id) {
      case _ColId.name:
        return item.name;
      case _ColId.category:
        return item.categoryName ?? '—';
      case _ColId.accounting:
        return TmcUiLabels.accountingType(item.accountingType);
      case _ColId.qtyInStock:
        return formatQuantity(item.qtyInStock);
      case _ColId.qtyIssued:
        return formatQuantity(item.qtyIssued);
      case _ColId.location:
        return item.locationSummary?.isNotEmpty == true
            ? item.locationSummary!
            : (item.qtyInStock <= 0 && item.qtyIssued <= 0 && item.qtyOnObject <= 0
                ? 'Нет остатка'
                : '—');
      case _ColId.unitPrice:
        return formatCurrency(item.unitPrice);
      case _ColId.totalCost:
        return formatCurrency(item.totalCost);
      case _ColId.status:
        return TmcUiLabels.itemStatus(item.status);
      case _ColId.actions:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = index.isEven
        ? Colors.transparent
        : scheme.surfaceContainerHighest.withValues(alpha: 0.25);

    return Material(
      color: bg,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: scheme.outline.withValues(alpha: 0.12),
              ),
            ),
          ),
          child: Row(
            children: columns.map((col) {
              if (col.id == _ColId.actions) {
                return Expanded(
                  flex: col.flex,
                  child: Align(
                    alignment: col.align,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (onIssue != null)
                          PermissionGuard(
                            module: 'tmc',
                            permission: 'issue',
                            child: IconButton(
                              tooltip: TmcUiLabels.actionIssue,
                              icon: const Icon(
                                CupertinoIcons.arrow_right_circle,
                                size: 18,
                              ),
                              onPressed: () => onIssue!(item),
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                        if (onReturn != null)
                          PermissionGuard(
                            module: 'tmc',
                            permission: 'issue',
                            child: IconButton(
                              tooltip: TmcUiLabels.actionReturn,
                              icon: const Icon(
                                CupertinoIcons.arrow_left_circle,
                                size: 18,
                              ),
                              onPressed: () => onReturn!(item),
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                        if (onMove != null)
                          PermissionGuard(
                            module: 'tmc',
                            permission: 'move',
                            child: IconButton(
                              tooltip: TmcUiLabels.actionMove,
                              icon: const Icon(
                                CupertinoIcons.arrow_2_circlepath,
                                size: 18,
                              ),
                              onPressed: () => onMove!(item),
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }

              return Expanded(
                flex: col.flex,
                child: Align(
                  alignment: col.align,
                  child: Text(
                    _cellText(col.id),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
