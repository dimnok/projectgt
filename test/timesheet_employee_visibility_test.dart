import 'package:flutter_test/flutter_test.dart';
import 'package:projectgt/domain/entities/employee.dart';
import 'package:projectgt/features/timesheet/domain/timesheet_employee_list_scope.dart';
import 'package:projectgt/features/timesheet/domain/timesheet_employee_visibility.dart';
import 'package:projectgt/features/timesheet/domain/timesheet_hours_index.dart';

Employee _employee({
  required String id,
  required String lastName,
  EmployeeStatus status = EmployeeStatus.working,
  bool includeInTimesheet = true,
}) {
  return Employee(
    id: id,
    companyId: 'c1',
    lastName: lastName,
    firstName: 'И',
    employmentType: EmploymentType.official,
    status: status,
    includeInTimesheet: includeInTimesheet,
  );
}

void main() {
  group('isTimesheetGridEmployeeVisible', () {
    final index = TimesheetHoursIndex.fromEmployeeHours([
      (employeeId: 'fired-with', hours: 8),
      (employeeId: 'active-with', hours: 4),
    ]);

    test('без фильтра объектов: активные всегда видны', () {
      expect(
        isTimesheetGridEmployeeVisible(
          isFired: false,
          includeInTimesheet: true,
          employeeId: 'nobody',
          hoursIndex: index,
          hasObjectFilter: false,
        ),
        isTrue,
      );
    });

    test('без фильтра объектов: исключён из табеля только с записями', () {
      expect(
        isTimesheetGridEmployeeVisible(
          isFired: false,
          includeInTimesheet: false,
          employeeId: 'active-with',
          hoursIndex: index,
          hasObjectFilter: false,
        ),
        isTrue,
      );
      expect(
        isTimesheetGridEmployeeVisible(
          isFired: false,
          includeInTimesheet: false,
          employeeId: 'nobody',
          hoursIndex: index,
          hasObjectFilter: false,
        ),
        isFalse,
      );
    });

    test('без фильтра объектов: уволенный только с записями', () {
      expect(
        isTimesheetGridEmployeeVisible(
          isFired: true,
          includeInTimesheet: true,
          employeeId: 'fired-with',
          hoursIndex: index,
          hasObjectFilter: false,
        ),
        isTrue,
      );
      expect(
        isTimesheetGridEmployeeVisible(
          isFired: true,
          includeInTimesheet: true,
          employeeId: 'fired-empty',
          hoursIndex: index,
          hasObjectFilter: false,
        ),
        isFalse,
      );
    });

    test('с фильтром объектов: только с записями', () {
      expect(
        isTimesheetGridEmployeeVisible(
          isFired: false,
          includeInTimesheet: true,
          employeeId: 'active-with',
          hoursIndex: index,
          hasObjectFilter: true,
        ),
        isTrue,
      );
      expect(
        isTimesheetGridEmployeeVisible(
          isFired: false,
          includeInTimesheet: true,
          employeeId: 'nobody',
          hoursIndex: index,
          hasObjectFilter: true,
        ),
        isFalse,
      );
    });
  });

  group('visibleTimesheetGridEmployees', () {
    test('исключён из табеля без часов не в списке', () {
      final employees = [
        _employee(id: 'x', lastName: 'Офис'),
        _employee(
          id: 'y',
          lastName: 'Смена',
          includeInTimesheet: false,
        ),
      ];
      final index = TimesheetHoursIndex.fromEmployeeHours([
        (employeeId: 'y', hours: 8),
      ]);
      final visible = visibleTimesheetGridEmployees(
        employees: employees,
        hoursIndex: index,
        hasObjectFilter: false,
      );
      expect(visible.map((e) => e.id).toList(), ['x', 'y']);
    });

    final employees = [
      _employee(id: 'a', lastName: 'Антонов'),
      _employee(id: 'b', lastName: 'Борисов', status: EmployeeStatus.fired),
      _employee(id: 'c', lastName: 'Васильев'),
    ];

    final index = TimesheetHoursIndex.fromEmployeeHours([
      (employeeId: 'b', hours: 8),
      (employeeId: 'c', hours: 0),
    ]);

    test('сегмент withHours', () {
      final visible = visibleTimesheetGridEmployees(
        employees: employees,
        hoursIndex: index,
        hasObjectFilter: false,
        listScope: TimesheetEmployeeListScope.withHours,
      );
      expect(visible.map((e) => e.id).toList(), ['b']);
    });

    test('сегмент withoutHours включает активных без записей', () {
      final visible = visibleTimesheetGridEmployees(
        employees: employees,
        hoursIndex: index,
        hasObjectFilter: false,
        listScope: TimesheetEmployeeListScope.withoutHours,
      );
      expect(visible.map((e) => e.id).toSet(), {'a', 'c'});
    });
  });

  group('visibleTimesheetExportEmployees', () {
    test('ограничение по выбранным id', () {
      final employees = [
        _employee(id: 'a', lastName: 'А'),
        _employee(id: 'b', lastName: 'Б'),
      ];
      final index = TimesheetHoursIndex.fromEmployeeHours([
        (employeeId: 'a', hours: 1),
        (employeeId: 'b', hours: 2),
      ]);

      final visible = visibleTimesheetExportEmployees(
        employees: employees,
        hoursIndex: index,
        hasObjectFilter: false,
        onlyEmployeeIds: ['b'],
      );

      expect(visible.map((e) => e.id).toList(), ['b']);
    });
  });
}
