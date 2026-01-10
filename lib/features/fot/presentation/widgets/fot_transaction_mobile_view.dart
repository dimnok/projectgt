import 'package:flutter/material.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/payroll_transaction.dart';
import 'fot_transaction_table_widget.dart';
import 'package:collection/collection.dart';

/// Мобильный вид для транзакций ФОТ (премии и штрафы).
class FOTTransactionMobileView extends StatelessWidget {
  /// Список транзакций.
  final List<PayrollTransaction> transactions;

  /// Список сотрудников.
  final List<dynamic> employees;

  /// Список объектов.
  final List<dynamic> objects;

  /// Тип транзакции.
  final FOTTransactionTableType type;

  /// Обработчик долгого нажатия.
  final void Function(PayrollTransaction transaction, Offset position) onRowLongPress;

  /// Создает мобильный вид транзакций.
  const FOTTransactionMobileView({
    super.key,
    required this.transactions,
    required this.employees,
    required this.objects,
    required this.type,
    required this.onRowLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isBonus = type == FOTTransactionTableType.bonus;

    final totalAmount = transactions.fold<double>(0, (sum, t) => sum + t.amount);

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: transactions.length,
            padding: const EdgeInsets.only(top: 8, bottom: 80),
            itemBuilder: (context, index) {
              final t = transactions[index];
              final employeeName = _getEmployeeName(t.employeeId);
              final objectName = _getObjectName(t.objectId);
              final dateStr = formatRuDate(t.date ?? t.createdAt ?? DateTime.now());

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.05),
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onLongPress: () {
                      final RenderBox box = context.findRenderObject() as RenderBox;
                      final Offset position = box.localToGlobal(Offset.zero);
                      onRowLongPress(t, position);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  employeeName,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                formatCurrency(t.amount),
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: isBonus ? theme.colorScheme.primary : theme.colorScheme.error,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today_outlined, 
                                size: 12, 
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.5)
                              ),
                              const SizedBox(width: 4),
                              Text(
                                dateStr,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Icon(
                                Icons.location_on_outlined, 
                                size: 12, 
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.5)
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  objectName,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          if (t.reason != null && t.reason!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              t.reason!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontStyle: FontStyle.italic,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        // Bottom Total
        Container(
          padding: EdgeInsets.fromLTRB(
            16, 10, 16, MediaQuery.of(context).padding.bottom + 10,
          ),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
            border: Border(
              top: BorderSide(
                color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ИТОГО ${isBonus ? "ПРЕМИЙ" : "ШТРАФОВ"}:',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
              Text(
                formatCurrency(totalAmount),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  color: isBonus ? theme.colorScheme.primary : theme.colorScheme.error,
                ),
              ),
            ],
          ),
        ),
      ],
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

