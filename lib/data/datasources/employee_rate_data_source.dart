import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/employee_rate_model.dart';

/// Абстракция data source для работы со ставками сотрудников
abstract class EmployeeRateDataSource {
  /// Получить все ставки сотрудника (включая историю)
  Future<List<EmployeeRateModel>> getEmployeeRates(String employeeId);

  /// Получить текущую активную ставку сотрудника
  Future<EmployeeRateModel?> getCurrentRate(String employeeId);

  /// Получить ставку сотрудника на конкретную дату
  Future<double> getRateForDate(String employeeId, DateTime date);

  /// Установить новую ставку сотрудника
  Future<void> setNewRate(String employeeId, double rate, DateTime validFrom);

  /// Закрыть текущую ставку сотрудника
  Future<void> closeCurrentRate(String employeeId, DateTime validTo);

  /// Найти все ставки сотрудника, период действия которых пересекается с
  /// открытым полуинтервалом [validFrom, +∞).
  ///
  /// Возвращаются как открытые ставки (`valid_to IS NULL`), так и закрытые,
  /// у которых `valid_to >= validFrom` — то есть всё, что должно быть закрыто
  /// или удалено перед вставкой новой ставки c указанной датой начала.
  Future<List<EmployeeRateModel>> findOverlappingRates(
    String employeeId,
    DateTime validFrom,
  );

  /// Обновить дату окончания действия конкретной ставки.
  Future<void> updateValidTo(String rateId, DateTime validTo);

  /// Удалить ставку по идентификатору.
  Future<void> deleteRate(String rateId);
}

/// Реализация data source через Supabase
class EmployeeRateDataSourceImpl implements EmployeeRateDataSource {
  final SupabaseClient _client;
  final String _activeCompanyId;

  /// Создаёт экземпляр [EmployeeRateDataSourceImpl] с заданным [_client].
  const EmployeeRateDataSourceImpl(this._client, this._activeCompanyId);

  @override
  Future<List<EmployeeRateModel>> getEmployeeRates(String employeeId) async {
    final response = await _client
        .from('employee_rates')
        .select()
        .eq('employee_id', employeeId)
        .eq('company_id', _activeCompanyId)
        .order('valid_from', ascending: false);

    return response
        .map<EmployeeRateModel>((json) => EmployeeRateModel.fromJson(json))
        .toList();
  }

  @override
  Future<EmployeeRateModel?> getCurrentRate(String employeeId) async {
    final response = await _client
        .from('employee_rates')
        .select()
        .eq('employee_id', employeeId)
        .eq('company_id', _activeCompanyId)
        .isFilter('valid_to', null)
        .maybeSingle();

    return response != null ? EmployeeRateModel.fromJson(response) : null;
  }

  @override
  Future<double> getRateForDate(String employeeId, DateTime date) async {
    final result = await _client.rpc('get_employee_rate', params: {
      'p_employee_id': employeeId,
      'p_date': date.toIso8601String().split('T')[0], // только дата
      'p_company_id': _activeCompanyId,
    });

    return (result as num?)?.toDouble() ?? 0.0;
  }

  @override
  Future<void> setNewRate(
      String employeeId, double rate, DateTime validFrom) async {
    // Чистый INSERT без побочной логики закрытий/удалений.
    // Корректировку пересекающихся ставок делает вышестоящий слой
    // ([EmployeeRateRepositoryImpl.setNewRate]) — это единая точка истины.
    await _client.from('employee_rates').insert({
      'employee_id': employeeId,
      'company_id': _activeCompanyId,
      'hourly_rate': rate,
      'valid_from': validFrom.toIso8601String().split('T')[0],
    });
  }

  @override
  Future<void> closeCurrentRate(String employeeId, DateTime validTo) async {
    await _client
        .from('employee_rates')
        .update({'valid_to': validTo.toIso8601String().split('T')[0]})
        .eq('employee_id', employeeId)
        .eq('company_id', _activeCompanyId)
        .isFilter('valid_to', null);
  }

  @override
  Future<List<EmployeeRateModel>> findOverlappingRates(
    String employeeId,
    DateTime validFrom,
  ) async {
    final fromStr = validFrom.toIso8601String().split('T')[0];

    // Пересечение с [validFrom, +∞):
    //   valid_to IS NULL                          — открытая ставка
    //   ИЛИ valid_to >= validFrom                 — закрытая, но ещё активная
    final response = await _client
        .from('employee_rates')
        .select()
        .eq('employee_id', employeeId)
        .eq('company_id', _activeCompanyId)
        .or('valid_to.is.null,valid_to.gte.$fromStr')
        .order('valid_from', ascending: true);

    return response
        .map<EmployeeRateModel>((json) => EmployeeRateModel.fromJson(json))
        .toList();
  }

  @override
  Future<void> updateValidTo(String rateId, DateTime validTo) async {
    await _client
        .from('employee_rates')
        .update({'valid_to': validTo.toIso8601String().split('T')[0]})
        .eq('id', rateId)
        .eq('company_id', _activeCompanyId);
  }

  @override
  Future<void> deleteRate(String rateId) async {
    await _client
        .from('employee_rates')
        .delete()
        .eq('id', rateId)
        .eq('company_id', _activeCompanyId);
  }
}
