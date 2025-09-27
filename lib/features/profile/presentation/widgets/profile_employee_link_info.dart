import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/domain/entities/profile.dart';
import 'package:projectgt/presentation/state/employee_state.dart';

/// Текстовое представление привязанного сотрудника для профиля пользователя.
///
/// Показывает ФИО сотрудника по `profile.object['employee_id']`,
/// либо «Не привязан», если связь отсутствует.
class ProfileLinkedEmployeeInfo extends ConsumerStatefulWidget {
  /// Профиль пользователя для отображения привязанного сотрудника.
  final Profile? profile;

  /// Создает виджет отображения привязанного сотрудника.
  ///
  /// [profile] - профиль пользователя с информацией о привязке к сотруднику.
  const ProfileLinkedEmployeeInfo({super.key, required this.profile});

  @override
  ConsumerState<ProfileLinkedEmployeeInfo> createState() =>
      _ProfileLinkedEmployeeInfoState();
}

class _ProfileLinkedEmployeeInfoState
    extends ConsumerState<ProfileLinkedEmployeeInfo> {
  @override
  void initState() {
    super.initState();
    // Однократная ленёвая загрузка списка сотрудников после первой отрисовки
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(employeeProvider.notifier).getEmployees();
    });
  }

  @override
  Widget build(BuildContext context) {
    final employeesState = ref.watch(employeeProvider);
    final employees = employeesState.employees;

    final String? linkedEmployeeId = (widget.profile?.object != null)
        ? (widget.profile!.object!['employee_id'] as String?)
        : null;

    if (linkedEmployeeId == null || linkedEmployeeId.isEmpty) {
      final theme = Theme.of(context);
      return Text(
        'Не привязан',
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w500,
          color: theme.colorScheme.onSurface,
        ),
      );
    }

    // Ищем сотрудника безопасно
    var employee = null as dynamic;
    for (final e in employees) {
      if (e.id == linkedEmployeeId) {
        employee = e;
        break;
      }
    }

    if (employee == null) {
      final theme = Theme.of(context);
      return Text(
        'Не привязан',
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w500,
          color: theme.colorScheme.onSurface,
        ),
      );
    }

    final middle =
        (employee.middleName != null && employee.middleName!.isNotEmpty)
            ? ' ${employee.middleName}'
            : '';
    final fio = '${employee.lastName} ${employee.firstName}$middle';
    final theme = Theme.of(context);
    return Text(
      fio,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w500,
        color: theme.colorScheme.onSurface,
      ),
    );
  }
}
