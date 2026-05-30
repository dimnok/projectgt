import 'package:flutter_test/flutter_test.dart';
import 'package:projectgt/domain/entities/employee.dart';
import 'package:projectgt/features/timesheet/presentation/widgets/timesheet_filter_widget.dart';

Employee _employee(String id, String lastName) => Employee(
  id: id,
  companyId: 'c1',
  lastName: lastName,
  firstName: 'Иван',
  employmentType: EmploymentType.official,
  status: EmployeeStatus.working,
);

void main() {
  group('filterEmployeesByTimesheetNameSearch', () {
    final employees = [
      _employee('1', 'Антонов'),
      _employee('2', 'Борисов'),
    ];

    test('пустой запрос — все сотрудники', () {
      expect(
        filterEmployeesByTimesheetNameSearch(employees, ''),
        employees,
      );
    });

    test('частичное совпадение по фамилии', () {
      expect(
        filterEmployeesByTimesheetNameSearch(employees, 'бор').map((e) => e.id),
        ['2'],
      );
    });
  });
}
