import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/gt_adaptive_table.dart';
import '../../domain/entities/payroll_transaction.dart';

/// Тип транзакции для конфигурации таблицы.
enum FOTTransactionTableType {
  /// Премия.
  bonus,

  /// Штраф.
  penalty,
}

/// Переиспользуемый виджет таблицы для транзакций ФОТ (премии и штрафы).
class FOTTransactionTable extends ConsumerWidget {
  /// Список транзакций.
  final List<PayrollTransaction> transactions;

  /// Список сотрудников для маппинга имен.
  final List<dynamic> employees;

  /// Список объектов для маппинга имен.
  final List<dynamic> objects;

  /// Тип таблицы (премии или штрафы).
  final FOTTransactionTableType type;

  /// Текущий подсвеченный элемент.
  final PayrollTransaction? highlightedItem;

  /// Обратный вызов при нажатии на строку (контекстное меню).
  final void Function(PayrollTransaction transaction, Offset position) onRowTap;

  /// Создаёт экземпляр [FOTTransactionTable].
  const FOTTransactionTable({
    super.key,
    required this.transactions,
    required this.employees,
    required this.objects,
    required this.type,
    required this.onRowTap,
    this.highlightedItem,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isBonus = type == FOTTransactionTableType.bonus;

    // Вычисляем итоговую сумму
    final totalAmount = transactions.fold<double>(
      0,
      (sum, t) => sum + t.amount,
    );

    final columns = [
      GTColumnConfig<PayrollTransaction>(
        title: 'Дата',
        headerAlign: TextAlign.center,
        cellAlignment: Alignment.center,
        measureText: (t) => formatRuDate(t.date ?? t.createdAt ?? DateTime.now()),
        builder: (t, _, __) =>
            Text(formatRuDate(t.date ?? t.createdAt ?? DateTime.now())),
      ),
      GTColumnConfig<PayrollTransaction>(
        title: 'Сотрудник',
        flex: 2,
        isFlexible: true,
        measureText: (t) => _getEmployeeName(t.employeeId),
        measureTotal: () => 'ИТОГО:',
        totalBuilder: (theme) => Text(
          'ИТОГО:',
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        builder: (t, _, theme) {
          final employeeName = _getEmployeeName(t.employeeId);
          return Text(
            employeeName,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          );
        },
      ),
      GTColumnConfig<PayrollTransaction>(
        title: 'Сумма',
        headerAlign: TextAlign.right,
        cellAlignment: Alignment.centerRight,
        measureText: (t) => formatCurrency(t.amount),
        measureTotal: () => formatCurrency(totalAmount),
        totalBuilder: (theme) => Text(
          formatCurrency(totalAmount),
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: isBonus ? theme.colorScheme.primary : theme.colorScheme.error,
          ),
        ),
        builder: (t, _, theme) => Text(
          formatCurrency(t.amount),
          style: TextStyle(
            color: isBonus ? theme.colorScheme.primary : theme.colorScheme.error,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      GTColumnConfig<PayrollTransaction>(
        title: 'Объект',
        flex: 1.5,
        isFlexible: true,
        measureText: (t) => _getObjectName(t.objectId),
        builder: (t, _, __) => Text(_getObjectName(t.objectId)),
      ),
      GTColumnConfig<PayrollTransaction>(
        title: 'Примечание',
        flex: 2,
        isFlexible: true,
        measureText: (t) => t.reason ?? '',
        builder: (t, _, __) => Text(
          t.reason ?? '—',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ];

    return GTAdaptiveTable<PayrollTransaction>(
      items: transactions,
      columns: columns,
      showTotalRow: true,
      minRowHeight: 30,
      highlightedItem: highlightedItem,
      onRowTapDown: (t, details) => onRowTap(t, details.globalPosition),
      onRowSecondaryTapDown: (t, details) => onRowTap(t, details.globalPosition),
    );
  }

  String _getEmployeeName(String? id) {
    final employee = employees.firstWhereOrNull((e) => e.id == id);
    if (employee == null) return id ?? 'Неизвестный';
    return [
      employee.lastName,
      employee.firstName,
      if (employee.middleName != null && employee.middleName!.isNotEmpty)
        employee.middleName,
    ].join(' ').trim();
  }

  String _getObjectName(String? id) {
    final object = objects.firstWhereOrNull((o) => o.id == id);
    return object?.name ?? id ?? '—';
  }
}

