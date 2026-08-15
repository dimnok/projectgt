import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/features/tmc/domain/entities/tmc_enums.dart';
import 'package:projectgt/features/tmc/domain/entities/tmc_operation.dart';
import 'package:projectgt/features/tmc/presentation/state/tmc_providers.dart';
import 'package:projectgt/features/tmc/presentation/utils/tmc_ui_labels.dart';

const _kFilterTypes = <TmcOperationType>[
  TmcOperationType.receipt,
  TmcOperationType.issue,
  TmcOperationType.returnFromEmployee,
  TmcOperationType.transferToObject,
  TmcOperationType.moveBetweenWarehouses,
  TmcOperationType.sendToRepair,
  TmcOperationType.returnFromRepair,
  TmcOperationType.writeOff,
  TmcOperationType.changeCondition,
  TmcOperationType.correction,
];

const _kRowHeight = 40.0;
const _kHeaderHeight = 32.0;
const _kDateWidth = 132.0;
const _kTypeWidth = 128.0;
const _kQtyWidth = 72.0;

/// Журнал операций ТМЦ внутри модуля.
class TmcOperationsPanel extends ConsumerWidget {
  /// Создаёт панель журнала.
  const TmcOperationsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(tmcOperationsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _OperationsTypeFilter(
          selected: state.operationType,
          onSelected: (type) =>
              ref.read(tmcOperationsProvider.notifier).setOperationType(type),
        ),
        const SizedBox(height: 8),
        Expanded(child: _buildBody(context, state)),
      ],
    );
  }

  Widget _buildBody(BuildContext context, TmcOperationsListState state) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    if (state.isLoading && state.operations.isEmpty) {
      return const Center(child: CupertinoActivityIndicator());
    }
    if (state.error != null && state.operations.isEmpty) {
      return Center(child: Text(state.error!));
    }
    if (state.operations.isEmpty) {
      return Center(
        child: Text(
          TmcUiLabels.emptyOperations,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurface.withValues(alpha: 0.55),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: scheme.outline.withValues(alpha: isDark ? 0.22 : 0.14),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          const _OperationsHeader(),
          Expanded(
            child: ListView.builder(
              itemCount: state.operations.length,
              itemBuilder: (context, index) {
                return _OperationRow(
                  operation: state.operations[index],
                  index: index,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Компактный сегментный фильтр типа операции.
class _OperationsTypeFilter extends StatelessWidget {
  final TmcOperationType? selected;
  final ValueChanged<TmcOperationType?> onSelected;

  const _OperationsTypeFilter({
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      children: [
        Icon(
          CupertinoIcons.line_horizontal_3_decrease,
          size: 13,
          color: scheme.onSurface.withValues(alpha: 0.45),
        ),
        const SizedBox(width: 6),
        Text(
          TmcUiLabels.operationsColType,
          style: theme.textTheme.labelSmall?.copyWith(
            color: scheme.onSurface.withValues(alpha: 0.45),
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 30,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(
                alpha: isDark ? 0.28 : 0.22,
              ),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: scheme.outline.withValues(alpha: isDark ? 0.22 : 0.14),
              ),
            ),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(3, 3, 8, 3),
              children: [
                _TypeSegment(
                  label: TmcUiLabels.operationsFilterAll,
                  tooltip: TmcUiLabels.operationsFilterAll,
                  selected: selected == null,
                  onTap: () => onSelected(null),
                  scheme: scheme,
                  theme: theme,
                ),
                ..._kFilterTypes.map(
                  (type) => _TypeSegment(
                    label: TmcUiLabels.operationTypeShort(type),
                    tooltip: TmcUiLabels.operationType(type),
                    selected: selected == type,
                    onTap: () => onSelected(type),
                    scheme: scheme,
                    theme: theme,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Сегмент фильтра внутри общей полоски.
class _TypeSegment extends StatelessWidget {
  final String label;
  final String tooltip;
  final bool selected;
  final VoidCallback onTap;
  final ColorScheme scheme;
  final ThemeData theme;

  const _TypeSegment({
    required this.label,
    required this.tooltip,
    required this.selected,
    required this.onTap,
    required this.scheme,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: tooltip,
      child: Tooltip(
        message: tooltip,
        waitDuration: const Duration(milliseconds: 400),
        child: Padding(
          padding: const EdgeInsets.only(right: 2),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(6),
              hoverColor: scheme.onSurface.withValues(alpha: 0.06),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                padding: const EdgeInsets.symmetric(horizontal: 9),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? scheme.onSurface : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: selected
                        ? scheme.surface
                        : scheme.onSurface.withValues(alpha: 0.62),
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Шапка колонок журнала операций.
class _OperationsHeader extends StatelessWidget {
  const _OperationsHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final style = theme.textTheme.labelSmall?.copyWith(
      color: scheme.onSurface.withValues(alpha: 0.6),
      fontWeight: FontWeight.w600,
      letterSpacing: 0.2,
    );

    return Container(
      height: _kHeaderHeight,
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
        children: [
          _headerCell(TmcUiLabels.operationsColDate, _kDateWidth, style),
          _headerCell(TmcUiLabels.operationsColType, _kTypeWidth, style),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(TmcUiLabels.operationsColItems, style: style),
            ),
          ),
          SizedBox(
            width: _kQtyWidth,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                TmcUiLabels.operationsColQty,
                style: style,
                textAlign: TextAlign.right,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerCell(String title, double width, TextStyle? style) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Text(title, style: style),
      ),
    );
  }
}

/// Компактная строка журнала операций.
class _OperationRow extends StatelessWidget {
  final TmcOperation operation;
  final int index;

  const _OperationRow({required this.operation, required this.index});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final itemNames = operation.items
        .map((l) => l.itemName ?? l.inventoryNumber ?? l.itemId)
        .join(', ');
    final qty = operation.items.fold<double>(0, (s, l) => s + l.quantity);
    final doc = operation.documentNumber?.trim();
    final itemsLabel = (doc != null && doc.isNotEmpty)
        ? '$itemNames · № $doc'
        : itemNames;

    final muted = theme.textTheme.bodySmall?.copyWith(
      color: scheme.onSurface.withValues(alpha: 0.55),
    );
    final primary = theme.textTheme.bodySmall?.copyWith(
      fontWeight: FontWeight.w600,
    );

    return Semantics(
      label:
          '${TmcUiLabels.operationType(operation.operationType)}, '
          '${formatRuDateTime(operation.operatedAt)}, $itemsLabel',
      child: Container(
        height: _kRowHeight,
        decoration: BoxDecoration(
          color: index.isEven
              ? Colors.transparent
              : scheme.surfaceContainerHighest.withValues(
                  alpha: isDark ? 0.18 : 0.12,
                ),
          border: Border(
            bottom: BorderSide(
              color: scheme.outline.withValues(alpha: isDark ? 0.12 : 0.08),
            ),
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: _kDateWidth,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  formatRuDateTime(operation.operatedAt),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: muted,
                ),
              ),
            ),
            SizedBox(
              width: _kTypeWidth,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Tooltip(
                  message: TmcUiLabels.operationType(operation.operationType),
                  waitDuration: const Duration(milliseconds: 400),
                  child: Text(
                    TmcUiLabels.operationTypeShort(operation.operationType),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: primary,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  itemsLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ),
            SizedBox(
              width: _kQtyWidth,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  formatQuantity(qty),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: muted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
