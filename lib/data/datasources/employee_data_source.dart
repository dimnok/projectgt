import 'package:logger/logger.dart';
import 'package:projectgt/data/models/employee_model.dart';
import 'package:projectgt/domain/entities/employee_blocking_shift.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Абстракция для источника данных по сотрудникам.
///
/// Определяет контракт для получения, создания, обновления и удаления сотрудников.
abstract class EmployeeDataSource {
  /// Получает список всех сотрудников с текущими ставками ([employee_rates]).
  ///
  /// Возвращает список [EmployeeModel].
  /// Генерирует исключение при ошибке.
  Future<List<EmployeeModel>> getEmployees();

  /// Справочник сотрудников компании без загрузки [employee_rates].
  ///
  /// Для табеля, выпадающих списков и других сценариев, где ставка не нужна.
  Future<List<EmployeeModel>> getEmployeesCatalog();

  /// Получает сотрудника по идентификатору.
  ///
  /// [id] — идентификатор сотрудника.
  /// Возвращает [EmployeeModel], если найден, иначе null.
  /// Генерирует исключение при ошибке.
  Future<EmployeeModel?> getEmployee(String id);

  /// Текущая почасовая ставка сотрудника (`employee_rates`, `valid_to IS NULL`).
  Future<double?> getCurrentHourlyRate(String employeeId);

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

  /// Смены, в которых у сотрудника есть строки в `work_hours` (для сообщения при запрете удаления).
  ///
  /// [employeeId] — идентификатор сотрудника.
  /// Возвращает смены текущей компании, от новых к старым по дате.
  Future<List<EmployeeBlockingShift>> getEmployeeDeleteBlockingShifts(
    String employeeId,
  );

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

  /// Уникальные должности сотрудников активной компании (отсортированные по алфавиту).
  ///
  /// Пустые и `null`-значения отфильтровываются на стороне БД.
  Future<List<String>> getPositions();
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

  bool get _hasActiveCompany =>
      activeCompanyId.isNotEmpty && activeCompanyId != 'null';

  /// Строки таблицы `employees` активной компании (без ставок).
  Future<List<EmployeeModel>> _fetchCompanyEmployees() async {
    final employeesResponse = await client
        .from('employees')
        .select('*')
        .eq('company_id', activeCompanyId)
        .order('last_name');

    return (employeesResponse as List)
        .map<EmployeeModel>((json) => EmployeeModel.fromJson(json))
        .toList();
  }

  /// Текущие ставки: `employee_id` → `hourly_rate`.
  Future<Map<String, double>> _fetchCurrentRatesByEmployeeId() async {
    final ratesResponse = await client
        .from('employee_rates')
        .select('employee_id, hourly_rate')
        .eq('company_id', activeCompanyId)
        .isFilter('valid_to', null);

    final ratesMap = <String, double>{};
    for (final rate in ratesResponse as List) {
      final employeeId = rate['employee_id'] as String;
      final hourlyRate = (rate['hourly_rate'] as num?)?.toDouble();
      if (hourlyRate != null) {
        ratesMap[employeeId] = hourlyRate;
      }
    }
    return ratesMap;
  }

  List<EmployeeModel> _mergeEmployeesWithRates(
    List<EmployeeModel> employees,
    Map<String, double> ratesByEmployeeId,
  ) {
    return employees.map((employee) {
      final currentRate = ratesByEmployeeId[employee.id];
      return currentRate != null
          ? employee.copyWith(currentHourlyRate: currentRate)
          : employee;
    }).toList();
  }

  @override
  Future<List<EmployeeModel>> getEmployeesCatalog() async {
    if (!_hasActiveCompany) {
      return [];
    }
    try {
      return await _fetchCompanyEmployees();
    } catch (e) {
      Logger().e('Error fetching employees catalog: $e');
      return [];
    }
  }

  @override
  Future<List<EmployeeModel>> getEmployees() async {
    if (!_hasActiveCompany) {
      return [];
    }
    try {
      final (employees, ratesByEmployeeId) = await (
        _fetchCompanyEmployees(),
        _fetchCurrentRatesByEmployeeId(),
      ).wait;

      return _mergeEmployeesWithRates(employees, ratesByEmployeeId);
    } catch (e) {
      Logger().e('Error fetching employees: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> _fetchCurrentRateRow(String employeeId) async {
    try {
      return await client
          .from('employee_rates')
          .select('hourly_rate')
          .eq('employee_id', employeeId)
          .eq('company_id', activeCompanyId)
          .isFilter('valid_to', null)
          .maybeSingle();
    } catch (e) {
      Logger().e('Error fetching current rate: $e');
      return null;
    }
  }

  @override
  Future<double?> getCurrentHourlyRate(String employeeId) async {
    final rateResponse = await _fetchCurrentRateRow(employeeId);
    if (rateResponse == null) return null;
    return (rateResponse['hourly_rate'] as num?)?.toDouble();
  }

  @override
  Future<EmployeeModel?> getEmployee(String id) async {
    try {
      final (response, rateResponse) = await (
        client
            .from('employees')
            .select('*')
            .eq('id', id)
            .eq('company_id', activeCompanyId)
            .single(),
        _fetchCurrentRateRow(id),
      ).wait;

      final employee = EmployeeModel.fromJson(response);
      if (rateResponse != null) {
        final currentRate = rateResponse['hourly_rate'] as num?;
        return employee.copyWith(
          currentHourlyRate: currentRate?.toDouble(),
        );
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
  Future<List<EmployeeBlockingShift>> getEmployeeDeleteBlockingShifts(
    String employeeId,
  ) async {
    if (activeCompanyId.isEmpty || activeCompanyId == 'null') {
      return [];
    }
    try {
      final hoursRows = await client
          .from('work_hours')
          .select('work_id')
          .eq('employee_id', employeeId);

      final workIds = <String>{};
      for (final row in hoursRows as List) {
        final wid = (row as Map)['work_id'] as String?;
        if (wid != null && wid.isNotEmpty) {
          workIds.add(wid);
        }
      }
      if (workIds.isEmpty) {
        return [];
      }

      final allWorkIds = workIds.toList();
      final worksRows = <dynamic>[];
      const chunk = 20;
      for (var i = 0; i < allWorkIds.length; i += chunk) {
        final slice = allWorkIds.sublist(
          i,
          i + chunk > allWorkIds.length ? allWorkIds.length : i + chunk,
        );
        final chunkRows = await client
            .from('works')
            .select('id, date, object_id, objects(name)')
            .eq('company_id', activeCompanyId)
            .inFilter('id', slice);
        worksRows.addAll(chunkRows as List);
      }
      
      // Сортировка на клиенте, так как мы запрашивали частями
      worksRows.sort((a, b) {
        final dateA = (a as Map)['date'] as String? ?? '';
        final dateB = (b as Map)['date'] as String? ?? '';
        return dateB.compareTo(dateA); // descending
      });

      final out = <EmployeeBlockingShift>[];
      for (final row in worksRows) {
        final m = Map<String, dynamic>.from(row as Map);
        final id = m['id'] as String? ?? '';
        final dateRaw = m['date'];
        DateTime? date;
        if (dateRaw is String) {
          date = DateTime.tryParse(dateRaw);
        } else if (dateRaw != null) {
          date = DateTime.tryParse(dateRaw.toString());
        }
        if (date == null) {
          continue;
        }

        var objectName = 'Объект не указан';
        final nested = m['objects'];
        if (nested is Map && nested['name'] != null) {
          final n = nested['name'].toString().trim();
          if (n.isNotEmpty) {
            objectName = n;
          }
        }

        out.add(
          EmployeeBlockingShift(
            workId: id,
            date: date,
            objectName: objectName,
          ),
        );
      }
      out.sort((a, b) => b.date.compareTo(a.date));
      return out;
    } catch (e) {
      Logger().e('Error loading employee delete blocking shifts: $e');
      return [];
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
  Future<List<String>> getPositions() async {
    if (activeCompanyId.isEmpty || activeCompanyId == 'null') {
      return [];
    }
    try {
      final response = await client.rpc(
        'get_employee_positions',
        params: {'p_company_id': activeCompanyId},
      );
      if (response is! List) return [];
      final out = <String>[];
      for (final row in response) {
        if (row is Map) {
          final name = row['position_name']?.toString().trim();
          if (name != null && name.isNotEmpty) {
            out.add(name);
          }
        }
      }
      return out;
    } catch (e) {
      Logger().e('Error fetching employee positions: $e');
      return [];
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
