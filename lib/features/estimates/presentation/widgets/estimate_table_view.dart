import 'dart:math' as math;
import 'dart:ui' as ui show TextDirection;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/formatters.dart';
import '../../../../data/models/estimate_completion_model.dart';
import '../../../../domain/entities/estimate.dart';
import '../../../../features/roles/application/permission_service.dart';
import '../utils/estimate_sorter.dart';

/// Режимы отображения таблицы сметы.
enum EstimateViewMode {
  /// Режим "Смета" — базовая информация по позициям.
  planning,

  /// Режим "Выполнение" — фактические данные выполнения.
  execution,
}

/// Облегчённая таблица сметы без зависимостей от PlutoGrid.
class EstimateTableView extends ConsumerStatefulWidget {
  /// Создает экземпляр [EstimateTableView].
  const EstimateTableView({
    super.key,
    required this.items,
    required this.onEdit,
    required this.onDuplicate,
    required this.onDelete,
    this.onRowTap,
    this.completionData,
    this.selectedId,
    this.viewMode = EstimateViewMode.planning,
  });

  /// Список позиций сметы.
  final List<Estimate> items;

  /// Данные о выполнении позиций сметы.
  final Map<String, EstimateCompletionModel>? completionData;

  /// ID выбранной позиции для выделения.
  final String? selectedId;

  /// Режим отображения таблицы.
  final EstimateViewMode viewMode;

  /// Обратный вызов при клике на строку.
  final void Function(Estimate)? onRowTap;

  /// Обратный вызов для редактирования позиции.
  final void Function(Estimate) onEdit;

  /// Обратный вызов для дублирования позиции.
  final void Function(Estimate) onDuplicate;

  /// Обратный вызов для удаления позиции по ID.
  final void Function(String id) onDelete;

  @override
  ConsumerState<EstimateTableView> createState() => _EstimateTableViewState();
}

class _EstimateTableViewState extends ConsumerState<EstimateTableView> {
  static const double _kCellVerticalPadding = 1;
  static const double _kCellHorizontalPadding = 8;
  static const double _kDefaultMinColumnWidth = 32;

  final ScrollController _verticalController = ScrollController();
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _headerHorizontalController = ScrollController();
  bool _isSyncingScroll = false;

  bool get _isPlanning => widget.viewMode == EstimateViewMode.planning;
  bool get _isExecution => widget.viewMode == EstimateViewMode.execution;

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
    final permissionService = ref.watch(permissionServiceProvider);
    // Используем специальное право 'manual_edit' для UI-элементов ручного управления (кнопки, меню действий).
    // Стандартные права (update, create, delete) остаются для технического доступа к БД (RLS).
    final canUpdate = permissionService.can('estimates', 'manual_edit');
    final canCreate = permissionService.can('estimates', 'manual_edit');
    final canDelete = permissionService.can('estimates', 'manual_edit');

    final configs = _buildColumnConfigs(
      canUpdate: canUpdate,
      canCreate: canCreate,
      canDelete: canDelete,
    );
    final headerRow = _buildHeaderRow(theme, configs);
    final bodyRows = _buildRows(theme, configs);

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
            ? Colors.grey[800]
            : Colors.grey[200];
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
                  child: buildTable(bodyRows),
                ),
              ),
            ),
          ),
        );

        return Column(
          children: [
            header,
            const SizedBox(height: 4),
            body,
          ],
        );
      },
    );
  }

  TableRow _buildHeaderRow(
    ThemeData theme,
    List<_EstimateColumnConfig> configs,
  ) {
    return TableRow(
      children: [
        for (final config in configs)
          _headerCell(theme, config.title, align: config.headerAlign),
      ],
    );
  }

  List<TableRow> _buildRows(
    ThemeData theme,
    List<_EstimateColumnConfig> configs,
  ) {
    final rows = <TableRow>[];

    if (widget.items.isEmpty) {
      rows.add(
        TableRow(
          children: [
            _bodyCell(
              theme,
              const Text('Нет позиций', textAlign: TextAlign.center),
              align: Alignment.center,
            ),
            for (int i = 1; i < configs.length; i++)
              _bodyCell(theme, const SizedBox.shrink()),
          ],
        ),
      );
      return rows;
    }

    final sortedItems = [...widget.items]..sort(EstimateSorter.compareByNumber);

    bool alternate = false;
    for (final estimate in sortedItems) {
      alternate = !alternate;
      final completion = widget.completionData?[estimate.id];
      final isSelected = widget.selectedId == estimate.id;

      rows.add(
        TableRow(
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primaryContainer
                : (alternate
                ? theme.colorScheme.primary.withValues(alpha: 0.08)
                    : Colors.transparent),
            border: isSelected
                ? Border.all(
                    color: theme.colorScheme.primary,
                    width: 2,
                  )
                : null,
          ),
          children: [
            for (final config in configs)
              _bodyCell(
                theme,
                config.builder(estimate, completion, theme),
                align: config.cellAlignment,
                isSelected: isSelected,
                onTap: widget.onRowTap != null
                    ? () => widget.onRowTap!(estimate)
                    : null,
              ),
          ],
        ),
      );
    }

    return rows;
  }

  List<_EstimateColumnConfig> _buildColumnConfigs({
    required bool canUpdate,
    required bool canCreate,
    required bool canDelete,
  }) {
    final configs = <_EstimateColumnConfig>[
      _EstimateColumnConfig(
        title: 'Система',
        headerAlign: TextAlign.center,
        cellAlignment: Alignment.center,
        flex: 0.9,
        minWidth: 50,
        measureText: (estimate, _) => estimate.system,
        builder: (estimate, _, __) => Text(estimate.system),
      ),
      _EstimateColumnConfig(
        title: 'Подсистема',
        headerAlign: TextAlign.center,
        cellAlignment: Alignment.center,
        flex: 0.9,
        minWidth: 50,
        measureText: (estimate, _) => estimate.subsystem,
        builder: (estimate, _, __) => Text(estimate.subsystem),
      ),
      _EstimateColumnConfig(
        title: '№',
        headerAlign: TextAlign.center,
        cellAlignment: Alignment.center,
        flex: 0.7,
        minWidth: 40,
        measureText: (estimate, _) => estimate.number,
        builder: (estimate, _, __) => Text(estimate.number),
      ),
      _EstimateColumnConfig(
        title: 'Наименование',
        headerAlign: TextAlign.center,
        flex: 4.2,
        isFlexible: true,
        minWidth: 220,
        measureText: (estimate, _) => estimate.name,
        builder: (estimate, _, __) => Text(
          estimate.name,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ];

    if (_isPlanning) {
      configs.addAll([
        _EstimateColumnConfig(
          title: 'Артикул',
          headerAlign: TextAlign.center,
          cellAlignment: Alignment.center,
          flex: 0.8,
          minWidth: 60,
          measureText: (estimate, _) => estimate.article,
          builder: (estimate, _, __) => Text(estimate.article),
        ),
        _EstimateColumnConfig(
          title: 'Производитель',
          headerAlign: TextAlign.center,
          cellAlignment: Alignment.center,
          flex: 0.8,
          minWidth: 70,
          measureText: (estimate, _) => estimate.manufacturer,
          builder: (estimate, _, __) => Text(estimate.manufacturer),
        ),
      ]);
    }

    configs.addAll([
      _EstimateColumnConfig(
        title: 'Ед. изм.',
        headerAlign: TextAlign.center,
        cellAlignment: Alignment.center,
        flex: 0.8,
        minWidth: 60,
        measureText: (estimate, _) => estimate.unit,
        builder: (estimate, _, __) => Text(estimate.unit),
      ),
      _EstimateColumnConfig(
        title: 'Кол-во',
        headerAlign: TextAlign.center,
        cellAlignment: Alignment.center,
        flex: 0.8,
        minWidth: 70,
          measureText: (estimate, _) => formatQuantity(estimate.quantity),
        builder: (estimate, _, __) =>
              Text(formatQuantity(estimate.quantity)),
      ),
    ]);

    if (_isPlanning) {
      configs.addAll([
        _EstimateColumnConfig(
          title: 'Цена',
          headerAlign: TextAlign.center,
          cellAlignment: Alignment.centerRight,
          flex: 1.1,
          minWidth: 90,
          measureText: (estimate, _) => formatCurrency(estimate.price),
          builder: (estimate, _, theme) => Text(
            formatCurrency(estimate.price),
            style: TextStyle(
              color: theme.colorScheme.primary,
            ),
          ),
        ),
      ]);
    }

    if (!_isExecution) {
      configs.add(
        _EstimateColumnConfig(
          title: 'Сумма',
          headerAlign: TextAlign.center,
          cellAlignment: Alignment.centerRight,
          flex: 1.2,
          minWidth: 100,
          measureText: (estimate, _) => formatCurrency(estimate.total),
          builder: (estimate, _, __) => Text(formatCurrency(estimate.total)),
        ),
      );
    }

    if (_isExecution) {
      configs.addAll([
        _EstimateColumnConfig(
          title: 'Кол-во вып.',
          headerAlign: TextAlign.center,
          cellAlignment: Alignment.center,
          flex: 1.0,
          minWidth: 80,
          measureText: (_, completion) =>
              formatQuantity(completion?.completedQuantity ?? 0),
          builder: (estimate, completion, __) => Text(
            formatQuantity(completion?.completedQuantity ?? 0),
          ),
        ),
        /*
        _EstimateColumnConfig(
          title: 'Сумма вып.',
          headerAlign: TextAlign.center,
          cellAlignment: Alignment.centerRight,
          flex: 1.2,
          minWidth: 110,
          measureText: (_, completion) =>
              formatCurrency(completion?.completedTotal ?? 0),
          builder: (estimate, completion, __) => Text(
            formatCurrency(completion?.completedTotal ?? 0),
          ),
        ),
        */
        _EstimateColumnConfig(
          title: 'Остаток',
          headerAlign: TextAlign.center,
          cellAlignment: Alignment.center,
          flex: 1.0,
          minWidth: 90,
          measureText: (estimate, completion) => formatQuantity(
              completion?.remainingQuantity ?? estimate.quantity),
          builder: (estimate, completion, __) => Text(
            formatQuantity(
              completion?.remainingQuantity ?? estimate.quantity,
            ),
          ),
        ),
        _EstimateColumnConfig(
          title: '%',
          headerAlign: TextAlign.center,
          cellAlignment: Alignment.center,
          flex: 0.7,
          minWidth: 60,
          measureText: (_, completion) =>
              '${(completion?.percentage ?? 0).toStringAsFixed(0)}%',
          builder: (estimate, completion, theme) {
            final percent = (completion?.percentage ?? 0).toDouble();
            Color color = theme.colorScheme.onSurface;
            if (percent > 100) {
              color = theme.colorScheme.error;
            } else if ((percent - 100).abs() < 0.01) {
              color = Colors.green;
            }
            return Text(
              '${percent.toStringAsFixed(0)}%',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            );
          },
        ),
      ]);
    }

    if (!_isExecution) {
      configs.add(
        _EstimateColumnConfig(
          title: '',
          headerAlign: TextAlign.center,
          cellAlignment: Alignment.center,
          minWidth: 36,
          measureText: (_, __) => '⋮',
          builder: (estimate, _, theme) => _ActionsMenu(
            theme: theme,
            estimate: estimate,
            canEdit: canUpdate,
            canDuplicate: canCreate,
            canDelete: canDelete,
            onEdit: widget.onEdit,
            onDuplicate: widget.onDuplicate,
            onDelete: widget.onDelete,
          ),
        ),
      );
    }

    return configs;
  }

  Widget _headerCell(ThemeData theme, String title,
      {TextAlign align = TextAlign.left}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      alignment: _alignmentFromTextAlign(align),
      child: Text(
        title,
        textAlign: align,
        softWrap: true,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ) ??
            const TextStyle(fontWeight: FontWeight.w600, fontSize: 10),
      ),
    );
  }

  Widget _bodyCell(
    ThemeData theme,
    Widget child, {
    Alignment align = Alignment.centerLeft,
    VoidCallback? onTap,
    bool isSelected = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
      padding: const EdgeInsets.symmetric(
            horizontal: _kCellHorizontalPadding,
            vertical: _kCellVerticalPadding),
      constraints: const BoxConstraints(minHeight: 30),
      alignment: align,
      child: DefaultTextStyle.merge(
          style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 12,
                height: 1.0,
                fontWeight: isSelected ? FontWeight.bold : null,
                color: isSelected ? theme.colorScheme.onPrimaryContainer : null,
              ) ??
            const TextStyle(fontSize: 12, height: 1.0),
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
    List<_EstimateColumnConfig> configs,
    ThemeData theme,
    double availableWidth,
  ) {
    final widths = <int, TableColumnWidth>{};
    final fixedWidths = <int, double>{};
    double totalFixed = 0;

    final headerStyle = theme.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ) ??
        const TextStyle(fontWeight: FontWeight.w600, fontSize: 11);
    final bodyStyle =
        theme.textTheme.bodySmall?.copyWith(fontSize: 12, height: 1.0) ??
            const TextStyle(fontSize: 12, height: 1.0);

    const paddingWidth = _kCellHorizontalPadding * 2;

    for (var i = 0; i < configs.length; i++) {
      final config = configs[i];

      if (config.isFlexible) {
        // handle later
        continue;
      }

      double columnWidth = config.minWidth ?? _kDefaultMinColumnWidth;
      if (config.measureText != null) {
        for (final estimate in widget.items) {
          final completion = widget.completionData?[estimate.id];
          final text = config.measureText!(estimate, completion);
          if (text == null || text.isEmpty) continue;
          final width = _measureText(text, bodyStyle) + paddingWidth;
          columnWidth = math.max(columnWidth, width);
        }
      }

      if (widget.items.isEmpty) {
        final headerWidth =
            _measureText(config.title, headerStyle) + paddingWidth;
        columnWidth = math.max(columnWidth, headerWidth);
      }

      columnWidth =
          math.max(columnWidth, config.minWidth ?? _kDefaultMinColumnWidth);

      fixedWidths[i] = columnWidth;
      totalFixed += columnWidth;
    }

    double remainingWidth =
        math.max(availableWidth - totalFixed, configs.length * 40);
    final flexibleIndexes = <int>[];
    for (var i = 0; i < configs.length; i++) {
      final config = configs[i];
      if (config.isFlexible) {
        flexibleIndexes.add(i);
      } else {
        widths[i] = FixedColumnWidth(fixedWidths[i]!);
      }
    }

    if (flexibleIndexes.isEmpty) {
      return widths;
    }

    final totalFlex = flexibleIndexes
        .map((index) => configs[index].flex)
        .fold<double>(0, (prev, flex) => prev + flex);

    for (final index in flexibleIndexes) {
      final config = configs[index];
      final flexPortion = totalFlex == 0
          ? 1.0 / flexibleIndexes.length
          : config.flex / totalFlex;
      double width = remainingWidth * flexPortion;
      width = math.max(width, config.minWidth ?? 100);
      widths[index] = FixedColumnWidth(width);
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

class _EstimateColumnConfig {
  const _EstimateColumnConfig({
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
  final Widget Function(
    Estimate estimate,
    EstimateCompletionModel? completion,
    ThemeData theme,
  ) builder;
  final TextAlign headerAlign;
  final Alignment cellAlignment;
  final double flex;
  final double? minWidth;
  final bool isFlexible;
  final String? Function(
      Estimate estimate, EstimateCompletionModel? completion)? measureText;
}

enum _RowAction { edit, duplicate, delete }

class _ActionsMenu extends StatelessWidget {
  const _ActionsMenu({
    required this.theme,
    required this.estimate,
    required this.canEdit,
    required this.canDuplicate,
    required this.canDelete,
    required this.onEdit,
    required this.onDuplicate,
    required this.onDelete,
  });

  final ThemeData theme;
  final Estimate estimate;
  final bool canEdit;
  final bool canDuplicate;
  final bool canDelete;
  final void Function(Estimate) onEdit;
  final void Function(Estimate) onDuplicate;
  final void Function(String) onDelete;

  @override
  Widget build(BuildContext context) {
    if (!canEdit && !canDuplicate && !canDelete) {
      return const SizedBox.shrink();
    }

    return Theme(
      data: theme.copyWith(
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        hoverColor: Colors.transparent,
        highlightColor: Colors.transparent,
        splashColor: Colors.transparent,
        iconButtonTheme: IconButtonThemeData(
          style: ButtonStyle(
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            minimumSize: WidgetStateProperty.all<Size>(
              const Size(28, 28),
            ),
            overlayColor: WidgetStateProperty.all<Color>(
              Colors.transparent,
            ),
            splashFactory: NoSplash.splashFactory,
          ),
        ),
      ),
      child: PopupMenuButton<_RowAction>(
        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
        tooltip: 'Действия',
        padding: EdgeInsets.zero,
        icon: Icon(
          CupertinoIcons.ellipsis_vertical,
          size: 16,
          color: theme.colorScheme.onSurface,
        ),
        onSelected: (action) {
          switch (action) {
            case _RowAction.edit:
              onEdit(estimate);
              break;
            case _RowAction.duplicate:
              onDuplicate(estimate);
              break;
            case _RowAction.delete:
              onDelete(estimate.id);
              break;
          }
        },
        itemBuilder: (context) => [
          if (canEdit)
            PopupMenuItem(
              value: _RowAction.edit,
              child: _MenuRow(
                icon: CupertinoIcons.pencil,
                color: theme.colorScheme.primary,
                label: 'Редактировать',
              ),
            ),
          if (canDuplicate)
            PopupMenuItem(
              value: _RowAction.duplicate,
              child: _MenuRow(
                icon: CupertinoIcons.doc_on_doc,
                color: theme.colorScheme.secondary,
                label: 'Дублировать',
              ),
            ),
          if (canDelete)
            PopupMenuItem(
              value: _RowAction.delete,
              child: _MenuRow(
                icon: CupertinoIcons.trash,
                color: theme.colorScheme.error,
                label: 'Удалить',
              ),
            ),
        ],
      ),
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
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
