import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pluto_grid/pluto_grid.dart';
import 'package:intl/intl.dart';

import '../../../../domain/entities/estimate.dart';
import '../../../../features/roles/application/permission_service.dart';

/// Виджет таблицы сметы для Desktop версии.
///
/// Использует [PlutoGrid] для отображения данных.
class EstimateTableView extends ConsumerStatefulWidget {
  /// Список позиций сметы для отображения.
  final List<Estimate> items;

  /// Коллбек редактирования позиции.
  final Function(Estimate) onEdit;

  /// Коллбек дублирования позиции.
  final Function(Estimate) onDuplicate;

  /// Коллбек удаления позиции.
  final Function(String) onDelete;

  /// Создаёт виджет таблицы сметы.
  const EstimateTableView({
    super.key,
    required this.items,
    required this.onEdit,
    required this.onDuplicate,
    required this.onDelete,
  });

  @override
  ConsumerState<EstimateTableView> createState() => _EstimateTableViewState();
}

class _EstimateTableViewState extends ConsumerState<EstimateTableView> {
  late List<PlutoColumn> _columns;
  late List<PlutoRow> _rows;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Используем LayoutBuilder для получения ширины контейнера
    return LayoutBuilder(
      builder: (context, constraints) {
        final containerWidth = constraints.maxWidth;
        _buildTableData(containerWidth);

        final cellStyle = theme.textTheme.bodyMedium ?? const TextStyle();
        final columnStyle = theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ) ??
            const TextStyle(fontWeight: FontWeight.bold);

        const ruLocale = PlutoGridLocaleText(
          unfreezeColumn: 'Открепить',
          freezeColumnToStart: 'Закрепить в начале',
          freezeColumnToEnd: 'Закрепить в конце',
          autoFitColumn: 'Автоматический размер',
          hideColumn: 'Скрыть колонку',
          setColumns: 'Выбрать колонки',
          setFilter: 'Установить фильтр',
          resetFilter: 'Сбросить фильтр',
          setColumnsTitle: 'Настройка колонок',
          filterColumn: 'Колонка',
          filterType: 'Тип',
          filterValue: 'Значение',
          filterAllColumns: 'Все колонки',
          filterContains: 'Поиск',
          filterEquals: 'Равно',
          filterStartsWith: 'Начинается с',
          filterEndsWith: 'Заканчивается на',
          filterGreaterThan: 'Больше чем',
          filterGreaterThanOrEqualTo: 'Больше или равно',
          filterLessThan: 'Меньше чем',
          filterLessThanOrEqualTo: 'Меньше или равно',
          sunday: 'Вск',
          monday: 'Пн',
          tuesday: 'Вт',
          wednesday: 'Ср',
          thursday: 'Чт',
          friday: 'Пт',
          saturday: 'Сб',
          hour: 'Часы',
          minute: 'Минуты',
          loadingText: 'Загрузка',
        );

        return PlutoGrid(
          key: ValueKey(
              'estimate_table_${widget.items.length}_${isDark ? 'dark' : 'light'}'),
          columns: _columns,
          rows: _rows,
          mode: PlutoGridMode.normal,
          onLoaded: (PlutoGridOnLoadedEvent event) {
            event.stateManager.setShowColumnFilter(true);
          },
          configuration: isDark
              ? PlutoGridConfiguration.dark(
                  localeText: ruLocale,
                  style: PlutoGridStyleConfig.dark(
                    columnFilterHeight: 36,
                    cellTextStyle: cellStyle,
                    columnTextStyle: columnStyle,
                    gridBorderRadius: BorderRadius.circular(12),
                    gridBorderColor:
                        theme.colorScheme.outline.withValues(alpha: 0.12),
                  ),
                )
              : PlutoGridConfiguration(
                  localeText: ruLocale,
                  style: PlutoGridStyleConfig(
                    columnFilterHeight: 36,
                    cellTextStyle: cellStyle,
                    columnTextStyle: columnStyle,
                    gridBorderRadius: BorderRadius.circular(12),
                    gridBorderColor:
                        theme.colorScheme.outline.withValues(alpha: 0.12),
                  ),
                ),
        );
      },
    );
  }

  void _buildTableData(double containerWidth) {
    final availableWidth = containerWidth;

    final nameColumnWidth = availableWidth * 0.4;
    const otherColumnCount = 9;
    final otherColumnWidth = (availableWidth * 0.6) / otherColumnCount;

    final moneyFormat = NumberFormat('###,##0.00', 'ru_RU');

    _columns = [
      PlutoColumn(
        title: 'Система',
        field: 'system',
        type: PlutoColumnType.text(),
        width: otherColumnWidth,
        titleTextAlign: PlutoColumnTextAlign.center,
      ),
      PlutoColumn(
        title: 'Подсистема',
        field: 'subsystem',
        type: PlutoColumnType.text(),
        width: otherColumnWidth,
        titleTextAlign: PlutoColumnTextAlign.center,
      ),
      PlutoColumn(
        title: '№',
        field: 'number',
        type: PlutoColumnType.text(),
        width: otherColumnWidth,
        titleTextAlign: PlutoColumnTextAlign.center,
        renderer: (rendererContext) {
          return Text(
            rendererContext.cell.value?.toString() ?? '',
            textAlign: TextAlign.center,
            style:
                Theme.of(rendererContext.stateManager.gridKey.currentContext!)
                    .textTheme
                    .bodyMedium,
          );
        },
      ),
      PlutoColumn(
        title: 'Наименование',
        field: 'name',
        type: PlutoColumnType.text(),
        width: nameColumnWidth,
        titleTextAlign: PlutoColumnTextAlign.center,
        renderer: (rendererContext) {
          return Text(
            rendererContext.cell.value?.toString() ?? '',
            softWrap: true,
            overflow: TextOverflow.visible,
            maxLines: null,
            style:
                Theme.of(rendererContext.stateManager.gridKey.currentContext!)
                    .textTheme
                    .bodyMedium,
          );
        },
      ),
      PlutoColumn(
        title: 'Артикул',
        field: 'article',
        type: PlutoColumnType.text(),
        width: otherColumnWidth,
        titleTextAlign: PlutoColumnTextAlign.center,
        renderer: (rendererContext) {
          return Text(
            rendererContext.cell.value?.toString() ?? '',
            textAlign: TextAlign.center,
            style:
                Theme.of(rendererContext.stateManager.gridKey.currentContext!)
                    .textTheme
                    .bodyMedium,
          );
        },
      ),
      PlutoColumn(
        title: 'Производитель',
        field: 'manufacturer',
        type: PlutoColumnType.text(),
        width: otherColumnWidth,
        titleTextAlign: PlutoColumnTextAlign.center,
        renderer: (rendererContext) {
          return Text(
            rendererContext.cell.value?.toString() ?? '',
            textAlign: TextAlign.center,
            style:
                Theme.of(rendererContext.stateManager.gridKey.currentContext!)
                    .textTheme
                    .bodyMedium,
          );
        },
      ),
      PlutoColumn(
        title: 'Ед. изм.',
        field: 'unit',
        type: PlutoColumnType.text(),
        width: otherColumnWidth,
        titleTextAlign: PlutoColumnTextAlign.center,
        renderer: (rendererContext) {
          return Text(
            rendererContext.cell.value?.toString() ?? '',
            textAlign: TextAlign.center,
            style:
                Theme.of(rendererContext.stateManager.gridKey.currentContext!)
                    .textTheme
                    .bodyMedium,
          );
        },
      ),
      PlutoColumn(
        title: 'Количество',
        field: 'quantity',
        type: PlutoColumnType.number(),
        width: otherColumnWidth,
        titleTextAlign: PlutoColumnTextAlign.center,
        renderer: (rendererContext) {
          return Text(
            rendererContext.cell.value?.toString() ?? '',
            textAlign: TextAlign.center,
            style:
                Theme.of(rendererContext.stateManager.gridKey.currentContext!)
                    .textTheme
                    .bodyMedium,
          );
        },
      ),
      PlutoColumn(
        title: 'Цена',
        field: 'price',
        type: PlutoColumnType.number(),
        width: otherColumnWidth,
        titleTextAlign: PlutoColumnTextAlign.center,
        renderer: (rendererContext) {
          final value = rendererContext.cell.value;
          final formatted = value is num
              ? moneyFormat.format(value)
              : (value?.toString() ?? '');
          return Text(
            formatted,
            textAlign: TextAlign.right,
            style:
                Theme.of(rendererContext.stateManager.gridKey.currentContext!)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(
                      color: Colors.green,
                    ),
          );
        },
      ),
      PlutoColumn(
        title: 'Сумма',
        field: 'total',
        type: PlutoColumnType.number(),
        width: otherColumnWidth,
        titleTextAlign: PlutoColumnTextAlign.center,
        renderer: (rendererContext) {
          final value = rendererContext.cell.value;
          final formatted = value is num
              ? moneyFormat.format(value)
              : (value?.toString() ?? '');
          return Text(
            formatted,
            textAlign: TextAlign.right,
            style:
                Theme.of(rendererContext.stateManager.gridKey.currentContext!)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
          );
        },
      ),
      PlutoColumn(
        title: 'Действия',
        field: 'actions',
        type: PlutoColumnType.text(),
        width: otherColumnWidth,
        titleTextAlign: PlutoColumnTextAlign.center,
        enableFilterMenuItem: false,
        enableSorting: false,
        renderer: (rendererContext) {
          final rowData = rendererContext.row;
          final itemId = rowData.cells['id']!.value.toString();
          // Находим объект Estimate для этой строки
          final itemData = widget.items.firstWhere(
            (e) => e.id == itemId,
            orElse: () => widget.items.first,
          );
          final theme = Theme.of(context);

          return _ActionButton(
            onTap: (details) => _showActionMenu(
                context, details.globalPosition, itemData, itemId),
            theme: theme,
          );
        },
      ),
    ];

    _rows = widget.items
        .map((e) => PlutoRow(cells: {
              'id': PlutoCell(value: e.id),
              'number': PlutoCell(value: e.number),
              'name': PlutoCell(value: e.name),
              'system': PlutoCell(value: e.system),
              'subsystem': PlutoCell(value: e.subsystem),
              'article': PlutoCell(value: e.article),
              'manufacturer': PlutoCell(value: e.manufacturer),
              'unit': PlutoCell(value: e.unit),
              'quantity': PlutoCell(value: e.quantity),
              'price': PlutoCell(value: e.price),
              'total': PlutoCell(value: e.total),
              'actions': PlutoCell(value: ''),
            }))
        .toList();
  }

  void _showActionMenu(
      BuildContext context, Offset position, Estimate item, String itemId) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final permissionService = ref.read(permissionServiceProvider);
    final canUpdate = permissionService.can('estimates', 'update');
    final canCreate = permissionService.can('estimates', 'create');
    final canDelete = permissionService.can('estimates', 'delete');

    if (!canUpdate && !canCreate && !canDelete) {
      return;
    }

    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
          position.dx, position.dy, position.dx + 1, position.dy + 1),
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: isDark ? theme.colorScheme.surface : theme.colorScheme.surface,
      items: [
        if (canUpdate)
          PopupMenuItem(
            height: 40,
            child: Row(
              children: [
                Icon(
                  CupertinoIcons.pencil,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Редактировать',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            onTap: () {
              // Закрываем меню и вызываем колбэк
              Future.delayed(const Duration(milliseconds: 10), () {
                widget.onEdit(item);
              });
            },
          ),
        if (canCreate)
          PopupMenuItem(
            height: 40,
            child: Row(
              children: [
                Icon(
                  CupertinoIcons.doc_on_doc,
                  color: theme.colorScheme.secondary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Дублировать',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            onTap: () {
              Future.delayed(const Duration(milliseconds: 10), () {
                widget.onDuplicate(item);
              });
            },
          ),
        if (canDelete)
          PopupMenuItem(
            height: 40,
            child: Row(
              children: [
                Icon(
                  CupertinoIcons.trash,
                  color: theme.colorScheme.error,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Удалить',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
            ),
            onTap: () {
              Future.delayed(const Duration(milliseconds: 10), () {
                widget.onDelete(itemId);
              });
            },
          ),
      ],
    );
  }
}

/// Внутренний виджет кнопки действий
class _ActionButton extends StatefulWidget {
  final void Function(TapDownDetails) onTap;
  final ThemeData theme;

  const _ActionButton({
    required this.onTap,
    required this.theme,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: widget.onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            color: Colors.transparent,
          ),
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Center(
            child: _isHovered
                ? const Icon(
                    CupertinoIcons.ellipsis,
                    size: 18,
                    color: Colors.green,
                  )
                : const Icon(
                    CupertinoIcons.ellipsis,
                    size: 18,
                    color: Colors.red,
                  ),
          ),
        ),
      ),
    );
  }
}
