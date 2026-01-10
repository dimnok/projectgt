import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';
import 'package:projectgt/core/widgets/gt_adaptive_table.dart';
import 'package:projectgt/core/widgets/gt_context_menu.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/snackbar_utils.dart';
import 'package:projectgt/core/utils/responsive_utils.dart';
import 'package:projectgt/core/utils/employee_ui_utils.dart';
import '../../domain/entities/payroll_calculation.dart';
import '../../domain/entities/payroll_transaction.dart';
import '../../../../domain/entities/employee.dart';
import '../utils/balance_utils.dart';
import '../services/payroll_pdf_service.dart';
import '../providers/payroll_filter_providers.dart';
import '../../../../core/di/providers.dart';
import 'package:projectgt/features/company/presentation/providers/company_providers.dart';
import 'payroll_transaction_form_modal.dart';
import 'payroll_payout_form_modal.dart';
import 'payroll_card.dart';
import 'payroll_mobile_view.dart';
import '../../data/models/payroll_payout_model.dart';

/// Константы для таблицы ФОТ (Фонд оплаты труда).
class PayrollTableConstants {
  /// Цвет для выделения премий.
  static const Color bonusColor = Color(0xFF2E7D32);

  /// Цвет для выделения штрафов.
  static const Color penaltyColor = Color(0xFFC62828);

  /// Цвет для выделения выплат.
  static const Color payoutColor = Color(0xFF1565C0);
}

/// Информация о сотруднике для отображения в строке таблицы ФОТ.
class _EmployeeRowInfo {
  final String name;
  final EmployeeStatus? status;
  final int index;

  const _EmployeeRowInfo({
    required this.name,
    this.status,
    required this.index,
  });
}

/// Адаптивная таблица ФОТ, построенная по аналогии с таблицей смет.
///
/// Использует [GTAdaptiveTable] для отображения данных.
class PayrollTableView extends ConsumerStatefulWidget {
  /// Список расчётов ФОТ.
  final List<PayrollCalculation> payrolls;

  /// Список сотрудников.
  final List<dynamic> employees;

  /// Выплаты по сотрудникам.
  final Map<String, double> payoutsByEmployee;

  /// Агрегированный баланс по сотрудникам.
  final Map<String, double> aggregatedBalance;

  /// Флаг мобильного устройства.
  final bool isMobile;

  /// Флаг планшета.
  final bool isTablet;

  /// Флаг десктопа.
  final bool isDesktop;

  /// Создаёт экземпляр [PayrollTableView].
  const PayrollTableView({
    super.key,
    required this.payrolls,
    required this.employees,
    required this.payoutsByEmployee,
    required this.aggregatedBalance,
    required this.isMobile,
    required this.isTablet,
    required this.isDesktop,
  });

  @override
  ConsumerState<PayrollTableView> createState() => _PayrollTableViewState();
}

class _PayrollTableViewState extends ConsumerState<PayrollTableView> {
  /// Текущий подсвеченный расчет (для контекстного меню).
  _PayrollFlatRow? _highlightedRow;

  @override
  Widget build(BuildContext context) {
    // Подготовка данных
    final groupedPayrollsMap = _groupPayrolls();
    final sortedEmployeeKeys = _sortEmployeeKeys(
      groupedPayrollsMap.keys.toList(),
    );

    final totals = _calculateTotals(groupedPayrollsMap);

    // Если мобильный вид - возвращаем кастомное представление
    if (widget.isMobile) {
      final flatPayrolls = <PayrollCalculation>[];
      final infoMap = <String, PayrollCardInfo>{};

      for (final employeeId in sortedEmployeeKeys) {
        if (employeeId == null) continue;
        final employeePayrolls = groupedPayrollsMap[employeeId]!;
        final employeeInfo = _getEmployeeInfo(
          employeeId,
          0,
        ); // Индекс не важен для мобилок

        final payout = widget.payoutsByEmployee[employeeId] ?? 0;
        final balance = widget.aggregatedBalance[employeeId] ?? 0;

        infoMap[employeeId] = PayrollCardInfo(
          name: employeeInfo.name,
          status: employeeInfo.status,
          payout: payout,
          balance: balance,
        );

        for (final p in employeePayrolls) {
          flatPayrolls.add(p);
        }
      }

      final mobileTotals = PayrollMobileTotals(
        netSalary: totals.amount,
        payout: totals.payout,
        balance: widget.employees
            .map((e) => widget.aggregatedBalance[e.id] ?? 0.0)
            .fold<double>(0, (sum, b) => sum + b),
      );

      return PayrollMobileView(
        payrolls: flatPayrolls,
        employeeInfoMap: infoMap,
        totals: mobileTotals,
        onRowLongPress: (payroll, position) => _showContextMenu(
          context,
          _PayrollFlatRow(
            payroll: payroll,
            info: _getEmployeeInfo(payroll.employeeId, 0),
          ),
          position,
        ),
      );
    }

    // Преобразуем сгруппированные данные в плоский список для GTAdaptiveTable
    final flatList = <_PayrollFlatRow>[];
    int counter = 1;
    for (final employeeId in sortedEmployeeKeys) {
      final employeePayrolls = groupedPayrollsMap[employeeId]!;
      final employeeInfo = _getEmployeeInfo(employeeId, counter);
      for (final p in employeePayrolls) {
        flatList.add(_PayrollFlatRow(payroll: p, info: employeeInfo));
      }
      counter++;
    }

    final columns = [
      GTColumnConfig<_PayrollFlatRow>(
        title: 'Сотрудник',
        flex: 3,
        isFlexible: true,
        measureText: (row) {
          String text = row.info.name;
          if (row.info.status != null) {
            final statusInfo = EmployeeUIUtils.getStatusInfo(row.info.status!);
            text += ' ${statusInfo.$1}';
          }
          return text;
        },
        builder: (row, _, theme) {
          final statusInfo = row.info.status != null
              ? EmployeeUIUtils.getStatusInfo(row.info.status!)
              : null;

          return Text.rich(
            TextSpan(
              children: [
                TextSpan(text: row.info.name),
                if (statusInfo != null) ...[
                  const TextSpan(text: ' '),
                  TextSpan(
                    text: statusInfo.$1.toLowerCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.normal,
                      color: statusInfo.$2.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 12,
              height: 1.0,
              fontWeight: FontWeight.w600,
            ),
          );
        },
        totalBuilder: (theme) => Text(
          'ИТОГО',
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 12,
            height: 1.0,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      GTColumnConfig<_PayrollFlatRow>(
        title: 'Часы',
        headerAlign: TextAlign.center,
        cellAlignment: Alignment.center,
        measureText: (row) => formatQuantity(row.payroll.hoursWorked),
        measureTotal: () => formatQuantity(totals.hours),
        builder: (row, _, __) => Text(formatQuantity(row.payroll.hoursWorked)),
        totalBuilder: (_) => Text(
          formatQuantity(totals.hours),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      if (widget.isDesktop)
        GTColumnConfig<_PayrollFlatRow>(
          title: 'Ставка',
          headerAlign: TextAlign.right,
          cellAlignment: Alignment.centerRight,
          measureText: (row) => formatCurrency(row.payroll.hourlyRate),
          builder: (row, _, __) => Text(formatCurrency(row.payroll.hourlyRate)),
        ),
      if (widget.isDesktop || widget.isTablet)
        GTColumnConfig<_PayrollFlatRow>(
          title: 'База',
          headerAlign: TextAlign.right,
          cellAlignment: Alignment.centerRight,
          measureText: (row) => formatCurrency(row.payroll.baseSalary),
          measureTotal: () => formatCurrency(totals.base),
          builder: (row, _, __) => Text(formatCurrency(row.payroll.baseSalary)),
          totalBuilder: (_) => Text(
            formatCurrency(totals.base),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      if (widget.isDesktop)
        GTColumnConfig<_PayrollFlatRow>(
          title: 'Премии',
          headerAlign: TextAlign.right,
          cellAlignment: Alignment.centerRight,
          measureText: (row) => row.payroll.bonusesTotal > 0
              ? formatCurrency(row.payroll.bonusesTotal)
              : '—',
          measureTotal: () => formatCurrency(totals.bonus),
          builder: (row, _, theme) => Text(
            row.payroll.bonusesTotal > 0
                ? formatCurrency(row.payroll.bonusesTotal)
                : '—',
            style: TextStyle(
              color: row.payroll.bonusesTotal > 0
                  ? PayrollTableConstants.bonusColor
                  : null,
              fontWeight: row.payroll.bonusesTotal > 0 ? FontWeight.w500 : null,
            ),
          ),
          totalBuilder: (_) => Text(
            formatCurrency(totals.bonus),
            style: const TextStyle(
              color: PayrollTableConstants.bonusColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      if (widget.isDesktop)
        GTColumnConfig<_PayrollFlatRow>(
          title: 'Штрафы',
          headerAlign: TextAlign.right,
          cellAlignment: Alignment.centerRight,
          measureText: (row) => row.payroll.penaltiesTotal > 0
              ? formatCurrency(row.payroll.penaltiesTotal)
              : '—',
          measureTotal: () => formatCurrency(totals.penalty),
          builder: (row, _, theme) => Text(
            row.payroll.penaltiesTotal > 0
                ? formatCurrency(row.payroll.penaltiesTotal)
                : '—',
            style: TextStyle(
              color: row.payroll.penaltiesTotal > 0
                  ? PayrollTableConstants.penaltyColor
                  : null,
              fontWeight: row.payroll.penaltiesTotal > 0
                  ? FontWeight.w500
                  : null,
            ),
          ),
          totalBuilder: (_) => Text(
            formatCurrency(totals.penalty),
            style: const TextStyle(
              color: PayrollTableConstants.penaltyColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      GTColumnConfig<_PayrollFlatRow>(
        title: 'Суточные',
        headerAlign: TextAlign.right,
        cellAlignment: Alignment.centerRight,
        measureText: (row) => formatCurrency(row.payroll.businessTripTotal),
        measureTotal: () => formatCurrency(totals.trip),
        builder: (row, _, __) =>
            Text(formatCurrency(row.payroll.businessTripTotal)),
        totalBuilder: (_) => Text(
          formatCurrency(totals.trip),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      GTColumnConfig<_PayrollFlatRow>(
        title: 'К выплате',
        headerAlign: TextAlign.right,
        cellAlignment: Alignment.centerRight,
        measureText: (row) => formatCurrency(row.payroll.netSalary),
        measureTotal: () => formatCurrency(totals.amount),
        extraWidth: 12,
        builder: (row, _, theme) => Text(
          formatCurrency(row.payroll.netSalary),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        totalBuilder: (theme) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            formatCurrency(totals.amount),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
        ),
      ),
      GTColumnConfig<_PayrollFlatRow>(
        title: 'Выплаты',
        headerAlign: TextAlign.right,
        cellAlignment: Alignment.centerRight,
        measureText: (row) {
          final payout = widget.payoutsByEmployee[row.payroll.employeeId] ?? 0;
          return payout > 0 ? formatCurrency(payout) : '—';
        },
        measureTotal: () => formatCurrency(totals.payout),
        builder: (row, _, theme) {
          final payout = widget.payoutsByEmployee[row.payroll.employeeId] ?? 0;
          return Text(
            payout > 0 ? formatCurrency(payout) : '—',
            style: TextStyle(
              color: payout > 0 ? PayrollTableConstants.payoutColor : null,
              fontWeight: payout > 0 ? FontWeight.w500 : null,
            ),
          );
        },
        totalBuilder: (theme) => Text(
          formatCurrency(totals.payout),
          style: const TextStyle(
            color: PayrollTableConstants.payoutColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      GTColumnConfig<_PayrollFlatRow>(
        title: 'Остаток',
        headerAlign: TextAlign.right,
        cellAlignment: Alignment.centerRight,
        measureText: (row) {
          final payout = widget.payoutsByEmployee[row.payroll.employeeId] ?? 0;
          return formatCurrency(row.payroll.netSalary - payout);
        },
        measureTotal: () => formatCurrency(totals.remainder),
        builder: (row, _, theme) {
          final payout = widget.payoutsByEmployee[row.payroll.employeeId] ?? 0;
          final remainder = row.payroll.netSalary - payout;
          return Text(
            formatCurrency(remainder),
            style: TextStyle(
              color: remainder > 0
                  ? Colors.green[700]
                  : (remainder < 0 ? Colors.red[700] : null),
              fontWeight: FontWeight.w500,
            ),
          );
        },
        totalBuilder: (_) => Text(
          formatCurrency(totals.remainder),
          style: TextStyle(
            color: totals.remainder > 0
                ? Colors.green[700]
                : (totals.remainder < 0 ? Colors.red[700] : null),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      GTColumnConfig<_PayrollFlatRow>(
        title: 'Баланс',
        headerAlign: TextAlign.right,
        cellAlignment: Alignment.centerRight,
        extraWidth: 32,
        measureText: (row) => BalanceUtils.formatBalance(
          widget.aggregatedBalance[row.payroll.employeeId ?? ''] ?? 0,
        ),
        measureTotal: () {
          final totalBalance = widget.employees
              .map((e) => widget.aggregatedBalance[e.id] ?? 0.0)
              .fold<double>(0, (sum, b) => sum + b);
          return BalanceUtils.formatBalance(totalBalance);
        },
        builder: (row, _, theme) {
          final balance =
              widget.aggregatedBalance[row.payroll.employeeId ?? ''] ?? 0;
          return BalanceUtils.buildBalanceWidget(
            balance,
            theme,
            showIcon: true,
            showDescription: false,
            textStyle: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
          );
        },
        totalBuilder: (theme) {
          final totalBalance = widget.employees
              .map((e) => widget.aggregatedBalance[e.id] ?? 0.0)
              .fold<double>(0, (sum, b) => sum + b);

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: BalanceUtils.getBalanceColor(
                totalBalance,
                theme,
              ).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: BalanceUtils.buildBalanceWidget(
              totalBalance,
              theme,
              showIcon: true,
              showDescription: false,
              textStyle: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          );
        },
      ),
    ];

    return GTAdaptiveTable<_PayrollFlatRow>(
      items: flatList,
      columns: columns,
      showTotalRow: true,
      highlightedItem: _highlightedRow,
      onRowTapDown: (row, details) =>
          _showContextMenu(context, row, details.globalPosition),
      onRowSecondaryTapDown: (row, details) =>
          _showContextMenu(context, row, details.globalPosition),
    );
  }

  void _showContextMenu(
    BuildContext context,
    _PayrollFlatRow row,
    Offset position,
  ) {
    setState(() => _highlightedRow = row);

    GTContextMenu.show(
      context: context,
      tapPosition: position,
      onDismiss: () => setState(() => _highlightedRow = null),
      items: [
        GTContextMenuItem(
          icon: CupertinoIcons.add_circled,
          label: 'Премия',
          onTap: () => _showBonusForm(context, row.payroll.employeeId),
        ),
        GTContextMenuItem(
          icon: CupertinoIcons.minus_circle,
          label: 'Штраф',
          onTap: () => _showPenaltyForm(context, row.payroll.employeeId),
        ),
        GTContextMenuItem(
          icon: Icons.payment_outlined,
          label: 'Выплата',
          onTap: () => _showPayoutForm(context, row.payroll.employeeId),
        ),
        const Divider(height: 4, indent: 8, endIndent: 8),
        GTContextMenuItem(
          icon: CupertinoIcons.info,
          label: 'Детали',
          onTap: () => _showDetails(context, row.payroll.employeeId),
        ),
      ],
    );
  }

  void _showBonusForm(BuildContext context, String? employeeId) {
    final isDesktop = ResponsiveUtils.isDesktop(context);
    if (isDesktop) {
      showDialog(
        context: context,
        builder: (ctx) => PayrollTransactionFormModal(
          transactionType: PayrollTransactionType.bonus,
          initialEmployeeId: employeeId,
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => PayrollTransactionFormModal(
          transactionType: PayrollTransactionType.bonus,
          initialEmployeeId: employeeId,
        ),
      );
    }
  }

  void _showPenaltyForm(BuildContext context, String? employeeId) {
    final isDesktop = ResponsiveUtils.isDesktop(context);
    if (isDesktop) {
      showDialog(
        context: context,
        builder: (ctx) => PayrollTransactionFormModal(
          transactionType: PayrollTransactionType.penalty,
          initialEmployeeId: employeeId,
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => PayrollTransactionFormModal(
          transactionType: PayrollTransactionType.penalty,
          initialEmployeeId: employeeId,
        ),
      );
    }
  }

  void _showPayoutForm(BuildContext context, String? employeeId) {
    final isDesktop = ResponsiveUtils.isDesktop(context);
    if (isDesktop) {
      showDialog(
        context: context,
        builder: (ctx) => PayrollPayoutFormModal(initialEmployeeId: employeeId),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => PayrollPayoutFormModal(initialEmployeeId: employeeId),
      );
    }
  }

  Future<void> _showDetails(BuildContext context, String? employeeId) async {
    if (employeeId == null) return;

    final employee = widget.employees.firstWhereOrNull(
      (e) => e.id == employeeId,
    );
    if (employee == null) return;

    final filterState = ref.read(payrollFilterProvider);
    final year = filterState.selectedYear;

    SnackBarUtils.showInfo(context, 'Формирование отчета за $year год...');

    try {
      final client = ref.read(supabaseClientProvider);
      final List<MonthlyReportData> monthlyReportData = [];

      final startDate = DateTime(year, 1, 1);
      final endDate = DateTime(year, 12, 31, 23, 59, 59);

      // 1. Получаем историю ставок сотрудника
      final ratesResponse = await client
          .from('employee_rates')
          .select()
          .eq('employee_id', employeeId)
          .order('valid_from');

      final List<Map<String, dynamic>> rates = List<Map<String, dynamic>>.from(
        ratesResponse,
      );

      // 2. Получаем все отработанные часы за год (смены + ручной ввод)
      final workHoursResponse = await client
          .from('work_hours')
          .select('''
            hours,
            works!inner(date, status)
          ''')
          .eq('employee_id', employeeId)
          .eq('works.status', 'closed')
          .gte('works.date', startDate.toIso8601String())
          .lte('works.date', endDate.toIso8601String());

      final attendanceResponse = await client
          .from('employee_attendance')
          .select('hours, date')
          .eq('employee_id', employeeId)
          .gte('date', startDate.toIso8601String())
          .lte('date', endDate.toIso8601String());

      final allWorkEntries = [
        ...(workHoursResponse as List).map(
          (row) => {
            'hours': (row['hours'] as num).toDouble(),
            'date': DateTime.parse(row['works']['date']),
          },
        ),
        ...(attendanceResponse as List).map(
          (row) => {
            'hours': (row['hours'] as num).toDouble(),
            'date': DateTime.parse(row['date']),
          },
        ),
      ];

      // 3. Получаем все выплаты сотрудника за выбранный год
      final payoutsResponse = await client
          .from('payroll_payout')
          .select()
          .eq('employee_id', employeeId)
          .gte('payout_date', startDate.toIso8601String())
          .lte('payout_date', endDate.toIso8601String())
          .order('payout_date');

      final allPayouts = (payoutsResponse as List)
          .map((json) => PayrollPayoutModel.fromJson(json))
          .toList();

      // 4. Получаем расчеты ФОТ за каждый месяц через RPC
      final List<Future<dynamic>> payrollFutures = [];
      final activeCompanyId = ref.read(activeCompanyIdProvider);
      
      for (int month = 1; month <= 12; month++) {
        payrollFutures.add(
          client.rpc(
            'calculate_payroll_for_month',
            params: {
              'p_year': year, 
              'p_month': month,
              'p_company_id': activeCompanyId,
            },
          ),
        );
      }

      final results = await Future.wait(payrollFutures);

      // 5. Формируем помесячную детализацию
      for (int i = 0; i < 12; i++) {
        final month = i + 1;
        final monthResults = results[i] as List;

        final monthRow = monthResults.firstWhereOrNull(
          (row) => row['employee_id'] == employeeId,
        );

        PayrollCalculation? calc;
        if (monthRow != null) {
          calc = PayrollCalculation(
            employeeId: employeeId,
            periodMonth: DateTime(year, month, 1),
            hoursWorked: (monthRow['total_hours'] as num).toDouble(),
            hourlyRate: (monthRow['current_hourly_rate'] as num).toDouble(),
            baseSalary: (monthRow['base_salary'] as num).toDouble(),
            bonusesTotal: (monthRow['bonuses_total'] as num).toDouble(),
            penaltiesTotal: (monthRow['penalties_total'] as num).toDouble(),
            businessTripTotal: (monthRow['business_trip_total'] as num)
                .toDouble(),
            netSalary: (monthRow['net_salary'] as num).toDouble(),
          );
        }

        // Детализация по ставкам для этого месяца
        final Map<double, double> rateHoursMap = {};
        final monthEntries = allWorkEntries.where((e) {
          final date = e['date'] as DateTime;
          return date.year == year && date.month == month;
        });

        for (final entry in monthEntries) {
          final date = entry['date'] as DateTime;
          final hours = entry['hours'] as double;

          // Ищем ставку на эту дату
          double activeRate = 0;
          for (final rate in rates) {
            final validFrom = DateTime.parse(rate['valid_from']);
            final validTo = rate['valid_to'] != null
                ? DateTime.parse(rate['valid_to'])
                : null;

            if ((date.isAfter(validFrom) || date.isAtSameMomentAs(validFrom)) &&
                (validTo == null ||
                    date.isBefore(validTo) ||
                    date.isAtSameMomentAs(validTo))) {
              activeRate = (rate['hourly_rate'] as num).toDouble();
              break;
            }
          }

          if (activeRate > 0) {
            rateHoursMap[activeRate] = (rateHoursMap[activeRate] ?? 0) + hours;
          }
        }

        final List<RateBreakdown> breakdowns = rateHoursMap.entries
            .map(
              (entry) => RateBreakdown(
                rate: entry.key,
                hours: entry.value,
                amount: entry.key * entry.value,
              ),
            )
            .toList();

        final monthPayouts = allPayouts.where((p) {
          return p.payoutDate.year == year && p.payoutDate.month == month;
        }).toList();

        if (calc != null || monthPayouts.isNotEmpty) {
          monthlyReportData.add(
            MonthlyReportData(
              month: month,
              year: year,
              calculation: calc,
              payouts: monthPayouts,
              rateBreakdowns: breakdowns,
            ),
          );
        }
      }

      if (monthlyReportData.isEmpty) {
        if (context.mounted) {
          SnackBarUtils.showWarning(context, 'Нет данных за $year год');
        }
        return;
      }

      // 3. Генерируем и показываем через системный просмотрщик
      final pdfService = PayrollPdfService();
      await pdfService.generateEmployeeYearlyReport(
        employee: employee as Employee,
        year: year,
        monthlyData: monthlyReportData,
      );
    } catch (e) {
      if (context.mounted) {
        SnackBarUtils.showError(context, 'Ошибка при формировании отчета: $e');
      }
    }
  }

  // Вспомогательные методы
  Map<String?, List<PayrollCalculation>> _groupPayrolls() {
    final Map<String?, List<PayrollCalculation>> grouped = {};

    // 1. Сначала добавляем тех, у кого есть расчеты в текущем месяце
    for (final payroll in widget.payrolls) {
      final key = payroll.employeeId ?? 'unknown';
      grouped.putIfAbsent(key, () => []).add(payroll);
    }

    final periodMonth = widget.payrolls.isNotEmpty
        ? widget.payrolls.first.periodMonth
        : DateTime.now();

    final lastDayOfMonth = DateTime(
      periodMonth.year,
      periodMonth.month + 1,
      0,
      23,
      59,
      59,
    );

    // 2. Добавляем сотрудников с балансом или активных
    for (final employee in widget.employees) {
      final empId = employee.id;
      final balance = widget.aggregatedBalance[empId] ?? 0;
      final employmentDate = (employee as dynamic).employmentDate as DateTime?;
      final isFired = (employee as dynamic).status == EmployeeStatus.fired;

      // Условие 1: Сотрудник устроен НЕ позже конца текущего месяца
      final isHiredBeforeEnd =
          employmentDate == null ||
          employmentDate.isBefore(lastDayOfMonth) ||
          employmentDate.isAtSameMomentAs(lastDayOfMonth);

      if (!isHiredBeforeEnd) continue;

      // Условие 2: У сотрудника есть долг ИЛИ он еще работает
      final hasBalance = balance.abs() > 0.01;
      final isWorking = !isFired;

      if ((hasBalance || isWorking) && !grouped.containsKey(empId)) {
        final hourlyRate =
            (employee as dynamic).currentHourlyRate?.toDouble() ?? 0.0;

        grouped[empId] = [
          PayrollCalculation(
            employeeId: empId,
            periodMonth: periodMonth,
            hoursWorked: 0,
            hourlyRate: hourlyRate,
            baseSalary: 0,
            bonusesTotal: 0,
            penaltiesTotal: 0,
            businessTripTotal: 0,
            netSalary: 0,
          ),
        ];
      }
    }

    return grouped;
  }

  List<String?> _sortEmployeeKeys(List<String?> keys) {
    return keys..sort((a, b) {
      if (a == null || a == 'unknown') return 1;
      if (b == null || b == 'unknown') return -1;
      final empA = widget.employees.firstWhereOrNull((e) => e.id == a);
      final empB = widget.employees.firstWhereOrNull((e) => e.id == b);
      if (empA == null) return 1;
      if (empB == null) return -1;

      final nameA =
          '${empA.lastName} ${empA.firstName} ${empA.middleName ?? ''}'
              .toLowerCase();
      final nameB =
          '${empB.lastName} ${empB.firstName} ${empB.middleName ?? ''}'
              .toLowerCase();
      return nameA.compareTo(nameB);
    });
  }

  _EmployeeRowInfo _getEmployeeInfo(String? id, int counter) {
    if (id == null || id == 'unknown') {
      return _EmployeeRowInfo(name: 'Неизвестный', index: counter);
    }
    final emp = widget.employees.firstWhereOrNull((e) => e.id == id);
    if (emp == null) {
      return _EmployeeRowInfo(name: 'Сотрудник $id', index: counter);
    }

    final fullName = [
      emp.lastName,
      emp.firstName,
      emp.middleName,
    ].where((e) => e != null && e.toString().isNotEmpty).join(' ');

    EmployeeStatus? status;
    if (emp is Employee) {
      status = emp.status;
    } else {
      // Если это динамический объект (например, из Supabase)
      try {
        status = emp.status;
      } catch (_) {}
    }

    return _EmployeeRowInfo(name: fullName, status: status, index: counter);
  }

  _PayrollTotals _calculateTotals(
    Map<String?, List<PayrollCalculation>> grouped,
  ) {
    final t = _PayrollTotals();
    for (final list in grouped.values) {
      for (final p in list) {
        t.hours += p.hoursWorked;
        t.base += p.baseSalary;
        t.bonus += p.bonusesTotal;
        t.penalty += p.penaltiesTotal;
        t.amount += p.netSalary;
        t.trip += p.businessTripTotal;
        final payout = widget.payoutsByEmployee[p.employeeId] ?? 0;
        t.payout += payout;
        t.remainder += (p.netSalary - payout);
      }
    }
    return t;
  }
}

/// Плоская строка для таблицы ФОТ.
class _PayrollFlatRow {
  final PayrollCalculation payroll;
  final _EmployeeRowInfo info;

  _PayrollFlatRow({required this.payroll, required this.info});
}

class _PayrollTotals {
  double hours = 0;
  double base = 0;
  double bonus = 0;
  double penalty = 0;
  double amount = 0;
  double trip = 0;
  double payout = 0;
  double remainder = 0;
}
