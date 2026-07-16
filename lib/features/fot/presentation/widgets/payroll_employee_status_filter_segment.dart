import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/domain/entities/employee.dart';

import '../../domain/entities/payroll_calculation.dart';
import 'payroll_toolbar_metrics.dart';

/// Фильтр списка ФОТ по статусу сотрудника.
enum PayrollEmployeeStatusFilter {
  /// Все статусы.
  all,

  /// Только со статусом «Работает».
  working,

  /// Только со статусом «Уволен».
  fired,
}

/// Активный фильтр статуса на вкладке «ФОТ».
final payrollEmployeeStatusFilterProvider =
    StateProvider<PayrollEmployeeStatusFilter>(
      (ref) => PayrollEmployeeStatusFilter.all,
    );

/// Возвращает [EmployeeStatus] из элемента списка сотрудников (entity или map).
EmployeeStatus? payrollEmployeeStatusOf(dynamic employee) {
  if (employee is Employee) return employee.status;
  try {
    return employee.status as EmployeeStatus?;
  } catch (_) {
    return null;
  }
}

/// Оставляет сотрудников, подходящих под [filter].
List<T> filterEmployeesByPayrollStatus<T>(
  List<T> employees,
  PayrollEmployeeStatusFilter filter,
) {
  if (filter == PayrollEmployeeStatusFilter.all) return employees;

  return employees.where((employee) {
    final status = payrollEmployeeStatusOf(employee);
    if (status == null) return false;
    return switch (filter) {
      PayrollEmployeeStatusFilter.all => true,
      PayrollEmployeeStatusFilter.working => status == EmployeeStatus.working,
      PayrollEmployeeStatusFilter.fired => status == EmployeeStatus.fired,
    };
  }).toList();
}

/// Оставляет расчёты ФОТ сотрудников, прошедших [filterEmployeesByPayrollStatus].
List<PayrollCalculation> filterPayrollsByEmployeeStatus(
  List<PayrollCalculation> payrolls,
  List<dynamic> employees,
  PayrollEmployeeStatusFilter filter,
) {
  if (filter == PayrollEmployeeStatusFilter.all) return payrolls;

  final allowedIds = filterEmployeesByPayrollStatus(employees, filter)
      .map((e) => (e as dynamic).id as String?)
      .whereType<String>()
      .toSet();
  return payrolls
      .where((p) => p.employeeId != null && allowedIds.contains(p.employeeId))
      .toList();
}

/// Текстовый переключатель «Все» / «Работает» / «Уволен» для панели фильтров ФОТ.
class PayrollEmployeeStatusFilterSegment extends ConsumerWidget {
  /// Создаёт сегмент фильтра по статусу.
  const PayrollEmployeeStatusFilterSegment({super.key});

  static const List<(PayrollEmployeeStatusFilter, String)> _options = [
    (PayrollEmployeeStatusFilter.all, 'Все'),
    (PayrollEmployeeStatusFilter.working, 'Работает'),
    (PayrollEmployeeStatusFilter.fired, 'Уволен'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(payrollEmployeeStatusFilterProvider);
    final notifier = ref.read(payrollEmployeeStatusFilterProvider.notifier);
    final selectedLabel = _options.firstWhere((e) => e.$1 == selected).$2;

    return PayrollToolbarSegmentTrack(
      semanticsLabel: 'Статус сотрудников: $selectedLabel',
      children: [
        for (final (value, label) in _options)
          PayrollToolbarSegmentChip(
            label: label,
            selected: selected == value,
            onTap: () {
              if (selected != value) notifier.state = value;
            },
          ),
      ],
    );
  }
}
