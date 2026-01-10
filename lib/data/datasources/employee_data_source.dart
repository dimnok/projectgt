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

  /// Получает сотрудников, которые могут быть назначены ответственными по объекту.
  ///
  /// [objectId] — идентификатор объекта.
  /// Возвращает список [EmployeeModel] с can_be_responsible=true, status='working'
  /// и привязкой к объекту.
  Future<List<EmployeeModel>> getResponsibleEmployees(String objectId);

  /// Обновляет флаг can_be_responsible для сотрудника.
  Future<EmployeeModel> setCanBeResponsible({
    required String employeeId,
    required bool value,
  });

  /// Возвращает текущее значение флага can_be_responsible для сотрудника.
  Future<bool> getCanBeResponsible(String employeeId);

  /// Возвращает мапу флага can_be_responsible для всех сотрудников: id -> bool.
  Future<Map<String, bool>> getCanBeResponsibleMap();
}

/// Реализация [EmployeeDataSource] через Supabase.
///
/// Использует Supabase для CRUD-операций с таблицей employees.
class SupabaseEmployeeDataSource implements EmployeeDataSource {
  /// Экземпляр клиента Supabase.
  final SupabaseClient client;

  /// ID активной компании.
  final String activeCompanyId;

  /// Создаёт источник данных по сотрудникам через Supabase.
  ///
  /// [client] — экземпляр [SupabaseClient].
  /// [activeCompanyId] — ID активной компании.
  SupabaseEmployeeDataSource(this.client, this.activeCompanyId);

  @override
  Future<List<EmployeeModel>> getEmployees() async {
    if (activeCompanyId.isEmpty || activeCompanyId == 'null') {
      return [];
    }
    try {
      final response = await client
          .from('employees')
          .select('*')
          .eq('company_id', activeCompanyId)
          .order('last_name');

      final employees = response
          .map<EmployeeModel>((json) => EmployeeModel.fromJson(json))
          .toList();

      // Загружаем текущие ставки для всех сотрудников одним запросом
      try {
        final ratesResponse = await client
            .from('employee_rates')
            .select('employee_id, hourly_rate')
            .eq('company_id', activeCompanyId)
            .isFilter('valid_to', null);

        // Создаем мапу employee_id -> hourly_rate
        final ratesMap = <String, double>{};
        for (final rate in ratesResponse) {
          final employeeId = rate['employee_id'] as String;
          final hourlyRate = (rate['hourly_rate'] as num?)?.toDouble();
          if (hourlyRate != null) {
            ratesMap[employeeId] = hourlyRate;
          }
        }

        // Обновляем сотрудников с их текущими ставками
        return employees.map((employee) {
          final currentRate = ratesMap[employee.id];
          return currentRate != null
              ? employee.copyWith(currentHourlyRate: currentRate)
              : employee;
        }).toList();
      } catch (e) {
        Logger().e('Error fetching current rates: $e');
        return employees;
      }
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
          .eq('company_id', activeCompanyId)
          .single();

      final employee = EmployeeModel.fromJson(response);

      // Загружаем текущую ставку сотрудника
      try {
        final rateResponse = await client
            .from('employee_rates')
            .select('hourly_rate')
            .eq('employee_id', id)
            .eq('company_id', activeCompanyId)
            .isFilter('valid_to', null)
            .maybeSingle();

        if (rateResponse != null) {
          final currentRate = rateResponse['hourly_rate'] as num?;
          return employee.copyWith(
            currentHourlyRate: currentRate?.toDouble(),
          );
        }
      } catch (e) {
        Logger().e('Error fetching current rate: $e');
      }

      return employee;
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
          .eq('company_id', activeCompanyId)
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
          .eq('id', id)
          .eq('company_id', activeCompanyId);
    } catch (e) {
      Logger().e('Error deleting employee: $e');
      rethrow;
    }
  }

  @override
  Future<List<EmployeeModel>> getResponsibleEmployees(String objectId) async {
    try {
      final response = await client
          .from('employees')
          .select('*')
          .eq('company_id', activeCompanyId)
          .eq('status', 'working')
          .eq('can_be_responsible', true)
          .contains('object_ids', [objectId]).order('last_name');

      return response
          .map<EmployeeModel>((json) => EmployeeModel.fromJson(json))
          .toList();
    } catch (e) {
      Logger().e('Error fetching responsible employees: $e');
      return [];
    }
  }

  @override
  Future<EmployeeModel> setCanBeResponsible({
    required String employeeId,
    required bool value,
  }) async {
    try {
      final now = DateTime.now().toIso8601String();
      final response = await client
          .from('employees')
          .update({
            'can_be_responsible': value,
            'updated_at': now,
          })
          .eq('id', employeeId)
          .eq('company_id', activeCompanyId)
          .select('*')
          .single();

      return EmployeeModel.fromJson(response);
    } catch (e) {
      Logger().e('Error updating can_be_responsible: $e');
      rethrow;
    }
  }

  @override
  Future<bool> getCanBeResponsible(String employeeId) async {
    try {
      final response = await client
          .from('employees')
          .select('can_be_responsible')
          .eq('id', employeeId)
          .eq('company_id', activeCompanyId)
          .single();
      final value = response['can_be_responsible'] as bool?;
      return value == true;
    } catch (e) {
      Logger().e('Error reading can_be_responsible: $e');
      return false;
    }
  }

  @override
  Future<Map<String, bool>> getCanBeResponsibleMap() async {
    if (activeCompanyId.isEmpty) {
      return {};
    }
    try {
      final rows = await client
          .from('employees')
          .select('id, can_be_responsible')
          .eq('company_id', activeCompanyId);
      final map = <String, bool>{};
      for (final row in rows as List<dynamic>) {
        final id = (row as Map)['id'] as String?;
        final v = row['can_be_responsible'] as bool?;
        if (id != null) {
          map[id] = v == true;
        }
      }
      return map;
    } catch (e) {
      Logger().e('Error fetching can_be_responsible map: $e');
      return {};
    }
  }
}
