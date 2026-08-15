import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/core/widgets/gt_context_menu.dart';
import 'package:projectgt/features/roles/application/permission_service.dart';
import 'package:projectgt/features/tmc/domain/entities/tmc_enums.dart';
import 'package:projectgt/features/tmc/domain/entities/tmc_item.dart';
import 'package:projectgt/features/tmc/presentation/widgets/tmc_item_form_dialog.dart';
import 'package:projectgt/features/tmc/presentation/widgets/tmc_operation_dialog.dart';

/// Идентификаторы колонок таблицы ТМЦ.
enum _ColId {
  number,
  name,
  category,
  qtyInStock,
  qtyIssued,
  location,
  unitPrice,
  totalCost,
  actions,
}

/// Описание конфигурации колонки.
class _ColDef {
  final _ColId id;
  final String title;
  final double minWidth;
  final double flex;
  final Alignment align;
  final TextAlign textAlign;

  const _ColDef({
    required this.id,
    required this.title,
    required this.minWidth,
    required this.flex,
    this.align = Alignment.centerLeft,
    this.textAlign = TextAlign.left,
  });
}

/// Таблица реестра позиций ТМЦ с адаптивной шириной и защитой от слипания колонок.
class TmcItemsTable extends ConsumerStatefulWidget {
  /// Позиции.
  final List<TmcItem> items;

  /// Тап по строке.
  final void Function(TmcItem item) onRowTap;

  /// Показывать стоимость.
  final bool showCost;

  /// Создаёт таблицу.
  const TmcItemsTable({
    super.key,
    required this.items,
    required this.onRowTap,
    this.showCost = false,
  });

  @override
  ConsumerState<TmcItemsTable> createState() => _TmcItemsTableState();
}

class _TmcItemsTableState extends ConsumerState<TmcItemsTable> {
  String? _highlightedItemId;

  void _openOperation(
    BuildContext context,
    TmcOperationType type,
    TmcItem item,
  ) {
    TmcOperationDialog.show(context, operationType: type, item: item);
  }

  List<_ColDef> _buildColumns() {
    final cols = <_ColDef>[
      const _ColDef(
        id: _ColId.number,
        title: '№',
        minWidth: 44,
        flex: 0.4,
        align: Alignment.center,
        textAlign: TextAlign.center,
      ),
      const _ColDef(
        id: _ColId.name,
        title: 'Наименование',
        minWidth: 260,
        flex: 3.8,
        align: Alignment.centerLeft,
        textAlign: TextAlign.left,
      ),
      const _ColDef(
        id: _ColId.category,
        title: 'Категория',
        minWidth: 150,
        flex: 2.0,
        align: Alignment.centerLeft,
        textAlign: TextAlign.left,
      ),
      const _ColDef(
        id: _ColId.qtyInStock,
        title: 'На складе',
        minWidth: 95,
        flex: 1.1,
        align: Alignment.centerRight,
        textAlign: TextAlign.right,
      ),
      const _ColDef(
        id: _ColId.qtyIssued,
        title: 'Выдано',
        minWidth: 85,
        flex: 1.0,
        align: Alignment.centerRight,
        textAlign: TextAlign.right,
      ),
      const _ColDef(
        id: _ColId.location,
        title: 'Где лежит',
        minWidth: 200,
        flex: 2.6,
        align: Alignment.centerLeft,
        textAlign: TextAlign.left,
      ),
    ];

    if (widget.showCost) {
      cols.addAll([
        const _ColDef(
          id: _ColId.unitPrice,
          title: 'Цена',
          minWidth: 115,
          flex: 1.4,
          align: Alignment.centerRight,
          textAlign: TextAlign.right,
        ),
        const _ColDef(
          id: _ColId.totalCost,
          title: 'Стоимость',
          minWidth: 125,
          flex: 1.5,
          align: Alignment.centerRight,
          textAlign: TextAlign.right,
        ),
      ]);
    }

    cols.add(
      const _ColDef(
        id: _ColId.actions,
        title: 'Действия',
        minWidth: 140,
        flex: 1.6,
        align: Alignment.centerRight,
        textAlign: TextAlign.right,
      ),
    );

    return cols;
  }

  void _showItemContextMenu(
    BuildContext context,
    TmcItem item,
    Offset position,
  ) {
    setState(() => _highlightedItemId = item.id);

    final permissions = ref.read(permissionServiceProvider);
    final canIssue = permissions.can('tmc', 'issue');
    final canMove = permissions.can('tmc', 'move');
    final canCreate = permissions.can('tmc', 'create');
    final canRepair = permissions.can('tmc', 'repair');
    final canWriteOff = permissions.can('tmc', 'write_off');
    final canUpdate = permissions.can('tmc', 'update');

    final hasStock = item.qtyInStock > 0;
    final hasIssued = item.qtyIssued > 0;

    GTContextMenu.show(
      context: context,
      tapPosition: position,
      onDismiss: () {
        if (mounted) setState(() => _highlightedItemId = null);
      },
      items: [
        if (canIssue)
          GTContextMenuItem(
            icon: CupertinoIcons.arrow_up_right_circle,
            label: 'Выдать сотруднику',
            enabled: hasStock,
            onTap: () => _openOperation(context, TmcOperationType.issue, item),
          ),
        if (canIssue)
          GTContextMenuItem(
            icon: CupertinoIcons.arrow_down_left_circle,
            label: 'Принять возврат',
            enabled: hasIssued,
            onTap: () => _openOperation(
              context,
              TmcOperationType.returnFromEmployee,
              item,
            ),
          ),
        if (canMove)
          GTContextMenuItem(
            icon: CupertinoIcons.arrow_2_circlepath,
            label: 'Переместить между складами',
            onTap: () => _openOperation(
              context,
              TmcOperationType.moveBetweenWarehouses,
              item,
            ),
          ),
        if (canMove)
          GTContextMenuItem(
            icon: CupertinoIcons.location,
            label: 'Переместить на объект',
            enabled: hasStock,
            onTap: () => _openOperation(
              context,
              TmcOperationType.transferToObject,
              item,
            ),
          ),
        if (canCreate)
          GTContextMenuItem(
            icon: CupertinoIcons.plus_circle,
            label: 'Поступление (приход)',
            onTap: () =>
                _openOperation(context, TmcOperationType.receipt, item),
          ),
        if (canRepair || canWriteOff)
          const Divider(height: 4, indent: 8, endIndent: 8),
        if (canRepair)
          GTContextMenuItem(
            icon: CupertinoIcons.wrench,
            label: 'Отправить в ремонт',
            onTap: () =>
                _openOperation(context, TmcOperationType.sendToRepair, item),
          ),
        if (canRepair)
          GTContextMenuItem(
            icon: CupertinoIcons.arrow_uturn_left,
            label: 'Принять из ремонта',
            onTap: () => _openOperation(
              context,
              TmcOperationType.returnFromRepair,
              item,
            ),
          ),
        if (canWriteOff)
          GTContextMenuItem(
            icon: CupertinoIcons.trash,
            label: 'Списать ТМЦ',
            isDestructive: true,
            onTap: () =>
                _openOperation(context, TmcOperationType.writeOff, item),
          ),
        const Divider(height: 4, indent: 8, endIndent: 8),
        if (canUpdate)
          GTContextMenuItem(
            icon: CupertinoIcons.pencil,
            label: 'Редактировать',
            onTap: () => TmcItemFormDialog.show(context, item: item),
          ),
        GTContextMenuItem(
          icon: CupertinoIcons.info_circle,
          label: 'Карточка позиции',
          onTap: () => widget.onRowTap(item),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final permissions = ref.watch(permissionServiceProvider);
    final canIssue = permissions.can('tmc', 'issue');
    final columns = _buildColumns();

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final totalMinWidth = columns.fold<double>(0, (s, c) => s + c.minWidth);
        final totalFlex = columns.fold<double>(0, (s, c) => s + c.flex);

        final columnWidths = <_ColId, double>{};
        if (availableWidth > totalMinWidth && totalFlex > 0) {
          final extra = availableWidth - totalMinWidth;
          for (final col in columns) {
            columnWidths[col.id] =
                col.minWidth + (extra * (col.flex / totalFlex));
          }
        } else {
          for (final col in columns) {
            columnWidths[col.id] = col.minWidth;
          }
        }

        final tableWidth = math.max(availableWidth, totalMinWidth);

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: scheme.outline.withValues(alpha: isDark ? 0.22 : 0.14),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Scrollbar(
            thumbVisibility: true,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: tableWidth,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _HeaderRow(
                      columns: columns,
                      columnWidths: columnWidths,
                      scheme: scheme,
                      theme: theme,
                      isDark: isDark,
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: widget.items.length,
                        itemBuilder: (context, index) {
                          final item = widget.items[index];
                          final isHighlighted = _highlightedItemId == item.id;

                          return _DataRow(
                            item: item,
                            columns: columns,
                            columnWidths: columnWidths,
                            index: index,
                            theme: theme,
                            scheme: scheme,
                            isDark: isDark,
                            isHighlighted: isHighlighted,
                            canIssue: canIssue,
                            onTap: () => widget.onRowTap(item),
                            onQuickAction: () {
                              if (!canIssue) return;
                              if (item.qtyInStock > 0) {
                                _openOperation(
                                  context,
                                  TmcOperationType.issue,
                                  item,
                                );
                              } else if (item.qtyIssued > 0) {
                                _openOperation(
                                  context,
                                  TmcOperationType.returnFromEmployee,
                                  item,
                                );
                              }
                            },
                            onShowMenu: (pos) =>
                                _showItemContextMenu(context, item, pos),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HeaderRow extends StatelessWidget {
  final List<_ColDef> columns;
  final Map<_ColId, double> columnWidths;
  final ColorScheme scheme;
  final ThemeData theme;
  final bool isDark;

  const _HeaderRow({
    required this.columns,
    required this.columnWidths,
    required this.scheme,
    required this.theme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(
          alpha: isDark ? 0.4 : 0.3,
        ),
        border: Border(
          bottom: BorderSide(
            color: scheme.outline.withValues(alpha: isDark ? 0.25 : 0.16),
          ),
        ),
      ),
      child: Row(
        children: columns.map((col) {
          final width = columnWidths[col.id] ?? col.minWidth;
          return SizedBox(
            width: width,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Align(
                alignment: col.align,
                child: Text(
                  col.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: col.textAlign,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _DataRow extends StatelessWidget {
  final TmcItem item;
  final List<_ColDef> columns;
  final Map<_ColId, double> columnWidths;
  final int index;
  final ThemeData theme;
  final ColorScheme scheme;
  final bool isDark;
  final bool isHighlighted;
  final bool canIssue;
  final VoidCallback onTap;
  final VoidCallback onQuickAction;
  final void Function(Offset globalPosition) onShowMenu;

  const _DataRow({
    required this.item,
    required this.columns,
    required this.columnWidths,
    required this.index,
    required this.theme,
    required this.scheme,
    required this.isDark,
    required this.isHighlighted,
    required this.canIssue,
    required this.onTap,
    required this.onQuickAction,
    required this.onShowMenu,
  });

  Widget _buildCellContent(_ColDef col) {
    switch (col.id) {
      case _ColId.number:
        return Text(
          '${index + 1}',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurface.withValues(alpha: 0.4),
            fontWeight: FontWeight.w500,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        );

      case _ColId.name:
        final subtitleParts = <String>[];
        if (item.sku != null && item.sku!.trim().isNotEmpty) {
          subtitleParts.add('Арт. ${item.sku!.trim()}');
        }
        if (item.model != null && item.model!.trim().isNotEmpty) {
          subtitleParts.add(item.model!.trim());
        }
        if (item.unitOfMeasure.isNotEmpty && item.unitOfMeasure != 'шт') {
          subtitleParts.add(item.unitOfMeasure);
        }

        final isArchived = item.status == TmcItemStatus.archived;

        return Tooltip(
          message: item.name,
          waitDuration: const Duration(milliseconds: 400),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                  if (isArchived) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.onSurface.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: scheme.outline.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Text(
                        'В архиве',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w500,
                          color: scheme.onSurface.withValues(alpha: 0.55),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              if (subtitleParts.isNotEmpty) ...[
                const SizedBox(height: 1),
                Text(
                  subtitleParts.join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.45),
                    fontSize: 10.5,
                  ),
                ),
              ],
            ],
          ),
        );

      case _ColId.category:
        final categoryText = item.categoryName ?? '—';
        return Tooltip(
          message: categoryText,
          waitDuration: const Duration(milliseconds: 400),
          child: Text(
            categoryText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: item.categoryName != null
                  ? scheme.onSurface
                  : scheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
        );

      case _ColId.qtyInStock:
        final hasStock = item.qtyInStock > 0;
        final text = formatQuantity(item.qtyInStock);
        return Tooltip(
          message: 'На складе: $text',
          child: Text(
            text,
            textAlign: TextAlign.right,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: hasStock ? FontWeight.w600 : FontWeight.w400,
              color: hasStock
                  ? scheme.onSurface
                  : scheme.onSurface.withValues(alpha: 0.35),
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        );

      case _ColId.qtyIssued:
        final hasIssued = item.qtyIssued > 0;
        final text = formatQuantity(item.qtyIssued);
        return Tooltip(
          message: 'Выдано: $text',
          child: Text(
            text,
            textAlign: TextAlign.right,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: hasIssued ? FontWeight.w500 : FontWeight.w400,
              color: hasIssued
                  ? scheme.onSurface
                  : scheme.onSurface.withValues(alpha: 0.35),
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        );

      case _ColId.location:
        final hasLocation = item.locationSummary?.isNotEmpty == true;
        final locText = hasLocation
            ? item.locationSummary!
            : (item.qtyInStock <= 0 &&
                      item.qtyIssued <= 0 &&
                      item.qtyOnObject <= 0
                  ? 'Нет остатка'
                  : '—');
        return Tooltip(
          message: locText,
          waitDuration: const Duration(milliseconds: 400),
          child: Text(
            locText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: hasLocation
                  ? scheme.onSurface.withValues(alpha: 0.85)
                  : scheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
        );

      case _ColId.unitPrice:
        final text = formatCurrency(item.unitPrice);
        return Tooltip(
          message: 'Цена за ед.: $text',
          child: Text(
            text,
            textAlign: TextAlign.right,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w400,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        );

      case _ColId.totalCost:
        final text = formatCurrency(item.totalCost);
        return Tooltip(
          message: 'Общая стоимость: $text',
          child: Text(
            text,
            textAlign: TextAlign.right,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        );

      case _ColId.actions:
        final hasStock = item.qtyInStock > 0;
        final hasIssued = item.qtyIssued > 0;

        return Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // Быстрая кнопка действия (Выдать / Возврат)
            if (canIssue)
              _QuickActionButton(
                label: hasStock ? 'Выдать' : (hasIssued ? 'Возврат' : 'Выдать'),
                icon: hasStock
                    ? CupertinoIcons.arrow_up_right
                    : (hasIssued
                          ? CupertinoIcons.arrow_down_left
                          : CupertinoIcons.arrow_up_right),
                enabled: hasStock || hasIssued,
                tooltip: hasStock
                    ? 'Быстрая выдача сотруднику'
                    : (hasIssued
                          ? 'Принять возврат от сотрудника'
                          : 'Нет остатка для выдачи'),
                onTap: onQuickAction,
                scheme: scheme,
                theme: theme,
                isDark: isDark,
              ),

            const SizedBox(width: 6),

            // Кнопка подробного меню "···"
            _MoreActionsButton(
              onTapDown: (details) => onShowMenu(details.globalPosition),
              scheme: scheme,
              theme: theme,
              isDark: isDark,
            ),
          ],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    Color bg;
    if (isHighlighted) {
      bg = scheme.primary.withValues(alpha: isDark ? 0.12 : 0.08);
    } else if (index.isEven) {
      bg = Colors.transparent;
    } else {
      bg = scheme.surfaceContainerHighest.withValues(
        alpha: isDark ? 0.18 : 0.12,
      );
    }

    return Material(
      color: bg,
      child: InkWell(
        onTap: onTap,
        onSecondaryTapDown: (details) => onShowMenu(details.globalPosition),
        hoverColor: scheme.onSurface.withValues(alpha: 0.04),
        child: Container(
          height: 46,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: scheme.outline.withValues(alpha: isDark ? 0.12 : 0.08),
              ),
            ),
          ),
          child: Row(
            children: columns.map((col) {
              final width = columnWidths[col.id] ?? col.minWidth;
              return SizedBox(
                width: width,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Align(
                    alignment: col.align,
                    child: _buildCellContent(col),
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

/// Стильная кнопка быстрого действия ("Выдать" / "Возврат").
class _QuickActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool enabled;
  final String tooltip;
  final VoidCallback onTap;
  final ColorScheme scheme;
  final ThemeData theme;
  final bool isDark;

  const _QuickActionButton({
    required this.label,
    required this.icon,
    required this.enabled,
    required this.tooltip,
    required this.onTap,
    required this.scheme,
    required this.theme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final fg = enabled
        ? scheme.onSurface
        : scheme.onSurface.withValues(alpha: 0.3);

    final bg = enabled
        ? scheme.surfaceContainerHighest.withValues(alpha: isDark ? 0.5 : 0.35)
        : Colors.transparent;

    final borderColor = enabled
        ? scheme.outline.withValues(alpha: isDark ? 0.3 : 0.2)
        : scheme.outline.withValues(alpha: isDark ? 0.12 : 0.08);

    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 300),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(6),
        hoverColor: scheme.onSurface.withValues(alpha: 0.08),
        child: Container(
          height: 26,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 12, color: fg),
              const SizedBox(width: 4),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Кнопка выпадающего меню операций ("···").
class _MoreActionsButton extends StatelessWidget {
  final void Function(TapDownDetails details) onTapDown;
  final ColorScheme scheme;
  final ThemeData theme;
  final bool isDark;

  const _MoreActionsButton({
    required this.onTapDown,
    required this.scheme,
    required this.theme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Все действия с позицией',
      waitDuration: const Duration(milliseconds: 300),
      child: GestureDetector(
        onTapDown: onTapDown,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: scheme.outline.withValues(alpha: isDark ? 0.25 : 0.16),
              ),
            ),
            alignment: Alignment.center,
            child: Icon(
              CupertinoIcons.ellipsis,
              size: 14,
              color: scheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ),
      ),
    );
  }
}
