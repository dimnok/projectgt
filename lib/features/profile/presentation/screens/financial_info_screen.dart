import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:projectgt/presentation/widgets/app_bar_widget.dart';
import 'package:projectgt/presentation/state/profile_state.dart';
import 'package:projectgt/core/di/providers.dart';

/// Пустая страница "Финансовая информация" (заглушка).
class FinancialInfoScreen extends ConsumerStatefulWidget {
  /// Создает экран финансовой информации.
  const FinancialInfoScreen({super.key});

  @override
  ConsumerState<FinancialInfoScreen> createState() =>
      _FinancialInfoScreenState();
}

class _FinancialInfoScreenState extends ConsumerState<FinancialInfoScreen> {
  late DateTime _monthStart;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _monthStart = DateTime(now.year, now.month, 1);
  }

  void _shiftMonth(int delta) {
    setState(() {
      _monthStart = DateTime(_monthStart.year, _monthStart.month + delta, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profileState = ref.watch(currentUserProfileProvider);
    final employeeId = (profileState.profile?.object != null)
        ? (profileState.profile!.object!['employee_id'] as String?)
        : null;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: const AppBarWidget(
        title: 'Финансовая информация',
        leading: BackButton(),
      ),
      body: employeeId == null || employeeId.isEmpty
          ? Center(
              child: Text(
                'Для отображения данных привяжите сотрудника в профиле',
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => _shiftMonth(-1),
                        icon: const Icon(Icons.chevron_left),
                        label: const Text('Пред.'),
                      ),
                      const Spacer(),
                      OutlinedButton.icon(
                        onPressed: () => _shiftMonth(1),
                        icon: const Icon(Icons.chevron_right),
                        label: const Text('След.'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _FinancialInfoBody(
                    employeeId: employeeId,
                    monthStart: _monthStart,
                  ),
                ),
              ],
            ),
    );
  }
}

class _FinancialInfoBody extends ConsumerWidget {
  final String employeeId;
  final DateTime monthStart;
  const _FinancialInfoBody(
      {required this.employeeId, required this.monthStart});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(_financialInfoProvider(
        _FinancialArgs(employeeId: employeeId, monthStart: monthStart)));
    final theme = Theme.of(context);
    return asyncData.when(
      loading: () => const Center(child: CupertinoActivityIndicator()),
      error: (e, st) => Center(
        child: SelectableText(
          'Ошибка загрузки финансовых данных:\n$e',
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: theme.colorScheme.error),
        ),
      ),
      data: (data) {
        final month = data.month;
        final totals = data.totals;
        final monthTitle =
            DateFormat('LLLL yyyy', 'ru_RU').format(month.monthStart);
        final money = NumberFormat.currency(
            locale: 'ru_RU', symbol: '₽', decimalDigits: 0);
        final hoursFmt = NumberFormat('#,##0.##', 'ru_RU');

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CardBlock(
                title: 'Текущий период',
                children: [
                  _MonthChip(title: monthTitle),
                  const SizedBox(height: 8),
                  _MetricRow(
                    label: 'Отработанные часы',
                    value: '${hoursFmt.format(month.hours)} ч',
                    leadingIcon: Icons.access_time,
                    onTap: () {
                      _showHoursCalendarModal(
                        context: context,
                        monthStart: month.monthStart,
                        hoursByDate: data.monthHoursByDate,
                      );
                    },
                  ),
                  _MetricRow(
                    label: 'Заработано (база)',
                    value: money.format(month.baseSalary),
                    valueColor: _colorForAmount(month.baseSalary, theme),
                    leadingIcon: Icons.work_outline,
                  ),
                  _MetricRow(
                    label: 'Суточные',
                    value: money.format(month.businessTripTotal),
                    valueColor: _colorForAmount(month.businessTripTotal, theme),
                    leadingIcon: Icons.card_travel_outlined,
                  ),
                  _MetricRow(
                    label: 'Премии',
                    value: money.format(month.bonuses),
                    valueColor: _colorForAmount(month.bonuses, theme),
                    leadingIcon: Icons.emoji_events_outlined,
                    onTap: () {
                      _showMoneyListModal(
                        context: context,
                        title: 'Премии — $monthTitle',
                        records: data.monthBonusRecords,
                        money: money,
                        positive: true,
                        initialMonthStart: month.monthStart,
                      );
                    },
                  ),
                  _MetricRow(
                    label: 'Штрафы',
                    value: money.format(month.penalties),
                    valueColor: theme.colorScheme.error,
                    leadingIcon: Icons.report_gmailerrorred_outlined,
                    onTap: () {
                      _showMoneyListModal(
                        context: context,
                        title: 'Штрафы — $monthTitle',
                        records: data.monthPenaltyRecords,
                        money: money,
                        positive: false,
                        initialMonthStart: month.monthStart,
                      );
                    },
                  ),
                  const Divider(height: 24),
                  _MetricRow(
                    label: 'Итого к выплате',
                    value: money.format(month.netSalary),
                    emphasized: true,
                    valueColor: _colorForAmount(month.netSalary, theme),
                    leadingIcon: Icons.account_balance_wallet_outlined,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _CardBlock(
                title: 'Итоги',
                children: [
                  _MetricRow(
                    label: 'Общая сумма заработанного',
                    value: money.format(totals.totalEarned),
                    valueColor: _colorForAmount(totals.totalEarned, theme),
                    leadingIcon: Icons.trending_up,
                  ),
                  _MetricRow(
                    label: 'Общая сумма выплат',
                    value: money.format(totals.totalPayouts),
                    valueColor: theme.colorScheme.onSurface,
                    leadingIcon: Icons.payments_outlined,
                    onTap: () {
                      _showMoneyListModal(
                        context: context,
                        title: 'Выплаты (все)',
                        records: data.allPayoutRecords,
                        money: money,
                        positive: false,
                        initialMonthStart: month.monthStart,
                      );
                    },
                  ),
                  const Divider(height: 24),
                  _MetricRow(
                    label: 'Общий остаток',
                    value: money.format(totals.totalBalance),
                    emphasized: true,
                    valueColor: _colorForAmount(totals.totalBalance, theme),
                    leadingIcon: Icons.account_balance_outlined,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CardBlock extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _CardBlock({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  final String label;
  final String value;
  final bool emphasized;
  final Color? valueColor;
  final IconData? leadingIcon;
  final VoidCallback? onTap;
  const _MetricRow({
    required this.label,
    required this.value,
    this.emphasized = false,
    this.valueColor,
    this.leadingIcon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyle = emphasized
        ? theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          )
        : theme.textTheme.titleMedium;
    final row = Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          if (leadingIcon != null) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                leadingIcon,
                size: 18,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
          Text(
            value,
            style: textStyle!.copyWith(
              color:
                  valueColor ?? textStyle.color ?? theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
    if (onTap == null) return row;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: row,
    );
  }
}

class _MonthChip extends StatelessWidget {
  final String title;
  const _MonthChip({required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.calendar_today_outlined,
              size: 14, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            title,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

Color _colorForAmount(double amount, ThemeData theme) {
  if (amount > 0) return theme.colorScheme.primary;
  if (amount < 0) return theme.colorScheme.error;
  return theme.colorScheme.onSurface;
}

class _MoneyRecord {
  final DateTime date;
  final double amount;
  final String comment;
  const _MoneyRecord(
      {required this.date, required this.amount, required this.comment});
}

void _showMoneyListModal({
  required BuildContext context,
  required String title,
  required List<_MoneyRecord> records,
  required NumberFormat money,
  required bool positive,
  DateTime? initialMonthStart,
}) {
  final theme = Theme.of(context);
  showModalBottomSheet(
    context: context,
    backgroundColor: theme.colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    isScrollControlled: true,
    builder: (ctx) {
      // Локальный месяц показа
      DateTime current = initialMonthStart != null
          ? DateTime(initialMonthStart.year, initialMonthStart.month, 1)
          : (records.isNotEmpty
              ? DateTime(records.first.date.year, records.first.date.month, 1)
              : DateTime.now());

      List<_MoneyRecord> filterByMonth(DateTime m) {
        final start = DateTime(m.year, m.month, 1);
        final end = DateTime(m.year, m.month + 1, 0);
        return records
            .where((r) => !r.date.isBefore(start) && !r.date.isAfter(end))
            .toList();
      }

      return StatefulBuilder(builder: (ctx, setState) {
        final filtered = filterByMonth(current);
        final monthTitle = DateFormat('LLLL yyyy', 'ru_RU').format(current);

        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => setState(() {
                      current = DateTime(current.year, current.month - 1, 1);
                    }),
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          positive
                              ? Icons.emoji_events_outlined
                              : Icons.payments_outlined,
                          color: positive
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$title — $monthTitle',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() {
                      current = DateTime(current.year, current.month + 1, 1);
                    }),
                    icon: const Icon(Icons.chevron_right),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (filtered.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text('Записей нет', style: theme.textTheme.bodyMedium),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => Divider(
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.08),
                      height: 12,
                    ),
                    itemBuilder: (_, i) {
                      final r = filtered[i];
                      final dateStr = DateFormat('dd.MM.yyyy').format(r.date);
                      final color = positive
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface;
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 92,
                            child: Text(
                              dateStr,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.7),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  money.format(r.amount),
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: color,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (r.comment.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      r.comment,
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      });
    },
  );
}

class _FinancialMonthSummary {
  final DateTime monthStart;
  final double hours;
  final double hourlyRate; // текущая ставка из employees при join
  final double baseSalary;
  final double bonuses;
  final double penalties;
  final double businessTripTotal;
  final double netSalary;
  const _FinancialMonthSummary({
    required this.monthStart,
    required this.hours,
    required this.hourlyRate,
    required this.baseSalary,
    required this.bonuses,
    required this.penalties,
    required this.businessTripTotal,
    required this.netSalary,
  });
}

class _FinancialTotals {
  final double totalEarned;
  final double totalPayouts;
  final double totalBalance;
  const _FinancialTotals({
    required this.totalEarned,
    required this.totalPayouts,
    required this.totalBalance,
  });
}

class _FinancialInfoData {
  final _FinancialMonthSummary month;
  final _FinancialTotals totals;
  final List<_MoneyRecord> monthBonusRecords;
  final List<_MoneyRecord> monthPenaltyRecords;
  final Map<DateTime, double> monthHoursByDate;
  final List<_MoneyRecord> allPayoutRecords;
  const _FinancialInfoData({
    required this.month,
    required this.totals,
    required this.monthBonusRecords,
    required this.monthPenaltyRecords,
    required this.monthHoursByDate,
    required this.allPayoutRecords,
  });
}

class _FinancialArgs {
  final String employeeId;
  final DateTime monthStart;
  const _FinancialArgs({required this.employeeId, required this.monthStart});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _FinancialArgs &&
        other.employeeId == employeeId &&
        other.monthStart == monthStart;
  }

  @override
  int get hashCode => Object.hash(employeeId, monthStart);
}

final _financialInfoProvider =
    FutureProvider.family<_FinancialInfoData, _FinancialArgs>(
        (ref, args) async {
  final client = ref.watch(supabaseClientProvider);

  // Выбранный месяц
  final monthStart = DateTime(args.monthStart.year, args.monthStart.month, 1);
  final monthEnd = DateTime(args.monthStart.year, args.monthStart.month + 1, 0);
  final employeeId = args.employeeId;

  // Work hours с join-ами для месяца (только закрытые смены)
  final workHoursResp = await client.from('work_hours').select('''
        hours,
        works!inner(date, object_id, status)
      ''').eq('employee_id', employeeId).eq('works.status', 'closed');

  // Получаем текущую ставку сотрудника из employee_rates
  final currentRateResp = await client
      .from('employee_rates')
      .select('hourly_rate')
      .eq('employee_id', employeeId)
      .isFilter('valid_to', null)
      .maybeSingle();

  final currentHourlyRate = currentRateResp != null
      ? (currentRateResp['hourly_rate'] as num?)?.toDouble() ?? 0.0
      : 0.0;

  // Получаем активные ставки командировочных для периода и сотрудника
  final businessTripRatesResp = await client
      .from('business_trip_rates')
      .select(
          'object_id, rate, valid_from, valid_to, employee_id, minimum_hours')
      .eq('employee_id', employeeId)
      .or('valid_to.is.null,valid_to.gte.${monthStart.toIso8601String().split('T')[0]}')
      .lte('valid_from', monthEnd.toIso8601String().split('T')[0]);

  double monthHours = 0;
  final Map<String, int> monthObjectShiftCount = {};
  final Map<DateTime, double> monthHoursByDate = {};

  for (final record in (workHoursResp as List)) {
    final works = record['works'] as Map<String, dynamic>?;
    if (works == null) continue;
    final workDateStr = works['date'] as String?;
    if (workDateStr == null) continue;
    final workDate = DateTime.tryParse(workDateStr);
    if (workDate == null) continue;
    if (workDate.isBefore(monthStart) || workDate.isAfter(monthEnd)) continue;

    final hours = (record['hours'] as num?)?.toDouble() ?? 0;
    monthHours += hours;
    final dayKey = DateTime(workDate.year, workDate.month, workDate.day);
    monthHoursByDate[dayKey] = (monthHoursByDate[dayKey] ?? 0) + hours;

    final objectId = works['object_id'] as String?;
    if (objectId != null && objectId.isNotEmpty) {
      monthObjectShiftCount[objectId] =
          (monthObjectShiftCount[objectId] ?? 0) + 1;
    }
  }

  // Рассчитываем командировочные с учетом дат смен и минимальных часов
  double monthBusinessTrips = 0;
  for (final record in (workHoursResp as List)) {
    final works = record['works'] as Map<String, dynamic>?;
    if (works == null) continue;
    final workDateStr = works['date'] as String?;
    if (workDateStr == null) continue;
    final workDate = DateTime.tryParse(workDateStr);
    if (workDate == null) continue;
    if (workDate.isBefore(monthStart) || workDate.isAfter(monthEnd)) continue;

    final hours = (record['hours'] as num?)?.toDouble() ?? 0;
    final objectId = works['object_id'] as String?;
    if (objectId != null && objectId.isNotEmpty) {
      // Ищем активную ставку на дату смены для данного сотрудника
      for (final rateRecord in (businessTripRatesResp as List)) {
        if (rateRecord['object_id'] == objectId &&
            rateRecord['employee_id'] == employeeId) {
          final validFrom =
              DateTime.tryParse(rateRecord['valid_from'] as String? ?? '');
          final validToStr = rateRecord['valid_to'] as String?;
          final validTo =
              validToStr != null ? DateTime.tryParse(validToStr) : null;

          if (validFrom != null &&
              !workDate.isBefore(validFrom) &&
              (validTo == null || !workDate.isAfter(validTo))) {
            // Проверяем условие минимальных часов
            final minimumHours =
                (rateRecord['minimum_hours'] as num?)?.toDouble() ?? 0.0;
            if (hours >= minimumHours) {
              final rate = (rateRecord['rate'] as num?)?.toDouble() ?? 0;
              monthBusinessTrips += rate;
            }
            break; // Используем первую подходящую ставку
          }
        }
      }
    }
  }

  // Премии и штрафы за месяц
  final bonusesResp = await client
      .from('payroll_bonus')
      .select('amount, date, created_at, reason')
      .eq('employee_id', employeeId);
  final penaltiesResp = await client
      .from('payroll_penalty')
      .select('amount, date, reason')
      .eq('employee_id', employeeId);

  double monthBonuses = 0;
  for (final b in (bonusesResp as List)) {
    final dateStr = (b['date'] ?? b['created_at']) as String?;
    final d = dateStr != null ? DateTime.tryParse(dateStr) : null;
    if (d != null && !d.isBefore(monthStart) && !d.isAfter(monthEnd)) {
      monthBonuses += (b['amount'] as num).toDouble();
    }
  }
  final List<_MoneyRecord> monthBonusRecords = [
    for (final b in (bonusesResp as List))
      if (() {
        final dateStr = (b['date'] ?? b['created_at']) as String?;
        final d = dateStr != null ? DateTime.tryParse(dateStr) : null;
        return d != null && !d.isBefore(monthStart) && !d.isAfter(monthEnd);
      }())
        _MoneyRecord(
          date: DateTime.tryParse((b['date'] ?? b['created_at']) as String)!,
          amount: (b['amount'] as num).toDouble(),
          comment: (b['reason'] as String?) ?? '',
        ),
  ];
  double monthPenalties = 0;
  for (final p in (penaltiesResp as List)) {
    final dateStr = p['date'] as String?;
    final d = dateStr != null ? DateTime.tryParse(dateStr) : null;
    if (d != null && !d.isBefore(monthStart) && !d.isAfter(monthEnd)) {
      monthPenalties += (p['amount'] as num).toDouble();
    }
  }
  final List<_MoneyRecord> monthPenaltyRecords = [
    for (final p in (penaltiesResp as List))
      if (() {
        final dateStr = p['date'] as String?;
        final d = dateStr != null ? DateTime.tryParse(dateStr) : null;
        return d != null && !d.isBefore(monthStart) && !d.isAfter(monthEnd);
      }())
        _MoneyRecord(
          date: DateTime.tryParse((p['date']) as String)!,
          amount: (p['amount'] as num).toDouble(),
          comment: (p['reason'] as String?) ?? '',
        ),
  ];

  final double monthBase = monthHours * currentHourlyRate;
  final double monthNet =
      monthBase + monthBonuses + monthBusinessTrips - monthPenalties;

  final monthSummary = _FinancialMonthSummary(
    monthStart: monthStart,
    hours: monthHours,
    hourlyRate: currentHourlyRate,
    baseSalary: monthBase,
    bonuses: monthBonuses,
    penalties: monthPenalties,
    businessTripTotal: monthBusinessTrips,
    netSalary: monthNet,
  );

  // Тоталы по всему периоду
  double allEarnedBase = 0;
  final Map<String, int> allObjectShiftCount = {};

  for (final record in (workHoursResp as List)) {
    final hours = (record['hours'] as num?)?.toDouble() ?? 0;
    // Используем текущую ставку для всех расчетов
    allEarnedBase += hours * currentHourlyRate;
    final works = record['works'] as Map<String, dynamic>?;
    final objectId = works != null ? works['object_id'] as String? : null;
    if (objectId != null && objectId.isNotEmpty) {
      allObjectShiftCount[objectId] = (allObjectShiftCount[objectId] ?? 0) + 1;
    }
  }

  // Командировочные за все время - получаем все ставки для сотрудника
  final allBusinessTripRatesResp = await client
      .from('business_trip_rates')
      .select(
          'object_id, rate, valid_from, valid_to, employee_id, minimum_hours')
      .eq('employee_id', employeeId);

  double allTrips = 0;
  for (final record in (workHoursResp as List)) {
    final works = record['works'] as Map<String, dynamic>?;
    if (works == null) continue;
    final workDateStr = works['date'] as String?;
    if (workDateStr == null) continue;
    final workDate = DateTime.tryParse(workDateStr);
    if (workDate == null) continue;

    final hours = (record['hours'] as num?)?.toDouble() ?? 0;
    final objectId = works['object_id'] as String?;
    if (objectId != null && objectId.isNotEmpty) {
      // Ищем активную ставку на дату смены для данного сотрудника
      for (final rateRecord in (allBusinessTripRatesResp as List)) {
        if (rateRecord['object_id'] == objectId &&
            rateRecord['employee_id'] == employeeId) {
          final validFrom =
              DateTime.tryParse(rateRecord['valid_from'] as String? ?? '');
          final validToStr = rateRecord['valid_to'] as String?;
          final validTo =
              validToStr != null ? DateTime.tryParse(validToStr) : null;

          if (validFrom != null &&
              !workDate.isBefore(validFrom) &&
              (validTo == null || !workDate.isAfter(validTo))) {
            // Проверяем условие минимальных часов
            final minimumHours =
                (rateRecord['minimum_hours'] as num?)?.toDouble() ?? 0.0;
            if (hours >= minimumHours) {
              final rate = (rateRecord['rate'] as num?)?.toDouble() ?? 0;
              allTrips += rate;
            }
            break; // Используем первую подходящую ставку
          }
        }
      }
    }
  }

  // Все премии/штрафы (без фильтра по дате)
  double allBonuses = 0;
  for (final b in (bonusesResp as List)) {
    allBonuses += (b['amount'] as num).toDouble();
  }
  double allPenalties = 0;
  for (final p in (penaltiesResp as List)) {
    allPenalties += (p['amount'] as num).toDouble();
  }

  final double totalEarned =
      allEarnedBase + allBonuses + allTrips - allPenalties;

  // Все выплаты
  final payoutsResp = await client
      .from('payroll_payout')
      .select('amount, payout_date, comment')
      .eq('employee_id', employeeId);
  double totalPayouts = 0;
  final List<_MoneyRecord> allPayoutRecords = [
    for (final row in (payoutsResp as List))
      _MoneyRecord(
        date:
            DateTime.tryParse((row['payout_date']) as String) ?? DateTime.now(),
        amount: (row['amount'] as num).toDouble(),
        comment: (row['comment'] as String?) ?? '',
      )
  ];
  for (final p in allPayoutRecords) {
    totalPayouts += p.amount;
  }
  final double totalBalance = totalEarned - totalPayouts;

  final totals = _FinancialTotals(
    totalEarned: totalEarned,
    totalPayouts: totalPayouts,
    totalBalance: totalBalance,
  );

  return _FinancialInfoData(
    month: monthSummary,
    totals: totals,
    monthBonusRecords: monthBonusRecords,
    monthPenaltyRecords: monthPenaltyRecords,
    monthHoursByDate: monthHoursByDate,
    allPayoutRecords: allPayoutRecords,
  );
});

void _showHoursCalendarModal({
  required BuildContext context,
  required DateTime monthStart,
  required Map<DateTime, double> hoursByDate,
}) {
  final theme = Theme.of(context);
  final firstDay = DateTime(monthStart.year, monthStart.month, 1);
  final lastDay = DateTime(monthStart.year, monthStart.month + 1, 0);
  // Flutter's DateTime weekday: Monday=1..Sunday=7. We'll start grid from Mon.
  final startWeekday = firstDay.weekday; // 1..7
  final daysInMonth = lastDay.day;

  showModalBottomSheet(
    context: context,
    backgroundColor: theme.colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    isScrollControlled: true,
    builder: (ctx) {
      final monthTitle = DateFormat('LLLL yyyy', 'ru_RU').format(monthStart);
      return Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.access_time),
                const SizedBox(width: 8),
                Text(
                  'Отработанные часы — $monthTitle',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(ctx),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Weekday headers
            Row(
              children: [
                for (final w in ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'])
                  Expanded(
                    child: Center(
                      child: Text(
                        w,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.7),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            // Calendar grid
            LayoutBuilder(builder: (ctx, constraints) {
              // Адаптируем высоту строк под мобильные устройства
              final isTight = constraints.maxWidth < 420;
              final aspect = isTight ? 1.0 : 1.2;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 6,
                  childAspectRatio: aspect,
                ),
                itemCount: ((startWeekday + daysInMonth - 1) + 6) ~/ 7 * 7,
                itemBuilder: (_, idx) {
                  final dayNumber =
                      idx - (startWeekday - 1) + 1; // if idx before first, <1
                  if (dayNumber < 1 || dayNumber > daysInMonth) {
                    return Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.03),
                      ),
                    );
                  }
                  final cellDate =
                      DateTime(monthStart.year, monthStart.month, dayNumber);
                  final hours = hoursByDate[cellDate] ?? 0;
                  final hasHours = hours > 0;
                  final bg = hasHours
                      ? Colors.green.withValues(alpha: 0.08)
                      : theme.colorScheme.onSurface.withValues(alpha: 0.03);
                  final fg = hasHours
                      ? Colors.green
                      : theme.colorScheme.onSurface.withValues(alpha: 0.7);
                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: bg,
                      border: Border.all(
                        color: hasHours
                            ? Colors.green.withValues(alpha: 0.25)
                            : theme.colorScheme.onSurface
                                .withValues(alpha: 0.06),
                      ),
                    ),
                    padding: const EdgeInsets.all(6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dayNumber.toString(),
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: fg,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (hasHours)
                          Text(
                            '${hours.toStringAsFixed(hours.truncateToDouble() == hours ? 0 : 1)} ч',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: fg,
                            ),
                          ),
                      ],
                    ),
                  );
                },
              );
            }),
          ],
        ),
      );
    },
  );
}
