import '../../domain/entities/estimate.dart';
import '../../domain/entities/estimate_completion_history.dart';
import '../../domain/entities/ks6a_period.dart' as entity;
import '../../domain/repositories/estimate_repository.dart';
import '../datasources/estimate_data_source.dart';
import '../models/estimate_model.dart';
import '../models/estimate_completion_model.dart';
import '../models/ks6a_model.dart';

/// Реализация репозитория EstimateRepository для работы со сметами через data source.
class EstimateRepositoryImpl implements EstimateRepository {
  /// Источник данных для смет.
  final EstimateDataSource dataSource;

  /// Создаёт экземпляр [EstimateRepositoryImpl] с источником [dataSource].
  EstimateRepositoryImpl(this.dataSource);

  /// Получает список всех смет.
  @override
  Future<List<Estimate>> getEstimates() async {
    final models = await dataSource.getEstimates();
    return models.map((e) => e.toDomain()).toList();
  }

  /// Получает смету по идентификатору [id].
  @override
  Future<Estimate?> getEstimate(String id) async {
    final model = await dataSource.getEstimate(id);
    return model?.toDomain();
  }

  /// Создаёт новую смету [estimate].
  @override
  Future<void> createEstimate(Estimate estimate) async {
    await dataSource.createEstimate(estimate.toModel());
  }

  /// Обновляет существующую смету [estimate].
  @override
  Future<void> updateEstimate(Estimate estimate) async {
    await dataSource.updateEstimate(estimate.toModel());
  }

  /// Удаляет смету по идентификатору [id].
  @override
  Future<void> deleteEstimate(String id) async {
    await dataSource.deleteEstimate(id);
  }

  /// Получает список уникальных систем из всех смет.
  @override
  Future<List<String>> getSystems({String? estimateTitle}) async {
    return dataSource.getSystems(estimateTitle: estimateTitle);
  }

  /// Получает список уникальных подсистем из всех смет.
  @override
  Future<List<String>> getSubsystems({String? estimateTitle}) async {
    return dataSource.getSubsystems(estimateTitle: estimateTitle);
  }

  /// Получает сгруппированный список смет (заголовки).
  Future<List<Map<String, dynamic>>> getEstimateGroups() async {
    if (dataSource is SupabaseEstimateDataSource) {
      return (dataSource as SupabaseEstimateDataSource).getEstimateGroups();
    }
    return [];
  }

  /// Получает позиции сметы по фильтру (заголовок + объект + договор).
  Future<List<Estimate>> getEstimatesByFile({
    required String estimateTitle,
    String? objectId,
    String? contractId,
  }) async {
    if (dataSource is SupabaseEstimateDataSource) {
      final models =
          await (dataSource as SupabaseEstimateDataSource).getEstimatesByFile(
        estimateTitle: estimateTitle,
        objectId: objectId,
        contractId: contractId,
      );
      return models.map((e) => e.toDomain()).toList();
    }
    return [];
  }

  /// Получает выполнение только для указанных ID сметных позиций.
  Future<List<EstimateCompletionModel>> getEstimateCompletionByIds(
      List<String> estimateIds) async {
    if (dataSource is SupabaseEstimateDataSource) {
      return (dataSource as SupabaseEstimateDataSource)
          .getEstimateCompletionByIds(estimateIds);
    }
    return [];
  }

  /// Получает список уникальных единиц измерения из всех смет.
  @override
  Future<List<String>> getUnits({String? estimateTitle}) async {
    return dataSource.getUnits(estimateTitle: estimateTitle);
  }

  @override
  Future<List<EstimateCompletionHistory>> getEstimateCompletionHistory(String estimateId) async {
    final rawData = await dataSource.getEstimateCompletionHistory(estimateId);
    
    final history = rawData.map((row) {
      final works = row['works'] as Map<String, dynamic>?;
      final dateStr = works?['date'] as String?;
      final quantity = (row['quantity'] as num?)?.toDouble() ?? 0.0;
      final section = row['section'] as String? ?? '';
      final floor = row['floor'] as String? ?? '';
      
      return EstimateCompletionHistory(
        date: dateStr != null ? DateTime.parse(dateStr) : DateTime.now(),
        quantity: quantity,
        section: section,
        floor: floor,
      );
    }).toList();

    // Сортируем: сначала новые даты (по убыванию)
    history.sort((a, b) => b.date.compareTo(a.date));
    
    return history;
  }

  @override
  Future<List<Estimate>> getEstimatesByContract(String contractId) async {
    final models = await dataSource.getEstimatesByContract(contractId);
    return models.map((e) => e.toDomain()).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> getContractCompletionHistory(String contractId) async {
    return dataSource.getContractCompletionHistory(contractId);
  }

  @override
  Future<String> createKs6aPeriod({
    required String contractId,
    required DateTime startDate,
    required DateTime endDate,
    String? title,
  }) async {
    return dataSource.createKs6aPeriod(
      contractId: contractId,
      startDate: startDate,
      endDate: endDate,
      title: title,
    );
  }

  @override
  Future<void> refreshKs6aPeriod(String periodId) async {
    await dataSource.refreshKs6aPeriod(periodId);
  }

  @override
  Future<void> approveKs6aPeriod(String periodId) async {
    await dataSource.approveKs6aPeriod(periodId);
  }

  @override
  Future<entity.Ks6aContractData> getKs6aContractData(String contractId) async {
    final rawData = await dataSource.getKs6aContractData(contractId);
    final model = Ks6aContractData.fromJson(rawData);
    
    return entity.Ks6aContractData(
      periods: model.periods.map((p) => entity.Ks6aPeriod(
        id: p.id,
        startDate: p.startDate,
        endDate: p.endDate,
        status: p.status,
        title: p.title,
        totalAmount: p.totalAmount,
      )).toList(),
      items: model.items.map((i) => entity.Ks6aPeriodItem(
        id: i.id,
        periodId: i.periodId,
        estimateId: i.estimateId,
        quantity: i.quantity,
        priceSnapshot: i.priceSnapshot,
        amount: i.amount,
      )).toList(),
    );
  }
}
