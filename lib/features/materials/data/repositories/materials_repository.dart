import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/material_item.dart';

/// Репозиторий для работы с таблицей `public.materials` в Supabase.
class MaterialsRepository {
  /// Клиент Supabase для запросов к БД.
  final SupabaseClient client;

  /// Создаёт репозиторий материалов.
  const MaterialsRepository(this.client);

  /// Загрузка списка материалов с сортировкой по дате и имени.
  Future<List<MaterialItem>> fetchAll({String? contractNumber}) async {
    // ВАЖНО: сначала применяем фильтры, затем сортировку.
    // eq() доступен на PostgrestFilterBuilder, а order() возвращает PostgrestTransformBuilder.
    var builder = client.from('v_materials_with_usage').select();
    if (contractNumber != null && contractNumber.trim().isNotEmpty) {
      builder = builder.eq('contract_number', contractNumber.trim());
    }
    final data = await builder
        .order('receipt_date', ascending: false)
        .order('name', ascending: true);
    return (data as List<dynamic>)
        .map((e) => MaterialItem.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  /// Получить список уникальных номеров договоров из materials
  Future<List<String>> fetchDistinctContractNumbers() async {
    // Берём номера только активных договоров из справочника contracts
    final rows = await client
        .from('contracts')
        .select('number,status')
        .inFilter('status', ['active', 'активен', 'ACTIVE', 'Активен']);
    final set = <String>{};
    for (final r in rows as List) {
      final v = r['number']?.toString().trim();
      if (v != null && v.isNotEmpty) set.add(v);
    }
    final list = set.toList()..sort();
    return list;
  }
}
