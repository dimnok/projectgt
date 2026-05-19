import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/domain/entities/employee.dart';

import '../providers/payroll_grid_selection_providers.dart';

/// Компактный чекбокс в стиле табеля / подрядчиков.
class PayrollGridCheckbox extends StatelessWidget {
  /// Создаёт чекбокс строки таблицы ФОТ.
  const PayrollGridCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    required this.semanticLabel,
    this.tristate = false,
  });

  /// Значение чекбокса; `null` — частичный выбор (шапка «все»).
  final bool? value;

  /// Обработчик смены состояния.
  final ValueChanged<bool?> onChanged;

  /// Подпись для accessibility.
  final String semanticLabel;

  /// Режим трёх состояний (шапка таблицы).
  final bool tristate;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      child: SizedBox.square(
        dimension: 32,
        child: Center(
          child: SizedBox.square(
            dimension: 20,
            child: Checkbox(
              value: value,
              tristate: tristate,
              visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              overlayColor: const WidgetStatePropertyAll(Colors.transparent),
              splashRadius: 0,
              onChanged: onChanged,
            ),
          ),
        ),
      ),
    );
  }
}

/// Оставляет в провайдере только ID из [visibleEmployeeIds].
void prunePayrollGridSelection(WidgetRef ref, Set<String> visibleEmployeeIds) {
  final selected = ref.read(payrollGridSelectedEmployeeIdsProvider);
  final pruned = selected.where(visibleEmployeeIds.contains).toSet();
  if (pruned.length != selected.length) {
    ref.read(payrollGridSelectedEmployeeIdsProvider.notifier).state = pruned;
  }
}

/// Состояние чекбокса «выбрать всех» для [visibleEmployees].
bool? payrollHeaderSelectAllValue(
  List<dynamic> visibleEmployees,
  Set<String> selectedIds,
) {
  if (visibleEmployees.isEmpty) return false;
  final visibleIds = visibleEmployees
      .map((e) => e is Employee ? e.id : (e as dynamic).id as String?)
      .whereType<String>()
      .toSet();
  if (visibleIds.isEmpty) return false;
  final n = selectedIds.where(visibleIds.contains).length;
  if (n == 0) return false;
  if (n == visibleIds.length) return true;
  return null;
}

/// Переключает выбор всех видимых сотрудников.
void onPayrollHeaderSelectAllChanged(
  WidgetRef ref,
  List<dynamic> visibleEmployees,
  bool? value,
) {
  final notifier = ref.read(payrollGridSelectedEmployeeIdsProvider.notifier);
  if (value == true) {
    final ids = visibleEmployees
        .map((e) => e is Employee ? e.id : (e as dynamic).id as String?)
        .whereType<String>()
        .toSet();
    notifier.state = ids;
  } else {
    notifier.state = <String>{};
  }
}

/// Переключает выбор одного сотрудника.
void onPayrollRowCheckboxChanged(
  WidgetRef ref,
  String employeeId,
  bool? checked,
) {
  final notifier = ref.read(payrollGridSelectedEmployeeIdsProvider.notifier);
  final next = Set<String>.from(ref.read(payrollGridSelectedEmployeeIdsProvider));
  if (checked == true) {
    next.add(employeeId);
  } else {
    next.remove(employeeId);
  }
  notifier.state = next;
}
