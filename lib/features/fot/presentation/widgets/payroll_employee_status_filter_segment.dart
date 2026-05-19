import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/domain/entities/employee.dart';

import '../../domain/entities/payroll_calculation.dart';

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

/// Текстовый переключатель «Все» / «Работает» / «Уволен» для панели фильтров таблицы ФОТ.
///
/// Размещается в одной строке с [GTObjectPicker], выравнивание — вправо.
class PayrollEmployeeStatusFilterSegment extends ConsumerWidget {
  /// Создаёт сегмент фильтра по статусу.
  const PayrollEmployeeStatusFilterSegment({super.key});

  static const double _height = 30;
  static const double _radius = 16;
  static const double _segmentHorizontalPadding = 10;

  static const List<(PayrollEmployeeStatusFilter, String)> _options = [
    (PayrollEmployeeStatusFilter.all, 'Все'),
    (PayrollEmployeeStatusFilter.working, 'Работает'),
    (PayrollEmployeeStatusFilter.fired, 'Уволен'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final selected = ref.watch(payrollEmployeeStatusFilterProvider);
    final notifier = ref.read(payrollEmployeeStatusFilterProvider.notifier);

    final borderColor = scheme.outline.withValues(alpha: 0.38);
    final trackFill = scheme.surfaceContainerHighest.withValues(alpha: 0.45);
    final selectedFill = scheme.surface;
    final outlineSelected = scheme.outline.withValues(alpha: 0.22);
    final shadowSoft = scheme.shadow.withValues(alpha: 0.1);

    TextStyle segmentText(bool isSelected) {
      final base = theme.textTheme.labelLarge ?? theme.textTheme.bodyMedium!;
      return base.copyWith(
        fontWeight: FontWeight.w600,
        fontSize: 11.5,
        height: 1.1,
        color: isSelected
            ? scheme.onSurface
            : scheme.onSurface.withValues(alpha: 0.52),
      );
    }

    Widget segment(PayrollEmployeeStatusFilter value, String label) {
      final isSelected = selected == value;
      return Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(_radius - 3),
          onTap: () {
            if (!isSelected) notifier.state = value;
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOutCubic,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(
              horizontal: _segmentHorizontalPadding,
              vertical: 3,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(_radius - 3),
              color: isSelected ? selectedFill : Colors.transparent,
              border: Border.all(
                color: isSelected ? outlineSelected : Colors.transparent,
                width: 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: shadowSoft,
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ]
                  : null,
            ),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: segmentText(isSelected),
            ),
          ),
        ),
      );
    }

    final selectedLabel = _options.firstWhere((e) => e.$1 == selected).$2;

    return Semantics(
      label: 'Статус сотрудников: $selectedLabel',
      child: SizedBox(
        height: _height,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_radius),
            border: Border.all(color: borderColor),
            color: trackFill,
          ),
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final (value, label) in _options) segment(value, label),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
