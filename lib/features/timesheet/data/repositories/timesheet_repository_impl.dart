import 'package:projectgt/domain/repositories/employee_repository.dart';
import 'package:projectgt/domain/repositories/object_repository.dart';
import 'package:projectgt/domain/entities/employee.dart';
import 'package:projectgt/domain/entities/object.dart' as project_object;
import '../../domain/entities/timesheet_entry.dart';
import '../../domain/entities/timesheet_summary.dart';
import '../../domain/repositories/timesheet_repository.dart';
import '../datasources/timesheet_data_source.dart';

/// Реализация репозитория для работы с табелем рабочего времени.
class TimesheetRepositoryImpl implements TimesheetRepository {
  /// Источник данных для табеля.
  final TimesheetDataSource dataSource;

  /// Репозиторий сотрудников для получения дополнительной информации.
  final EmployeeRepository employeeRepository;

  /// Репозиторий объектов для получения дополнительной информации.
  final ObjectRepository objectRepository;

  /// Создает экземпляр [TimesheetRepositoryImpl].
  TimesheetRepositoryImpl({
    required this.dataSource,
    required this.employeeRepository,
    required this.objectRepository,
  });

  @override
  Future<List<TimesheetEntry>> getTimesheetEntries({
    DateTime? startDate,
    DateTime? endDate,
    String? employeeId,
    String? objectId,
  }) async {
    // Получаем данные из источника
    final entries = await dataSource.getTimesheetEntries(
      startDate: startDate,
      endDate: endDate,
      employeeId: employeeId,
      objectId: objectId,
    );

    // Получаем список всех сотрудников и объектов для обогащения данных
    final employees = await employeeRepository.getEmployees();
    final objects = await objectRepository.getObjects();

    // Преобразуем в сущности с добавлением имен сотрудников и названий объектов
    final resultEntries = entries.map((entry) {
      // Находим имя сотрудника
      Employee? employee;
      try {
        employee = employees.firstWhere(
          (e) => e.id == entry['employee_id'],
        );
      } catch (_) {
        employee = null;
      }

      // Находим название объекта
      project_object.ObjectEntity? object;
      try {
        object = objects.firstWhere(
          (o) => o.id == entry['object_id'],
        );
      } catch (_) {
        object = null;
      }

      // Преобразуем в TimesheetEntry
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
        employeePosition: employee?.position,
        objectName: object?.name ?? 'Объект #${entry['object_id']}',
        createdAt: entry['created_at'] != null
            ? DateTime.parse(entry['created_at'])
            : null,
        updatedAt: entry['updated_at'] != null
            ? DateTime.parse(entry['updated_at'])
            : null,
      );
    }).toList();

    return resultEntries;
  }

  @override
  Future<List<TimesheetSummary>> getTimesheetSummary({
    DateTime? startDate,
    DateTime? endDate,
    List<String>? employeeIds,
    List<String>? objectIds,
  }) async {
    // Получаем все записи с учетом фильтров по дате
    final entries = await getTimesheetEntries(
      startDate: startDate,
      endDate: endDate,
    );

    // Создаем словарь для сводки по сотрудникам
    final Map<String, TimesheetSummary> summaryMap = {};

    // Заполняем словарь
    for (final entry in entries) {
      // Применяем фильтр по сотрудникам, если задан
      if (employeeIds != null && !employeeIds.contains(entry.employeeId)) {
        continue;
      }

      // Применяем фильтр по объектам, если задан
      if (objectIds != null && !objectIds.contains(entry.objectId)) {
        continue;
      }

      // Получаем или создаем сводку для сотрудника
      final summary = summaryMap[entry.employeeId] ??
          TimesheetSummary(
            employeeId: entry.employeeId,
            employeeName:
                entry.employeeName ?? 'Сотрудник #${entry.employeeId}',
            hoursByDate: {},
            hoursByObject: {},
            totalHours: 0,
          );

      // Форматируем дату для ключа
      final dateKey =
          '${entry.date.year}-${entry.date.month.toString().padLeft(2, '0')}-${entry.date.day.toString().padLeft(2, '0')}';

      // Обновляем часы по дате
      final hoursByDate = Map<String, num>.from(summary.hoursByDate);
      hoursByDate[dateKey] = (hoursByDate[dateKey] ?? 0) + entry.hours;

      // Обновляем часы по объекту
      final hoursByObject = Map<String, num>.from(summary.hoursByObject);
      hoursByObject[entry.objectName ?? entry.objectId] =
          (hoursByObject[entry.objectName ?? entry.objectId] ?? 0) +
              entry.hours;

      // Обновляем общее количество часов
      final totalHours = summary.totalHours + entry.hours;

      // Обновляем сводку в словаре
      summaryMap[entry.employeeId] = summary.copyWith(
        hoursByDate: hoursByDate,
        hoursByObject: hoursByObject,
        totalHours: totalHours,
      );
    }

    // Возвращаем список сводок, отсортированный по имени сотрудника
    return summaryMap.values.toList()
      ..sort((a, b) => a.employeeName.compareTo(b.employeeName));
  }
}
