import '../../domain/entities/estimate.dart';
import '../../domain/repositories/estimate_repository.dart';
import '../datasources/estimate_data_source.dart';
import '../models/estimate_model.dart';
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
}
