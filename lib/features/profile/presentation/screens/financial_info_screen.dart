import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/presentation/widgets/app_bar_widget.dart';
import 'package:projectgt/presentation/widgets/grouped_menu.dart';
import 'package:projectgt/presentation/state/profile_state.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/features/profile/presentation/widgets/content_constrained_box.dart';
import 'package:projectgt/core/widgets/desktop_dialog_content.dart';
import 'package:projectgt/core/widgets/mobile_bottom_sheet_content.dart';
import 'package:projectgt/core/widgets/gt_buttons.dart';
import 'package:projectgt/features/fot/presentation/services/payroll_pdf_service.dart';
import 'package:projectgt/features/fot/presentation/services/employee_financial_report_service.dart';
import 'package:projectgt/domain/entities/employee.dart';
import 'package:projectgt/data/models/employee_model.dart';
import 'package:projectgt/core/utils/snackbar_utils.dart';
import 'package:projectgt/features/company/presentation/providers/company_providers.dart';
import 'package:projectgt/features/fot/presentation/providers/payroll_providers.dart';
import 'package:collection/collection.dart';
import 'package:logger/logger.dart';

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
    final isCurrentMonth =
        _monthStart.year == currentMonth.year &&
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
    final monthTitle = formatMonthYear(monthStart);

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

    return ContentConstrainedBox(child: navigationBar);
  }
}

/// Кнопка навигации в стиле iOS.
class _NavigationButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _NavigationButton({required this.icon, required this.onPressed});

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
        child: Icon(widget.icon, color: theme.colorScheme.primary, size: 20),
      ),
    );
  }
}

class _FinancialInfoBody extends ConsumerWidget {
  final String employeeId;
  final DateTime monthStart;
  const _FinancialInfoBody({
    required this.employeeId,
    required this.monthStart,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(
      _financialInfoProvider(
        _FinancialArgs(employeeId: employeeId, monthStart: monthStart),
      ),
    );
    final theme = Theme.of(context);
    return asyncData.when(
      loading: () => const Center(child: CupertinoActivityIndicator()),
      error: (e, st) => Center(
        child: SelectableText(
          'Ошибка загрузки финансовых данных:\n$e',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.error,
          ),
        ),
      ),
      data: (data) {
        final month = data.month;
        final totals = data.totals;

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
                          '${formatQuantity(month.hours)} ч',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.7,
                            ),
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
                        formatCurrency(month.baseSalary),
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
                        formatCurrency(month.businessTripTotal),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: _colorForAmount(
                            month.businessTripTotal,
                            theme,
                          ),
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
                          formatCurrency(month.bonuses),
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
                          formatCurrency(month.penalties),
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
                        formatCurrency(month.netSalary),
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
                        formatCurrency(month.paid),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.7,
                          ),
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
                        formatCurrency(month.balance),
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
                        formatCurrency(totals.totalEarned),
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
                          formatCurrency(totals.totalPayouts),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.7,
                            ),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      onTap: () {
                        _showMoneyListModal(
                          context: context,
                          title: 'Выплаты (все)',
                          records: data.allPayoutRecords,
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
                        formatCurrency(totals.totalBalance),
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: _colorForAmount(totals.totalBalance, theme),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      showChevron: false,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Кнопка скачивания финансового отчёта
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  child: GTPrimaryButton(
                    text: 'Скачать финансовый отчёт за ${monthStart.year} год',
                    onPressed: () => _generateFinancialReport(
                      context: context,
                      ref: ref,
                      year: monthStart.year,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
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
  const _MoneyRecord({
    required this.date,
    required this.amount,
    required this.comment,
  });
}

void _showMoneyListModal({
  required BuildContext context,
  required String title,
  required List<_MoneyRecord> records,
  required bool positive,
  DateTime? initialMonthStart,
  bool useMonthFilter = true,
}) {
  final isDesktop =
      kIsWeb ||
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

    return StatefulBuilder(
      builder: (ctx, setState) {
        final filtered = filterByMonth(current);
        final monthTitle = formatMonthYear(current);
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
                    final dateStr = formatRuDate(r.date);
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
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.7,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                formatCurrency(r.amount),
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
      },
    );
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

/// Метод генерации финансового отчёта за год для текущего пользователя.
Future<void> _generateFinancialReport({
  required BuildContext context,
  required WidgetRef ref,
  required int year,
}) async {
  final profileState = ref.read(currentUserProfileProvider);
  final employeeId = (profileState.profile?.object != null)
      ? (profileState.profile!.object!['employee_id'] as String?)
      : null;

  if (employeeId == null || employeeId.isEmpty) {
    SnackBarUtils.showError(context, 'Нет привязанного сотрудника');
    return;
  }

  // 1. Загружаем данные сотрудника для отчета
  Employee? employee;
  try {
    final employeeResponse = await ref
        .read(supabaseClientProvider)
        .from('employees')
        .select()
        .eq('id', employeeId)
        .maybeSingle();
    if (employeeResponse != null) {
      employee = EmployeeModel.fromJson(employeeResponse).toDomain();
    }
  } catch (e) {
    Logger().e('Ошибка загрузки сотрудника: $e');
  }

  // Фоллбек если не удалось загрузить полную сущность
  employee ??= Employee(
    id: employeeId,
    companyId: '',
    lastName: profileState.profile?.fullName?.split(' ').first ?? 'Сотрудник',
    firstName: '',
  );

  if (!context.mounted) return;
  SnackBarUtils.showInfo(context, 'Формирование отчёта за $year год...');

  try {
    // 2. Используем общий сервис для сбора данных (учитывает смены + табель + RPC)
    final reportService = ref.read(employeeFinancialReportServiceProvider);
    final monthlyData = await reportService.getYearlyReportData(
      employeeId: employeeId,
      year: year,
    );

    if (monthlyData.isEmpty) {
      if (context.mounted) {
        SnackBarUtils.showWarning(context, 'Нет данных за $year год');
      }
      return;
    }

    if (!context.mounted) return;

    // 3. Используем PayrollPdfService из модуля FOT
    final pdfService = PayrollPdfService();
    await pdfService.generateEmployeeYearlyReport(
      employee: employee,
      year: year,
      monthlyData: monthlyData,
    );

    if (context.mounted) {
      SnackBarUtils.showSuccess(context, 'Отчёт сформирован');
    }
  } catch (e, st) {
    Logger().e('Ошибка формирования отчёта', error: e, stackTrace: st);
    if (context.mounted) SnackBarUtils.showError(context, 'Ошибка: $e');
  }
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
    FutureProvider.family<_FinancialInfoData, _FinancialArgs>((
      ref,
      args,
    ) async {
      final client = ref.watch(supabaseClientProvider);
      final activeCompanyId = ref.watch(activeCompanyIdProvider);

      final monthStart = DateTime(
        args.monthStart.year,
        args.monthStart.month,
        1,
      );
      final monthEnd = DateTime(
        args.monthStart.year,
        args.monthStart.month + 1,
        0,
      );
      final employeeId = args.employeeId;

      // 1. Загружаем расчет ФОТ через RPC (учитывает все виды часов)
      final payrollResponse = await client.rpc(
        'calculate_payroll_for_month',
        params: {
          'p_year': args.monthStart.year,
          'p_month': args.monthStart.month,
          'p_company_id': activeCompanyId,
        },
      );

      final monthRow = (payrollResponse as List).firstWhereOrNull(
        (row) => row['employee_id'] == employeeId,
      );

      // 2. Загружаем детализацию для UI (премии, штрафы, часы по дням)
      final results = await Future.wait([
        client
            .from('payroll_bonus')
            .select('amount, date, created_at, reason')
            .eq('employee_id', employeeId),
        client
            .from('payroll_penalty')
            .select('amount, date, reason')
            .eq('employee_id', employeeId),
        client
            .from('payroll_payout')
            .select('amount, payout_date, comment')
            .eq('employee_id', employeeId)
            .order('payout_date', ascending: true),
        // Часы по дням (смены + табель)
        client
            .from('work_hours')
            .select('hours, works!inner(date, status)')
            .eq('employee_id', employeeId)
            .eq('works.status', 'closed')
            .gte('works.date', monthStart.toIso8601String())
            .lte('works.date', monthEnd.toIso8601String()),
        client
            .from('employee_attendance')
            .select('hours, date')
            .eq('employee_id', employeeId)
            .gte('date', monthStart.toIso8601String())
            .lte('date', monthEnd.toIso8601String()),
      ]);

      final bonusesResp = results[0] as List;
      final penaltiesResp = results[1] as List;
      final payoutsResp = results[2] as List;
      final workHoursResp = results[3] as List;
      final attendanceResp = results[4] as List;

      // 3. Получаем выплаты за этот месяц через FIFO
      final fifoData = await ref.watch(
        payoutsByEmployeeAndMonthFIFOProvider(monthStart.year).future,
      );
      final employeeFIFO = fifoData[employeeId];
      final monthPaid = employeeFIFO?.payouts[monthStart.month] ?? 0.0;
      final monthBalance = employeeFIFO?.balances[monthStart.month] ?? 0.0;

      // 4. Формируем итоги (Totals) через RPC для точности
      final totalsResponse = await client.rpc(
        'calculate_employee_balances_before_date',
        params: {
          'p_before_date': DateTime(
            DateTime.now().year + 1,
          ).toIso8601String(), // До конца текущего года или просто "сейчас"
          'p_company_id': activeCompanyId,
        },
      );
      final totalRow = (totalsResponse as List).firstWhereOrNull(
        (row) => row['employee_id'] == employeeId,
      );

      // Расчет часов по дням
      final Map<DateTime, double> hoursByDate = {};
      for (final row in workHoursResp) {
        final d = DateTime.parse(row['works']['date']);
        final day = DateTime(d.year, d.month, d.day);
        hoursByDate[day] =
            (hoursByDate[day] ?? 0) + (row['hours'] as num).toDouble();
      }
      for (final row in attendanceResp) {
        final d = DateTime.parse(row['date']);
        final day = DateTime(d.year, d.month, d.day);
        hoursByDate[day] =
            (hoursByDate[day] ?? 0) + (row['hours'] as num).toDouble();
      }

      // Списки для модалок
      final monthBonusRecords = bonusesResp
          .where((b) {
            final d = DateTime.tryParse(
              (b['date'] ?? b['created_at']) as String,
            );
            return d != null && !d.isBefore(monthStart) && !d.isAfter(monthEnd);
          })
          .map(
            (b) => _MoneyRecord(
              date: DateTime.parse((b['date'] ?? b['created_at']) as String),
              amount: (b['amount'] as num).toDouble(),
              comment: (b['reason'] as String?) ?? '',
            ),
          )
          .toList();

      final monthPenaltyRecords = penaltiesResp
          .where((p) {
            final d = DateTime.tryParse(p['date'] as String);
            return d != null && !d.isBefore(monthStart) && !d.isAfter(monthEnd);
          })
          .map(
            (p) => _MoneyRecord(
              date: DateTime.parse(p['date'] as String),
              amount: (p['amount'] as num).toDouble(),
              comment: (p['reason'] as String?) ?? '',
            ),
          )
          .toList();

      final allPayoutRecords = payoutsResp.reversed
          .map(
            (p) => _MoneyRecord(
              date: DateTime.parse(p['payout_date'] as String),
              amount: (p['amount'] as num).toDouble(),
              comment: (p['comment'] as String?) ?? '',
            ),
          )
          .toList();

      final netSalary = (monthRow?['net_salary'] as num?)?.toDouble() ?? 0;

      return _FinancialInfoData(
        month: _FinancialMonthSummary(
          monthStart: monthStart,
          hours: (monthRow?['total_hours'] as num?)?.toDouble() ?? 0,
          hourlyRate:
              (monthRow?['current_hourly_rate'] as num?)?.toDouble() ?? 0,
          baseSalary: (monthRow?['base_salary'] as num?)?.toDouble() ?? 0,
          bonuses: (monthRow?['bonuses_total'] as num?)?.toDouble() ?? 0,
          penalties: (monthRow?['penalties_total'] as num?)?.toDouble() ?? 0,
          businessTripTotal:
              (monthRow?['business_trip_total'] as num?)?.toDouble() ?? 0,
          netSalary: netSalary,
          paid: monthPaid,
          balance: monthBalance,
        ),
        totals: _FinancialTotals(
          totalEarned: (totalRow?['accruals_sum'] as num?)?.toDouble() ?? 0,
          totalPayouts: (totalRow?['payouts_sum'] as num?)?.toDouble() ?? 0,
          totalBalance: (totalRow?['balance'] as num?)?.toDouble() ?? 0,
        ),
        monthBonusRecords: monthBonusRecords,
        monthPenaltyRecords: monthPenaltyRecords,
        monthHoursByDate: hoursByDate,
        allPayoutRecords: allPayoutRecords,
      );
    });

void _showHoursCalendarModal({
  required BuildContext context,
  required DateTime monthStart,
  required Map<DateTime, double> hoursByDate,
}) {
  final isDesktop =
      kIsWeb ||
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
    final monthTitle = formatMonthYear(monthStart);

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
        LayoutBuilder(
          builder: (ctx, constraints) {
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
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.03,
                      ),
                    ),
                  );
                }
                final cellDate = DateTime(
                  monthStart.year,
                  monthStart.month,
                  dayNumber,
                );
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
          },
        ),
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
