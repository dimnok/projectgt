import 'package:flutter_test/flutter_test.dart';
import 'package:projectgt/domain/entities/employee.dart';
import 'package:projectgt/features/timesheet/domain/timesheet_position_filter.dart';

Employee _employee({required String id, String? position}) => Employee(
  id: id,
  companyId: 'c1',
  lastName: 'Иванов',
  firstName: 'Иван',
  employmentType: EmploymentType.official,
  status: EmployeeStatus.working,
  position: position,
);

void main() {
  group('buildTimesheetPositionFilterOptions', () {
    test('объединяет регистр и добавляет «Без должности»', () {
      final options = buildTimesheetPositionFilterOptions([
        _employee(id: '1', position: 'Монтажник'),
        _employee(id: '2', position: 'монтажник'),
        _employee(id: '3'),
      ]);

      expect(options.length, 2);
      expect(
        options.map((o) => o.key),
        containsAll([kTimesheetNoPositionFilterKey, 'монтажник']),
      );
      expect(
        options.firstWhere((o) => o.key == 'монтажник').label,
        'Монтажник',
      );
    });
  });

  group('filterEmployeesByTimesheetPositionKeys', () {
    final employees = [
      _employee(id: '1', position: 'Инженер'),
      _employee(id: '2', position: 'Монтажник'),
      _employee(id: '3'),
    ];

    test('пустой набор — без фильтрации', () {
      expect(
        filterEmployeesByTimesheetPositionKeys(employees, const {}).map((e) => e.id),
        ['1', '2', '3'],
      );
    });

    test('одна должность', () {
      expect(
        filterEmployeesByTimesheetPositionKeys(employees, {'инженер'})
            .map((e) => e.id),
        ['1'],
      );
    });

    test('без должности', () {
      expect(
        filterEmployeesByTimesheetPositionKeys(
          employees,
          {kTimesheetNoPositionFilterKey},
        ).map((e) => e.id),
        ['3'],
      );
    });
  });
}
