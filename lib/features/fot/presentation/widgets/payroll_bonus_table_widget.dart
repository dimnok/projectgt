import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'payroll_bonus_table_view.dart';
import '../providers/bonus_providers.dart';
import '../providers/payroll_filter_providers.dart';
import '../utils/payroll_name_search_filters.dart';
import '../../../../presentation/state/employee_state.dart';
import 'package:projectgt/core/di/providers.dart';

/// Виджет для отображения таблицы премий сотрудников за текущий месяц в модуле ФОТ.
class PayrollBonusTableWidget extends ConsumerWidget {
  /// Конструктор [PayrollBonusTableWidget].
  const PayrollBonusTableWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final allBonuses = ref.watch(filteredBonusesProvider);
    final searchQuery = ref.watch(payrollSearchQueryProvider);
    final bonuses = filterTransactionsByEmployeeName(
      allBonuses,
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

    if (bonuses.isEmpty) {
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
                  ? 'Нет премий за ${DateFormat.yMMMM('ru').format(monthDate)}'
                  : 'Нет премий',
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

    return PayrollBonusTableView(
      bonuses: bonuses,
      employees: employeeState.employees,
      objects: objectState.objects,
    );
  }
}
