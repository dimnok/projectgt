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
}

/// Реализация data source через Supabase
class EmployeeRateDataSourceImpl implements EmployeeRateDataSource {
  final SupabaseClient _client;

  /// Создаёт экземпляр [EmployeeRateDataSourceImpl] с заданным [_client].
  const EmployeeRateDataSourceImpl(this._client);

  @override
  Future<List<EmployeeRateModel>> getEmployeeRates(String employeeId) async {
    final response = await _client
        .from('employee_rates')
        .select()
        .eq('employee_id', employeeId)
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
        .isFilter('valid_to', null)
        .maybeSingle();

    return response != null ? EmployeeRateModel.fromJson(response) : null;
  }

  @override
  Future<double> getRateForDate(String employeeId, DateTime date) async {
    final result = await _client.rpc('get_employee_rate', params: {
      'p_employee_id': employeeId,
      'p_date': date.toIso8601String().split('T')[0], // только дата
    });

    return (result as num?)?.toDouble() ?? 0.0;
  }

  @override
  Future<void> setNewRate(
      String employeeId, double rate, DateTime validFrom) async {
    // Получаем текущую активную ставку
    final currentRate = await getCurrentRate(employeeId);

    if (currentRate != null) {
      final currentValidFrom = currentRate.validFrom;
      final validFromDate =
          DateTime(validFrom.year, validFrom.month, validFrom.day);
      final currentValidFromDate = DateTime(
          currentValidFrom.year, currentValidFrom.month, currentValidFrom.day);

      // Если новая ставка устанавливается на ту же дату, что и текущая активная
      if (validFromDate.isAtSameMomentAs(currentValidFromDate)) {
        // Просто обновляем сумму существующей записи
        await _client
            .from('employee_rates')
            .update({'hourly_rate': rate}).eq('id', currentRate.id);
        return;
      } else if (validFromDate.isAfter(currentValidFromDate)) {
        // Если новая дата позже текущей, закрываем текущую ставку
        final previousDay = validFrom.subtract(const Duration(days: 1));
        await closeCurrentRate(employeeId, previousDay);
      } else {
        // Если новая дата раньше текущей, удаляем текущую активную ставку
        // чтобы избежать нарушения constraint valid_dates_check
        await _client.from('employee_rates').delete().eq('id', currentRate.id);
      }
    }

    // Добавляем новую ставку
    await _client.from('employee_rates').insert({
      'employee_id': employeeId,
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
        .isFilter('valid_to', null);
  }
}
