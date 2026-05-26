import 'package:flutter_test/flutter_test.dart';
import 'package:projectgt/domain/entities/employee.dart';
import 'package:projectgt/features/fot/domain/entities/payroll_payout_import.dart';
import 'package:projectgt/features/fot/presentation/services/payroll_payout_excel_import_service.dart';

void main() {
  group('normalizePayrollImportFio', () {
    test('приводит к нижнему регистру и схлопывает пробелы', () {
      expect(
        normalizePayrollImportFio('  АИБЕК   УУЛУ  ОРОЗМАМАТ  '),
        'аибек уулу орозмамат',
      );
    });
  });

  group('matchFioToEmployees', () {
    final employees = [
      const Employee(
        id: '1',
        companyId: 'c1',
        lastName: 'Аибек',
        firstName: 'Уулу',
        middleName: 'Орозмамат',
        employmentType: EmploymentType.official,
        status: EmployeeStatus.working,
      ),
      const Employee(
        id: '2',
        companyId: 'c1',
        lastName: 'Джембеков',
        firstName: 'Омурбек',
        employmentType: EmploymentType.official,
        status: EmployeeStatus.fired,
      ),
      const Employee(
        id: '3',
        companyId: 'c1',
        lastName: 'Иванов',
        firstName: 'Иван',
        middleName: 'Иванович',
        employmentType: EmploymentType.official,
        status: EmployeeStatus.working,
      ),
      const Employee(
        id: '4',
        companyId: 'c1',
        lastName: 'Иванов',
        firstName: 'Иван',
        middleName: 'Петрович',
        employmentType: EmploymentType.official,
        status: EmployeeStatus.working,
      ),
    ];

    PayrollPayoutImportRow match(String fio) {
      return PayrollPayoutExcelImportService.matchFioToEmployees(
        excelRowNumber: 2,
        fioFromFile: fio,
        amount: 100,
        employees: employees,
      );
    }

    test('находит сотрудника по ФИО в верхнем регистре', () {
      final row = match('АИБЕК УУЛУ ОРОЗМАМАТ');
      expect(row.status, PayrollPayoutImportMatchStatus.matched);
      expect(row.matchedEmployee?.id, '1');
    });

    test('находит уволенного при совпадении фамилии и имени', () {
      final row = match('Джембеков Омурбек');
      expect(row.status, PayrollPayoutImportMatchStatus.matched);
      expect(row.matchedEmployee?.id, '2');
    });

    test('неоднозначно при одинаковых фамилии и имени', () {
      final row = match('ИВАНОВ ИВАН');
      expect(row.status, PayrollPayoutImportMatchStatus.ambiguous);
      expect(row.ambiguousCandidates.length, 2);
    });

    test('не найден для неизвестного ФИО', () {
      final row = match('ПЕТРОВ ПЁТР ПЕТРОВИЧ');
      expect(row.status, PayrollPayoutImportMatchStatus.notFound);
    });

    test('точное совпадение с отчеством различает однофамильцев', () {
      final row = match('Иванов Иван Иванович');
      expect(row.status, PayrollPayoutImportMatchStatus.matched);
      expect(row.matchedEmployee?.id, '3');
    });
  });
}
