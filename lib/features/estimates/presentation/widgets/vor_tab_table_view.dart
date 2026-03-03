import 'dart:math' as math;
import 'dart:ui' as ui show TextDirection;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/formatters.dart';
import '../../../../domain/entities/estimate.dart';
import '../../../../domain/entities/vor.dart';
import '../providers/estimate_providers.dart';
import '../utils/estimate_sorter.dart';

/// Таблица для отображения вкладки ВОР в детальном режиме сметы.
///
/// Показывает базовые колонки сметы и динамический набор колонок по ведомостям
/// ВОР (`ВОР-1 ... ВОР-N`) с итогом по строке.
class VorTabTableView extends ConsumerStatefulWidget {
  /// Позиции выбранной сметы.
  final List<Estimate> items;

  /// Идентификатор договора для загрузки списка ВОР и их количеств.
  final String contractId;

  /// Поисковый запрос.
  final String searchQuery;

  /// Создает экземпляр [VorTabTableView].
  const VorTabTableView({
    super.key,
    required this.items,
    required this.contractId,
    this.searchQuery = '',
  });

  @override
  ConsumerState<VorTabTableView> createState() => _VorTabTableViewState();
}

class _VorTabTableViewState extends ConsumerState<VorTabTableView> {
  final ScrollController _verticalController = ScrollController();
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _headerHorizontalController = ScrollController();
  bool _isSyncingHeader = false;

  @override
  void initState() {
    super.initState();
    _horizontalController.addListener(_syncHeaderScroll);
  }

  void _syncHeaderScroll() {
    if (_isSyncingHeader || !_headerHorizontalController.hasClients) return;
    _isSyncingHeader = true;
    _headerHorizontalController.jumpTo(_horizontalController.offset);
    _isSyncingHeader = false;
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
    final dividerColor = theme.colorScheme.outline.withValues(alpha: 0.18);
    final headerColor = theme.brightness == Brightness.dark
        ? Colors.grey[800]!
        : Colors.grey[200]!;

    final completionDataAsync = ref.watch(
      contractVorCompletionProvider(widget.contractId),
    );

    return completionDataAsync.when(
      data: (data) {
        final vors = [...data.vors]..sort(
          (a, b) {
            final aOrder = _extractVorOrder(a.number);
            final bOrder = _extractVorOrder(b.number);
            final byOrder = aOrder.compareTo(bOrder);
            if (byOrder != 0) return byOrder;
            return a.number.toLowerCase().compareTo(b.number.toLowerCase());
          },
        );
        final completionMap = data.completionMap;
        final filteredItems = _filterItems(widget.items);
        final sortedItems = [...filteredItems]..sort(EstimateSorter.compareByNumber);

        if (sortedItems.isEmpty) {
          return const Center(child: Text('Нет позиций для отображения'));
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final availableWidth = constraints.maxWidth.isFinite
                ? constraints.maxWidth
                : MediaQuery.of(context).size.width;

            final columnWidths = _buildColumnWidths(
              items: sortedItems,
              vors: vors,
              availableWidth: availableWidth,
              theme: theme,
            );
            final headerRow = _buildHeaderRow(
              theme,
              dividerColor,
              columnWidths,
              vors,
            );
            final bodyRows = _buildBodyRows(
              theme: theme,
              dividerColor: dividerColor,
              items: sortedItems,
              vors: vors,
              completionMap: completionMap,
            );

            Widget buildTable(List<TableRow> rows) {
              return Table(
                columnWidths: columnWidths,
                border: TableBorder(
                  top: BorderSide(color: dividerColor),
                  bottom: BorderSide(color: dividerColor),
                  left: BorderSide(color: dividerColor),
                  right: BorderSide(color: dividerColor),
                  horizontalInside: BorderSide(color: dividerColor),
                  verticalInside: BorderSide(color: dividerColor),
                ),
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                children: rows,
              );
            }

            return Column(
              children: [
                Container(
                  color: headerColor,
                  child: SingleChildScrollView(
                    controller: _headerHorizontalController,
                    physics: const NeverScrollableScrollPhysics(),
                    scrollDirection: Axis.horizontal,
                    child: buildTable([headerRow]),
                  ),
                ),
                const SizedBox(height: 4),
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
      },
      loading: () => const Center(child: CupertinoActivityIndicator()),
      error: (e, s) => Center(child: Text('Ошибка загрузки ВОР: $e')),
    );
  }

  List<Estimate> _filterItems(List<Estimate> items) {
    final query = widget.searchQuery.trim().toLowerCase();
    if (query.isEmpty) return items;

    return items.where((item) {
      return item.number.toLowerCase().contains(query) ||
          item.name.toLowerCase().contains(query) ||
          item.system.toLowerCase().contains(query) ||
          item.subsystem.toLowerCase().contains(query);
    }).toList();
  }

  Map<int, TableColumnWidth> _buildColumnWidths({
    required List<Estimate> items,
    required List<Vor> vors,
    required double availableWidth,
    required ThemeData theme,
  }) {
    // Для колонок "Система / Подсистема / № / Наименование" применяем тот же
    // подход, что и в таблице "Смета/Выполнение":
    // minWidth + измерение текста + гибкая колонка наименования.
    const minSystem = 50.0;
    const minSubsystem = 50.0;
    const minNumber = 40.0;
    const minNameBase = 600.0;
    const minNameWhenManyVorColumns = 600.0;
    const minUnit = 60.0;
    const minQty = 70.0;
    const vorWidth = 75.0;
    const totalWidth = 95.0;
    const cellHorizontalPadding = 8.0;
    const paddingWidth = cellHorizontalPadding * 2;

    final bodyStyle =
        theme.textTheme.bodySmall?.copyWith(fontSize: 12, letterSpacing: 0) ??
        const TextStyle(fontSize: 12, letterSpacing: 0);
    final headerStyle =
        theme.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 10,
          letterSpacing: 0,
        ) ??
        const TextStyle(fontWeight: FontWeight.w600, fontSize: 10, letterSpacing: 0);

    var systemW =
        math.max(minSystem, _measureText('Система', headerStyle) + paddingWidth);
    var subsystemW = math.max(
      minSubsystem,
      _measureText('Подсистема', headerStyle) + paddingWidth,
    );
    var numberW = math.max(minNumber, _measureText('№', headerStyle) + paddingWidth);

    for (final item in items) {
      systemW = math.max(systemW, _measureText(item.system, bodyStyle) + paddingWidth);
      subsystemW = math.max(
        subsystemW,
        _measureText(item.subsystem, bodyStyle) + paddingWidth,
      );
      numberW = math.max(numberW, _measureText(item.number, bodyStyle) + paddingWidth);
    }

    final unitW = math.max(
      minUnit,
      _measureText('Ед. изм.', headerStyle) + paddingWidth,
    );
    final qtyW = math.max(minQty, _measureText('Кол-во', headerStyle) + paddingWidth);

    final dynamicW = (vors.length * vorWidth) + totalWidth;
    final fixedWithoutName = systemW + subsystemW + numberW + unitW + qtyW + dynamicW;
    final minName = vors.length >= 5 ? minNameWhenManyVorColumns : minNameBase;
    final nameW = math.max(minName, availableWidth - fixedWithoutName);

    final widths = <int, TableColumnWidth>{
      0: FixedColumnWidth(systemW), // Система
      1: FixedColumnWidth(subsystemW), // Подсистема
      2: FixedColumnWidth(numberW), // №
      3: FixedColumnWidth(nameW), // Наименование (гибкая)
      4: FixedColumnWidth(unitW), // Ед. изм.
      5: FixedColumnWidth(qtyW), // Кол-во
    };

    var index = 6;
    for (var i = 0; i < vors.length; i++) {
      widths[index++] = const FixedColumnWidth(vorWidth); // ВОР-i
    }
    widths[index] = const FixedColumnWidth(totalWidth); // ИТОГО

    return widths;
  }

  TableRow _buildHeaderRow(
    ThemeData theme,
    Color dividerColor,
    Map<int, TableColumnWidth> widths,
    List<Vor> vors,
  ) {
    final style =
        theme.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 10,
          letterSpacing: 0,
        ) ??
        const TextStyle(fontWeight: FontWeight.w600, fontSize: 10, letterSpacing: 0);

    final cells = <Widget>[
      _headerCell('Система', style),
      _headerCell('Подсистема', style),
      _headerCell('№', style),
      _headerCell('Наименование', style),
      _headerCell('Ед. изм.', style),
      _headerCell('Кол-во', style),
    ];

    for (final vor in vors) {
      cells.add(_headerCell(vor.number, style));
    }
    cells.add(_headerCell('ИТОГО', style));

    return TableRow(children: cells);
  }

  List<TableRow> _buildBodyRows({
    required ThemeData theme,
    required Color dividerColor,
    required List<Estimate> items,
    required List<Vor> vors,
    required Map<String, Map<String, double>> completionMap,
  }) {
    final rows = <TableRow>[];

    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      final isAlternate = i.isEven;
      final rowColor = isAlternate
          ? theme.colorScheme.primary.withValues(alpha: 0.08)
          : Colors.transparent;
      final itemCompletion = completionMap[item.id] ?? const <String, double>{};
      final total = vors.fold<double>(
        0,
        (sum, vor) => sum + (itemCompletion[vor.id] ?? 0),
      );

      final isOverLimit = total > item.quantity;
      final rowStyle = isOverLimit ? const TextStyle(color: Colors.red) : null;

      final cells = <Widget>[
        _bodyCell(item.system, alignment: Alignment.center, style: rowStyle),
        _bodyCell(item.subsystem, alignment: Alignment.center, style: rowStyle),
        _bodyCell(item.number, alignment: Alignment.center, style: rowStyle),
        _bodyCell(item.name, alignment: Alignment.centerLeft, style: rowStyle),
        _bodyCell(item.unit, alignment: Alignment.center, style: rowStyle),
        _bodyCell(
          formatQuantity(item.quantity),
          alignment: Alignment.center,
          style: rowStyle,
        ),
      ];

      for (final vor in vors) {
        cells.add(
          _bodyCell(
            formatQuantity(itemCompletion[vor.id] ?? 0),
            alignment: Alignment.center,
            style: rowStyle,
          ),
        );
      }

      cells.add(
        _bodyCell(
          formatQuantity(total),
          alignment: Alignment.center,
          style: rowStyle?.copyWith(fontWeight: FontWeight.w700) ??
              const TextStyle(fontWeight: FontWeight.w700),
        ),
      );

      rows.add(TableRow(decoration: BoxDecoration(color: rowColor), children: cells));
    }

    return rows;
  }

  Widget _headerCell(String text, TextStyle style) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      alignment: Alignment.center,
      child: Text(text, textAlign: TextAlign.center, style: style),
    );
  }

  Widget _bodyCell(
    String text, {
    Alignment alignment = Alignment.center,
    TextStyle? style,
  }) {
    final theme = Theme.of(context);
    final baseStyle =
        theme.textTheme.bodySmall?.copyWith(fontSize: 12, letterSpacing: 0) ??
        const TextStyle(fontSize: 12, letterSpacing: 0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      constraints: const BoxConstraints(minHeight: 28),
      alignment: alignment,
      child: Text(
        text,
        style: baseStyle.merge(style),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        textAlign: alignment == Alignment.centerRight
            ? TextAlign.right
            : (alignment == Alignment.centerLeft
                  ? TextAlign.left
                  : TextAlign.center),
      ),
    );
  }

  double _measureText(String text, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: ui.TextDirection.ltr,
      maxLines: 1,
    )..layout();
    return painter.width;
  }

  int _extractVorOrder(String value) {
    final match = RegExp(r'\d+').firstMatch(value);
    if (match == null) return 1 << 30;
    return int.tryParse(match.group(0) ?? '') ?? (1 << 30);
  }
}
