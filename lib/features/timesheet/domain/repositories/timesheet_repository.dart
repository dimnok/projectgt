import 'package:projectgt/domain/entities/employee.dart';
import 'package:projectgt/features/objects/domain/entities/object.dart';

import '../entities/timesheet_entry.dart';
import '../entities/timesheet_load_result.dart';

/// Интерфейс репозитория для работы с данными табеля рабочего времени.
abstract class TimesheetRepository {
  /// Загружает записи табеля, справочник сотрудников и объекты за период.
  ///
  /// [objectIds] — серверный фильтр смен и посещаемости по объектам.
  Future<TimesheetLoadResult> loadTimesheet({
    DateTime? startDate,
    DateTime? endDate,
    List<String>? objectIds,
  });

  /// Справочник сотрудников компании (без ставок), как в [loadTimesheet].
  Future<List<Employee>> loadEmployeesCatalog();

  /// Перезагружает только часы (смены + посещаемость), без справочника сотрудников.
  ///
  /// [employees] и [objects] — для обогащения имён (из текущего состояния UI).
  Future<List<TimesheetEntry>> reloadHoursEntries({
    required DateTime startDate,
    required DateTime endDate,
    List<String>? objectIds,
    required List<Employee> employees,
    required List<ObjectEntity> objects,
  });

  /// Часы из закрытых смен для одного сотрудника (диалог посещаемости).
  Future<List<TimesheetEntry>> getShiftHoursForEmployee({
    required String employeeId,
    required DateTime startDate,
    required DateTime endDate,
  });
}
