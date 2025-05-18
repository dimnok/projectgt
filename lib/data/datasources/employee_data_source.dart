import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:projectgt/data/models/employee_model.dart';
import 'package:logger/logger.dart';

/// Абстракция для источника данных по сотрудникам.
///
/// Определяет контракт для получения, создания, обновления и удаления сотрудников.
abstract class EmployeeDataSource {
  /// Получает список всех сотрудников.
  ///
  /// Возвращает список [EmployeeModel].
  /// Генерирует исключение при ошибке.
  Future<List<EmployeeModel>> getEmployees();

  /// Получает сотрудника по идентификатору.
  ///
  /// [id] — идентификатор сотрудника.
  /// Возвращает [EmployeeModel], если найден, иначе null.
  /// Генерирует исключение при ошибке.
  Future<EmployeeModel?> getEmployee(String id);

  /// Создаёт нового сотрудника.
  ///
  /// [employee] — модель сотрудника.
  /// Возвращает созданный [EmployeeModel].
  /// Генерирует исключение при ошибке.
  Future<EmployeeModel> createEmployee(EmployeeModel employee);

  /// Обновляет существующего сотрудника.
  ///
  /// [employee] — модель сотрудника для обновления.
  /// Возвращает обновлённый [EmployeeModel].
  /// Генерирует исключение при ошибке.
  Future<EmployeeModel> updateEmployee(EmployeeModel employee);

  /// Удаляет сотрудника по идентификатору.
  ///
  /// [id] — идентификатор сотрудника.
  /// Генерирует исключение при ошибке.
  Future<void> deleteEmployee(String id);
}

/// Реализация [EmployeeDataSource] через Supabase.
///
/// Использует Supabase для CRUD-операций с таблицей employees.
class SupabaseEmployeeDataSource implements EmployeeDataSource {
  /// Экземпляр клиента Supabase.
  final SupabaseClient client;

  /// Создаёт источник данных по сотрудникам через Supabase.
  ///
  /// [client] — экземпляр [SupabaseClient].
  SupabaseEmployeeDataSource(this.client);

  @override
  Future<List<EmployeeModel>> getEmployees() async {
    try {
      final response = await client
          .from('employees')
          .select('*')
          .order('last_name');
      
      return response.map<EmployeeModel>((json) => EmployeeModel.fromJson(json)).toList();
    } catch (e) {
      Logger().e('Error fetching employees: $e');
      return [];
    }
  }

  @override
  Future<EmployeeModel?> getEmployee(String id) async {
    try {
      final response = await client
          .from('employees')
          .select('*')
          .eq('id', id)
          .single();
      
      return EmployeeModel.fromJson(response);
    } catch (e) {
      Logger().e('Error fetching employee: $e');
      return null;
    }
  }

  @override
  Future<EmployeeModel> createEmployee(EmployeeModel employee) async {
    try {
      // Создаем дату для created_at и updated_at
      final now = DateTime.now().toIso8601String();
      
      final employeeJson = employee.toJson();
      // Добавляем дату создания и обновления
      employeeJson['created_at'] = now;
      employeeJson['updated_at'] = now;
      
      final response = await client
          .from('employees')
          .insert(employeeJson)
          .select('*')
          .single();
      
      return EmployeeModel.fromJson(response);
    } catch (e) {
      Logger().e('Error creating employee: $e');
      rethrow;
    }
  }

  @override
  Future<EmployeeModel> updateEmployee(EmployeeModel employee) async {
    try {
      // Обновляем только updated_at
      final now = DateTime.now().toIso8601String();
      
      final employeeJson = employee.toJson();
      // Обновляем дату изменения
      employeeJson['updated_at'] = now;
      
      final response = await client
          .from('employees')
          .update(employeeJson)
          .eq('id', employee.id)
          .select('*')
          .single();
      
      return EmployeeModel.fromJson(response);
    } catch (e) {
      Logger().e('Error updating employee: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteEmployee(String id) async {
    try {
      await client
          .from('employees')
          .delete()
          .eq('id', id);
    } catch (e) {
      Logger().e('Error deleting employee: $e');
      rethrow;
    }
  }
} 