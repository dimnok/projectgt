import 'package:projectgt/domain/repositories/employee_repository.dart';
import 'package:projectgt/domain/repositories/object_repository.dart';
import 'package:projectgt/domain/entities/employee.dart';
import 'package:projectgt/domain/entities/object.dart' as project_object;
import '../../domain/entities/timesheet_entry.dart';
import '../../domain/repositories/timesheet_repository.dart';
import '../../domain/repositories/employee_attendance_repository.dart';
import '../datasources/timesheet_data_source.dart';

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
  Future<List<TimesheetEntry>> getTimesheetEntries({
    DateTime? startDate,
    DateTime? endDate,
    String? employeeId,
    List<String>? objectIds,
    List<String>? positions,
  }) async {
    // 1. Получаем данные из смен (work_hours)
    final workEntries = await dataSource.getTimesheetEntries(
      startDate: startDate,
      endDate: endDate,
      employeeId: employeeId,
      objectIds: objectIds,
      positions: positions,
    );

    // 2. Получаем данные из посещаемости (employee_attendance)
    final attendanceEntries = await attendanceRepository.getAttendanceRecords(
      startDate: startDate,
      endDate: endDate,
      employeeId: employeeId,
      objectId:
          objectIds != null && objectIds.isNotEmpty ? objectIds.first : null,
    );

    // 3. Получаем список всех сотрудников и объектов для обогащения данных
    final allEmployees = await employeeRepository.getEmployees();
    final objects = await objectRepository.getObjects();

    // 4. Фильтруем сотрудников: все, кроме уволенных
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

    // 5. Преобразуем записи из смен
    final workTimesheetEntries = workEntries.map((entry) {
      Employee? employee;
      try {
        employee = employees.firstWhere((e) => e.id == entry['employee_id']);
      } catch (_) {
        employee = null;
      }

      project_object.ObjectEntity? object;
      try {
        object = objects.firstWhere((o) => o.id == entry['object_id']);
      } catch (_) {
        object = null;
      }

      return TimesheetEntry(
        id: entry['id'],
        workId: entry['work_id'],
        employeeId: entry['employee_id'],
        hours: entry['hours'],
        comment: entry['comment'],
        date: DateTime.parse(entry['date']),
        objectId: entry['object_id'],
        employeeName: employee != null
            ? employee.middleName != null && employee.middleName!.isNotEmpty
                ? '${employee.lastName} ${employee.firstName} ${employee.middleName}'
                : '${employee.lastName} ${employee.firstName}'
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

    // 6. Преобразуем записи из посещаемости в TimesheetEntry
    final attendanceTimesheetEntries = attendanceEntries.map((entry) {
      return TimesheetEntry(
        id: entry.id,
        workId: entry.id, // Используем ID записи посещаемости
        employeeId: entry.employeeId,
        hours: entry.hours,
        comment: entry.comment,
        date: entry.date,
        objectId: entry.objectId,
        employeeName: entry.employeeName ?? 'Сотрудник #${entry.employeeId}',
        employeePosition: entry.employeePosition,
        objectName: entry.objectName ?? 'Объект #${entry.objectId}',
        createdAt: entry.createdAt,
        updatedAt: entry.updatedAt,
        isManualEntry: true, // Помечаем как ручной ввод
      );
    }).toList();

    // 7. Объединяем записи из обоих источников
    final allEntries = [...workTimesheetEntries, ...attendanceTimesheetEntries];

    // 8. Сортируем по дате
    allEntries.sort((a, b) => a.date.compareTo(b.date));

    return allEntries;
  }
}
