import 'package:projectgt/domain/repositories/employee_repository.dart';
import 'package:projectgt/features/objects/domain/repositories/object_repository.dart';
import 'package:projectgt/domain/entities/employee.dart';
import '../../domain/entities/timesheet_load_result.dart';
import '../../domain/entities/timesheet_entry.dart';
import '../../domain/repositories/timesheet_repository.dart';
import '../../domain/repositories/employee_attendance_repository.dart';
import '../datasources/timesheet_data_source.dart';

/// ФИО для отображения в табеле — тот же формат, что в календаре ([Employee]).
String _timesheetEmployeeDisplayName(Employee employee) {
  if (employee.middleName != null && employee.middleName!.isNotEmpty) {
    return '${employee.lastName} ${employee.firstName} ${employee.middleName}';
  }
  return '${employee.lastName} ${employee.firstName}';
}

/// Реализация репозитория для работы с табелем рабочего времени.
///
/// Объединяет данные из двух источников:
/// 1. Смены (work_hours + works) - для сотрудников, участвующих в сменах
/// 2. Посещаемость (employee_attendance) - для постоянного персонала и офисных сотрудников
class TimesheetRepositoryImpl implements TimesheetRepository {
  /// Источник данных для табеля (смены).
  final TimesheetDataSource dataSource;

  /// Репозиторий посещаемости сотрудников (вне смен).
  final EmployeeAttendanceRepository attendanceRepository;

  /// Репозиторий сотрудников для получения дополнительной информации.
  final EmployeeRepository employeeRepository;

  /// Репозиторий объектов для получения дополнительной информации.
  final ObjectRepository objectRepository;

  /// Создает экземпляр [TimesheetRepositoryImpl].
  TimesheetRepositoryImpl({
    required this.dataSource,
    required this.attendanceRepository,
    required this.employeeRepository,
    required this.objectRepository,
  });

  @override
  Future<TimesheetLoadResult> loadTimesheet({
    DateTime? startDate,
    DateTime? endDate,
    String? employeeId,
  }) async {
    final (
      workEntries,
      attendanceEntries,
      allEmployees,
      objects,
    ) = await (
      dataSource.getTimesheetEntries(
        startDate: startDate,
        endDate: endDate,
        employeeId: employeeId,
      ),
      attendanceRepository.getAttendanceRecords(
        startDate: startDate,
        endDate: endDate,
        employeeId: employeeId,
      ),
      employeeRepository.getEmployees(),
      objectRepository.getObjects(),
    ).wait;

    // Фильтруем сотрудников: все, кроме уволенных
    final activeEmployees =
        allEmployees.where((e) => e.status != EmployeeStatus.fired).toList();

    // Находим ID сотрудников, у которых есть часы
    final employeeIdsWithHoursFromWork =
        workEntries.map((entry) => entry['employee_id'] as String).toSet();

    final employeeIdsWithHoursFromAttendance =
        attendanceEntries.map((entry) => entry.employeeId).toSet();

    final employeeIdsWithHours = {
      ...employeeIdsWithHoursFromWork,
      ...employeeIdsWithHoursFromAttendance
    };

    // Добавляем уволенных сотрудников, у которых есть часы
    final firedEmployeesWithHours = allEmployees
        .where((e) =>
            e.status == EmployeeStatus.fired &&
            employeeIdsWithHours.contains(e.id))
        .toList();

    // Объединяем активных и уволенных с часами
    final employees = [...activeEmployees, ...firedEmployeesWithHours];
    final employeesById = {for (final e in employees) e.id: e};
    final objectsById = {for (final o in objects) o.id: o};

    // 5. Преобразуем записи из смен
    final workTimesheetEntries = workEntries.map((entry) {
      final employee = employeesById[entry['employee_id'] as String];
      final object = objectsById[entry['object_id'] as String];

      return TimesheetEntry(
        id: entry['id'],
        workId: entry['work_id'],
        employeeId: entry['employee_id'],
        hours: entry['hours'],
        comment: entry['comment'],
        date: DateTime.parse(entry['date']),
        objectId: entry['object_id'],
        employeeName: employee != null
            ? _timesheetEmployeeDisplayName(employee)
            : 'Сотрудник #${entry['employee_id']}',
        employeePosition: employee?.position ?? entry['employee_position'],
        objectName: object?.name ?? 'Объект #${entry['object_id']}',
        createdAt: entry['created_at'] != null
            ? DateTime.parse(entry['created_at'])
            : null,
        updatedAt: entry['updated_at'] != null
            ? DateTime.parse(entry['updated_at'])
            : null,
      );
    }).toList();

    // 6. Преобразуем записи из посещаемости в TimesheetEntry (ФИО как у смен — из [employees])
    final attendanceTimesheetEntries = attendanceEntries.map((entry) {
      final employee = employeesById[entry.employeeId];
      final object = objectsById[entry.objectId];

      return TimesheetEntry(
        id: entry.id,
        workId: entry.id, // Используем ID записи посещаемости
        employeeId: entry.employeeId,
        hours: entry.hours,
        comment: entry.comment,
        date: entry.date,
        objectId: entry.objectId,
        employeeName: employee != null
            ? _timesheetEmployeeDisplayName(employee)
            : entry.employeeName ?? 'Сотрудник #${entry.employeeId}',
        employeePosition: employee?.position ?? entry.employeePosition,
        objectName:
            object?.name ?? entry.objectName ?? 'Объект #${entry.objectId}',
        createdAt: entry.createdAt,
        updatedAt: entry.updatedAt,
        isManualEntry: true, // Помечаем как ручной ввод
      );
    }).toList();

    // 7. Объединяем записи из обоих источников
    final allEntries = [...workTimesheetEntries, ...attendanceTimesheetEntries];

    // 8. Сортируем по дате
    allEntries.sort((a, b) => a.date.compareTo(b.date));

    return TimesheetLoadResult(
      entries: allEntries,
      employees: allEmployees,
    );
  }
}
