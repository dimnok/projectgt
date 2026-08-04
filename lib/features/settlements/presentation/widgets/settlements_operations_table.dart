import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/features/roles/presentation/widgets/permission_guard.dart';
import 'package:projectgt/features/settlements/domain/entities/settlement_operation.dart';
import 'package:projectgt/features/settlements/presentation/utils/settlement_ui_labels.dart';

/// Чистая таблица счетов на оплату.
///
/// Колонки делят всю доступную ширину по фиксированным долям (flex).
/// Горизонтального скролла нет.
class SettlementsOperationsTable extends StatelessWidget {
  /// Операции (счета).
  final List<SettlementOperation> operations;

  /// Тап по строке.
  final void Function(SettlementOperation operation) onRowTap;

  /// Удаление.
  final void Function(SettlementOperation operation)? onDelete;

  /// Компактный режим (вкладка договора).
  final bool compact;

  /// Создаёт таблицу.
  const SettlementsOperationsTable({
    super.key,
    required this.operations,
    required this.onRowTap,
    this.onDelete,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final columns = _columns(compact: compact, hasActions: onDelete != null);

    final totalAmount =
        operations.fold<double>(0, (s, o) => s + o.totalToPay);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _HeaderRow(columns: columns, scheme: scheme, theme: theme),
        Expanded(
          child: operations.isEmpty
              ? Center(
                  child: Text(
                    'Нет данных',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: operations.length,
                  itemBuilder: (context, index) {
                    final op = operations[index];
                    return _DataRow(
                      operation: op,
                      columns: columns,
                      index: index,
                      theme: theme,
                      scheme: scheme,
                      onTap: () => onRowTap(op),
                      onDelete: onDelete,
                    );
                  },
                ),
        ),
        if (operations.isNotEmpty)
          _TotalRow(
            columns: columns,
            theme: theme,
            scheme: scheme,
            totalAmount: totalAmount,
          ),
      ],
    );
  }
}

enum _ColId {
  date,
  type,
  invoice,
  act,
  contract,
  contractor,
  object,
  amount,
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

List<_ColDef> _columns({required bool compact, required bool hasActions}) {
  return [
    const _ColDef(id: _ColId.date, title: 'Дата счёта', flex: 10),
    const _ColDef(id: _ColId.type, title: 'Тип', flex: 9),
    const _ColDef(id: _ColId.invoice, title: 'Счёт', flex: 11),
    const _ColDef(id: _ColId.act, title: 'Акт', flex: 10),
    if (!compact)
      const _ColDef(id: _ColId.contract, title: 'Договор', flex: 11),
    const _ColDef(id: _ColId.contractor, title: 'Контрагент', flex: 18),
    if (!compact) const _ColDef(id: _ColId.object, title: 'Объект', flex: 15),
    const _ColDef(
      id: _ColId.amount,
      title: 'Сумма',
      flex: 12,
      align: Alignment.centerRight,
    ),
    if (hasActions)
      const _ColDef(
        id: _ColId.actions,
        title: '',
        flex: 4,
        align: Alignment.center,
      ),
  ];
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
      height: 40,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
        border: Border(
          bottom: BorderSide(color: scheme.outline.withValues(alpha: 0.18)),
        ),
      ),
      child: Row(
        children: [
          for (final col in columns)
            Expanded(
              flex: col.flex,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Align(
                  alignment: col.align,
                  child: Text(
                    col.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: scheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DataRow extends StatelessWidget {
  final SettlementOperation operation;
  final List<_ColDef> columns;
  final int index;
  final ThemeData theme;
  final ColorScheme scheme;
  final VoidCallback onTap;
  final void Function(SettlementOperation operation)? onDelete;

  const _DataRow({
    required this.operation,
    required this.columns,
    required this.index,
    required this.theme,
    required this.scheme,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final striped = index.isEven;
    return Material(
      color: striped
          ? scheme.onSurface.withValues(alpha: 0.03)
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: scheme.outline.withValues(alpha: 0.1)),
            ),
          ),
          child: Row(
            children: [
              for (final col in columns)
                Expanded(
                  flex: col.flex,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Align(alignment: col.align, child: _cell(col.id)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cell(_ColId id) {
    final op = operation;
    final base = theme.textTheme.bodyMedium?.copyWith(
      fontSize: 13,
      height: 1.2,
      color: scheme.onSurface,
    );

    switch (id) {
      case _ColId.date:
        return _text(formatRuDate(op.invoiceDate), base);
      case _ColId.type:
        return _pill(
          settlementOperationTypeLabel(op.operationType),
          switch (op.operationType) {
            SettlementOperationType.act => scheme.primary,
            SettlementOperationType.advance => scheme.tertiary,
            SettlementOperationType.other => scheme.onSurface.withValues(
              alpha: 0.65,
            ),
          },
        );
      case _ColId.invoice:
        return _text(
          op.invoiceNumber,
          base?.copyWith(fontWeight: FontWeight.w700),
        );
      case _ColId.act:
        final has = op.actNumber != null && op.actNumber!.isNotEmpty;
        return _text(
          has ? op.actNumber! : '—',
          base?.copyWith(
            color: has ? null : scheme.onSurface.withValues(alpha: 0.35),
          ),
        );
      case _ColId.contract:
        return _text(op.contractNumber ?? '—', base);
      case _ColId.contractor:
        return _text(
          op.contractorName ?? '—',
          base?.copyWith(fontWeight: FontWeight.w600),
        );
      case _ColId.object:
        return _text(op.objectName ?? '—', base);
      case _ColId.amount:
        return _text(
          formatCurrency(op.totalToPay),
          base?.copyWith(
            fontWeight: FontWeight.w700,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
          align: TextAlign.right,
        );
      case _ColId.actions:
        return PermissionGuard(
          module: 'settlements',
          permission: 'delete',
          child: IconButton(
            tooltip: 'Удалить',
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            onPressed: onDelete == null ? null : () => onDelete!(op),
            icon: Icon(
              CupertinoIcons.delete,
              size: 16,
              color: scheme.onSurface.withValues(alpha: 0.45),
            ),
          ),
        );
    }
  }

  Widget _text(
    String value,
    TextStyle? style, {
    TextAlign align = TextAlign.left,
  }) {
    return Text(
      value,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: align,
      style: style,
    );
  }

  Widget _pill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  final List<_ColDef> columns;
  final ThemeData theme;
  final ColorScheme scheme;
  final double totalAmount;

  const _TotalRow({
    required this.columns,
    required this.theme,
    required this.scheme,
    required this.totalAmount,
  });

  @override
  Widget build(BuildContext context) {
    final style = theme.textTheme.bodyMedium?.copyWith(
      fontSize: 13,
      fontWeight: FontWeight.w800,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
        border: Border(
          top: BorderSide(color: scheme.outline.withValues(alpha: 0.2)),
        ),
      ),
      child: Row(
        children: [
          for (final col in columns)
            Expanded(
              flex: col.flex,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Align(
                  alignment: col.align,
                  child: switch (col.id) {
                    _ColId.date => Text('ИТОГО', style: style),
                    _ColId.amount => Text(
                      formatCurrency(totalAmount),
                      style: style,
                      textAlign: TextAlign.right,
                    ),
                    _ => const SizedBox.shrink(),
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}
