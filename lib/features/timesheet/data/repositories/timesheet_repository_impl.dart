import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/domain/entities/employee.dart';
import 'package:projectgt/domain/repositories/employee_repository.dart';
import 'package:projectgt/features/objects/domain/entities/object.dart';
import 'package:projectgt/features/objects/domain/repositories/object_repository.dart';
import '../../domain/entities/employee_attendance_entry.dart';
import '../../domain/entities/timesheet_load_result.dart';
import '../../domain/entities/timesheet_entry.dart';
import '../../domain/repositories/timesheet_repository.dart';
import '../../domain/repositories/employee_attendance_repository.dart';
import '../../domain/timesheet_today_open_shift.dart';
import '../datasources/timesheet_data_source.dart';

TimesheetEntry _workRowToTimesheetEntry(
  Map<String, dynamic> entry, {
  Employee? employee,
  ObjectEntity? object,
}) {
  return TimesheetEntry(
    id: entry['id'] as String,
    workId: entry['work_id'] as String,
    employeeId: entry['employee_id'] as String,
    hours: entry['hours'] as num,
    comment: entry['comment'] as String?,
    date: DateTime.parse(entry['date'] as String),
    objectId: entry['object_id'] as String,
    employeeName: employee != null
        ? formatFullName(
            employee.lastName,
            employee.firstName,
            employee.middleName,
          )
        : null,
    employeePosition: employee?.position,
    objectName: object?.name,
    createdAt: entry['created_at'] != null
        ? DateTime.parse(entry['created_at'] as String)
        : null,
    updatedAt: entry['updated_at'] != null
        ? DateTime.parse(entry['updated_at'] as String)
        : null,
  );
}

List<TimesheetEntry> _mapAttendanceToTimesheetEntries(
  List<EmployeeAttendanceEntry> attendanceEntries, {
  required Map<String, Employee> employeesById,
  required Map<String, ObjectEntity> objectsById,
}) {
  return attendanceEntries.map((entry) {
    final employee = employeesById[entry.employeeId];
    final object = objectsById[entry.objectId];

    return TimesheetEntry(
      id: entry.id,
      workId: entry.id,
      employeeId: entry.employeeId,
      hours: entry.hours,
      comment: entry.comment,
      date: entry.date,
      objectId: entry.objectId,
      employeeName: employee != null
          ? formatFullName(
              employee.lastName,
              employee.firstName,
              employee.middleName,
            )
          : entry.employeeName ?? 'Сотрудник #${entry.employeeId}',
      employeePosition: employee?.position ?? entry.employeePosition,
      objectName:
          object?.name ?? entry.objectName ?? 'Объект #${entry.objectId}',
      createdAt: entry.createdAt,
      updatedAt: entry.updatedAt,
      isManualEntry: true,
    );
  }).toList();
}

List<TimesheetEntry> _mergeTimesheetEntries(
  List<Map<String, dynamic>> workEntries,
  List<EmployeeAttendanceEntry> attendanceEntries, {
  required Map<String, Employee> employeesById,
  required Map<String, ObjectEntity> objectsById,
}) {
  final workTimesheetEntries = workEntries.map((entry) {
    final employee = employeesById[entry['employee_id'] as String];
    final object = objectsById[entry['object_id'] as String];
    final mapped = _workRowToTimesheetEntry(
      entry,
      employee: employee,
      object: object,
    );
    return mapped.copyWith(
      employeeName:
          mapped.employeeName ?? 'Сотрудник #${entry['employee_id']}',
      objectName: mapped.objectName ?? 'Объект #${entry['object_id']}',
    );
  }).toList();

  final attendanceTimesheetEntries = _mapAttendanceToTimesheetEntries(
    attendanceEntries,
    employeesById: employeesById,
    objectsById: objectsById,
  );

  final allEntries = [...workTimesheetEntries, ...attendanceTimesheetEntries]
    ..sort((a, b) => a.date.compareTo(b.date));

  return allEntries;
}

/// Реализация репозитория для работы с табелем рабочего времени.
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

  Future<({List<Map<String, dynamic>> work, List<EmployeeAttendanceEntry> attendance})>
      _fetchHoursRaw({
    DateTime? startDate,
    DateTime? endDate,
    List<String>? objectIds,
  }) async {
    final (workEntries, attendanceEntries) = await (
      dataSource.getTimesheetEntries(
        startDate: startDate,
        endDate: endDate,
        objectIds: objectIds,
      ),
      attendanceRepository.getAttendanceRecords(
        startDate: startDate,
        endDate: endDate,
        objectIds: objectIds,
      ),
    ).wait;

    return (work: workEntries, attendance: attendanceEntries);
  }

  @override
  Future<List<Employee>> loadEmployeesCatalog() =>
      employeeRepository.getEmployeesCatalog();

  @override
  Future<TimesheetLoadResult> loadTimesheet({
    DateTime? startDate,
    DateTime? endDate,
    List<String>? objectIds,
  }) async {
    final (workEntries, attendanceEntries, allEmployees, objects) = await (
      dataSource.getTimesheetEntries(
        startDate: startDate,
        endDate: endDate,
        objectIds: objectIds,
      ),
      attendanceRepository.getAttendanceRecords(
        startDate: startDate,
        endDate: endDate,
        objectIds: objectIds,
      ),
      employeeRepository.getEmployeesCatalog(),
      objectRepository.getObjects(),
    ).wait;

    final employeesById = {for (final e in allEmployees) e.id: e};
    final objectsById = {for (final o in objects) o.id: o};

    final entries = _mergeTimesheetEntries(
      workEntries,
      attendanceEntries,
      employeesById: employeesById,
      objectsById: objectsById,
    );

    return TimesheetLoadResult(entries: entries, employees: allEmployees);
  }

  @override
  Future<List<TimesheetEntry>> reloadHoursEntries({
    required DateTime startDate,
    required DateTime endDate,
    List<String>? objectIds,
    required List<Employee> employees,
    required List<ObjectEntity> objects,
  }) async {
    final raw = await _fetchHoursRaw(
      startDate: startDate,
      endDate: endDate,
      objectIds: objectIds,
    );

    final employeesById = {for (final e in employees) e.id: e};
    final objectsById = {for (final o in objects) o.id: o};

    return _mergeTimesheetEntries(
      raw.work,
      raw.attendance,
      employeesById: employeesById,
      objectsById: objectsById,
    );
  }

  @override
  Future<List<TimesheetEntry>> getShiftHoursForEmployee({
    required String employeeId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final workEntries = await dataSource.getShiftWorkHoursForEmployee(
      employeeId: employeeId,
      startDate: startDate,
      endDate: endDate,
    );

    final entries =
        workEntries.map((row) => _workRowToTimesheetEntry(row)).toList()
          ..sort((a, b) => a.date.compareTo(b.date));

    return entries;
  }

  @override
  Future<TimesheetTodayOpenShiftIndex> loadTodayOpenShiftIndex(
    DateTime date,
  ) async {
    final rows = await dataSource.getOpenWorksForDate(date);
    return parseTodayOpenShiftWorksResponse(rows);
  }
}
