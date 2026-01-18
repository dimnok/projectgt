import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/penalty_providers.dart' show filteredPenaltiesProvider;
import '../providers/payroll_filter_providers.dart';
import '../../../../presentation/state/employee_state.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/features/roles/presentation/widgets/permission_guard.dart';
import 'package:projectgt/core/widgets/gt_buttons.dart';
import '../../domain/entities/payroll_transaction.dart';
import 'package:projectgt/core/utils/responsive_utils.dart';
import 'package:projectgt/core/widgets/gt_month_picker.dart';
import 'package:projectgt/core/widgets/gt_object_picker.dart';
import '../utils/payroll_filter_helpers.dart';
import 'payroll_transaction_form_modal.dart';
import 'payroll_search_action.dart';
import 'payroll_penalty_table_view.dart';

/// Виджет для отображения таблицы штрафов сотрудников за текущий месяц в модуле ФОТ.
///
/// Использует [PayrollPenaltyTableView] на базе [GTAdaptiveTable] для унификации стиля.
class PayrollPenaltyTableWidget extends ConsumerWidget {
  /// Конструктор [PayrollPenaltyTableWidget].
  const PayrollPenaltyTableWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final allPenalties = ref.watch(filteredPenaltiesProvider);
    final searchQuery = ref.watch(payrollSearchQueryProvider);

    // Применяем фильтрацию по поисковому запросу
    final penalties = filterTransactionsByEmployeeName(
      allPenalties,
      searchQuery,
      ref,
    );

    final employeeState = ref.watch(employeeProvider);
    final objectState = ref.watch(objectProvider);
    final filterState = ref.watch(payrollFilterProvider);

    // Проверяем, применен ли фильтр по периоду
    final now = DateTime.now();
    final isPeriodFiltered = filterState.selectedYear != now.year ||
        filterState.selectedMonth != now.month;

    final monthDate =
        DateTime(filterState.selectedYear, filterState.selectedMonth);
    final isDesktop = ResponsiveUtils.isDesktop(context);
    final isMobile = ResponsiveUtils.isMobile(context);

    final tableTitle = isPeriodFiltered
        ? 'Штрафы за ${DateFormat.yMMMM('ru').format(monthDate)}'
        : 'Штрафы (все)';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isMobile) ...[
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
                  selectedDate: monthDate,
                  onPrevious: () {
                    final prev = DateTime(monthDate.year, monthDate.month - 1);
                    ref.read(payrollFilterProvider.notifier).setYearAndMonth(prev.year, prev.month);
                  },
                  onNext: () {
                    final next = DateTime(monthDate.year, monthDate.month + 1);
                    ref.read(payrollFilterProvider.notifier).setYearAndMonth(next.year, next.month);
                  },
                  onTap: () => PayrollFilterHelpers.showMonthSelection(context, ref, monthDate),
                ),
                const SizedBox(width: 8),
                GTObjectPicker(
                  objectName: PayrollFilterHelpers.getObjectName(ref, filterState.selectedObjectIds),
                  onPrevious: () => PayrollFilterHelpers.handleObjectSwitch(ref, filterState.selectedObjectIds, -1),
                  onNext: () => PayrollFilterHelpers.handleObjectSwitch(ref, filterState.selectedObjectIds, 1),
                  onTap: () => PayrollFilterHelpers.showObjectSelection(context, ref),
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
                        builder: (ctx) => const PayrollTransactionFormModal(
                          transactionType: PayrollTransactionType.penalty,
                        ),
                      );
                    } else {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (ctx) => const PayrollTransactionFormModal(
                          transactionType: PayrollTransactionType.penalty,
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
        if (isMobile) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                PermissionGuard(
                  module: 'payroll',
                  permission: 'create',
                  child: GTTextButton(
                    text: 'Добавить',
                    icon: Icons.add_circle_outline,
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (ctx) => const PayrollTransactionFormModal(
                          transactionType: PayrollTransactionType.penalty,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
        Expanded(
          child: penalties.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.gavel_outlined,
                        size: 64,
                        color: theme.colorScheme.outline.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        isPeriodFiltered
                            ? 'Нет штрафов за ${DateFormat.yMMMM('ru').format(monthDate)}'
                            : 'Нет штрафов',
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
                )
              : PayrollPenaltyTableView(
                  penalties: penalties,
                  employees: employeeState.employees,
                  objects: objectState.objects,
                ),
        ),
      ],
    );
  }
}
