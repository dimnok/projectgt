import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/widgets/mobile_atmosphere_backdrop.dart';
import 'package:projectgt/core/widgets/mobile_atmosphere_screen_header.dart';
import 'package:projectgt/presentation/state/employee_state.dart';

import '../../data/models/payroll_payout_model.dart';
import '../../domain/entities/payroll_calculation.dart';
import '../../domain/entities/payroll_transaction.dart';
import '../providers/payroll_filter_providers.dart';

final _payrollSearchControllerProvider =
    Provider.autoDispose<TextEditingController>((ref) {
      final initial = ref.read(payrollSearchQueryProvider);
      final controller = TextEditingController(text: initial);
      ref.onDispose(controller.dispose);

      ref.listen<String>(payrollSearchQueryProvider, (prev, next) {
        if (controller.text != next) {
          controller.text = next;
          controller.selection = TextSelection.fromPosition(
            TextPosition(offset: controller.text.length),
          );
        }
      });

      return controller;
    });

/// Виджет поиска по ФИО в шапке экрана ФОТ: раскрываемое поле и кнопка «хрома».
///
/// Визуально согласован с [TimesheetSearchAction] в модуле табеля.
class PayrollSearchAction extends ConsumerWidget {
  /// Создаёт виджет действий поиска.
  const PayrollSearchAction({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final appearance = MobileAtmosphereAppearance.of(context);
    final visible = ref.watch(payrollSearchVisibleProvider);
    final query = ref.watch(payrollSearchQueryProvider);
    final hasQuery = query.trim().isNotEmpty;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          width: visible ? 420 : 0,
          child: visible
              ? Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: appearance.chromeFill,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: appearance.chromeBorder),
                    ),
                    child: TextField(
                      controller: ref.watch(_payrollSearchControllerProvider),
                      autofocus: true,
                      onChanged: (value) =>
                          ref.read(payrollSearchQueryProvider.notifier).state =
                              value,
                      decoration: InputDecoration(
                        hintText: 'Поиск по ФИО...',
                        isDense: true,
                        prefixIconConstraints: const BoxConstraints(
                          minWidth: 44,
                          minHeight: 40,
                        ),
                        border: InputBorder.none,
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide: BorderSide(
                            color: scheme.primary.withValues(alpha: 0.85),
                            width: 1.5,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        prefixIcon: Icon(
                          Icons.person_search_rounded,
                          size: 20,
                          color: scheme.onSurface.withValues(alpha: 0.75),
                        ),
                      ),
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
        MobileAtmosphereChromeCircleButton(
          appearance: appearance,
          tooltip: hasQuery ? 'Очистить поиск' : 'Поиск по ФИО',
          icon: hasQuery ? Icons.close_rounded : Icons.search_rounded,
          iconColor: hasQuery ? scheme.error : null,
          onTap: () {
            if (hasQuery) {
              ref.read(payrollSearchQueryProvider.notifier).state = '';
            } else {
              final newVisible = !ref.read(payrollSearchVisibleProvider);
              ref.read(payrollSearchVisibleProvider.notifier).state = newVisible;
            }
          },
        ),
      ],
    );
  }
}

/// Фильтрует расчёты ФОТ по ФИО сотрудника.
List<PayrollCalculation> filterPayrollsByEmployeeName(
  List<PayrollCalculation> payrolls,
  String query,
  WidgetRef ref,
) {
  final searchQuery = query.trim().toLowerCase();
  final employeeState = ref.watch(employeeProvider);
  final employees = employeeState.employees;

  var filteredPayrolls = payrolls;

  if (searchQuery.isNotEmpty) {
    filteredPayrolls = filteredPayrolls.where((payroll) {
      final employee =
          employees.where((e) => e.id == payroll.employeeId).firstOrNull;

      if (employee == null) return false;

      final fullName = [
        employee.lastName,
        employee.firstName,
        if (employee.middleName != null && employee.middleName!.isNotEmpty)
          employee.middleName,
      ].join(' ').toLowerCase();

      return fullName.contains(searchQuery);
    }).toList();
  }

  return filteredPayrolls;
}

/// Фильтрует транзакции (премии/штрафы) по ФИО и объектам.
List<PayrollTransaction> filterTransactionsByEmployeeName(
  List<PayrollTransaction> transactions,
  String query,
  WidgetRef ref,
) {
  final searchQuery = query.trim().toLowerCase();
  final employeeState = ref.watch(employeeProvider);
  final employees = employeeState.employees;
  final filterState = ref.watch(payrollFilterProvider);

  var filteredTransactions = transactions;

  if (searchQuery.isNotEmpty) {
    filteredTransactions = filteredTransactions.where((transaction) {
      final employee =
          employees.where((e) => e.id == transaction.employeeId).firstOrNull;

      if (employee == null) return false;

      final fullName = [
        employee.lastName,
        employee.firstName,
        if (employee.middleName != null && employee.middleName!.isNotEmpty)
          employee.middleName,
      ].join(' ').toLowerCase();

      return fullName.contains(searchQuery);
    }).toList();
  }

  if (filterState.selectedObjectIds.isNotEmpty) {
    filteredTransactions = filteredTransactions
        .where(
          (transaction) =>
              transaction.objectId != null &&
              filterState.selectedObjectIds.contains(transaction.objectId),
        )
        .toList();
  }

  return filteredTransactions;
}

/// Фильтрует выплаты по ФИО.
List<PayrollPayoutModel> filterPayoutsByEmployeeName(
  List<PayrollPayoutModel> payouts,
  String query,
  WidgetRef ref,
) {
  final searchQuery = query.trim().toLowerCase();
  final employeeState = ref.watch(employeeProvider);
  final employees = employeeState.employees;

  var filteredPayouts = payouts;

  if (searchQuery.isNotEmpty) {
    filteredPayouts = filteredPayouts.where((payout) {
      final employee =
          employees.where((e) => e.id == payout.employeeId).firstOrNull;

      if (employee == null) return false;

      final fullName = [
        employee.lastName,
        employee.firstName,
        if (employee.middleName != null && employee.middleName!.isNotEmpty)
          employee.middleName,
      ].join(' ').toLowerCase();

      return fullName.contains(searchQuery);
    }).toList();
  }

  return filteredPayouts;
}

/// Фильтрует список сотрудников по поисковому запросу.
List<dynamic> filterEmployeesBySearchQuery(
  List<dynamic> employees,
  String query,
) {
  final searchQuery = query.trim().toLowerCase();
  if (searchQuery.isEmpty) return employees;

  return employees.where((employee) {
    final fullName = [
      employee.lastName,
      employee.firstName,
      if (employee.middleName != null && employee.middleName!.isNotEmpty)
        employee.middleName,
    ].join(' ').toLowerCase();

    return fullName.contains(searchQuery);
  }).toList();
}
