import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/domain/entities/profile.dart';
import 'package:projectgt/presentation/state/employee_state.dart';

/// Текстовое представление привязанного сотрудника для профиля пользователя.
///
/// Показывает ФИО сотрудника по `profile.object['employee_id']`,
/// либо «Не привязан», если связь отсутствует.
/// Поддерживает клик для перехода к деталям сотрудника.
class ProfileLinkedEmployeeInfo extends ConsumerStatefulWidget {
  /// Профиль пользователя для отображения привязанного сотрудника.
  final Profile? profile;

  /// Callback для обработки клика по сотруднику.
  /// Получает ID сотрудника в качестве параметра.
  final void Function(String employeeId)? onEmployeeTap;

  /// Создает виджет отображения привязанного сотрудника.
  ///
  /// [profile] - профиль пользователя с информацией о привязке к сотруднику.
  /// [onEmployeeTap] - callback для обработки клика по сотруднику.
  const ProfileLinkedEmployeeInfo({
    super.key,
    required this.profile,
    this.onEmployeeTap,
  });

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

    // Если есть callback для клика, делаем текст кликабельным
    if (widget.onEmployeeTap != null) {
      return InkWell(
        onTap: () => widget.onEmployeeTap!(linkedEmployeeId),
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  fio,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.primary,
                    decoration: TextDecoration.underline,
                    decorationColor:
                        theme.colorScheme.primary.withValues(alpha: 0.5),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: theme.colorScheme.primary.withValues(alpha: 0.7),
              ),
            ],
          ),
        ),
      );
    }

    // Обычный текст без клика
    return Text(
      fio,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w500,
        color: theme.colorScheme.onSurface,
      ),
    );
  }
}
