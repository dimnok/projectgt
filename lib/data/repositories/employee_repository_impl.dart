import 'package:projectgt/data/datasources/employee_data_source.dart';
import 'package:projectgt/data/models/employee_model.dart';
import 'package:projectgt/domain/entities/employee.dart';
import 'package:projectgt/domain/repositories/employee_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Имплементация [EmployeeRepository] для работы с сотрудниками через data source.
///
/// Инкапсулирует преобразование моделей и делегирует вызовы data-слою.
class EmployeeRepositoryImpl implements EmployeeRepository {
  /// Data source для работы с сотрудниками.
  final EmployeeDataSource dataSource;

  /// ID активной компании.
  final String activeCompanyId;

  /// Создаёт [EmployeeRepositoryImpl] с указанным [dataSource] и [activeCompanyId].
  EmployeeRepositoryImpl(this.dataSource, this.activeCompanyId);

  @override
  Future<List<Employee>> getEmployees() async {
    final employeeModels = await dataSource.getEmployees();
    return employeeModels.map((model) => model.toDomain()).toList();
  }

  @override
  Future<Employee?> getEmployee(String id) async {
    final employeeModel = await dataSource.getEmployee(id);
    return employeeModel?.toDomain();
  }

  @override
  Future<Employee> createEmployee(Employee employee) async {
    final employeeModel =
        await dataSource.createEmployee(EmployeeModel.fromDomain(employee));
    return employeeModel.toDomain();
  }

  @override
  Future<Employee> updateEmployee(Employee employee) async {
    final employeeModel =
        await dataSource.updateEmployee(EmployeeModel.fromDomain(employee));
    return employeeModel.toDomain();
  }

  @override
  Future<void> deleteEmployee(String id) async {
    await dataSource.deleteEmployee(id);
  }

  @override
  Future<List<String>> getPositions() async {
    final data = await Supabase.instance.client
        .from('employees')
        .select('position')
        .eq('company_id', activeCompanyId)
        .not('position', 'is', null);

    final positions = <String>{};
    for (final row in data as List) {
      final pos = row['position']?.toString().trim();
      if (pos != null && pos.isNotEmpty) {
        positions.add(pos);
      }
    }
    return positions.toList()..sort();
  }
}
