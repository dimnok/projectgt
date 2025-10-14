import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:projectgt/presentation/widgets/app_bar_widget.dart';
import 'package:projectgt/presentation/state/profile_state.dart';
import 'package:projectgt/core/di/providers.dart';

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
      backgroundColor: theme.brightness == Brightness.light
          ? const Color(0xFFF2F2F7) // iOS светлый grouped background
          : const Color(0xFF1C1C1E), // iOS темный grouped background
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

    return Container(
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
            icon: Icons.chevron_left,
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
              icon: Icons.chevron_right,
              onPressed: onNextMonth,
            )
          else
            const SizedBox(width: 36), // Для симметрии
        ],
      ),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Текущий период
              _AppleMenuGroup(
                children: [
                  _AppleMenuItem(
                    icon: Icons.access_time,
                    iconColor: Colors.blue,
                    title: 'Отработанные часы',
                    trailing: Text(
                      '${hoursFmt.format(month.hours)} ч',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.7),
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
                  _AppleMenuItem(
                    icon: Icons.work_outline,
                    iconColor: Colors.purple,
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
                  _AppleMenuItem(
                    icon: Icons.card_travel_outlined,
                    iconColor: Colors.orange,
                    title: 'Суточные',
                    trailing: Text(
                      money.format(month.businessTripTotal),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: _colorForAmount(month.businessTripTotal, theme),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    showChevron: false,
                  ),
                  _AppleMenuItem(
                    icon: Icons.emoji_events_outlined,
                    iconColor: Colors.green,
                    title: 'Премии',
                    trailing: Text(
                      money.format(month.bonuses),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: _colorForAmount(month.bonuses, theme),
                        fontWeight: FontWeight.w600,
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
                  _AppleMenuItem(
                    icon: Icons.report_gmailerrorred_outlined,
                    iconColor: Colors.red,
                    title: 'Штрафы',
                    trailing: Text(
                      money.format(month.penalties),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
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
              _AppleMenuGroup(
                children: [
                  _AppleMenuItem(
                    icon: Icons.account_balance_wallet_outlined,
                    iconColor: Colors.teal,
                    title: 'Итого к выплате',
                    trailing: Text(
                      money.format(month.netSalary),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: _colorForAmount(month.netSalary, theme),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    showChevron: false,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Итоги за весь период
              _AppleMenuGroup(
                children: [
                  _AppleMenuItem(
                    icon: Icons.trending_up,
                    iconColor: Colors.green,
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
                  _AppleMenuItem(
                    icon: Icons.payments_outlined,
                    iconColor: Colors.blue,
                    title: 'Общая сумма выплат',
                    trailing: Text(
                      money.format(totals.totalPayouts),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w600,
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
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Общий остаток - отдельная группа
              _AppleMenuGroup(
                children: [
                  _AppleMenuItem(
                    icon: Icons.account_balance_outlined,
                    iconColor: Colors.purple,
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
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}

/// Группа элементов меню в стиле Apple Settings.
class _AppleMenuGroup extends StatelessWidget {
  final List<Widget> children;

  const _AppleMenuGroup({
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: _buildChildrenWithDividers(context),
        ),
      ),
    );
  }

  List<Widget> _buildChildrenWithDividers(BuildContext context) {
    final theme = Theme.of(context);
    final List<Widget> widgets = [];

    for (int i = 0; i < children.length; i++) {
      widgets.add(children[i]);
      if (i < children.length - 1) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(left: 60, right: 16),
            child: Divider(
              height: 1,
              thickness: 1,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
            ),
          ),
        );
      }
    }

    return widgets;
  }
}

/// Элемент меню в стиле Apple Settings.
class _AppleMenuItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final Widget? trailing;
  final bool showChevron;
  final VoidCallback? onTap;

  const _AppleMenuItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.trailing,
    this.showChevron = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Иконка в цветном квадратике
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          // Текст
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          // Trailing виджет или стрелка
          if (trailing != null)
            trailing!
          else if (showChevron)
            Icon(
              Icons.chevron_right,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
              size: 20,
            ),
        ],
      ),
    );

    if (onTap != null) {
      return _IOSTapEffect(
        onTap: onTap!,
        child: content,
      );
    }

    return content;
  }
}

/// Виджет для создания iOS-подобного эффекта затемнения при нажатии.
class _IOSTapEffect extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _IOSTapEffect({
    required this.child,
    required this.onTap,
  });

  @override
  State<_IOSTapEffect> createState() => _IOSTapEffectState();
}

class _IOSTapEffectState extends State<_IOSTapEffect> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        color: _isPressed
            ? theme.colorScheme.onSurface.withValues(alpha: 0.08)
            : Colors.transparent,
        child: widget.child,
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
  final double hourlyRate;
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

  // Обрабатываем часы за месяц в одном проходе
  double monthHours = 0;
  double monthBusinessTrips = 0;
  final Map<DateTime, double> monthHoursByDate = {};

  for (final record in (workHoursResp as List)) {
    final works = record['works'] as Map<String, dynamic>?;
    if (works == null) continue;

    final workDateStr = works['date'] as String?;
    if (workDateStr == null) continue;

    final workDate = DateTime.tryParse(workDateStr);
    if (workDate == null) continue;

    final hours = (record['hours'] as num?)?.toDouble() ?? 0;
    final isInMonth =
        !workDate.isBefore(monthStart) && !workDate.isAfter(monthEnd);

    // Считаем часы за месяц
    if (isInMonth) {
      monthHours += hours;
      final dayKey = DateTime(workDate.year, workDate.month, workDate.day);
      monthHoursByDate[dayKey] = (monthHoursByDate[dayKey] ?? 0) + hours;
    }

    // Рассчитываем командировочные для месяца
    final objectId = works['object_id'] as String?;
    if (isInMonth && objectId != null && objectId.isNotEmpty) {
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
            final minimumHours =
                (rateRecord['minimum_hours'] as num?)?.toDouble() ?? 0.0;
            if (hours >= minimumHours) {
              final rate = (rateRecord['rate'] as num?)?.toDouble() ?? 0;
              monthBusinessTrips += rate;
            }
            break;
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

  // Получаем все ставки командировочных для расчета итогов
  final allBusinessTripRatesResp = await client
      .from('business_trip_rates')
      .select(
          'object_id, rate, valid_from, valid_to, employee_id, minimum_hours')
      .eq('employee_id', employeeId);

  // Обрабатываем все часы за весь период в одном проходе
  double allEarnedBase = 0;
  double allTrips = 0;

  for (final record in (workHoursResp as List)) {
    final works = record['works'] as Map<String, dynamic>?;
    if (works == null) continue;

    final hours = (record['hours'] as num?)?.toDouble() ?? 0;
    allEarnedBase += hours * currentHourlyRate;

    // Рассчитываем командировочные за все время
    final workDateStr = works['date'] as String?;
    final workDate =
        workDateStr != null ? DateTime.tryParse(workDateStr) : null;
    final objectId = works['object_id'] as String?;

    if (workDate != null && objectId != null && objectId.isNotEmpty) {
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
            final minimumHours =
                (rateRecord['minimum_hours'] as num?)?.toDouble() ?? 0.0;
            if (hours >= minimumHours) {
              final rate = (rateRecord['rate'] as num?)?.toDouble() ?? 0;
              allTrips += rate;
            }
            break;
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
