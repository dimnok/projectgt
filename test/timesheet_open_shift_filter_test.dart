import 'package:flutter_test/flutter_test.dart';
import 'package:projectgt/domain/entities/employee.dart';
import 'package:projectgt/features/timesheet/domain/timesheet_open_shift_filter.dart';
import 'package:projectgt/features/timesheet/domain/timesheet_today_open_shift.dart';

Employee _employee({required String id, String? position}) => Employee(
  id: id,
  companyId: 'c1',
  lastName: 'Иванов',
  firstName: 'Иван',
  employmentType: EmploymentType.official,
  status: EmployeeStatus.working,
  position: position,
);

TimesheetTodayOpenShiftIndex _index(Map<String, Set<String>> byEmployee) {
  return TimesheetTodayOpenShiftIndex(
    employeeIds: byEmployee.keys.toSet(),
    objectIdsByEmployeeId: byEmployee,
    hintByEmployeeId: const {},
  );
}

void main() {
  final employees = [
    _employee(id: 'e1', position: 'Монтажник'),
    _employee(id: 'e2', position: 'Инженер'),
    _employee(id: 'e3', position: 'Монтажник'),
  ];

  final todayOpenShift = _index({
    'e1': {'obj-a'},
    'e2': {'obj-b'},
  });

  group('filterEmployeesByOpenShiftScope', () {
    test('all — без изменений', () {
      expect(
        filterEmployeesByOpenShiftScope(
          employees,
          todayOpenShift: todayOpenShift,
          scope: TimesheetOpenShiftFilterScope.all,
          periodContainsToday: true,
        ).map((e) => e.id),
        ['e1', 'e2', 'e3'],
      );
    });

    test('inOpenShift — только назначенные', () {
      expect(
        filterEmployeesByOpenShiftScope(
          employees,
          todayOpenShift: todayOpenShift,
          scope: TimesheetOpenShiftFilterScope.inOpenShift,
          periodContainsToday: true,
        ).map((e) => e.id),
        ['e1', 'e2'],
      );
    });

    test('notInOpenShift — без назначенных', () {
      expect(
        filterEmployeesByOpenShiftScope(
          employees,
          todayOpenShift: todayOpenShift,
          scope: TimesheetOpenShiftFilterScope.notInOpenShift,
          periodContainsToday: true,
        ).map((e) => e.id),
        ['e3'],
      );
    });

    test('вне текущего месяца — фильтр не применяется', () {
      expect(
        filterEmployeesByOpenShiftScope(
          employees,
          todayOpenShift: todayOpenShift,
          scope: TimesheetOpenShiftFilterScope.inOpenShift,
          periodContainsToday: false,
        ).map((e) => e.id),
        ['e1', 'e2', 'e3'],
      );
    });
  });

  group('employeesInTodayOpenShift', () {
    test('учитывает должности и объекты', () {
      final result = employeesInTodayOpenShift(
        allEmployees: employees,
        todayOpenShift: todayOpenShift,
        positionKeys: {'монтажник'},
        selectedObjectIds: ['obj-a'],
      );

      expect(result.map((e) => e.id), ['e1']);
    });

    test('без фильтра объектов — все в смене', () {
      expect(
        employeesInTodayOpenShift(
          allEmployees: employees,
          todayOpenShift: todayOpenShift,
          positionKeys: const {},
          selectedObjectIds: null,
        ).map((e) => e.id),
        ['e1', 'e2'],
      );
    });
  });
}
