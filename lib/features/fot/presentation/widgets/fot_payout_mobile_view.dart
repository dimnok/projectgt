import 'package:flutter/material.dart';
import '../../../../core/utils/formatters.dart';
import '../../data/models/payroll_payout_model.dart';
import '../utils/payout_converters.dart';
import 'package:collection/collection.dart';

/// Мобильный вид для выплат ФОТ.
class FOTPayoutMobileView extends StatelessWidget {
  /// Список выплат.
  final List<PayrollPayoutModel> payouts;

  /// Список сотрудников.
  final List<dynamic> employees;

  /// Обработчик долгого нажатия.
  final void Function(PayrollPayoutModel payout, Offset position) onRowLongPress;

  /// Создает мобильный вид выплат.
  const FOTPayoutMobileView({
    super.key,
    required this.payouts,
    required this.employees,
    required this.onRowLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final totalAmount = payouts.fold<double>(0, (sum, p) => sum + p.amount);

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: payouts.length,
            padding: const EdgeInsets.only(top: 8, bottom: 80),
            itemBuilder: (context, index) {
              final p = payouts[index];
              final employeeName = _getEmployeeName(p);
              final dateStr = formatRuDate(p.payoutDate);
              final methodName = getPayoutMethodName(p.method);
              final typeName = getPayoutTypeName(p.type);

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
                      onRowLongPress(p, position);
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
                                formatCurrency(p.amount),
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFF1565C0),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.calendar_today_outlined, size: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                              const SizedBox(width: 4),
                              Text(
                                dateStr,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Icon(Icons.payment_outlined, size: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                              const SizedBox(width: 4),
                              Text(
                                methodName,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.label_outline, size: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                              const SizedBox(width: 4),
                              Text(
                                typeName,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                ),
                              ),
                            ],
                          ),
                          if (p.comment != null && p.comment!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              p.comment!,
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
                'ИТОГО ВЫПЛАЧЕНО:',
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
                  color: const Color(0xFF1565C0),
                ),
              ),
            ],
          ),
        ),
      ],
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

