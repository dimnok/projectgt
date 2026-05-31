import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/presentation/state/employee_state.dart';

import 'timesheet_provider.dart';

/// Синхронизирует каталог табеля после изменений в модуле «Сотрудники».
///
/// Подключать через [ref.watch] на экране табеля. Не трогает табель, пока он
/// ни разу не загружал данные (пустые `employees` и `entries`).
final timesheetEmployeesCatalogSyncProvider = Provider<void>((ref) {
  var timesheetHasData = ref.read(
    timesheetProvider.select(
      (s) => s.employees.isNotEmpty || s.entries.isNotEmpty,
    ),
  );

  ref.listen(timesheetProvider, (_, next) {
    timesheetHasData =
        next.employees.isNotEmpty || next.entries.isNotEmpty;
  });

  ref.listen(employeeProvider, (previous, next) {
    if (!timesheetHasData || previous == null) return;
    if (next.status != EmployeeStatus.success) return;
    if (identical(previous.employees, next.employees)) return;

    unawaited(ref.read(timesheetProvider.notifier).reloadEmployeesCatalog());
  });
});
