import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/payroll_providers.dart';
import '../../../../presentation/state/employee_state.dart';
import 'package:projectgt/features/roles/presentation/widgets/permission_guard.dart';
import 'package:projectgt/core/widgets/gt_buttons.dart';
import 'package:projectgt/core/utils/responsive_utils.dart';
import 'payroll_payout_form_modal.dart';
import 'payroll_payout_table_view.dart';
import 'payroll_search_action.dart';
import 'package:projectgt/core/widgets/gt_month_picker.dart';
import 'package:projectgt/core/widgets/gt_object_picker.dart';
import '../providers/payroll_filter_providers.dart';
import '../utils/payroll_filter_helpers.dart';

/// Таблица всех выплат по ФОТ.
///
/// Использует [PayrollPayoutTableView] на базе [GTAdaptiveTable] для унификации стиля.
class PayrollPayoutTableWidget extends ConsumerWidget {
  /// Конструктор [PayrollPayoutTableWidget].
  const PayrollPayoutTableWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final employeeState = ref.watch(employeeProvider);
    final payoutsAsync = ref.watch(filteredPayrollPayoutsProvider);
    final searchQuery = ref.watch(payrollSearchQueryProvider);
    final filterState = ref.watch(payrollFilterProvider);
    final isDesktop = ResponsiveUtils.isDesktop(context);

    final selectedDate =
        DateTime(filterState.selectedYear, filterState.selectedMonth);

    // Проверяем, применен ли фильтр по периоду
    final now = DateTime.now();
    final isPeriodFiltered = filterState.selectedYear != now.year ||
        filterState.selectedMonth != now.month;

    final tableTitle = isPeriodFiltered
        ? 'Выплаты за ${DateFormat.yMMMM('ru').format(selectedDate)}'
        : 'Выплаты (все)';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              tableTitle,
              style: theme.textTheme.headlineSmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (isDesktop) ...[
              const SizedBox(width: 16),
              GTMonthPicker(
                selectedDate: selectedDate,
                onPrevious: () {
                  final prev =
                      DateTime(selectedDate.year, selectedDate.month - 1);
                  ref
                      .read(payrollFilterProvider.notifier)
                      .setYearAndMonth(prev.year, prev.month);
                },
                onNext: () {
                  final next =
                      DateTime(selectedDate.year, selectedDate.month + 1);
                  ref
                      .read(payrollFilterProvider.notifier)
                      .setYearAndMonth(next.year, next.month);
                },
                onTap: () => PayrollFilterHelpers.showMonthSelection(
                    context, ref, selectedDate),
              ),
              const SizedBox(width: 8),
              GTObjectPicker(
                objectName: PayrollFilterHelpers.getObjectName(
                    ref, filterState.selectedObjectIds),
                onPrevious: () => PayrollFilterHelpers.handleObjectSwitch(
                    ref, filterState.selectedObjectIds, -1),
                onNext: () => PayrollFilterHelpers.handleObjectSwitch(
                    ref, filterState.selectedObjectIds, 1),
                onTap: () =>
                    PayrollFilterHelpers.showObjectSelection(context, ref),
                enabled: false,
              ),
            ],
            const Spacer(),
            PermissionGuard(
              module: 'payroll',
              permission: 'create',
              child: GTTextButton(
                text: 'Добавить',
                icon: Icons.add_circle_outline,
                onPressed: () {
                  final isDesktop = ResponsiveUtils.isDesktop(context);
                  if (isDesktop) {
                    showDialog(
                      context: context,
                      builder: (ctx) => const PayrollPayoutFormModal(),
                    );
                  } else {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (ctx) => const PayrollPayoutFormModal(),
                    );
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: payoutsAsync.when(
            data: (allPayouts) {
              final payouts = filterPayoutsByEmployeeName(
                allPayouts,
                searchQuery,
                ref,
              );
              if (payouts.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.payment_outlined,
                        size: 64,
                        color: theme.colorScheme.outline.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        isPeriodFiltered
                            ? 'Нет выплат за ${DateFormat.yMMMM('ru').format(selectedDate)}'
                            : 'Нет выплат',
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          'За выбранный период записей не найдено. Попробуйте выбрать другой месяц или добавьте новую операцию.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return PayrollPayoutTableView(
                payouts: payouts,
                employees: employeeState.employees,
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => Center(
              child: Text('Ошибка загрузки выплат: $e'),
            ),
          ),
        ),
      ],
    );
  }
}
