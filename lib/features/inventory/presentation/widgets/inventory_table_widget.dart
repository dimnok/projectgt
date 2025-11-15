import 'package:flutter/material.dart';
import 'package:projectgt/features/inventory/presentation/widgets/inventory_table_row_widget.dart';
import 'package:projectgt/features/inventory/presentation/widgets/inventory_item_view_modal.dart';

/// Виджет кастомной таблицы для отображения всех ТМЦ со всех складов.
///
/// Отображает все записи из таблицы inventory_items независимо от местоположения.
/// Поддерживает адаптивный дизайн для desktop/tablet/mobile.
class InventoryTableWidget extends StatefulWidget {
  /// Список ТМЦ для отображения (пока заглушка).
  final List<Map<String, dynamic>> items;

  /// Создаёт виджет таблицы ТМЦ.
  const InventoryTableWidget({
    super.key,
    this.items = const [],
  });

  @override
  State<InventoryTableWidget> createState() => _InventoryTableWidgetState();
}

class _InventoryTableWidgetState extends State<InventoryTableWidget> {
  /// Контроллер для вертикального скролла таблицы.
  final ScrollController _verticalController = ScrollController();

  /// Колонка для сортировки (null = без сортировки).
  String? _sortColumn;

  /// Направление сортировки (true = по возрастанию, false = по убыванию).
  bool _sortAscending = true;

  @override
  void dispose() {
    _verticalController.dispose();
    super.dispose();
  }

  /// Сортирует список ТМЦ по выбранной колонке.
  List<Map<String, dynamic>> _sortItems(List<Map<String, dynamic>> items) {
    if (_sortColumn == null) return items;

    final sorted = List<Map<String, dynamic>>.from(items);
    sorted.sort((a, b) {
      dynamic aValue;
      dynamic bValue;

      switch (_sortColumn) {
        case 'name':
          aValue = (a['name'] ?? '').toString().toLowerCase();
          bValue = (b['name'] ?? '').toString().toLowerCase();
          break;
        case 'category':
          aValue = (a['category'] ?? '').toString().toLowerCase();
          bValue = (b['category'] ?? '').toString().toLowerCase();
          break;
        case 'unit':
          aValue = (a['unit'] ?? 'шт.').toString().toLowerCase();
          bValue = (b['unit'] ?? 'шт.').toString().toLowerCase();
          break;
        case 'quantity':
          aValue = (a['quantity'] ?? 1) as num;
          bValue = (b['quantity'] ?? 1) as num;
          break;
        case 'serial_number':
          aValue = (a['serial_number'] ?? '').toString().toLowerCase();
          bValue = (b['serial_number'] ?? '').toString().toLowerCase();
          break;
        case 'status':
          aValue = (a['status'] ?? 'working').toString().toLowerCase();
          bValue = (b['status'] ?? 'working').toString().toLowerCase();
          break;
        case 'purchase_date':
          aValue = a['purchase_date'] as DateTime?;
          bValue = b['purchase_date'] as DateTime?;
          if (aValue == null && bValue == null) return 0;
          if (aValue == null) return 1;
          if (bValue == null) return -1;
          break;
        case 'location':
          aValue = (a['location'] ?? 'Склад').toString().toLowerCase();
          bValue = (b['location'] ?? 'Склад').toString().toLowerCase();
          break;
        default:
          return 0;
      }

      final comparison = Comparable.compare(aValue, bValue);
      return _sortAscending ? comparison : -comparison;
    });

    return sorted;
  }

  /// Обрабатывает клик по заголовку колонки для сортировки.
  ///
  /// Логика:
  /// 1. Первый клик - сортировка по возрастанию
  /// 2. Второй клик - сортировка по убыванию
  /// 3. Третий клик - отмена сортировки
  void _onHeaderTap(String column) {
    setState(() {
      if (_sortColumn == column) {
        // Кликнули по той же колонке
        if (_sortAscending) {
          // Было по возрастанию -> меняем на по убыванию
          _sortAscending = false;
        } else {
          // Было по убыванию -> отменяем сортировку
          _sortColumn = null;
          _sortAscending = true;
        }
      } else {
        // Кликнули по другой колонке -> устанавливаем её и сортируем по возрастанию
        _sortColumn = column;
        _sortAscending = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (widget.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Нет данных',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Данные будут отображаться после подключения к базе',
              style: theme.textTheme.bodyMedium?.copyWith(
                color:
                    theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final dividerColor = theme.colorScheme.outline.withValues(alpha: 0.18);
        final headerBackgroundColor = theme.brightness == Brightness.dark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.06);

        Widget headerCell(
          String text,
          String column, {
          TextAlign align = TextAlign.left,
        }) {
          Alignment headerAlignment;
          switch (align) {
            case TextAlign.center:
              headerAlignment = Alignment.center;
              break;
            case TextAlign.right:
              headerAlignment = Alignment.centerRight;
              break;
            default:
              headerAlignment = Alignment.centerLeft;
          }

          final isSorted = _sortColumn == column;
          final showUpArrow = isSorted && _sortAscending;
          final showDownArrow = isSorted && !_sortAscending;

          return GestureDetector(
            onTap: () => _onHeaderTap(column),
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              alignment: headerAlignment,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: align == TextAlign.center
                    ? MainAxisAlignment.center
                    : align == TextAlign.right
                        ? MainAxisAlignment.end
                        : MainAxisAlignment.start,
                children: [
                  Flexible(
                    child: Text(
                      text,
                      textAlign: align,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  if (showUpArrow)
                    const Icon(
                      Icons.arrow_upward,
                      size: 16,
                      color: Colors.green,
                    )
                  else if (showDownArrow)
                    const Icon(
                      Icons.arrow_downward,
                      size: 16,
                      color: Colors.green,
                    )
                  else
                    Icon(
                      Icons.unfold_more,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.5,
                      ),
                    ),
                ],
              ),
            ),
          );
        }

        List<TableRow> buildRows() {
          final list = <TableRow>[];
          final sortedItems = _sortItems(widget.items);

          // Заголовок
          list.add(
            TableRow(
              decoration: BoxDecoration(color: headerBackgroundColor),
              children: [
                headerCell('№', 'number', align: TextAlign.center),
                headerCell('Наименование', 'name', align: TextAlign.center),
                headerCell('Категория', 'category', align: TextAlign.center),
                headerCell('Ед. изм.', 'unit', align: TextAlign.center),
                headerCell('Количество', 'quantity', align: TextAlign.center),
                headerCell('Серийный\nномер', 'serial_number',
                    align: TextAlign.center),
                headerCell('Состояние', 'status', align: TextAlign.center),
                headerCell('Дата\nпоступления', 'purchase_date',
                    align: TextAlign.center),
                headerCell('Местоположение', 'location',
                    align: TextAlign.center),
              ],
            ),
          );

          // Строки данных
          for (int i = 0; i < sortedItems.length; i++) {
            final item = sortedItems[i];

            list.add(
              buildInventoryTableRow(
                item: item,
                index: i,
                context: context,
                onAction: (itemId, action) {
                  _handleItemAction(context, itemId, action);
                },
                buildStatusChip: (ctx, theme, status) => _buildStatusChip(
                  context: ctx,
                  theme: theme,
                  status: status,
                ),
              ),
            );
          }

          return list;
        }

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: theme.colorScheme.outline.withValues(alpha: 0.12),
              width: 1,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Scrollbar(
            controller: _verticalController,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: _verticalController,
              child: SizedBox(
                width: constraints.maxWidth,
                child: Table(
                  border: TableBorder(
                    top: BorderSide(color: dividerColor, width: 1),
                    bottom: BorderSide(color: dividerColor, width: 1),
                    left: BorderSide.none,
                    right: BorderSide.none,
                    horizontalInside: BorderSide(color: dividerColor, width: 1),
                    verticalInside: BorderSide(color: dividerColor, width: 1),
                  ),
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  columnWidths: const <int, TableColumnWidth>{
                    0: IntrinsicColumnWidth(), // №
                    1: FlexColumnWidth(
                        1), // Наименование (остаток пространства)
                    2: IntrinsicColumnWidth(), // Категория
                    3: IntrinsicColumnWidth(), // Ед. изм.
                    4: IntrinsicColumnWidth(), // Количество
                    5: IntrinsicColumnWidth(), // Серийный номер
                    6: IntrinsicColumnWidth(), // Состояние
                    7: IntrinsicColumnWidth(), // Дата поступления
                    8: IntrinsicColumnWidth(), // Местоположение
                  },
                  children: buildRows(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Строит чип для отображения состояния ТМЦ.
  Widget _buildStatusChip({
    required BuildContext context,
    required ThemeData theme,
    required String status,
  }) {
    final statusConfig = _getStatusConfig(status, theme);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusConfig['color'] as Color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        statusConfig['label'] as String,
        style: theme.textTheme.bodySmall?.copyWith(
          color: statusConfig['textColor'] as Color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  /// Обрабатывает действие с элементом ТМЦ.
  void _handleItemAction(BuildContext context, String itemId, String action) {
    switch (action) {
      case 'view':
        InventoryItemViewModal.show(
          context: context,
          itemId: itemId,
        );
        break;
      case 'edit':
        // TODO: Переход на экран редактирования
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Редактирование ТМЦ: $itemId'),
            duration: const Duration(seconds: 1),
          ),
        );
        break;
      case 'delete':
        // TODO: Подтверждение и удаление
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Удаление ТМЦ: $itemId'),
            duration: const Duration(seconds: 1),
          ),
        );
        break;
    }
  }

  /// Возвращает конфигурацию для статуса ТМЦ.
  Map<String, dynamic> _getStatusConfig(String status, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;

    switch (status) {
      case 'working':
        return {
          'label': 'Исправен',
          'color': isDark
              ? Colors.green.withValues(alpha: 0.2)
              : Colors.green.withValues(alpha: 0.1),
          'textColor': Colors.green,
        };
      case 'repair':
        return {
          'label': 'В ремонте',
          'color': isDark
              ? Colors.orange.withValues(alpha: 0.2)
              : Colors.orange.withValues(alpha: 0.1),
          'textColor': Colors.orange,
        };
      case 'written_off':
        return {
          'label': 'Списан',
          'color': isDark
              ? Colors.red.withValues(alpha: 0.2)
              : Colors.red.withValues(alpha: 0.1),
          'textColor': Colors.red,
        };
      case 'new':
        return {
          'label': 'Новый',
          'color': isDark
              ? Colors.blue.withValues(alpha: 0.2)
              : Colors.blue.withValues(alpha: 0.1),
          'textColor': Colors.blue,
        };
      case 'used':
        return {
          'label': 'Б/у',
          'color': isDark
              ? theme.colorScheme.surfaceContainerHighest
              : theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.5),
          'textColor': theme.colorScheme.onSurfaceVariant,
        };
      case 'good':
        return {
          'label': 'Хорошее',
          'color': isDark
              ? Colors.green.withValues(alpha: 0.2)
              : Colors.green.withValues(alpha: 0.1),
          'textColor': Colors.green,
        };
      case 'broken':
        return {
          'label': 'Сломан',
          'color': isDark
              ? Colors.red.withValues(alpha: 0.2)
              : Colors.red.withValues(alpha: 0.1),
          'textColor': Colors.red,
        };
      case 'critical':
        return {
          'label': 'Критическое',
          'color': isDark
              ? Colors.deepOrange.withValues(alpha: 0.2)
              : Colors.deepOrange.withValues(alpha: 0.1),
          'textColor': Colors.deepOrange,
        };
      default:
        return {
          'label': status,
          'color': theme.colorScheme.surfaceContainerHighest,
          'textColor': theme.colorScheme.onSurfaceVariant,
        };
    }
  }
}
