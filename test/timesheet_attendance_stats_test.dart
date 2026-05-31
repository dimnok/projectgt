import 'package:flutter_test/flutter_test.dart';
import 'package:projectgt/domain/entities/employee.dart';
import 'package:projectgt/features/timesheet/domain/entities/timesheet_entry.dart';
import 'package:projectgt/features/timesheet/domain/timesheet_attendance_stats.dart';

Employee _employee({
  required String id,
  required String lastName,
}) {
  return Employee(
    id: id,
    companyId: 'c1',
    lastName: lastName,
    firstName: 'И',
    employmentType: EmploymentType.official,
    status: EmployeeStatus.working,
    includeInTimesheet: true,
  );
}

TimesheetEntry _entry({
  required String employeeId,
  required DateTime date,
  num hours = 8,
}) {
  return TimesheetEntry(
    id: '${employeeId}_${date.day}',
    workId: 'w1',
    employeeId: employeeId,
    hours: hours,
    date: date,
    objectId: 'o1',
  );
}

void main() {
  final start = DateTime(2026, 5, 1);
  final end = DateTime(2026, 5, 31);

  group('computeTimesheetAttendanceStats', () {
    test('возвращает топ-5 по отработанным дням', () {
      final employees = List.generate(
        7,
        (i) => _employee(id: 'e$i', lastName: 'Сотрудник${7 - i}'),
      );

      final entries = <TimesheetEntry>[];
      for (var i = 0; i < 7; i++) {
        final days = i + 1;
        for (var d = 1; d <= days; d++) {
          entries.add(_entry(employeeId: 'e$i', date: DateTime(2026, 5, d)));
        }
      }

      final result = computeTimesheetAttendanceStats(
        employees: employees,
        entries: entries,
        startDate: start,
        endDate: end,
        hasObjectFilter: false,
        topCount: 5,
      );

      expect(result.totalEmployeesConsidered, 7);
      expect(result.topHighAttendance, hasLength(5));
      expect(result.topHighAttendance.first.employeeId, 'e6');
      expect(result.topHighAttendance.first.workedDays, 7);
      expect(result.topLowAttendance, hasLength(5));
      expect(result.topLowAttendance.first.employeeId, 'e0');
      expect(result.topLowAttendance.first.workedDays, 1);
    });

    test('пустой каталог — пустой результат', () {
      final result = computeTimesheetAttendanceStats(
        employees: const [],
        entries: const [],
        startDate: start,
        endDate: end,
        hasObjectFilter: false,
      );
      expect(result, TimesheetAttendanceStatsResult.empty);
    });
  });
}
