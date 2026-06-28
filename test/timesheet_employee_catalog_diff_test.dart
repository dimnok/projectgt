import 'package:flutter_test/flutter_test.dart';
import 'package:projectgt/domain/entities/employee.dart';
import 'package:projectgt/features/timesheet/domain/timesheet_employee_catalog_diff.dart';

Employee _employee({
  required String id,
  String lastName = 'Иванов',
  double? rate,
  bool includeInTimesheet = true,
}) {
  return Employee(
    id: id,
    companyId: 'c1',
    lastName: lastName,
    firstName: 'Иван',
    currentHourlyRate: rate,
    includeInTimesheet: includeInTimesheet,
  );
}

void main() {
  group('timesheetEmployeeCatalogChanged', () {
    test('false для одинаковых списков по ссылке', () {
      const list = <Employee>[];
      expect(timesheetEmployeeCatalogChanged(list, list), isFalse);
    });

    test('false при изменении только ставки', () {
      final before = [_employee(id: '1', rate: 100)];
      final after = [_employee(id: '1', rate: 200)];
      expect(timesheetEmployeeCatalogChanged(before, after), isFalse);
    });

    test('true при изменении include_in_timesheet', () {
      final before = [_employee(id: '1', includeInTimesheet: true)];
      final after = [_employee(id: '1', includeInTimesheet: false)];
      expect(timesheetEmployeeCatalogChanged(before, after), isTrue);
    });

    test('true при добавлении сотрудника', () {
      final before = [_employee(id: '1')];
      final after = [_employee(id: '1'), _employee(id: '2', lastName: 'Петров')];
      expect(timesheetEmployeeCatalogChanged(before, after), isTrue);
    });
  });
}
