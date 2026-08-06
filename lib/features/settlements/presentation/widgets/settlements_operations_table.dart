import 'package:flutter/material.dart';
import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/features/settlements/domain/entities/settlement_operation.dart';
import 'package:projectgt/features/settlements/presentation/utils/settlement_ui_labels.dart';

/// Чистая таблица счетов на оплату.
///
/// Колонки делят всю доступную ширину по фиксированным долям (flex).
/// Горизонтального скролла нет. Стиль — как таблица операций Cash Flow.
class SettlementsOperationsTable extends StatefulWidget {
  /// Операции (счета).
  final List<SettlementOperation> operations;

  /// Тап по строке.
  final void Function(SettlementOperation operation) onRowTap;

  /// Компактный режим (вкладка договора).
  final bool compact;

  /// Создаёт таблицу.
  const SettlementsOperationsTable({
    super.key,
    required this.operations,
    required this.onRowTap,
    this.compact = false,
  });

  @override
  State<SettlementsOperationsTable> createState() =>
      _SettlementsOperationsTableState();
}

class _SettlementsOperationsTableState extends State<SettlementsOperationsTable> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final columns = _columns(compact: widget.compact);
    final operations = widget.operations;

    final totalAmount = operations.totalAmount;
    final totalPaid = operations.totalPaid;
    final totalRemaining = operations.totalDebt;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: scheme.outline.withValues(alpha: 0.1),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _HeaderRow(columns: columns, scheme: scheme, theme: theme),
          const Divider(height: 1, thickness: 1),
          Expanded(
            child: operations.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        'Нет данных',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.hintColor,
                        ),
                      ),
                    ),
                  )
                : Scrollbar(
                    controller: _scrollController,
                    child: ListView.separated(
                      controller: _scrollController,
                      itemCount: operations.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final op = operations[index];
                        return _DataRow(
                          operation: op,
                          columns: columns,
                          theme: theme,
                          scheme: scheme,
                          onTap: () => widget.onRowTap(op),
                        );
                      },
                    ),
                  ),
          ),
          if (operations.isNotEmpty) ...[
            const Divider(height: 1, thickness: 1),
            _TotalRow(
              columns: columns,
              theme: theme,
              scheme: scheme,
              totalAmount: totalAmount,
              totalPaid: totalPaid,
              totalRemaining: totalRemaining,
              compact: widget.compact,
            ),
          ],
        ],
      ),
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
  status,
  paid,
  remaining,
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

List<_ColDef> _columns({required bool compact}) {
  return [
    const _ColDef(id: _ColId.date, title: 'Дата счёта', flex: 9),
    const _ColDef(id: _ColId.type, title: 'Тип', flex: 8),
    const _ColDef(id: _ColId.invoice, title: 'Счёт', flex: 9),
    const _ColDef(id: _ColId.act, title: 'Акт', flex: 8),
    if (!compact)
      const _ColDef(id: _ColId.contract, title: 'Договор', flex: 9),
    _ColDef(
      id: _ColId.contractor,
      title: 'Контрагент',
      flex: compact ? 16 : 14,
    ),
    if (!compact) const _ColDef(id: _ColId.object, title: 'Объект', flex: 11),
    const _ColDef(
      id: _ColId.amount,
      title: 'К оплате',
      flex: 12,
      align: Alignment.centerRight,
    ),
    const _ColDef(id: _ColId.status, title: 'Статус', flex: 11),
    if (!compact)
      const _ColDef(
        id: _ColId.paid,
        title: 'Оплачено',
        flex: 9,
        align: Alignment.centerRight,
      ),
    const _ColDef(
      id: _ColId.remaining,
      title: 'Остаток',
      flex: 9,
      align: Alignment.centerRight,
    ),
  ];
}

/// Ячейка колонки с отступом и ограничением ширины (текст не наезжает на соседей).
class _ColumnCell extends StatelessWidget {
  final _ColDef column;
  final bool isLast;
  final Widget child;

  const _ColumnCell({
    required this.column,
    required this.isLast,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: column.flex,
      child: Padding(
        padding: EdgeInsets.only(right: isLast ? 0 : 8),
        child: column.align == Alignment.centerRight
            ? SizedBox(
                width: double.infinity,
                child: child,
              )
            : Align(
                alignment: column.align,
                widthFactor: 1,
                child: child,
              ),
      ),
    );
  }
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: scheme.onSurface.withValues(alpha: 0.03),
      child: Row(
        children: [
          for (var i = 0; i < columns.length; i++)
            _ColumnCell(
              column: columns[i],
              isLast: i == columns.length - 1,
              child: Text(
                columns[i].title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: columns[i].align == Alignment.centerRight
                    ? TextAlign.right
                    : TextAlign.left,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  color: scheme.onSurface.withValues(alpha: 0.7),
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
  final ThemeData theme;
  final ColorScheme scheme;
  final VoidCallback onTap;

  const _DataRow({
    required this.operation,
    required this.columns,
    required this.theme,
    required this.scheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(
          children: [
            for (var i = 0; i < columns.length; i++)
              _ColumnCell(
                column: columns[i],
                isLast: i == columns.length - 1,
                child: _cell(columns[i].id),
              ),
          ],
        ),
      ),
    );
  }

  Widget _cell(_ColId id) {
    final op = operation;
    final base = theme.textTheme.bodySmall?.copyWith(
      fontSize: 12,
      height: 1.25,
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
          base?.copyWith(fontWeight: FontWeight.w600),
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
            fontWeight: FontWeight.bold,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
          align: TextAlign.right,
        );
      case _ColId.status:
        final status = op.resolvedPaymentStatus;
        final color = settlementPaymentStatusColor(theme, status);
        return _pill(settlementPaymentStatusLabel(status), color);
      case _ColId.paid:
        return _text(
          op.paidAmount > 0 ? formatCurrency(op.paidAmount) : '—',
          base?.copyWith(
            fontFeatures: const [FontFeature.tabularFigures()],
            color: op.paidAmount > 0
                ? null
                : scheme.onSurface.withValues(alpha: 0.35),
          ),
          align: TextAlign.right,
        );
      case _ColId.remaining:
        final remaining = op.remainingAmount;
        final hasRemaining = op.hasOutstandingDebt;
        final hasOverpay = op.hasOverpayment;
        return _text(
          hasRemaining || hasOverpay ? formatCurrency(remaining) : '—',
          base?.copyWith(
            fontWeight: hasRemaining || hasOverpay ? FontWeight.bold : null,
            fontFeatures: const [FontFeature.tabularFigures()],
            color: hasRemaining
                ? scheme.error
                : hasOverpay
                    ? settlementPaymentStatusColor(
                        theme,
                        SettlementPaymentStatus.overpaid,
                      )
                    : scheme.onSurface.withValues(alpha: 0.35),
          ),
          align: TextAlign.right,
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
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 10,
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
  final double totalPaid;
  final double totalRemaining;
  final bool compact;

  const _TotalRow({
    required this.columns,
    required this.theme,
    required this.scheme,
    required this.totalAmount,
    required this.totalPaid,
    required this.totalRemaining,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final style = theme.textTheme.bodySmall?.copyWith(
      fontSize: 12,
      fontWeight: FontWeight.bold,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: scheme.onSurface.withValues(alpha: 0.03),
      child: Row(
        children: [
          for (var i = 0; i < columns.length; i++)
            _ColumnCell(
              column: columns[i],
              isLast: i == columns.length - 1,
              child: switch (columns[i].id) {
                _ColId.date => Text('ИТОГО', style: style),
                _ColId.amount => Text(
                  formatCurrency(totalAmount),
                  style: style,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                _ColId.paid when !compact => Text(
                  formatCurrency(totalPaid),
                  style: style,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                _ColId.remaining => Text(
                  formatCurrency(totalRemaining),
                  style: style?.copyWith(
                    color: totalRemaining > SettlementOperation.amountEpsilon
                        ? scheme.error
                        : null,
                  ),
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                _ => const SizedBox.shrink(),
              },
            ),
        ],
      ),
    );
  }
}
