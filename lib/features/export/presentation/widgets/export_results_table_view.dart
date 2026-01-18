import 'dart:math' as math;
import 'dart:ui' as ui show TextDirection;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/formatters.dart';
import '../../domain/entities/work_search_result.dart';

/// Таблица результатов поиска работ с синхронизированным скроллом.
/// Аналог EstimateTableView, адаптированный под нужды модуля выгрузки.
class ExportResultsTableView extends ConsumerStatefulWidget {
  /// Создает экземпляр [ExportResultsTableView].
  const ExportResultsTableView({
    super.key,
    required this.results,
    required this.totalQuantity,
    this.totalSum,
    required this.onEdit,
    required this.onNavigateToWork,
    required this.onMaterialTap,
    this.selectedId,
    this.canEdit = false,
  });

  /// Список результатов поиска.
  final List<WorkSearchResult> results;

  /// Итоговое количество.
  final num totalQuantity;

  /// Итоговая сумма (опционально).
  final double? totalSum;

  /// ID выбранной строки для выделения.
  final String? selectedId;

  /// Обратный вызов для редактирования позиции.
  final void Function(WorkSearchResult) onEdit;

  /// Обратный вызов для перехода к смене.
  final void Function(WorkSearchResult) onNavigateToWork;

  /// Обратный вызов при клике на наименование материала.
  final void Function(String) onMaterialTap;

  /// Разрешено ли редактирование.
  final bool canEdit;

  @override
  ConsumerState<ExportResultsTableView> createState() => _ExportResultsTableViewState();
}

class _ExportResultsTableViewState extends ConsumerState<ExportResultsTableView> {
  static const double _kCellVerticalPadding = 6;
  static const double _kCellHorizontalPadding = 8;
  static const double _kDefaultMinColumnWidth = 50;

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
    final configs = _buildColumnConfigs(theme);
    final headerRow = _buildHeaderRow(theme, configs);
    final bodyRows = _buildRows(theme, configs);
    final footerRow = _buildFooterRow(theme, configs);

    final dividerColor = theme.colorScheme.outline.withValues(alpha: 0.18);

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.of(context).size.width;
        
        final columnWidths = _buildColumnWidths(configs, theme, availableWidth);

        Widget buildTable(List<TableRow> rows) {
          return ConstrainedBox(
            constraints: BoxConstraints(minWidth: availableWidth),
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

        final headerBackgroundColor = theme.brightness == Brightness.dark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.06);

        final header = Container(
          color: headerBackgroundColor,
          child: SingleChildScrollView(
            controller: _headerHorizontalController,
            physics: const NeverScrollableScrollPhysics(),
            scrollDirection: Axis.horizontal,
            child: buildTable([headerRow]),
          ),
        );

        final body = Expanded(
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
                  child: Column(
                    children: [
                      buildTable(bodyRows),
                      buildTable([footerRow]),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );

        return Column(
          children: [
            header,
            body,
          ],
        );
      },
    );
  }

  TableRow _buildHeaderRow(ThemeData theme, List<_ExportColumnConfig> configs) {
    return TableRow(
      children: [
        for (final config in configs)
          _headerCell(theme, config.title, align: config.headerAlign),
      ],
    );
  }

  List<TableRow> _buildRows(ThemeData theme, List<_ExportColumnConfig> configs) {
    final rows = <TableRow>[];

    if (widget.results.isEmpty) {
      rows.add(
        TableRow(
          children: [
            _bodyCell(
              theme,
              const Text('Ничего не найдено', textAlign: TextAlign.center),
              align: Alignment.center,
            ),
            for (int i = 1; i < configs.length; i++)
              _bodyCell(theme, const SizedBox.shrink()),
          ],
        ),
      );
      return rows;
    }

    bool alternate = false;
    for (final result in widget.results) {
      alternate = !alternate;
      final isSelected = widget.selectedId == result.workItemId;

      rows.add(
        TableRow(
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primaryContainer
                : (alternate
                    ? theme.colorScheme.primary.withValues(alpha: 0.04)
                    : Colors.transparent),
          ),
          children: [
            for (final config in configs)
              _bodyCell(
                theme,
                config.builder(result, theme),
                align: config.cellAlignment,
                isSelected: isSelected,
                onLongPress: (details) => _showRowMenu(result, details.globalPosition),
                onSecondaryTap: (details) => _showRowMenu(result, details.globalPosition),
              ),
          ],
        ),
      );
    }

    return rows;
  }

  void _showRowMenu(WorkSearchResult result, Offset offset) {
    final theme = Theme.of(context);
    
    showMenu<_RowAction>(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx,
        offset.dy,
        offset.dx + 1,
        offset.dy + 1,
      ),
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      items: [
        PopupMenuItem(
          value: _RowAction.navigate,
          child: _MenuRow(
            icon: CupertinoIcons.arrow_right_circle,
            color: theme.colorScheme.primary,
            label: 'Перейти к смене',
          ),
        ),
        if (widget.canEdit)
          PopupMenuItem(
            value: _RowAction.edit,
            child: _MenuRow(
              icon: CupertinoIcons.pencil,
              color: theme.colorScheme.secondary,
              label: 'Редактировать',
            ),
          ),
      ],
    ).then((action) {
      if (action == null) return;
      switch (action) {
        case _RowAction.edit:
          widget.onEdit(result);
          break;
        case _RowAction.navigate:
          widget.onNavigateToWork(result);
          break;
      }
    });
  }

  TableRow _buildFooterRow(ThemeData theme, List<_ExportColumnConfig> configs) {
    final isLightTheme = theme.brightness == Brightness.light;
    final totalTextColor = isLightTheme ? Colors.green : theme.colorScheme.primary;
    final totalBackgroundColor = isLightTheme
        ? Colors.blue.withValues(alpha: 0.15)
        : theme.colorScheme.primaryContainer.withValues(alpha: 0.25);

    return TableRow(
      decoration: BoxDecoration(color: totalBackgroundColor),
      children: [
        // 0: Дата смены -> ИТОГО
        _bodyCell(
          theme,
          Text(
            'ИТОГО',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: totalTextColor,
              fontSize: 14,
            ),
          ),
          align: Alignment.center,
        ),
        // 1: Объект
        _bodyCell(theme, const SizedBox.shrink()),
        // 2: Система
        _bodyCell(theme, const SizedBox.shrink()),
        // 3: Подсистема
        _bodyCell(theme, const SizedBox.shrink()),
        // 4: Участок
        _bodyCell(theme, const SizedBox.shrink()),
        // 5: Этаж
        _bodyCell(theme, const SizedBox.shrink()),
        // 6: Материал
        _bodyCell(theme, const SizedBox.shrink()),
        // 7: Ед. изм.
        _bodyCell(theme, const SizedBox.shrink()),
        // 8: Кол-во
        _bodyCell(
          theme,
          Text(
            formatQuantity(widget.totalQuantity),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: totalTextColor,
              fontSize: 14,
            ),
          ),
          align: Alignment.center,
        ),
        // 9: Цена
        _bodyCell(theme, const SizedBox.shrink()),
        // 10: Сумма
        _bodyCell(
          theme,
          Text(
            widget.totalSum != null ? formatCurrency(widget.totalSum!) : '—',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: totalTextColor,
              fontSize: 14,
            ),
          ),
          align: Alignment.centerRight,
        ),
      ],
    );
  }

  List<_ExportColumnConfig> _buildColumnConfigs(ThemeData theme) {
    return [
      _ExportColumnConfig(
        title: 'Дата смены',
        headerAlign: TextAlign.center,
        cellAlignment: Alignment.center,
        minWidth: 85,
        measureText: (res) => formatRuDate(res.workDate),
        builder: (res, _) => Text(formatRuDate(res.workDate)),
      ),
      _ExportColumnConfig(
        title: 'Объект',
        headerAlign: TextAlign.center,
        minWidth: 100,
        measureText: (res) => res.objectName,
        builder: (res, _) => Text(res.objectName),
      ),
      _ExportColumnConfig(
        title: 'Система',
        headerAlign: TextAlign.center,
        cellAlignment: Alignment.center,
        minWidth: 110,
        measureText: (res) => res.system,
        builder: (res, _) => Text(res.system),
      ),
      _ExportColumnConfig(
        title: 'Подсистема',
        headerAlign: TextAlign.center,
        cellAlignment: Alignment.center,
        minWidth: 100,
        measureText: (res) => res.subsystem,
        builder: (res, _) => Text(res.subsystem),
      ),
      _ExportColumnConfig(
        title: 'Участок',
        headerAlign: TextAlign.center,
        cellAlignment: Alignment.center,
        minWidth: 80,
        measureText: (res) => res.section,
        builder: (res, _) => Text(res.section),
      ),
      _ExportColumnConfig(
        title: 'Этаж',
        headerAlign: TextAlign.center,
        cellAlignment: Alignment.center,
        minWidth: 60,
        measureText: (res) => res.floor,
        builder: (res, _) => Text(res.floor),
      ),
      _ExportColumnConfig(
        title: 'Наименование материала',
        headerAlign: TextAlign.center,
        flex: 1.0,
        isFlexible: true,
        minWidth: 200,
        measureText: (res) => res.materialName,
        builder: (res, _) => InkWell(
          onTap: () => widget.onMaterialTap(res.materialName),
          hoverColor: Colors.transparent,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          child: Text(res.materialName),
        ),
      ),
      _ExportColumnConfig(
        title: 'Ед. изм.',
        headerAlign: TextAlign.center,
        cellAlignment: Alignment.center,
        minWidth: 60,
        measureText: (res) => res.unit,
        builder: (res, _) => Text(res.unit),
      ),
      _ExportColumnConfig(
        title: 'Кол-во',
        headerAlign: TextAlign.center,
        cellAlignment: Alignment.center,
        minWidth: 70,
        measureText: (res) => formatQuantity(res.quantity),
        builder: (res, _) => Text(formatQuantity(res.quantity)),
      ),
      _ExportColumnConfig(
        title: 'Цена',
        headerAlign: TextAlign.center,
        cellAlignment: Alignment.centerRight,
        minWidth: 90,
        measureText: (res) => res.price != null ? formatCurrency(res.price!) : '—',
        builder: (res, _) => Text(res.price != null ? formatCurrency(res.price!) : '—'),
      ),
      _ExportColumnConfig(
        title: 'Сумма',
        headerAlign: TextAlign.center,
        cellAlignment: Alignment.centerRight,
        minWidth: 100,
        measureText: (res) => res.total != null ? formatCurrency(res.total!) : '—',
        builder: (res, _) => Text(res.total != null ? formatCurrency(res.total!) : '—'),
      ),
    ];
  }

  Widget _headerCell(ThemeData theme, String title, {TextAlign align = TextAlign.left}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      alignment: _alignmentFromTextAlign(align),
      child: Text(
        title,
        textAlign: align,
        style: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _bodyCell(
    ThemeData theme,
    Widget child, {
    Alignment align = Alignment.centerLeft,
    bool isSelected = false,
    void Function(LongPressStartDetails)? onLongPress,
    void Function(TapDownDetails)? onSecondaryTap,
  }) {
    return GestureDetector(
      onLongPressStart: onLongPress,
      onSecondaryTapDown: onSecondaryTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: _kCellHorizontalPadding, vertical: _kCellVerticalPadding),
        constraints: const BoxConstraints(minHeight: 32),
        alignment: align,
        child: DefaultTextStyle.merge(
          style: theme.textTheme.bodyMedium?.copyWith(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : null,
          ),
          child: child,
        ),
      ),
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
    List<_ExportColumnConfig> configs,
    ThemeData theme,
    double availableWidth,
  ) {
    final widths = <int, TableColumnWidth>{};
    final fixedWidths = <int, double>{};
    double totalFixed = 0;

    final headerStyle = theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ) ??
        const TextStyle(fontWeight: FontWeight.w600, fontSize: 13);
    final bodyStyle = theme.textTheme.bodyMedium?.copyWith(fontSize: 14) ??
        const TextStyle(fontSize: 14);

    const paddingWidth = _kCellHorizontalPadding * 2;

    for (var i = 0; i < configs.length; i++) {
      final config = configs[i];

      if (config.isFlexible) continue;

      double columnWidth = config.minWidth ?? _kDefaultMinColumnWidth;
      
      if (config.measureText != null) {
        for (final res in widget.results) {
          final text = config.measureText!(res);
          if (text.isEmpty) continue;
          final width = _measureText(text, bodyStyle) + paddingWidth;
          columnWidth = math.max(columnWidth, width);
        }
      }

      // Дополнительно измеряем итоговые значения в футере для соответствующих колонок
      if (i == 8) { // Кол-во
        final footerText = formatQuantity(widget.totalQuantity);
        final width = _measureText(footerText, bodyStyle.copyWith(fontWeight: FontWeight.bold)) + paddingWidth;
        columnWidth = math.max(columnWidth, width);
      } else if (i == 10) { // Сумма
        if (widget.totalSum != null) {
          final footerText = formatCurrency(widget.totalSum!);
          final width = _measureText(footerText, bodyStyle.copyWith(fontWeight: FontWeight.bold)) + paddingWidth;
          columnWidth = math.max(columnWidth, width);
        }
      }

      // Check header width
      final headerWidth = _measureText(config.title, headerStyle) + paddingWidth;
      columnWidth = math.max(columnWidth, headerWidth);

      fixedWidths[i] = columnWidth;
      totalFixed += columnWidth;
    }

    double remainingWidth = math.max(availableWidth - totalFixed, 100);
    final flexibleIndexes = <int>[];
    for (var i = 0; i < configs.length; i++) {
      if (configs[i].isFlexible) {
        flexibleIndexes.add(i);
      } else {
        widths[i] = FixedColumnWidth(fixedWidths[i]!);
      }
    }

    if (flexibleIndexes.isNotEmpty) {
      final totalFlex = flexibleIndexes
          .map((index) => configs[index].flex)
          .fold<double>(0, (prev, flex) => prev + flex);

      for (final index in flexibleIndexes) {
        final config = configs[index];
        final flexPortion = totalFlex == 0 ? 1.0 / flexibleIndexes.length : config.flex / totalFlex;
        double width = remainingWidth * flexPortion;
        width = math.max(width, config.minWidth ?? 150);
        widths[index] = FixedColumnWidth(width);
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

class _ExportColumnConfig {
  const _ExportColumnConfig({
    required this.title,
    required this.builder,
    this.headerAlign = TextAlign.left,
    this.cellAlignment = Alignment.centerLeft,
    this.flex = 1,
    this.minWidth,
    this.isFlexible = false,
    this.measureText,
  });

  final String title;
  final Widget Function(WorkSearchResult result, ThemeData theme) builder;
  final TextAlign headerAlign;
  final Alignment cellAlignment;
  final double flex;
  final double? minWidth;
  final bool isFlexible;
  final String Function(WorkSearchResult result)? measureText;
}

enum _RowAction { edit, navigate }

// ignore: unused_element
class _ActionsMenu extends StatelessWidget {
  const _ActionsMenu({
    required this.theme,
    required this.result,
    required this.canEdit,
    required this.onEdit,
    required this.onNavigateToWork,
  });

  final ThemeData theme;
  final WorkSearchResult result;
  final bool canEdit;
  final void Function(WorkSearchResult) onEdit;
  final void Function(WorkSearchResult) onNavigateToWork;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_RowAction>(
      tooltip: 'Действия',
      padding: EdgeInsets.zero,
      icon: Icon(
        CupertinoIcons.ellipsis_vertical,
        size: 18,
        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
      ),
      onSelected: (action) {
        switch (action) {
          case _RowAction.edit:
            onEdit(result);
            break;
          case _RowAction.navigate:
            onNavigateToWork(result);
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: _RowAction.navigate,
          child: _MenuRow(
            icon: CupertinoIcons.arrow_right_circle,
            color: theme.colorScheme.primary,
            label: 'Перейти к смене',
          ),
        ),
        if (canEdit)
          PopupMenuItem(
            value: _RowAction.edit,
            child: _MenuRow(
              icon: CupertinoIcons.pencil,
              color: theme.colorScheme.secondary,
              label: 'Редактировать',
            ),
          ),
      ],
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.color,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 12),
        Text(label),
      ],
    );
  }
}
