import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/payroll_calculation.dart';
import '../utils/balance_utils.dart';
import 'payroll_card.dart';

/// Суммарные показатели для мобильного вида.
class PayrollMobileTotals {
  /// Итоговая начисленная сумма (за вычетом налогов/штрафов)
  final double netSalary;

  /// Сумма фактически произведенных выплат
  final double payout;

  /// Текущий баланс (задолженность/переплата)
  final double balance;

  /// Создает объект суммарных показателей
  const PayrollMobileTotals({
    required this.netSalary,
    required this.payout,
    required this.balance,
  });
}

/// Мобильный вид списка ФОТ.
class PayrollMobileView extends ConsumerWidget {
  /// Список сгруппированных расчетов.
  final List<PayrollCalculation> payrolls;

  /// Маппинг информации о сотрудниках (имя, статус).
  final Map<String, PayrollCardInfo> employeeInfoMap;

  /// Суммарные показатели.
  final PayrollMobileTotals totals;

  /// Обработчик долгого нажатия на карточку.
  final void Function(PayrollCalculation payroll, Offset position)
  onRowLongPress;

  /// Создает мобильный вид ФОТ.
  const PayrollMobileView({
    super.key,
    required this.payrolls,
    required this.employeeInfoMap,
    required this.totals,
    required this.onRowLongPress,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: payrolls.length,
            padding: const EdgeInsets.only(
              top: 8,
              bottom: 100,
            ), // Отступ под Bottom Summary Bar
            itemBuilder: (context, index) {
              final payroll = payrolls[index];
              final info =
                  employeeInfoMap[payroll.employeeId] ??
                  PayrollCardInfo(
                    name: 'Сотрудник ${payroll.employeeId}',
                    payout: 0,
                    balance: 0,
                  );

              return GestureDetector(
                onLongPressStart: (details) =>
                    onRowLongPress(payroll, details.globalPosition),
                child: PayrollCard(
                  payroll: payroll,
                  info: info,
                  theme: theme,
                  onLongPress: () {
                    // Используем GestureDetector для получения позиции,
                    // но здесь можно оставить пустое для срабатывания InkWell
                  },
                ),
              );
            },
          ),
        ),
        // Bottom Summary Bar
        Container(
          padding: EdgeInsets.fromLTRB(
            16,
            10,
            16,
            MediaQuery.of(context).padding.bottom + 10,
          ),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
            border: Border(
              top: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.05),
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryItem(
                context,
                'К выплате',
                formatCurrency(totals.netSalary),
                theme.colorScheme.primary,
              ),
              _buildSummaryItem(
                context,
                'Выплачено',
                formatCurrency(totals.payout),
                const Color(0xFF1565C0),
              ),
              _buildSummaryItem(
                context,
                'Баланс',
                BalanceUtils.formatBalance(totals.balance),
                BalanceUtils.getBalanceColor(totals.balance, theme),
                icon: BalanceUtils.getBalanceIcon(totals.balance),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryItem(
    BuildContext context,
    String label,
    String value,
    Color color, {
    IconData? icon,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            fontSize: 8,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 10, color: color),
              const SizedBox(width: 2),
            ],
            Text(
              value,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: color,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
