import 'dart:math' as math;
import 'dart:ui' as ui show TextDirection;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:projectgt/core/widgets/gt_context_menu.dart';
import 'package:projectgt/domain/entities/estimate.dart';
import 'package:projectgt/features/contractors/presentation/providers/subcontractors_contractor_unit_prices_provider.dart';
import 'package:projectgt/features/contractors/presentation/providers/subcontractors_execution_progress_provider.dart';
import 'package:projectgt/features/contractors/presentation/widgets/subcontractors_estimate_table_cells.dart';
import 'package:projectgt/features/contractors/presentation/widgets/subcontractors_estimate_table_column_config.dart';
import 'package:projectgt/features/contractors/presentation/widgets/subcontractors_estimate_table_column_factories.dart';
import 'package:projectgt/features/contractors/presentation/widgets/subcontractors_estimate_table_math.dart';
import 'package:projectgt/features/contractors/presentation/widgets/subcontractors_estimate_table_mode.dart';
import 'package:projectgt/features/contractors/presentation/widgets/subcontractors_estimate_table_selection.dart';
import 'package:projectgt/features/roles/application/permission_service.dart';

/// Таблица позиций сметы для модуля «Подрядчики».
///
/// Самостоятельная реализация (не использует [EstimateTableView] из модуля смет):
/// плановые колонки без «Система»/«Подсистема», оформление и поведение скопированы
/// с вкладки «Смета». Позиции **группируются по** [Estimate.estimateTitle] (сортировка
/// групп по названию, внутри группы — сортировка по номеру, см.
/// [SubcontractorsEstimateTableMath.buildEstimateTitleGroups]). Контекстное меню —
/// пункты по модулям `subcontractors` / `estimates`, опционально добавление позиции сметы
/// ([onAddPosition] + право `estimates` / `update`) и опционально «История по ДС»
/// ([onEstimateAddendumHistory] + право `estimates` / `read`).
class SubcontractorsEstimateTableView extends ConsumerStatefulWidget {
  /// Создаёт таблицу.
  const SubcontractorsEstimateTableView({
    super.key,
    required this.items,
    required this.onEdit,
    required this.onDuplicate,
    required this.onDelete,
    this.onAddPosition,
    this.onRowTap,
    this.selectedId,
    this.subcontractorPricingByEstimateId,
    this.executionByEstimateId,
    this.mode = SubcontractorsEstimateTableMode.rates,
    this.expandSections = false,
    this.selectedEstimateIds = const <String>{},
    this.onSelectedEstimateIdsChanged,
    this.showInEstimatesModuleColumn = false,
    this.onVisibleInEstimatesModuleTap,
    this.onDeleteSelected,
    this.onEstimateAddendumHistory,
  });

  /// Позиции.
  final List<Estimate> items;

  /// Расценка и объём выбранного подрядчика по [Estimate.id].
  ///
  /// Если null — колонки не показываются. Отсутствующее поле — «—».
  final Map<String, SubcontractorPricingForEstimate>?
  subcontractorPricingByEstimateId;

  /// Факт выполнения подрядчика по [Estimate.id].
  final Map<String, SubcontractorExecutionProgress>? executionByEstimateId;

  /// Режим таблицы: расценки или выполнение.
  final SubcontractorsEstimateTableMode mode;

  /// После синхронизации набора позиций: `true` — разделы раскрыты, `false` — все свёрнуты.
  /// Заголовок группы можно нажать, чтобы локально развернуть или свернуть раздел.
  final bool expandSections;

  /// ID позиций, отмеченных чекбоксами в таблице.
  final Set<String> selectedEstimateIds;

  /// Вызывается при изменении набора отмеченных позиций.
  final ValueChanged<Set<String>>? onSelectedEstimateIdsChanged;

  /// Нажатие на строку.
  final void Function(Estimate)? onRowTap;

  /// ID выбранной строки.
  final String? selectedId;

  /// Редактирование позиции.
  final void Function(Estimate) onEdit;

  /// Дублирование позиции.
  final void Function(Estimate) onDuplicate;

  /// Удаление позиции по id.
  final void Function(String id) onDelete;

  /// Добавить новую позицию в ту же смету, что и [contextRow] (контекст: заголовок, объект, договор).
  ///
  /// Если null — пункт в контекстном меню не показывается.
  final void Function(Estimate contextRow)? onAddPosition;

  /// Показывать колонку «в модуле Сметы» в режиме расценок.
  final bool showInEstimatesModuleColumn;

  /// Нажатие на индикатор видимости в модуле «Сметы» (без смены оформления индикатора).
  final void Function(Estimate estimate)? onVisibleInEstimatesModuleTap;

  /// Удалить все позиции из [selectedEstimateIds] (контекстное меню; только если задано снаружи).
  ///
  /// Используется на карточке договора: пункт «Удалить выбранное» показывается при
  /// непустом наборе отмеченных чекбоксами позиций.
  final void Function(BuildContext context)? onDeleteSelected;

  /// История позиции по снимкам ДС (только read-only UI; карточка договора).
  ///
  /// Если null — пункт «История по ДС» в контекстном меню не показывается.
  final void Function(Estimate estimate)? onEstimateAddendumHistory;

  @override
  ConsumerState<SubcontractorsEstimateTableView> createState() =>
      _SubcontractorsEstimateTableViewState();
}

class _SubcontractorsEstimateTableViewState
    extends ConsumerState<SubcontractorsEstimateTableView> {
  static const double _kCellVerticalPadding = 2;
  static const double _kCellHorizontalPadding = 8;
  static const double _kDefaultMinColumnWidth = 32;

  final ScrollController _verticalController = ScrollController();
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _headerHorizontalController = ScrollController();
  bool _isSyncingScroll = false;

  SubcontractorsEstimateTableMath get _math => SubcontractorsEstimateTableMath(
    subcontractorPricingByEstimateId: widget.subcontractorPricingByEstimateId,
    executionByEstimateId: widget.executionByEstimateId,
  );

  String? _contextMenuSelectedId;

  /// Ключи разделов ([Estimate.estimateTitle] после нормализации), свёрнутых в таблице.
  ///
  /// По умолчанию все разделы свёрнуты. Смена [mode] или [expandSections] пересчитывает
  /// состояние. Смена только набора позиций лишь убирает ключи исчезнувших разделов —
  /// раскрытые пользователем секции не сворачиваются снова.
  final Set<String> _collapsedSectionKeys = <String>{};

  @override
  void initState() {
    super.initState();
    _horizontalController.addListener(_syncHeaderScroll);
    _syncSectionCollapseState();
  }

  @override
  void didUpdateWidget(SubcontractorsEstimateTableView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldIds = oldWidget.items.map((e) => e.id).toSet();
    final newIds = widget.items.map((e) => e.id).toSet();
    final idsChanged = !_sameIds(oldIds, newIds);
    final modeOrExpandChanged =
        oldWidget.mode != widget.mode ||
        oldWidget.expandSections != widget.expandSections;

    if (modeOrExpandChanged) {
      _syncSectionCollapseState();
    } else if (idsChanged) {
      _pruneCollapsedSectionKeysForCurrentItems();
    }

    if (idsChanged || modeOrExpandChanged) {
      final prunedSelectedIds = widget.selectedEstimateIds
          .where(newIds.contains)
          .toSet();
      if (prunedSelectedIds.length != widget.selectedEstimateIds.length) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          widget.onSelectedEstimateIdsChanged?.call(prunedSelectedIds);
        });
      }
    }
  }

  bool _sameIds(Set<String> a, Set<String> b) {
    return a.length == b.length && a.containsAll(b);
  }

  void _syncSectionCollapseState() {
    if (widget.expandSections) {
      _collapsedSectionKeys.clear();
      return;
    }
    _collapseAllSections();
  }

  void _collapseAllSections() {
    final tableItems = _math.tableItems(mode: widget.mode, items: widget.items);
    _collapsedSectionKeys
      ..clear()
      ..addAll(
        _math.buildEstimateTitleGroups(tableItems).map((g) => g.sortKey),
      );
  }

  /// Убирает ключи разделов, которых больше нет в данных, не трогая раскрытые пользователем блоки.
  void _pruneCollapsedSectionKeysForCurrentItems() {
    if (widget.expandSections) {
      _collapsedSectionKeys.clear();
      return;
    }
    final tableItems = _math.tableItems(mode: widget.mode, items: widget.items);
    final validKeys = _math
        .buildEstimateTitleGroups(tableItems)
        .map((g) => g.sortKey)
        .toSet();
    _collapsedSectionKeys.removeWhere((k) => !validKeys.contains(k));
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
    final tableItems = _math.tableItems(mode: widget.mode, items: widget.items);
    final isEmpty = tableItems.isEmpty;
    final configs = _buildColumnConfigs();
    final headerRow = _buildHeaderRow(theme, configs);
    final bodyRows = isEmpty
        ? <TableRow>[]
        : _buildRows(theme, configs, tableItems);

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

        final body = isEmpty
            ? Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 32,
                    ),
                    child: Text(
                      'Нет позиций',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              )
            : Expanded(
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

        return Column(children: [header, const SizedBox(height: 4), body]);
      },
    );
  }

  TableRow _buildHeaderRow(
    ThemeData theme,
    List<SubcontractorColumnConfig> configs,
  ) {
    return TableRow(
      children: [
        for (final config in configs)
          _headerCell(
            theme,
            config.title,
            align: config.headerAlign,
            headerChild: config.headerBuilder?.call(theme),
            backgroundColor: config.isSubcontractorBlock
                ? _subBlockHeaderFill(theme)
                : null,
            border: _subBlockBorder(theme, config.subBlockEdge),
          ),
      ],
    );
  }

  /// Индекс колонки выбора — в строке-заголовке группы выбирает весь раздел.
  static const int _kSelectionColumnIndex = 0;

  /// Индекс колонки «Наименование» — в строке-заголовке группы показываем название сметы.
  static const int _kEstimateTitleColumnIndex = 2;

  Color _subBlockHeaderFill(ThemeData theme) {
    return theme.colorScheme.tertiaryContainer.withValues(alpha: 0.42);
  }

  Color? _subBlockBodyFill(
    ThemeData theme,
    SubcontractorColumnConfig config, {
    required bool alternate,
    required bool isSelected,
    required bool isContextMenuSelected,
  }) {
    if (!config.isSubcontractorBlock || isSelected || isContextMenuSelected) {
      return null;
    }
    return theme.colorScheme.tertiaryContainer.withValues(
      alpha: alternate ? 0.12 : 0.18,
    );
  }

  Color? _subBlockFillOnGroupBand(
    ThemeData theme,
    SubcontractorColumnConfig config,
    Color groupBandColor,
  ) {
    if (!config.isSubcontractorBlock) return null;
    return Color.alphaBlend(
      theme.colorScheme.tertiaryContainer.withValues(alpha: 0.28),
      groupBandColor,
    );
  }

  BoxBorder? _subBlockBorder(
    ThemeData theme,
    SubcontractorTableBlockEdge edge,
  ) {
    final side = BorderSide(
      color: theme.colorScheme.tertiary.withValues(alpha: 0.5),
      width: 1.5,
    );
    switch (edge) {
      case SubcontractorTableBlockEdge.none:
        return null;
      case SubcontractorTableBlockEdge.start:
        return Border(left: side);
      case SubcontractorTableBlockEdge.inner:
        return null;
      case SubcontractorTableBlockEdge.end:
        return Border(right: side);
    }
  }

  bool _isEstimateSelected(Estimate estimate) {
    return widget.selectedEstimateIds.contains(estimate.id);
  }

  void _setEstimateSelected(Estimate estimate, bool selected) {
    final nextSelectedIds = widget.selectedEstimateIds.toSet();
    if (selected) {
      nextSelectedIds.add(estimate.id);
    } else {
      nextSelectedIds.remove(estimate.id);
    }
    widget.onSelectedEstimateIdsChanged?.call(nextSelectedIds);
  }

  bool? _groupSelectionValue(List<Estimate> estimates) {
    if (estimates.isEmpty) return false;
    final selectedCount = estimates
        .where((estimate) => widget.selectedEstimateIds.contains(estimate.id))
        .length;
    if (selectedCount == 0) return false;
    if (selectedCount == estimates.length) return true;
    return null;
  }

  void _setGroupSelected(List<Estimate> estimates, bool selected) {
    final nextSelectedIds = widget.selectedEstimateIds.toSet();
    for (final estimate in estimates) {
      if (selected) {
        nextSelectedIds.add(estimate.id);
      } else {
        nextSelectedIds.remove(estimate.id);
      }
    }
    widget.onSelectedEstimateIdsChanged?.call(nextSelectedIds);
  }

  void _cycleExecutionGroupSelection(List<Estimate> estimates) {
    final next = SubcontractorsEstimateTableSelection.cycleExecutionGroup(
      selectedEstimateIds: widget.selectedEstimateIds,
      groupEstimates: estimates,
      completedQuantity: _math.completedQuantity,
    );
    widget.onSelectedEstimateIdsChanged?.call(next);
  }

  Widget _selectionCheckbox({
    required bool? value,
    required ValueChanged<bool?> onChanged,
    required String semanticLabel,
    bool isGroup = false,
  }) {
    final checkbox = SizedBox.square(
      dimension: 18,
      child: Checkbox(
        value: value,
        tristate: true,
        visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        splashRadius: 0,
        onChanged: onChanged,
      ),
    );

    final child = isGroup
        ? DecoratedBox(
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.08),
              border: Border.all(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.38),
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: SizedBox.square(
              dimension: 24,
              child: Center(child: checkbox),
            ),
          )
        : checkbox;

    return Semantics(label: semanticLabel, child: child);
  }

  /// Список групп (ключ сортировки → позиции).
  List<({String sortKey, List<Estimate> estimates})> _buildEstimateTitleGroups([
    List<Estimate>? source,
  ]) {
    final items =
        source ?? _math.tableItems(mode: widget.mode, items: widget.items);
    return _math.buildEstimateTitleGroups(items);
  }

  List<TableRow> _buildRows(
    ThemeData theme,
    List<SubcontractorColumnConfig> configs,
    List<Estimate> tableItems,
  ) {
    if (tableItems.isEmpty) {
      return [];
    }

    final groups = _buildEstimateTitleGroups(tableItems);
    final rows = <TableRow>[];
    final showExecutionVolumeTotals =
        widget.mode != SubcontractorsEstimateTableMode.execution;

    final groupRowBackground = theme.brightness == Brightness.dark
        ? Colors.grey[800]
        : Colors.grey[300];
    final groupTitleStyle =
        theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 12,
          letterSpacing: 0,
        ) ??
        const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12,
          letterSpacing: 0,
        );

    var alternate = false;
    for (final group in groups) {
      final displayTitle = SubcontractorsEstimateTableMath.estimateTitleLabel(
        group.sortKey,
      );
      final isCollapsed = _collapsedSectionKeys.contains(group.sortKey);
      final groupSelectionValue = _groupSelectionValue(group.estimates);
      final planSectionSum = _math.sectionPlanTotalSum(group.estimates);
      final subQuantitySum = showExecutionVolumeTotals
          ? _math.sectionSubcontractorQuantitySum(group.estimates)
          : 0.0;
      final subMoneySum = _math.sectionSubcontractorMoneySum(group.estimates);
      final hasSubPrice = _math.sectionHasAnySubcontractorPrice(
        group.estimates,
      );
      final completedQuantitySum = showExecutionVolumeTotals
          ? _math.sectionCompletedQuantitySum(group.estimates)
          : 0.0;
      final completedAmountSum = _math.sectionCompletedAmountSum(
        group.estimates,
      );
      final remainingQuantitySum = showExecutionVolumeTotals
          ? _math.sectionRemainingQuantitySum(group.estimates)
          : 0.0;
      final remainingAmountSum = _math.sectionRemainingAmountSum(
        group.estimates,
      );
      final completionPercent = _math.sectionCompletionPercent(group.estimates);
      final sectionTotalsStyle = groupTitleStyle.copyWith(
        fontWeight: FontWeight.w700,
        fontSize: 11,
      );

      rows.add(
        TableRow(
          decoration: BoxDecoration(color: groupRowBackground),
          children: [
            for (var i = 0; i < configs.length; i++)
              i == _kSelectionColumnIndex
                  ? _bodyCell(
                      theme,
                      _selectionCheckbox(
                        value: groupSelectionValue,
                        semanticLabel:
                            'Выбрать все позиции раздела $displayTitle',
                        isGroup: true,
                        onChanged: (_) {
                          if (widget.mode ==
                              SubcontractorsEstimateTableMode.execution) {
                            _cycleExecutionGroupSelection(group.estimates);
                            return;
                          }
                          _setGroupSelected(
                            group.estimates,
                            groupSelectionValue != true,
                          );
                        },
                      ),
                      align: configs[i].cellAlignment,
                    )
                  : i == _kEstimateTitleColumnIndex
                  ? _bodyCell(
                      theme,
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          hoverColor: Colors.transparent,
                          focusColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          splashColor: Colors.transparent,
                          onTap: () {
                            setState(() {
                              if (isCollapsed) {
                                _collapsedSectionKeys.remove(group.sortKey);
                              } else {
                                _collapsedSectionKeys.add(group.sortKey);
                              }
                            });
                          },
                          child: Semantics(
                            button: true,
                            label: isCollapsed
                                ? 'Развернуть раздел $displayTitle'
                                : 'Свернуть раздел $displayTitle',
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Icon(
                                  isCollapsed
                                      ? Icons.chevron_right_rounded
                                      : Icons.expand_more_rounded,
                                  size: 22,
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.85,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                Expanded(
                                  child: Text(
                                    displayTitle,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: groupTitleStyle,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      align: configs[i].cellAlignment,
                    )
                  : _bodyCell(
                      theme,
                      SubcontractorsEstimateTableCells.groupHeaderSecondary(
                        theme,
                        widget.mode,
                        configs[i],
                        isCollapsed: isCollapsed,
                        planSectionSum: planSectionSum,
                        subQuantitySum: subQuantitySum,
                        subMoneySum: subMoneySum,
                        hasSubPrice: hasSubPrice,
                        completedQuantitySum: completedQuantitySum,
                        completedAmountSum: completedAmountSum,
                        remainingQuantitySum: remainingQuantitySum,
                        remainingAmountSum: remainingAmountSum,
                        completionPercent: completionPercent,
                        metricStyle: sectionTotalsStyle,
                        showExecutionVolumeTotals: showExecutionVolumeTotals,
                      ),
                      align: configs[i].cellAlignment,
                      backgroundColor: _subBlockFillOnGroupBand(
                        theme,
                        configs[i],
                        groupRowBackground ??
                            theme.colorScheme.surfaceContainerHighest,
                      ),
                      border: _subBlockBorder(theme, configs[i].subBlockEdge),
                    ),
          ],
        ),
      );

      if (isCollapsed) {
        continue;
      }

      for (final estimate in group.estimates) {
        alternate = !alternate;
        final isSelected = widget.selectedId == estimate.id;
        final isContextMenuSelected = _contextMenuSelectedId == estimate.id;
        final isChecked = _isEstimateSelected(estimate);

        rows.add(
          TableRow(
            decoration: BoxDecoration(
              color: isContextMenuSelected
                  ? theme.colorScheme.primary.withValues(alpha: 0.15)
                  : (isSelected
                        ? theme.colorScheme.primaryContainer
                        : (isChecked
                              ? theme.colorScheme.primary.withValues(
                                  alpha: 0.12,
                                )
                              : (alternate
                                    ? theme.colorScheme.primary.withValues(
                                        alpha: 0.08,
                                      )
                                    : Colors.transparent))),
              border: isSelected
                  ? Border.all(color: theme.colorScheme.primary, width: 2)
                  : null,
            ),
            children: [
              for (final config in configs)
                _bodyCell(
                  theme,
                  config.builder(estimate, theme),
                  align: config.cellAlignment,
                  isSelected: isSelected,
                  backgroundColor: _subBlockBodyFill(
                    theme,
                    config,
                    alternate: alternate,
                    isSelected: isSelected,
                    isContextMenuSelected: isContextMenuSelected,
                  ),
                  border: _subBlockBorder(theme, config.subBlockEdge),
                  onTap: widget.onRowTap != null
                      ? () => widget.onRowTap!(estimate)
                      : null,
                  onSecondaryTapDown: (details) => _showContextMenu(
                    context,
                    estimate,
                    details.globalPosition,
                  ),
                ),
            ],
          ),
        );
      }

      final groupBand =
          groupRowBackground ?? theme.colorScheme.surfaceContainerHighest;
      rows.add(
        TableRow(
          decoration: BoxDecoration(color: groupRowBackground),
          children: [
            for (var i = 0; i < configs.length; i++)
              _bodyCell(
                theme,
                SubcontractorsEstimateTableCells.aggregateFooter(
                  theme,
                  widget.mode,
                  configs[i],
                  nameColumnLabel: 'Итого по разделу',
                  planSum: planSectionSum,
                  subQuantitySum: subQuantitySum,
                  subMoneySum: subMoneySum,
                  hasSubPrice: hasSubPrice,
                  completedQuantitySum: completedQuantitySum,
                  completedAmountSum: completedAmountSum,
                  remainingQuantitySum: remainingQuantitySum,
                  remainingAmountSum: remainingAmountSum,
                  completionPercent: completionPercent,
                  totalLabelStyle: sectionTotalsStyle,
                  showExecutionVolumeTotals: showExecutionVolumeTotals,
                ),
                align: configs[i].cellAlignment,
                backgroundColor: _subBlockFillOnGroupBand(
                  theme,
                  configs[i],
                  groupBand,
                ),
                border: _subBlockBorder(theme, configs[i].subBlockEdge),
              ),
          ],
        ),
      );
    }

    final contractPlanTotal = _math.sectionPlanTotalSum(tableItems);
    final contractSubTotal = _math.sectionSubcontractorMoneySum(tableItems);
    final contractHasSub = _math.sectionHasAnySubcontractorPrice(tableItems);
    final contractCompletedAmount = _math.sectionCompletedAmountSum(tableItems);
    final contractRemainingAmount = _math.sectionRemainingAmountSum(tableItems);
    final contractCompletionPercent = _math.sectionCompletionPercent(
      tableItems,
    );
    // Тот же кегль/начертание, что у «Итого по разделу», чтобы ширина колонок совпадала.
    final contractFooterStyle = groupTitleStyle.copyWith(
      fontWeight: FontWeight.w700,
      fontSize: 11,
    );
    final grandTotalBand = Color.alphaBlend(
      theme.colorScheme.primary.withValues(
        alpha: theme.brightness == Brightness.dark ? 0.2 : 0.1,
      ),
      groupRowBackground ?? theme.colorScheme.surfaceContainerHighest,
    );
    rows.add(
      TableRow(
        decoration: BoxDecoration(
          color: grandTotalBand,
          border: Border(
            top: BorderSide(
              color: theme.colorScheme.outline.withValues(alpha: 0.45),
              width: 2,
            ),
          ),
        ),
        children: [
          for (var i = 0; i < configs.length; i++)
            _bodyCell(
              theme,
              SubcontractorsEstimateTableCells.aggregateFooter(
                theme,
                widget.mode,
                configs[i],
                nameColumnLabel: 'Итого по договору',
                planSum: contractPlanTotal,
                subQuantitySum: 0,
                subMoneySum: contractSubTotal,
                hasSubPrice: contractHasSub,
                completedQuantitySum: 0,
                completedAmountSum: contractCompletedAmount,
                remainingQuantitySum: 0,
                remainingAmountSum: contractRemainingAmount,
                completionPercent: contractCompletionPercent,
                totalLabelStyle: contractFooterStyle,
                showExecutionVolumeTotals: showExecutionVolumeTotals,
              ),
              align: configs[i].cellAlignment,
              backgroundColor: _subBlockFillOnGroupBand(
                theme,
                configs[i],
                grandTotalBand,
              ),
              border: _subBlockBorder(theme, configs[i].subBlockEdge),
            ),
        ],
      ),
    );

    return rows;
  }

  List<SubcontractorColumnConfig> _buildColumnConfigs() {
    final math = _math;
    Widget selectionForRow(Estimate e) => _selectionCheckbox(
      value: _isEstimateSelected(e),
      semanticLabel: 'Выбрать позицию ${e.number}',
      onChanged: (value) => _setEstimateSelected(e, value ?? false),
    );
    if (widget.mode == SubcontractorsEstimateTableMode.execution) {
      return buildSubcontractorsExecutionTableColumns(
        math: math,
        selectionForRow: selectionForRow,
      );
    }
    return buildSubcontractorsRatesTableColumns(
      math: math,
      showSubcontractorPricing: widget.subcontractorPricingByEstimateId != null,
      showInEstimatesModuleColumn: widget.showInEstimatesModuleColumn,
      selectionForRow: selectionForRow,
      onVisibleInEstimatesModuleTap: widget.onVisibleInEstimatesModuleTap,
    );
  }

  Widget _headerCell(
    ThemeData theme,
    String title, {
    TextAlign align = TextAlign.left,
    Widget? headerChild,
    Color? backgroundColor,
    BoxBorder? border,
  }) {
    final headerStyle =
        theme.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 10,
          letterSpacing: 0,
        ) ??
        const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 10,
          letterSpacing: 0,
        );
    return Container(
      decoration: (backgroundColor != null || border != null)
          ? BoxDecoration(color: backgroundColor, border: border)
          : null,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      alignment: _alignmentFromTextAlign(align),
      child:
          headerChild ??
          Text(
            title,
            textAlign: align,
            softWrap: false,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: headerStyle,
          ),
    );
  }

  Widget _bodyCell(
    ThemeData theme,
    Widget child, {
    Alignment align = Alignment.centerLeft,
    VoidCallback? onTap,
    void Function(TapDownDetails)? onSecondaryTapDown,
    bool isSelected = false,
    Color? backgroundColor,
    BoxBorder? border,
  }) {
    return GestureDetector(
      onTap: onTap,
      onSecondaryTapDown: onSecondaryTapDown,
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: (backgroundColor != null || border != null)
            ? BoxDecoration(color: backgroundColor, border: border)
            : null,
        padding: const EdgeInsets.symmetric(
          horizontal: _kCellHorizontalPadding,
          vertical: _kCellVerticalPadding,
        ),
        constraints: const BoxConstraints(minHeight: 28),
        alignment: align,
        child: DefaultTextStyle.merge(
          style: (theme.textTheme.bodySmall ?? const TextStyle()).copyWith(
            fontSize: 12,
            letterSpacing: 0,
            fontWeight: isSelected ? FontWeight.bold : null,
            color: isSelected ? theme.colorScheme.onPrimaryContainer : null,
          ),
          child: child,
        ),
      ),
    );
  }

  void _showContextMenu(
    BuildContext context,
    Estimate estimate,
    Offset position,
  ) {
    setState(() => _contextMenuSelectedId = estimate.id);

    // Однократное чтение прав; не [watch] — меню не должно подписывать rebuild.
    final permissionService = ref.read(permissionServiceProvider);
    final canUpdate = permissionService.can('subcontractors', 'update');
    final canSubcontractorsDelete =
        permissionService.can('subcontractors', 'delete');
    final canEstimatesUpdate = permissionService.can('estimates', 'update');
    final canEstimatesDelete = permissionService.can('estimates', 'delete');

    /// На карточке договора ([onAddPosition] != null) удаление позиции — право смет.
    final showDelete = widget.onAddPosition != null
        ? canEstimatesDelete
        : canSubcontractorsDelete;

    final items = <dynamic>[];

    if (widget.onAddPosition != null && canEstimatesUpdate) {
      items.add(
        GTContextMenuItem(
          icon: CupertinoIcons.add_circled,
          label: 'Добавить позицию',
          onTap: () => widget.onAddPosition!(estimate),
        ),
      );
    }

    if (canUpdate) {
      items.addAll([
        GTContextMenuItem(
          icon: CupertinoIcons.pencil,
          label: 'Редактировать',
          onTap: () => widget.onEdit(estimate),
        ),
        GTContextMenuItem(
          icon: CupertinoIcons.doc_on_doc,
          label: 'Дублировать',
          onTap: () => widget.onDuplicate(estimate),
        ),
      ]);
    }
    if (showDelete &&
        widget.onDeleteSelected != null &&
        widget.selectedEstimateIds.isNotEmpty) {
      items.add(
        GTContextMenuItem(
          icon: CupertinoIcons.trash_fill,
          label: 'Удалить выбранное',
          isDestructive: true,
          onTap: () => widget.onDeleteSelected!(context),
        ),
      );
    }
    if (showDelete) {
      items.add(
        GTContextMenuItem(
          icon: CupertinoIcons.trash,
          label: 'Удалить',
          isDestructive: true,
          onTap: () => widget.onDelete(estimate.id),
        ),
      );
    }
    final canEstimatesRead = permissionService.can('estimates', 'read');

    if (widget.onEstimateAddendumHistory != null && canEstimatesRead) {
      items.add(
        GTContextMenuItem(
          icon: CupertinoIcons.time,
          label: 'История по ДС',
          onTap: () => widget.onEstimateAddendumHistory!(estimate),
        ),
      );
    }

    if (items.isEmpty) {
      setState(() => _contextMenuSelectedId = null);
      return;
    }

    GTContextMenu.show(
      context: context,
      tapPosition: position,
      onDismiss: () => setState(() => _contextMenuSelectedId = null),
      items: items,
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
    List<SubcontractorColumnConfig> configs,
    ThemeData theme,
    double availableWidth,
  ) {
    final widths = <int, TableColumnWidth>{};
    final fixedWidths = <int, double>{};
    double totalFixed = 0;

    final headerStyle =
        theme.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 10,
          letterSpacing: 0,
        ) ??
        const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 10,
          letterSpacing: 0,
        );
    final bodyStyle =
        theme.textTheme.bodySmall?.copyWith(fontSize: 12, letterSpacing: 0) ??
        const TextStyle(fontSize: 12, letterSpacing: 0);

    const paddingWidth = _kCellHorizontalPadding * 2;

    for (var i = 0; i < configs.length; i++) {
      final config = configs[i];

      if (config.isFlexible) {
        continue;
      }

      double columnWidth = config.minWidth ?? _kDefaultMinColumnWidth;

      final headerWidth = config.headerBuilder != null
          ? (config.minWidth ?? 40) + paddingWidth
          : _measureText(config.title, headerStyle) + paddingWidth;
      columnWidth = math.max(columnWidth, headerWidth);

      if (config.measureText != null) {
        for (final estimate in widget.items) {
          final text = config.measureText!(estimate);
          if (text == null || text.isEmpty) continue;
          final width = _measureText(text, bodyStyle) + paddingWidth;
          columnWidth = math.max(columnWidth, width);
        }
      }

      fixedWidths[i] = columnWidth;
      totalFixed += columnWidth;
    }

    final remainingWidth = math.max(
      availableWidth - totalFixed,
      configs.length * 40,
    );
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
