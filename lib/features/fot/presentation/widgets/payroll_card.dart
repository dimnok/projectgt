import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/employee_ui_utils.dart';
import '../../domain/entities/payroll_calculation.dart';
import '../../../../domain/entities/employee.dart';
import '../utils/balance_utils.dart';

/// Информация о сотруднике для отображения в карточке ФОТ.
class PayrollCardInfo {
  /// Полное имя сотрудника
  final String name;

  /// Текущий статус сотрудника (активен, уволен и т.д.)
  final EmployeeStatus? status;

  /// Сумма, фактически выплаченная сотруднику
  final double payout;

  /// Текущий баланс (задолженность или переплата)
  final double balance;

  /// Создает объект информации для карточки ФОТ
  const PayrollCardInfo({
    required this.name,
    this.status,
    required this.payout,
    required this.balance,
  });
}

/// Карточка сотрудника для мобильного вида ФОТ.
class PayrollCard extends StatefulWidget {
  /// Расчет ФОТ.
  final PayrollCalculation payroll;

  /// Информация о сотруднике.
  final PayrollCardInfo info;

  /// Тема оформления.
  final ThemeData theme;

  /// Обработчик долгого нажатия (для контекстного меню).
  final VoidCallback? onLongPress;

  /// Создает экземпляр [PayrollCard].
  const PayrollCard({
    super.key,
    required this.payroll,
    required this.info,
    required this.theme,
    this.onLongPress,
  });

  @override
  State<PayrollCard> createState() => _PayrollCardState();
}

class _PayrollCardState extends State<PayrollCard>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final isDark = widget.theme.brightness == Brightness.dark;
    final statusInfo = widget.info.status != null
        ? EmployeeUIUtils.getStatusInfo(widget.info.status!)
        : null;

    final remainder = widget.payroll.netSalary - widget.info.payout;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.05),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            // Заголовок (всегда видим)
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => setState(() => _isExpanded = !_isExpanded),
                onLongPress: widget.onLongPress,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Лево: ФИО и статус
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.info.name,
                              style: widget.theme.textTheme.titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (statusInfo != null) ...[
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: statusInfo.$2,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    statusInfo.$1.toLowerCase(),
                                    style: widget.theme.textTheme.bodySmall
                                        ?.copyWith(
                                          color: statusInfo.$2.withValues(
                                            alpha: 0.8,
                                          ),
                                          fontWeight: FontWeight.w500,
                                        ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Право: К выплате / Баланс
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            formatCurrency(widget.payroll.netSalary),
                            style: widget.theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                              color: widget.theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          BalanceUtils.buildBalanceWidget(
                            widget.info.balance,
                            widget.theme,
                            showIcon: true,
                            textStyle: widget.theme.textTheme.bodySmall
                                ?.copyWith(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        _isExpanded
                            ? CupertinoIcons.chevron_up
                            : CupertinoIcons.chevron_down,
                        size: 16,
                        color: widget.theme.colorScheme.onSurface.withValues(
                          alpha: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Скрытая часть
            AnimatedCrossFade(
              firstChild: const SizedBox(width: double.infinity),
              secondChild: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  children: [
                    const Divider(height: 24),
                    _buildDetailRow(
                      'Отработано',
                      '${formatQuantity(widget.payroll.hoursWorked)} ч',
                    ),
                    _buildDetailRow(
                      'Ставка',
                      formatCurrency(widget.payroll.hourlyRate),
                    ),
                    _buildDetailRow(
                      'Базовая часть',
                      formatCurrency(widget.payroll.baseSalary),
                    ),
                    if (widget.payroll.bonusesTotal > 0)
                      _buildDetailRow(
                        'Премии',
                        formatCurrency(widget.payroll.bonusesTotal),
                        color: const Color(0xFF2E7D32),
                      ),
                    if (widget.payroll.penaltiesTotal > 0)
                      _buildDetailRow(
                        'Штрафы',
                        formatCurrency(widget.payroll.penaltiesTotal),
                        color: const Color(0xFFC62828),
                      ),
                    if (widget.payroll.businessTripTotal > 0)
                      _buildDetailRow(
                        'Суточные',
                        formatCurrency(widget.payroll.businessTripTotal),
                      ),
                    const SizedBox(height: 8),
                    _buildDetailRow(
                      'Выплачено',
                      formatCurrency(widget.info.payout),
                      color: const Color(0xFF1565C0),
                      isBold: true,
                    ),
                    _buildDetailRow(
                      'Остаток за месяц',
                      formatCurrency(remainder),
                      color: remainder > 0
                          ? Colors.green[700]
                          : (remainder < 0 ? Colors.red[700] : null),
                      isBold: true,
                    ),
                  ],
                ),
              ),
              crossFadeState: _isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 200),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    Color? color,
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: widget.theme.textTheme.bodySmall?.copyWith(
              color: widget.theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          Text(
            value,
            style: widget.theme.textTheme.bodySmall?.copyWith(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
