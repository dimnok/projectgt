import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/penalty_providers.dart' show filteredPenaltiesProvider;
import '../providers/payroll_filter_providers.dart';
import '../../../../presentation/state/employee_state.dart';
import 'package:projectgt/core/di/providers.dart';
import '../utils/payroll_name_search_filters.dart';
import 'payroll_penalty_table_view.dart';

/// Виджет для отображения таблицы штрафов сотрудников за текущий месяц в модуле ФОТ.
class PayrollPenaltyTableWidget extends ConsumerWidget {
  /// Конструктор [PayrollPenaltyTableWidget].
  const PayrollPenaltyTableWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final allPenalties = ref.watch(filteredPenaltiesProvider);
    final searchQuery = ref.watch(payrollSearchQueryProvider);
    final penalties = filterTransactionsByEmployeeName(
      allPenalties,
      searchQuery,
      ref,
    );

    final employeeState = ref.watch(employeeProvider);
    final objectState = ref.watch(objectProvider);
    final filterState = ref.watch(payrollFilterProvider);

    final now = DateTime.now();
    final isPeriodFiltered = filterState.selectedYear != now.year ||
        filterState.selectedMonth != now.month;
    final monthDate =
        DateTime(filterState.selectedYear, filterState.selectedMonth);

    if (penalties.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_late_outlined,
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
      );
    }

    return PayrollPenaltyTableView(
      penalties: penalties,
      employees: employeeState.employees,
      objects: objectState.objects,
    );
  }
}
