import 'package:projectgt/data/datasources/business_trip_rate_data_source.dart';
import 'package:projectgt/data/models/business_trip_rate_model.dart';
import 'package:projectgt/domain/entities/business_trip_rate.dart';
import 'package:projectgt/domain/repositories/business_trip_rate_repository.dart';

/// Реализация репозитория для работы с ставками командировочных выплат.
///
/// Использует [BusinessTripRateDataSource] для работы с данными и преобразует
/// модели данных в доменные сущности и обратно.
///
/// Пример использования:
/// ```dart
/// final repository = BusinessTripRateRepositoryImpl(dataSource);
/// final rates = await repository.getAllRates();
/// ```
class BusinessTripRateRepositoryImpl implements BusinessTripRateRepository {
  /// DataSource для работы с данными командировочных ставок.
  final BusinessTripRateDataSource _dataSource;

  /// Конструктор [BusinessTripRateRepositoryImpl].
  ///
  /// [_dataSource] — источник данных для работы с командировочными ставками.
  const BusinessTripRateRepositoryImpl(this._dataSource);

  @override
  Future<List<BusinessTripRate>> getAllRates() async {
    try {
      final models = await _dataSource.getAllRates();
      return models.map((model) => model.toDomain()).toList();
    } catch (e) {
      throw Exception('Ошибка получения всех ставок командировочных: $e');
    }
  }

  @override
  Future<List<BusinessTripRate>> getRatesByObjectId(String objectId) async {
    try {
      final models = await _dataSource.getRatesByObjectId(objectId);
      return models.map((model) => model.toDomain()).toList();
    } catch (e) {
      throw Exception('Ошибка получения ставок для объекта $objectId: $e');
    }
  }

  @override
  Future<BusinessTripRate?> getActiveRateForDate(
    String objectId,
    DateTime date,
  ) async {
    try {
      final model = await _dataSource.getActiveRateForDate(objectId, date);
      return model?.toDomain();
    } catch (e) {
      throw Exception(
          'Ошибка получения активной ставки для объекта $objectId на дату $date: $e');
    }
  }

  @override
  Future<BusinessTripRate?> getCurrentRate(String objectId) async {
    try {
      final model = await _dataSource.getCurrentRate(objectId);
      return model?.toDomain();
    } catch (e) {
      throw Exception(
          'Ошибка получения текущей ставки для объекта $objectId: $e');
    }
  }

  @override
  Future<BusinessTripRate> createRate(BusinessTripRate rate) async {
    try {
      // Проверяем пересекающиеся периоды перед созданием
      final hasOverlap = await _dataSource.hasOverlappingPeriods(
        rate.objectId,
        rate.employeeId,
        rate.validFrom,
        rate.validTo,
      );

      if (hasOverlap) {
        throw Exception(
            'Период действия ставки пересекается с существующими ставками для данного объекта');
      }

      final model = BusinessTripRateModel.fromDomain(rate);
      final createdModel = await _dataSource.createRate(model);
      return createdModel.toDomain();
    } catch (e) {
      throw Exception('Ошибка создания ставки командировочных: $e');
    }
  }

  @override
  Future<BusinessTripRate> updateRate(BusinessTripRate rate) async {
    try {
      // Проверяем пересекающиеся периоды перед обновлением
      final hasOverlap = await _dataSource.hasOverlappingPeriods(
        rate.objectId,
        rate.employeeId,
        rate.validFrom,
        rate.validTo,
        rate.id, // Исключаем текущую ставку из проверки
      );

      if (hasOverlap) {
        throw Exception(
            'Период действия ставки пересекается с существующими ставками для данного объекта');
      }

      final model = BusinessTripRateModel.fromDomain(rate);
      final updatedModel = await _dataSource.updateRate(model);
      return updatedModel.toDomain();
    } catch (e) {
      throw Exception('Ошибка обновления ставки командировочных: $e');
    }
  }

  @override
  Future<void> deleteRate(String id) async {
    try {
      await _dataSource.deleteRate(id);
    } catch (e) {
      throw Exception('Ошибка удаления ставки командировочных: $e');
    }
  }

  @override
  Future<BusinessTripRate?> getRateById(String id) async {
    try {
      final model = await _dataSource.getRateById(id);
      return model?.toDomain();
    } catch (e) {
      throw Exception('Ошибка получения ставки по ID $id: $e');
    }
  }

  @override
  Future<bool> hasOverlappingPeriods(
    String objectId,
    String? employeeId,
    DateTime validFrom,
    DateTime? validTo, [
    String? excludeId,
  ]) async {
    try {
      return await _dataSource.hasOverlappingPeriods(
        objectId,
        employeeId,
        validFrom,
        validTo,
        excludeId,
      );
    } catch (e) {
      throw Exception('Ошибка проверки пересекающихся периодов: $e');
    }
  }
}
