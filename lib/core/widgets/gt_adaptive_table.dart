import 'dart:math' as math;
import 'dart:ui' as ui show TextDirection;

import 'package:flutter/material.dart';

/// Конфигурация колонки для [GTAdaptiveTable].
class GTColumnConfig<T> {
  /// Заголовок колонки.
  final String title;

  /// Построитель контента ячейки.
  final Widget Function(T item, int index, ThemeData theme) builder;

  /// Построитель контента ячейки в итоговой строке.
  final Widget Function(ThemeData theme)? totalBuilder;

  /// Выравнивание текста в заголовке.
  final TextAlign headerAlign;

  /// Выравнивание контента в ячейке.
  final Alignment cellAlignment;

  /// Коэффициент гибкости ширины (используется если [isFlexible] = true).
  final double flex;

  /// Минимальная ширина колонки.
  final double? minWidth;

  /// Флаг, указывающий, что колонка должна занимать всё доступное пространство.
  final bool isFlexible;

  /// Функция для измерения ширины текста в ячейках (для автоматического расчета ширины).
  final String? Function(T item)? measureText;

  /// Функция для измерения ширины текста в итоговой строке.
  final String? Function()? measureTotal;

  /// Дополнительная ширина для учета иконок или контейнеров.
  final double extraWidth;

  /// Создаёт экземпляр [GTColumnConfig].
  const GTColumnConfig({
    required this.title,
    required this.builder,
    this.totalBuilder,
    this.headerAlign = TextAlign.left,
    this.cellAlignment = Alignment.centerLeft,
    this.flex = 1,
    this.minWidth,
    this.isFlexible = false,
    this.measureText,
    this.measureTotal,
    this.extraWidth = 0,
  });
}

/// Адаптивная таблица с синхронизированным скроллом и автоматическим расчетом ширины колонок.
///
/// Построена на базе стандартного [Table] для высокой производительности и полного контроля над дизайном.
class GTAdaptiveTable<T> extends StatefulWidget {
  /// Список элементов для отображения.
  final List<T> items;

  /// Конфигурация колонок.
  final List<GTColumnConfig<T>> columns;

  /// Флаг отображения итоговой строки.
  final bool showTotalRow;

  /// Цвет разделителей.
  final Color? dividerColor;

  /// Цвет фона заголовка.
  final Color? headerBackgroundColor;

  /// Цвет фона четных строк (для чередования).
  final Color? alternateRowColor;

  /// Внутренние отступы ячеек по горизонтали.
  final double cellHorizontalPadding;

  /// Внутренние отступы ячеек по вертикали.
  final double cellVerticalPadding;

  /// Минимальная высота строки.
  final double minRowHeight;

  /// Обработка нажатия на строку.
  final void Function(T item, TapDownDetails details)? onRowTapDown;

  /// Обработка вторичного нажатия (правой кнопкой мыши) на строку.
  final void Function(T item, TapDownDetails details)? onRowSecondaryTapDown;

  /// Элемент, который должен быть подсвечен (например, при открытом контекстном меню).
  final T? highlightedItem;

  /// Цвет подсветки выделенной строки.
  final Color? highlightedRowColor;

  /// Создаёт экземпляр [GTAdaptiveTable].
  const GTAdaptiveTable({
    super.key,
    required this.items,
    required this.columns,
    this.showTotalRow = false,
    this.dividerColor,
    this.headerBackgroundColor,
    this.alternateRowColor,
    this.cellHorizontalPadding = 8,
    this.cellVerticalPadding = 1,
    this.minRowHeight = 30,
    this.onRowTapDown,
    this.onRowSecondaryTapDown,
    this.highlightedItem,
    this.highlightedRowColor,
  });

  @override
  State<GTAdaptiveTable<T>> createState() => _GTAdaptiveTableState<T>();
}

class _GTAdaptiveTableState<T> extends State<GTAdaptiveTable<T>> {
  final ScrollController _verticalController = ScrollController();
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _headerHorizontalController = ScrollController();
  bool _isSyncingScroll = false;

  @override
  void initState() {
    super.initState();
    _horizontalController.addListener(_syncHeaderScroll);
  }

  void _syncHeaderScroll() {
    if (_isSyncingScroll) return;
    if (!_headerHorizontalController.hasClients) return;
    _isSyncingScroll = true;
    _headerHorizontalController.jumpTo(_horizontalController.offset);
    _isSyncingScroll = false;
  }

  @override
  void dispose() {
    _horizontalController.removeListener(_syncHeaderScroll);
    _verticalController.dispose();
    _horizontalController.dispose();
    _headerHorizontalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dividerColor =
        widget.dividerColor ??
        theme.colorScheme.outline.withValues(alpha: 0.18);
    final headerBgColor =
        widget.headerBackgroundColor ??
        (theme.brightness == Brightness.dark
            ? Colors.grey[800]
            : Colors.grey[100]);

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.of(context).size.width;

        final columnWidths = _buildColumnWidths(theme, availableWidth);
        final totalTableWidth = columnWidths.values.fold<double>(
          0,
          (sum, w) => sum + (w as FixedColumnWidth).value,
        );

        Widget buildTable(List<TableRow> rows) {
          return ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: math.max(availableWidth, totalTableWidth),
            ),
            child: Table(
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              border: TableBorder(
                top: BorderSide(color: dividerColor, width: 1),
                bottom: BorderSide(color: dividerColor, width: 1),
                left: BorderSide(color: dividerColor, width: 1),
                right: BorderSide(color: dividerColor, width: 1),
                horizontalInside: BorderSide(color: dividerColor, width: 1),
                verticalInside: BorderSide(color: dividerColor, width: 1),
              ),
              columnWidths: columnWidths,
              children: rows,
            ),
          );
        }

        final headerRow = _buildHeaderRow(theme);
        final bodyRows = _buildBodyRows(theme);

        return Column(
          children: [
            // Заголовок
            Container(
              color: headerBgColor,
              child: SingleChildScrollView(
                controller: _headerHorizontalController,
                physics: const NeverScrollableScrollPhysics(),
                scrollDirection: Axis.horizontal,
                child: buildTable([headerRow]),
              ),
            ),
            // Тело таблицы
            Expanded(
              child: Scrollbar(
                controller: _verticalController,
                thumbVisibility: true,
                child: SingleChildScrollView(
                  controller: _verticalController,
                  child: Scrollbar(
                    controller: _horizontalController,
                    thumbVisibility: true,
                    notificationPredicate: (notification) =>
                        notification.depth == 1,
                    child: SingleChildScrollView(
                      controller: _horizontalController,
                      scrollDirection: Axis.horizontal,
                      child: buildTable(bodyRows),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  TableRow _buildHeaderRow(ThemeData theme) {
    return TableRow(
      children: [
        for (final config in widget.columns)
          _headerCell(theme, config.title, align: config.headerAlign),
      ],
    );
  }

  List<TableRow> _buildBodyRows(ThemeData theme) {
    final rows = <TableRow>[];

    for (var i = 0; i < widget.items.length; i++) {
      final item = widget.items[i];
      final isHighlighted =
          widget.highlightedItem != null && widget.highlightedItem == item;

      rows.add(
        TableRow(
          decoration: BoxDecoration(
            color: isHighlighted
                ? (widget.highlightedRowColor ??
                      theme.colorScheme.primary.withValues(alpha: 0.08))
                : (i.isEven
                      ? widget.alternateRowColor ??
                            theme.colorScheme.primary.withValues(alpha: 0.04)
                      : Colors.transparent),
          ),
          children: [
            for (final config in widget.columns)
              _bodyCell(
                theme,
                item,
                config.builder(item, i, theme),
                align: config.cellAlignment,
              ),
          ],
        ),
      );
    }

    if (widget.showTotalRow && widget.items.isNotEmpty) {
      rows.add(
        TableRow(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.5,
            ),
          ),
          children: [
            for (final config in widget.columns)
              _bodyCell(
                theme,
                null,
                config.totalBuilder != null
                    ? config.totalBuilder!(theme)
                    : const SizedBox.shrink(),
                align: config.cellAlignment,
                isTotal: true,
              ),
          ],
        ),
      );
    }

    return rows;
  }

  Widget _headerCell(
    ThemeData theme,
    String title, {
    TextAlign align = TextAlign.left,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: widget.cellHorizontalPadding,
        vertical: 12,
      ),
      alignment: _alignmentFromTextAlign(align),
      child: Text(
        title,
        textAlign: align,
        style: theme.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _bodyCell(
    ThemeData theme,
    T? item,
    Widget child, {
    Alignment align = Alignment.centerLeft,
    bool isTotal = false,
  }) {
    final content = Container(
      padding: EdgeInsets.symmetric(
        horizontal: widget.cellHorizontalPadding,
        vertical: widget.cellVerticalPadding,
      ),
      constraints: BoxConstraints(minHeight: widget.minRowHeight),
      alignment: align,
      child: DefaultTextStyle.merge(
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodySmall?.copyWith(
          fontSize: 12,
          height: 1.0,
          fontWeight: isTotal ? FontWeight.bold : null,
        ),
        child: child,
      ),
    );

    if (item == null ||
        isTotal ||
        (widget.onRowTapDown == null && widget.onRowSecondaryTapDown == null)) {
      return content;
    }

    return GestureDetector(
      onTapDown: widget.onRowTapDown != null
          ? (details) => widget.onRowTapDown!(item, details)
          : null,
      onSecondaryTapDown: widget.onRowSecondaryTapDown != null
          ? (details) => widget.onRowSecondaryTapDown!(item, details)
          : null,
      behavior: HitTestBehavior.opaque,
      child: content,
    );
  }

  Alignment _alignmentFromTextAlign(TextAlign align) {
    switch (align) {
      case TextAlign.center:
        return Alignment.center;
      case TextAlign.right:
        return Alignment.centerRight;
      default:
        return Alignment.centerLeft;
    }
  }

  Map<int, TableColumnWidth> _buildColumnWidths(
    ThemeData theme,
    double availableWidth,
  ) {
    final widths = <int, TableColumnWidth>{};
    final fixedWidths = <int, double>{};
    double totalFixed = 0;

    final headerStyle =
        theme.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.bold,
          fontSize: 11,
          height: 1.0,
        ) ??
        const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, height: 1.0);
    final bodyStyle =
        theme.textTheme.bodySmall?.copyWith(fontSize: 12, height: 1.0) ??
        const TextStyle(fontSize: 12, height: 1.0);

    final paddingWidth = widget.cellHorizontalPadding * 2 + 6;

    for (var i = 0; i < widget.columns.length; i++) {
      final config = widget.columns[i];

      if (config.isFlexible) continue;

      double columnWidth = config.minWidth ?? 32;

      // Измерение текста в ячейках
      if (config.measureText != null) {
        for (final item in widget.items) {
          final text = config.measureText!(item);
          if (text != null && text.isNotEmpty) {
            double width =
                _measureText(text, bodyStyle) +
                paddingWidth +
                config.extraWidth;
            columnWidth = math.max(columnWidth, width);
          }
        }
      }

      // Измерение текста в итоговой строке
      if (config.measureTotal != null) {
        final text = config.measureTotal!();
        if (text != null && text.isNotEmpty) {
          double width =
              _measureText(
                text,
                bodyStyle.copyWith(fontWeight: FontWeight.bold),
              ) +
              paddingWidth +
              config.extraWidth;
          columnWidth = math.max(columnWidth, width);
        }
      }

      // Измерение текста в заголовке
      final headerWidth =
          _measureText(config.title, headerStyle) + paddingWidth;
      columnWidth = math.max(columnWidth, headerWidth);

      fixedWidths[i] = columnWidth;
      totalFixed += columnWidth;
    }

    double remainingWidth = math.max(
      availableWidth - totalFixed,
      widget.columns.length * 40,
    );
    final flexibleIndexes = <int>[];
    for (var i = 0; i < widget.columns.length; i++) {
      final config = widget.columns[i];
      if (config.isFlexible) {
        flexibleIndexes.add(i);
      } else {
        widths[i] = FixedColumnWidth(fixedWidths[i]!);
      }
    }

    if (flexibleIndexes.isNotEmpty) {
      final totalFlex = flexibleIndexes.fold<double>(
        0,
        (sum, i) => sum + widget.columns[i].flex,
      );

      for (final i in flexibleIndexes) {
        final flexPortion = totalFlex == 0
            ? 1.0 / flexibleIndexes.length
            : widget.columns[i].flex / totalFlex;
        double width = math.max(
          remainingWidth * flexPortion,
          widget.columns[i].minWidth ?? 100,
        );
        widths[i] = FixedColumnWidth(width);
      }
    }

    return widths;
  }

  double _measureText(String text, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: ui.TextDirection.ltr,
      maxLines: 1,
    )..layout();
    return painter.width;
  }
}
