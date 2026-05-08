import '../datasources/employee_rate_data_source.dart';
import '../models/employee_rate_model.dart';
import '../../domain/repositories/employee_rate_repository.dart';
import '../../domain/entities/employee_rate.dart';

/// Реализация репозитория для работы со ставками сотрудников
class EmployeeRateRepositoryImpl implements EmployeeRateRepository {
  final EmployeeRateDataSource _dataSource;

  /// Создаёт экземпляр [EmployeeRateRepositoryImpl] с заданным [_dataSource].
  const EmployeeRateRepositoryImpl(this._dataSource);

  @override
  Future<List<EmployeeRate>> getEmployeeRates(String employeeId) async {
    final models = await _dataSource.getEmployeeRates(employeeId);
    return models.map(_mapToEntity).toList();
  }

  @override
  Future<EmployeeRate?> getCurrentRate(String employeeId) async {
    final model = await _dataSource.getCurrentRate(employeeId);
    return model != null ? _mapToEntity(model) : null;
  }

  @override
  Future<double> getRateForDate(String employeeId, DateTime date) async {
    return await _dataSource.getRateForDate(employeeId, date);
  }

  @override
  Future<void> setNewRate(
      String employeeId, double rate, DateTime validFrom) async {
    final validFromDate =
        DateTime(validFrom.year, validFrom.month, validFrom.day);
    final dayBefore = validFromDate.subtract(const Duration(days: 1));

    // Единая точка истины для разрешения пересечений:
    // 1. Берём ВСЕ ставки, чьи периоды пересекаются с [validFrom, +∞).
    final overlapping =
        await _dataSource.findOverlappingRates(employeeId, validFromDate);

    for (final rate in overlapping) {
      final existingFrom = DateTime(
        rate.validFrom.year,
        rate.validFrom.month,
        rate.validFrom.day,
      );

      if (existingFrom.isAtSameMomentAs(validFromDate)) {
        // Совпадает дата начала — старую запись удаляем,
        // ниже вставится новая с актуальной суммой.
        await _dataSource.deleteRate(rate.id);
      } else if (existingFrom.isBefore(validFromDate)) {
        // Старая ставка началась раньше — закрываем её днём до новой.
        await _dataSource.updateValidTo(rate.id, dayBefore);
      } else {
        // existingFrom > validFromDate — новая ставка перекрывает будущую.
        // Удаляем будущую запись.
        await _dataSource.deleteRate(rate.id);
      }
    }

    // 2. Создаём новую ставку (data source делает чистый INSERT).
    await _dataSource.setNewRate(employeeId, rate, validFromDate);
  }

  @override
  Future<List<EmployeeRate>> findOverlappingRates(
    String employeeId,
    DateTime validFrom,
  ) async {
    final models =
        await _dataSource.findOverlappingRates(employeeId, validFrom);
    return models.map(_mapToEntity).toList();
  }

  /// Преобразует модель данных в доменную сущность
  EmployeeRate _mapToEntity(EmployeeRateModel model) {
    return EmployeeRate(
      id: model.id,
      companyId: model.companyId,
      employeeId: model.employeeId,
      hourlyRate: model.hourlyRate,
      validFrom: model.validFrom,
      validTo: model.validTo,
      createdAt: model.createdAt,
      createdBy: model.createdBy,
    );
  }
}
