import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/gt_adaptive_table.dart';
import '../../data/models/payroll_payout_model.dart';
import '../utils/payout_converters.dart';

/// Переиспользуемый виджет таблицы для выплат ФОТ.
class FOTPayoutTable extends ConsumerWidget {
  /// Список выплат.
  final List<PayrollPayoutModel> payouts;

  /// Список сотрудников для маппинга имен.
  final List<dynamic> employees;

  /// Текущий подсвеченный элемент.
  final PayrollPayoutModel? highlightedItem;

  /// Обратный вызов при нажатии на строку (контекстное меню).
  final void Function(PayrollPayoutModel payout, Offset position) onRowTap;

  /// Создаёт экземпляр [FOTPayoutTable].
  const FOTPayoutTable({
    super.key,
    required this.payouts,
    required this.employees,
    required this.onRowTap,
    this.highlightedItem,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Вычисляем итоговую сумму выплат
    final totalAmount = payouts.fold<double>(
      0.0,
      (sum, p) => sum + p.amount,
    );

    final columns = [
      GTColumnConfig<PayrollPayoutModel>(
        title: 'Дата',
        headerAlign: TextAlign.center,
        cellAlignment: Alignment.center,
        measureText: (payout) => formatRuDate(payout.payoutDate),
        builder: (payout, _, __) => Text(formatRuDate(payout.payoutDate)),
      ),
      GTColumnConfig<PayrollPayoutModel>(
        title: 'Сотрудник',
        flex: 2,
        isFlexible: true,
        measureText: (payout) => _getEmployeeName(payout),
        measureTotal: () => 'ИТОГО:',
        totalBuilder: (theme) => Text(
          'ИТОГО:',
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        builder: (payout, _, theme) => Text(
          _getEmployeeName(payout),
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
      GTColumnConfig<PayrollPayoutModel>(
        title: 'Сумма',
        headerAlign: TextAlign.right,
        cellAlignment: Alignment.centerRight,
        measureText: (payout) => formatCurrency(payout.amount),
        measureTotal: () => formatCurrency(totalAmount),
        totalBuilder: (theme) => Text(
          formatCurrency(totalAmount),
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        builder: (payout, _, __) => Text(
          formatCurrency(payout.amount),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      GTColumnConfig<PayrollPayoutModel>(
        title: 'Способ',
        headerAlign: TextAlign.center,
        cellAlignment: Alignment.center,
        measureText: (payout) => getPayoutMethodName(payout.method),
        builder: (payout, _, __) => Text(getPayoutMethodName(payout.method)),
      ),
      GTColumnConfig<PayrollPayoutModel>(
        title: 'Тип',
        headerAlign: TextAlign.center,
        cellAlignment: Alignment.center,
        measureText: (payout) => getPayoutTypeName(payout.type),
        builder: (payout, _, __) => Text(getPayoutTypeName(payout.type)),
      ),
      GTColumnConfig<PayrollPayoutModel>(
        title: 'Комментарий',
        flex: 2,
        isFlexible: true,
        measureText: (payout) => payout.comment ?? '',
        builder: (payout, _, __) => Text(
          payout.comment ?? '—',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ];

    return GTAdaptiveTable<PayrollPayoutModel>(
      items: payouts,
      columns: columns,
      showTotalRow: true,
      minRowHeight: 30,
      highlightedItem: highlightedItem,
      onRowTapDown: (payout, details) => onRowTap(payout, details.globalPosition),
      onRowSecondaryTapDown: (payout, details) => onRowTap(payout, details.globalPosition),
    );
  }

  String _getEmployeeName(PayrollPayoutModel payout) {
    final employee = employees.firstWhereOrNull((e) => e.id == payout.employeeId);
    if (employee == null) return payout.employeeId;
    return [
      employee.lastName,
      employee.firstName,
      if (employee.middleName != null && employee.middleName!.isNotEmpty)
        employee.middleName,
    ].join(' ').trim();
  }
}

