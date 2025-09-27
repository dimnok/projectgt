import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/widgets/gt_dropdown.dart';
import 'package:projectgt/presentation/state/employee_state.dart' as emp_state;
import 'package:projectgt/domain/entities/employee.dart';

/// Поле выбора сотрудника для привязки в профиле пользователя.
/// Использует кастомный GTDropdown (одинарный выбор).
class ProfileEmployeeLinkEditField extends ConsumerWidget {
  /// Идентификатор изначально выбранного сотрудника.
  final String? initialEmployeeId;

  /// Callback при изменении выбора сотрудника.
  ///
  /// [employeeId] - идентификатор выбранного сотрудника или null.
  final void Function(String? employeeId) onChanged;

  /// Флаг только для чтения.
  final bool readOnly;

  /// Создает поле выбора сотрудника для профиля.
  ///
  /// [initialEmployeeId] - идентификатор изначально выбранного сотрудника.
  /// [onChanged] - callback при изменении выбора.
  /// [readOnly] - если true, поле недоступно для редактирования.
  const ProfileEmployeeLinkEditField({
    super.key,
    required this.initialEmployeeId,
    required this.onChanged,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Тянем список сотрудников (id, ФИО)
    ref.read(emp_state.employeeProvider.notifier).getEmployees();
    final state = ref.watch(emp_state.employeeProvider);
    final List<Employee> employees = state.employees;

    // Подбираем текущий выбранный сотрудник
    Employee? selected;
    if (initialEmployeeId != null && initialEmployeeId!.isNotEmpty) {
      for (final e in employees) {
        if (e.id == initialEmployeeId) {
          selected = e;
          break;
        }
      }
    }

    return GTDropdown<Employee>(
      items: employees,
      itemDisplayBuilder: (Employee e) {
        final middle = (e.middleName != null && e.middleName!.isNotEmpty)
            ? ' ${e.middleName}'
            : '';
        return '${e.lastName} ${e.firstName}$middle';
      },
      selectedItem: selected,
      onSelectionChanged: (Employee? e) => onChanged(e?.id),
      labelText: 'Сотрудник (только для администратора)',
      hintText: 'Выберите сотрудника или оставьте пустым',
      allowMultipleSelection: false,
      allowCustomInput: false,
      allowClear: true,
      readOnly: readOnly,
      isLoading: state.status == emp_state.EmployeeStatus.loading,
      validator: (v) => null,
    );
  }
}
