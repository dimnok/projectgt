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
    // 1. Закрываем текущую ставку (если есть)
    await _dataSource.closeCurrentRate(
        employeeId, validFrom.subtract(const Duration(days: 1)));

    // 2. Создаём новую ставку
    await _dataSource.setNewRate(employeeId, rate, validFrom);
  }

  /// Преобразует модель данных в доменную сущность
  EmployeeRate _mapToEntity(EmployeeRateModel model) {
    return EmployeeRate(
      id: model.id,
      employeeId: model.employeeId,
      hourlyRate: model.hourlyRate,
      validFrom: model.validFrom,
      validTo: model.validTo,
      createdAt: model.createdAt,
      createdBy: model.createdBy,
    );
  }
}
