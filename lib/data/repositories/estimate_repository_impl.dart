import '../../domain/entities/estimate.dart';
import '../../domain/entities/estimate_completion_history.dart';
import '../../domain/repositories/estimate_repository.dart';
import '../datasources/estimate_data_source.dart';
import '../models/estimate_model.dart';
import '../models/estimate_completion_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
    var query = Supabase.instance.client
        .from('estimates')
        .select('system')
        .not('system', 'is', null);

    // Фильтруем по названию сметы, если оно указано
    if (estimateTitle != null) {
      query = query.eq('estimate_title', estimateTitle);
    }

    final data = await query;

    final systems = <String>{};
    for (final row in data as List) {
      final system = row['system']?.toString().trim();
      if (system != null && system.isNotEmpty) {
        systems.add(system);
      }
    }
    return systems.toList()..sort();
  }

  /// Получает список уникальных подсистем из всех смет.
  @override
  Future<List<String>> getSubsystems({String? estimateTitle}) async {
    var query = Supabase.instance.client
        .from('estimates')
        .select('subsystem')
        .not('subsystem', 'is', null);

    // Фильтруем по названию сметы, если оно указано
    if (estimateTitle != null) {
      query = query.eq('estimate_title', estimateTitle);
    }

    final data = await query;

    final subsystems = <String>{};
    for (final row in data as List) {
      final subsystem = row['subsystem']?.toString().trim();
      if (subsystem != null && subsystem.isNotEmpty) {
        subsystems.add(subsystem);
      }
    }
    return subsystems.toList()..sort();
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
    var query = Supabase.instance.client
        .from('estimates')
        .select('unit')
        .not('unit', 'is', null);

    // Фильтруем по названию сметы, если оно указано
    if (estimateTitle != null) {
      query = query.eq('estimate_title', estimateTitle);
    }

    final data = await query;

    final units = <String>{};
    for (final row in data as List) {
      final unit = row['unit']?.toString().trim();
      if (unit != null && unit.isNotEmpty) {
        units.add(unit);
      }
    }
    return units.toList()..sort();
  }

  @override
  Future<List<EstimateCompletionHistory>> getEstimateCompletionHistory(String estimateId) async {
    final rawData = await dataSource.getEstimateCompletionHistory(estimateId);
    
    final history = rawData.map((row) {
      final works = row['works'] as Map<String, dynamic>?;
      final dateStr = works?['date'] as String?;
      final quantity = (row['quantity'] as num?)?.toDouble() ?? 0.0;
      
      return EstimateCompletionHistory(
        date: dateStr != null ? DateTime.parse(dateStr) : DateTime.now(),
        quantity: quantity,
      );
    }).toList();

    // Сортируем: сначала новые даты (по убыванию)
    history.sort((a, b) => b.date.compareTo(a.date));
    
    return history;
  }
}
