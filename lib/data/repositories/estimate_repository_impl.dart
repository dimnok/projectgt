import '../../domain/entities/estimate.dart';
import '../../domain/entities/estimate_completion_history.dart';
import '../../domain/repositories/estimate_repository.dart';
import '../datasources/estimate_data_source.dart';
import '../models/estimate_model.dart';
import '../models/estimate_completion_model.dart';

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
}
