import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:projectgt/presentation/widgets/app_bar_widget.dart';
import 'package:projectgt/presentation/widgets/grouped_menu.dart';
import 'package:projectgt/presentation/state/profile_state.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/features/profile/presentation/widgets/content_constrained_box.dart';
import 'package:projectgt/core/widgets/desktop_dialog_content.dart';
import 'package:projectgt/core/widgets/mobile_bottom_sheet_content.dart';
import 'package:projectgt/core/widgets/gt_buttons.dart';

/// Экран финансовой информации сотрудника.
///
/// Отображает финансовые данные: часы, зарплату, премии, штрафы, суточные и выплаты.
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

    // Проверяем, является ли выбранный месяц текущим
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month, 1);
    final isCurrentMonth = _monthStart.year == currentMonth.year &&
        _monthStart.month == currentMonth.month;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
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
                _MonthNavigationBar(
                  monthStart: _monthStart,
                  isCurrentMonth: isCurrentMonth,
                  onPreviousMonth: () => _shiftMonth(-1),
                  onNextMonth: () => _shiftMonth(1),
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

/// Панель навигации по месяцам в стиле Apple.
class _MonthNavigationBar extends StatelessWidget {
  final DateTime monthStart;
  final bool isCurrentMonth;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;

  const _MonthNavigationBar({
    required this.monthStart,
    required this.isCurrentMonth,
    required this.onPreviousMonth,
    required this.onNextMonth,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final monthTitle = DateFormat('LLLL yyyy', 'ru_RU').format(monthStart);

    final navigationBar = Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Кнопка "Назад"
          _NavigationButton(
            icon: CupertinoIcons.chevron_left,
            onPressed: onPreviousMonth,
          ),
          // Название месяца
          Expanded(
            child: Text(
              monthTitle,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          // Кнопка "Вперед" (скрыта для текущего месяца)
          if (!isCurrentMonth)
            _NavigationButton(
              icon: CupertinoIcons.chevron_right,
              onPressed: onNextMonth,
            )
          else
            const SizedBox(width: 36), // Для симметрии
        ],
      ),
    );

    return ContentConstrainedBox(
      child: navigationBar,
    );
  }
}

/// Кнопка навигации в стиле iOS.
class _NavigationButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _NavigationButton({
    required this.icon,
    required this.onPressed,
  });

  @override
  State<_NavigationButton> createState() => _NavigationButtonState();
}

class _NavigationButtonState extends State<_NavigationButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: _isPressed
              ? theme.colorScheme.primary.withValues(alpha: 0.15)
              : theme.colorScheme.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          widget.icon,
          color: theme.colorScheme.primary,
          size: 20,
        ),
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
        final money = NumberFormat.currency(
            locale: 'ru_RU', symbol: '₽', decimalDigits: 0);
        final hoursFmt = NumberFormat('#,##0.##', 'ru_RU');

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ContentConstrainedBox(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Текущий период
                AppleMenuGroup(
                  children: [
                    AppleMenuItem(
                      icon: CupertinoIcons.clock,
                      iconColor: CupertinoColors.systemBlue,
                      title: 'Отработанные часы',
                      trailing: _buildClickableTrailing(
                        context,
                        Text(
                          '${hoursFmt.format(month.hours)} ч',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                      onTap: () {
                        _showHoursCalendarModal(
                          context: context,
                          monthStart: month.monthStart,
                          hoursByDate: data.monthHoursByDate,
                        );
                      },
                    ),
                    AppleMenuItem(
                      icon: CupertinoIcons.briefcase,
                      iconColor: CupertinoColors.systemPurple,
                      title: 'Заработано (база)',
                      trailing: Text(
                        money.format(month.baseSalary),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: _colorForAmount(month.baseSalary, theme),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      showChevron: false,
                    ),
                    AppleMenuItem(
                      icon: CupertinoIcons.tram_fill,
                      iconColor: CupertinoColors.systemOrange,
                      title: 'Суточные',
                      trailing: Text(
                        money.format(month.businessTripTotal),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color:
                              _colorForAmount(month.businessTripTotal, theme),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      showChevron: false,
                    ),
                    AppleMenuItem(
                      icon: CupertinoIcons.star,
                      iconColor: CupertinoColors.systemGreen,
                      title: 'Премии',
                      trailing: _buildClickableTrailing(
                        context,
                        Text(
                          money.format(month.bonuses),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: _colorForAmount(month.bonuses, theme),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      onTap: () {
                        _showMoneyListModal(
                          context: context,
                          title: 'Премии',
                          records: data.monthBonusRecords,
                          money: money,
                          positive: true,
                          initialMonthStart: month.monthStart,
                        );
                      },
                    ),
                    AppleMenuItem(
                      icon: CupertinoIcons.exclamationmark_triangle,
                      iconColor: CupertinoColors.systemRed,
                      title: 'Штрафы',
                      trailing: _buildClickableTrailing(
                        context,
                        Text(
                          money.format(month.penalties),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.red,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      onTap: () {
                        _showMoneyListModal(
                          context: context,
                          title: 'Штрафы',
                          records: data.monthPenaltyRecords,
                          money: money,
                          positive: false,
                          initialMonthStart: month.monthStart,
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Итого к выплате - отдельная группа
                AppleMenuGroup(
                  children: [
                    AppleMenuItem(
                      icon: CupertinoIcons.creditcard,
                      iconColor: CupertinoColors.systemTeal,
                      title: 'Начислено за месяц',
                      trailing: Text(
                        money.format(month.netSalary),
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: _colorForAmount(month.netSalary, theme),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      showChevron: false,
                    ),
                    AppleMenuItem(
                      icon: CupertinoIcons.checkmark_circle,
                      iconColor: CupertinoColors.systemBlue,
                      title: 'Выплачено',
                      trailing: Text(
                        money.format(month.paid),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.7),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      showChevron: false,
                    ),
                    AppleMenuItem(
                      icon: CupertinoIcons.money_dollar_circle,
                      iconColor: CupertinoColors.systemPurple,
                      title: 'Остаток к выплате',
                      trailing: Text(
                        money.format(month.balance),
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: _colorForAmount(month.balance, theme),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      showChevron: false,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Итоги за весь период
                AppleMenuGroup(
                  children: [
                    AppleMenuItem(
                      icon: CupertinoIcons.graph_square,
                      iconColor: CupertinoColors.systemGreen,
                      title: 'Общая сумма заработанного',
                      trailing: Text(
                        money.format(totals.totalEarned),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: _colorForAmount(totals.totalEarned, theme),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      showChevron: false,
                    ),
                    AppleMenuItem(
                      icon: CupertinoIcons.money_dollar,
                      iconColor: CupertinoColors.systemBlue,
                      title: 'Общая сумма выплат',
                      trailing: _buildClickableTrailing(
                        context,
                        Text(
                          money.format(totals.totalPayouts),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.7),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      onTap: () {
                        _showMoneyListModal(
                          context: context,
                          title: 'Выплаты (все)',
                          records: data.allPayoutRecords,
                          money: money,
                          positive: false,
                          initialMonthStart: month.monthStart,
                          useMonthFilter: false,
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Общий остаток - отдельная группа
                AppleMenuGroup(
                  children: [
                    AppleMenuItem(
                      icon: CupertinoIcons.home,
                      iconColor: CupertinoColors.systemPurple,
                      title: 'Общий остаток',
                      trailing: Text(
                        money.format(totals.totalBalance),
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: _colorForAmount(totals.totalBalance, theme),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      showChevron: false,
                    ),
                  ],
                ),
                const SizedBox(
                  height: 24,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

Color _colorForAmount(double amount, ThemeData theme) {
  if (amount > 0) return theme.colorScheme.primary;
  if (amount < 0) return theme.colorScheme.error;
  return theme.colorScheme.onSurface;
}

Widget _buildClickableTrailing(BuildContext context, Widget content) {
  final theme = Theme.of(context);
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      content,
      const SizedBox(width: 8),
      Icon(
        CupertinoIcons.chevron_right,
        size: 16,
        color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
      ),
    ],
  );
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
  bool useMonthFilter = true,
}) {
  final isDesktop = kIsWeb ||
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.linux;

  Widget buildContent(BuildContext ctx) {
    // Локальный месяц показа
    DateTime current = initialMonthStart != null
        ? DateTime(initialMonthStart.year, initialMonthStart.month, 1)
        : (records.isNotEmpty
            ? DateTime(records.first.date.year, records.first.date.month, 1)
            : DateTime.now());

    List<_MoneyRecord> filterByMonth(DateTime m) {
      if (!useMonthFilter) return records;
      final start = DateTime(m.year, m.month, 1);
      final end = DateTime(m.year, m.month + 1, 0);
      return records
          .where((r) => !r.date.isBefore(start) && !r.date.isAfter(end))
          .toList();
    }

    return StatefulBuilder(builder: (ctx, setState) {
      final filtered = filterByMonth(current);
      final monthTitle = DateFormat('LLLL yyyy', 'ru_RU').format(current);
      final theme = Theme.of(ctx);

      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (useMonthFilter) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => setState(() {
                    current = DateTime(current.year, current.month - 1, 1);
                  }),
                  icon: const Icon(CupertinoIcons.chevron_left),
                ),
                Text(
                  monthTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() {
                    current = DateTime(current.year, current.month + 1, 1);
                  }),
                  icon: const Icon(CupertinoIcons.chevron_right),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          if (filtered.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'Записей нет',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                physics: const ClampingScrollPhysics(),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => Divider(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
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
      );
    });
  }

  if (isDesktop) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(24),
        child: DesktopDialogContent(
          title: title,
          footer: GTPrimaryButton(
            text: 'Закрыть',
            onPressed: () => Navigator.of(context).pop(),
          ),
          child: buildContent(context),
        ),
      ),
    );
  } else {
    showModalBottomSheet(
      context: context,
      constraints: const BoxConstraints(maxWidth: 640),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => MobileBottomSheetContent(
        title: title,
        footer: GTPrimaryButton(
          text: 'Закрыть',
          onPressed: () => Navigator.of(ctx).pop(),
        ),
        child: buildContent(ctx),
      ),
    );
  }
}

class _FinancialMonthSummary {
  final DateTime monthStart;
  final double hours;
  final double hourlyRate;
  final double baseSalary;
  final double bonuses;
  final double penalties;
  final double businessTripTotal;
  final double netSalary;
  final double paid;
  final double balance;

  const _FinancialMonthSummary({
    required this.monthStart,
    required this.hours,
    required this.hourlyRate,
    required this.baseSalary,
    required this.bonuses,
    required this.penalties,
    required this.businessTripTotal,
    required this.netSalary,
    required this.paid,
    required this.balance,
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

class _MonthCalculation {
  double hours = 0;
  double baseSalary = 0;
  double businessTrip = 0;
  double bonuses = 0;
  double penalties = 0;
  double paid = 0;
  final Map<DateTime, double> hoursByDate = {};

  double get netSalary => baseSalary + businessTrip + bonuses - penalties;
  double get balance => netSalary - paid;
}

final _financialInfoProvider =
    FutureProvider.family<_FinancialInfoData, _FinancialArgs>(
        (ref, args) async {
  final client = ref.watch(supabaseClientProvider);

  // Выбранный месяц
  final monthStart = DateTime(args.monthStart.year, args.monthStart.month, 1);
  final monthEnd = DateTime(args.monthStart.year, args.monthStart.month + 1, 0);
  final employeeId = args.employeeId;

  // 1. Загружаем все данные параллельно
  final results = await Future.wait([
    // [0] work_hours (только закрытые смены)
    client.from('work_hours').select('''
        hours,
        works!inner(date, object_id, status)
      ''').eq('employee_id', employeeId).eq('works.status', 'closed'),

    // [1] employee_rates (история ставок)
    client
        .from('employee_rates')
        .select('hourly_rate, valid_from, valid_to')
        .eq('employee_id', employeeId)
        .order('valid_from', ascending: false),

    // [2] business_trip_rates (ставки командировочных)
    client
        .from('business_trip_rates')
        .select(
            'object_id, rate, valid_from, valid_to, employee_id, minimum_hours')
        .eq('employee_id', employeeId),

    // [3] payroll_bonus
    client
        .from('payroll_bonus')
        .select('amount, date, created_at, reason')
        .eq('employee_id', employeeId),

    // [4] payroll_penalty
    client
        .from('payroll_penalty')
        .select('amount, date, reason')
        .eq('employee_id', employeeId),

    // [5] payroll_payout (для FIFO распределения сортируем по дате)
    client
        .from('payroll_payout')
        .select('amount, payout_date, comment')
        .eq('employee_id', employeeId)
        .order('payout_date', ascending: true),
  ]);

  final workHoursResp = results[0] as List;
  final employeeRatesResp = results[1] as List;
  final businessTripRatesResp = results[2] as List;
  final bonusesResp = results[3] as List;
  final penaltiesResp = results[4] as List;
  final payoutsResp = results[5] as List;

  // Текущая ставка для отображения (берем самую свежую активную)
  final now = DateTime.now();
  double currentHourlyRate = 0;
  for (final r in employeeRatesResp) {
    final validFrom = DateTime.tryParse(r['valid_from'] as String? ?? '');
    final validToStr = r['valid_to'] as String?;
    final validTo = validToStr != null ? DateTime.tryParse(validToStr) : null;
    if (validFrom != null &&
        !validFrom.isAfter(now) &&
        (validTo == null || !validTo.isBefore(now))) {
      currentHourlyRate = (r['hourly_rate'] as num).toDouble();
      break;
    }
  }
  if (currentHourlyRate == 0 && employeeRatesResp.isNotEmpty) {
    currentHourlyRate =
        (employeeRatesResp.first['hourly_rate'] as num).toDouble();
  }

  // 2. Агрегируем данные по месяцам
  final Map<int, _MonthCalculation> monthlyCalculations = {};

  int getMonthKey(DateTime d) => d.year * 100 + d.month;

  // 2.1 Обработка часов (Базовая ЗП + Командировочные)
  for (final record in workHoursResp) {
    final works = record['works'] as Map<String, dynamic>?;
    if (works == null) continue;
    final workDateStr = works['date'] as String?;
    if (workDateStr == null) continue;
    final workDate = DateTime.tryParse(workDateStr);
    if (workDate == null) continue;

    final hours = (record['hours'] as num?)?.toDouble() ?? 0;
    final monthKey = getMonthKey(workDate);

    monthlyCalculations.putIfAbsent(monthKey, () => _MonthCalculation());
    final monthData = monthlyCalculations[monthKey]!;

    monthData.hours += hours;

    // Собираем статистику по дням только для целевого месяца
    if (monthKey == getMonthKey(monthStart)) {
      final dayKey = DateTime(workDate.year, workDate.month, workDate.day);
      monthData.hoursByDate[dayKey] =
          (monthData.hoursByDate[dayKey] ?? 0) + hours;
    }

    // Находим историческую ставку
    double rateForDate = 0;
    for (final r in employeeRatesResp) {
      final validFrom = DateTime.tryParse(r['valid_from'] as String? ?? '');
      final validToStr = r['valid_to'] as String?;
      final validTo = validToStr != null ? DateTime.tryParse(validToStr) : null;
      if (validFrom != null &&
          !workDate.isBefore(validFrom) &&
          (validTo == null || !workDate.isAfter(validTo))) {
        rateForDate = (r['hourly_rate'] as num).toDouble();
        break;
      }
    }
    // Fallback на текущую, если историческая не найдена
    if (rateForDate == 0) rateForDate = currentHourlyRate;

    monthData.baseSalary += hours * rateForDate;

    // Командировочные
    final objectId = works['object_id'] as String?;
    if (objectId != null && objectId.isNotEmpty) {
      for (final rateRecord in businessTripRatesResp) {
        if (rateRecord['object_id'] == objectId) {
          final validFrom =
              DateTime.tryParse(rateRecord['valid_from'] as String? ?? '');
          final validToStr = rateRecord['valid_to'] as String?;
          final validTo =
              validToStr != null ? DateTime.tryParse(validToStr) : null;

          if (validFrom != null &&
              !workDate.isBefore(validFrom) &&
              (validTo == null || !workDate.isAfter(validTo))) {
            final minHours =
                (rateRecord['minimum_hours'] as num?)?.toDouble() ?? 0.0;
            if (hours >= minHours) {
              monthData.businessTrip += (rateRecord['rate'] as num).toDouble();
            }
            break;
          }
        }
      }
    }
  }

  // 2.2 Обработка премий
  for (final b in bonusesResp) {
    final dateStr = (b['date'] ?? b['created_at']) as String?;
    final d = dateStr != null ? DateTime.tryParse(dateStr) : null;
    if (d != null) {
      final monthKey = getMonthKey(d);
      monthlyCalculations.putIfAbsent(monthKey, () => _MonthCalculation());
      monthlyCalculations[monthKey]!.bonuses += (b['amount'] as num).toDouble();
    }
  }

  // 2.3 Обработка штрафов
  for (final p in penaltiesResp) {
    final dateStr = p['date'] as String?;
    final d = dateStr != null ? DateTime.tryParse(dateStr) : null;
    if (d != null) {
      final monthKey = getMonthKey(d);
      monthlyCalculations.putIfAbsent(monthKey, () => _MonthCalculation());
      monthlyCalculations[monthKey]!.penalties +=
          (p['amount'] as num).toDouble();
    }
  }

  // 3. Распределение выплат (FIFO)
  double totalPayoutsRemaining = 0;
  final allPayoutRecords = <_MoneyRecord>[];

  for (final p in payoutsResp) {
    final amount = (p['amount'] as num).toDouble();
    totalPayoutsRemaining += amount;
    allPayoutRecords.add(_MoneyRecord(
      date: DateTime.tryParse((p['payout_date']) as String) ?? DateTime.now(),
      amount: amount,
      comment: (p['comment'] as String?) ?? '',
    ));
  }

  // Сортируем месяцы от старых к новым
  final sortedMonthKeys = monthlyCalculations.keys.toList()..sort();

  double totalEarnedAllTime = 0;

  for (final key in sortedMonthKeys) {
    final data = monthlyCalculations[key]!;
    final net = data.netSalary;
    totalEarnedAllTime += net;

    if (net > 0) {
      if (totalPayoutsRemaining >= net) {
        data.paid = net;
        totalPayoutsRemaining -= net;
      } else {
        data.paid = totalPayoutsRemaining;
        totalPayoutsRemaining = 0;
      }
    }
  }

  // 4. Формируем данные для целевого месяца
  final targetKey = getMonthKey(monthStart);
  final targetData = monthlyCalculations[targetKey] ?? _MonthCalculation();

  // Списки для UI (текущий месяц)
  final monthBonusRecords = <_MoneyRecord>[];
  for (final b in bonusesResp) {
    final dateStr = (b['date'] ?? b['created_at']) as String?;
    final d = dateStr != null ? DateTime.tryParse(dateStr) : null;
    if (d != null && !d.isBefore(monthStart) && !d.isAfter(monthEnd)) {
      monthBonusRecords.add(_MoneyRecord(
        date: d,
        amount: (b['amount'] as num).toDouble(),
        comment: (b['reason'] as String?) ?? '',
      ));
    }
  }

  final monthPenaltyRecords = <_MoneyRecord>[];
  for (final p in penaltiesResp) {
    final dateStr = p['date'] as String?;
    final d = dateStr != null ? DateTime.tryParse(dateStr) : null;
    if (d != null && !d.isBefore(monthStart) && !d.isAfter(monthEnd)) {
      monthPenaltyRecords.add(_MoneyRecord(
        date: d,
        amount: (p['amount'] as num).toDouble(),
        comment: (p['reason'] as String?) ?? '',
      ));
    }
  }

  double totalPayoutsAllTime = 0;
  for (final p in allPayoutRecords) {
    totalPayoutsAllTime += p.amount;
  }

  final totals = _FinancialTotals(
    totalEarned: totalEarnedAllTime,
    totalPayouts: totalPayoutsAllTime,
    totalBalance: totalEarnedAllTime - totalPayoutsAllTime,
  );

  return _FinancialInfoData(
    month: _FinancialMonthSummary(
      monthStart: monthStart,
      hours: targetData.hours,
      hourlyRate: currentHourlyRate,
      baseSalary: targetData.baseSalary,
      bonuses: targetData.bonuses,
      penalties: targetData.penalties,
      businessTripTotal: targetData.businessTrip,
      netSalary: targetData.netSalary,
      paid: targetData.paid,
      balance: targetData.balance,
    ),
    totals: totals,
    monthBonusRecords: monthBonusRecords,
    monthPenaltyRecords: monthPenaltyRecords,
    monthHoursByDate: targetData.hoursByDate,
    allPayoutRecords: allPayoutRecords.reversed.toList(), // Новые сверху
  );
});

void _showHoursCalendarModal({
  required BuildContext context,
  required DateTime monthStart,
  required Map<DateTime, double> hoursByDate,
}) {
  final isDesktop = kIsWeb ||
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.linux;

  Widget buildContent(BuildContext ctx) {
    final theme = Theme.of(ctx);
    final firstDay = DateTime(monthStart.year, monthStart.month, 1);
    final lastDay = DateTime(monthStart.year, monthStart.month + 1, 0);
    // Flutter's DateTime weekday: Monday=1..Sunday=7. We'll start grid from Mon.
    final startWeekday = firstDay.weekday; // 1..7
    final daysInMonth = lastDay.day;
    final monthTitle = DateFormat('LLLL yyyy', 'ru_RU').format(monthStart);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          monthTitle,
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        // Weekday headers
        Row(
          children: [
            for (final w in ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'])
              Expanded(
                child: Center(
                  child: Text(
                    w,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
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
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.03),
                  ),
                );
              }
              final cellDate =
                  DateTime(monthStart.year, monthStart.month, dayNumber);
              final hours = hoursByDate[cellDate] ?? 0;
              final hasHours = hours > 0;
              final bg = hasHours
                  ? CupertinoColors.systemGreen.withValues(alpha: 0.08)
                  : theme.colorScheme.onSurface.withValues(alpha: 0.03);
              final fg = hasHours
                  ? CupertinoColors.systemGreen
                  : theme.colorScheme.onSurface.withValues(alpha: 0.7);
              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: bg,
                  border: Border.all(
                    color: hasHours
                        ? CupertinoColors.systemGreen.withValues(alpha: 0.25)
                        : theme.colorScheme.onSurface.withValues(alpha: 0.06),
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
    );
  }

  if (isDesktop) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(24),
        child: DesktopDialogContent(
          title: 'Отработанные часы',
          footer: GTPrimaryButton(
            text: 'Закрыть',
            onPressed: () => Navigator.of(context).pop(),
          ),
          child: buildContent(context),
        ),
      ),
    );
  } else {
    showModalBottomSheet(
      context: context,
      constraints: const BoxConstraints(maxWidth: 640),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => MobileBottomSheetContent(
        title: 'Отработанные часы',
        footer: GTPrimaryButton(
          text: 'Закрыть',
          onPressed: () => Navigator.of(ctx).pop(),
        ),
        child: buildContent(ctx),
      ),
    );
  }
}
