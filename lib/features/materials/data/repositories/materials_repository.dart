import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/material_item.dart';
import '../models/grouped_material_item.dart';
import '../models/material_binding_model.dart';

/// Репозиторий для работы с таблицей `public.materials` в Supabase.
class MaterialsRepository {
  /// Клиент Supabase для запросов к БД.
  final SupabaseClient client;

  /// Создаёт репозиторий материалов.
  const MaterialsRepository(this.client);

  /// Загрузка списка материалов с сортировкой по дате и имени.
  Future<List<MaterialItem>> fetchAll({
    required String companyId,
    String? contractNumber,
  }) async {
    // ВАЖНО: сначала применяем фильтры, затем сортировку.
    var builder = client
        .from('v_materials_with_usage')
        .select()
        .eq('company_id', companyId);

    if (contractNumber != null && contractNumber.trim().isNotEmpty) {
      builder = builder.eq('contract_number', contractNumber.trim());
    }
    final data = await builder
        .order('receipt_date', ascending: false)
        .order('name', ascending: true);
    return (data as List<dynamic>)
        .map((e) => MaterialItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Загрузка сгруппированных материалов по смете.
  Future<List<GroupedMaterialItem>> fetchGrouped({
    required String companyId,
    String? contractNumber,
  }) async {
    var builder = client
        .from('v_materials_grouped_by_estimate')
        .select()
        .eq('company_id', companyId);

    if (contractNumber != null && contractNumber.trim().isNotEmpty) {
      builder = builder.eq('contract_number', contractNumber.trim());
    }

    final data = await builder
        .order('system', ascending: true)
        .order('estimate_name', ascending: true);

    return (data as List<dynamic>)
        .map((e) => GroupedMaterialItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Получить список уникальных номеров договоров из materials
  Future<List<String>> fetchDistinctContractNumbers({
    required String companyId,
  }) async {
    // Берём номера только активных договоров из справочника contracts
    final rows = await client
        .from('contracts')
        .select('number,status')
        .eq('company_id', companyId)
        .inFilter('status', ['active', 'активен', 'ACTIVE', 'Активен']);
    final set = <String>{};
    for (final r in rows as List) {
      final v = r['number']?.toString().trim();
      if (v != null && v.isNotEmpty) set.add(v);
    }
    final list = set.toList()..sort();
    return list;
  }

  /// Получить список уникальных названий материалов из накладных.
  Future<List<Map<String, dynamic>>> fetchUniqueMaterialNames({
    required String companyId,
    String? contractNumber,
  }) async {
    // Получаем уникальные тройки (имя, ед. изм, номер накладной) из таблицы материалов
    var builder = client
        .from('materials')
        .select('name, unit, receipt_number')
        .eq('company_id', companyId);

    if (contractNumber != null && contractNumber.trim().isNotEmpty) {
      builder = builder.eq('contract_number', contractNumber.trim());
    }

    final response = await builder.order('name');

    final data = response as List;
    final Map<String, Map<String, dynamic>> unique = {};
    for (final row in data) {
      final name = row['name']?.toString().trim();
      final unit = row['unit']?.toString().trim();
      final receiptNumber = row['receipt_number']?.toString().trim();
      if (name == null || name.isEmpty) continue;

      final key = "${name.toLowerCase()}_${unit?.toLowerCase() ?? ''}_${receiptNumber?.toLowerCase() ?? ''}";
      if (!unique.containsKey(key)) {
        unique[key] = {
          'name': name,
          'unit': unit ?? '',
          'receipt_number': receiptNumber ?? '',
        };
      }
    }
    final result = unique.values.toList();
    result.sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));
    return result;
  }

  /// Получить материалы со статусом привязки к текущей смете.
  Future<List<MaterialBindingModel>> fetchMaterialsWithBindingStatus({
    required String companyId,
    required String contractNumber,
    required String currentEstimateId,
  }) async {
    final response = await client.rpc(
      'get_materials_with_binding_status',
      params: {
        'p_company_id': companyId,
        'p_contract_number': contractNumber,
        'p_current_estimate_id': currentEstimateId,
      },
    );

    return (response as List<dynamic>)
        .map((e) => MaterialBindingModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Получить список материалов, привязанных к конкретной сметной позиции.
  Future<List<MaterialItem>> fetchLinkedMaterials({
    required String estimateId,
    required String companyId,
  }) async {
    final response = await client.rpc(
      'get_linked_materials_details',
      params: {
        'p_estimate_id': estimateId,
        'p_company_id': companyId,
      },
    );

    return (response as List)
        .map<MaterialItem>((e) => MaterialItem(
              id: e['id'],
              name: e['name'],
              unit: e['unit'],
              quantity: (e['quantity'] as num?)?.toDouble(),
              receiptNumber: e['receipt_number'],
              receiptDate: e['receipt_date'] != null 
                  ? DateTime.parse(e['receipt_date']) 
                  : null,
              companyId: companyId,
            ))
        .toList();
  }

  /// Привязать материал из накладной к сметной позиции.
  Future<void> linkMaterialToEstimate({
    required String estimateId,
    required String aliasRaw,
    required String? uomRaw,
    required String companyId,
    double multiplier = 1.0,
  }) async {
    await client.from('material_aliases').insert({
      'estimate_id': estimateId,
      'alias_raw': aliasRaw,
      'uom_raw': uomRaw,
      'multiplier_to_estimate': multiplier,
      'company_id': companyId,
    });
  }

  /// Отвязать материал от сметной позиции.
  Future<void> unlinkMaterialFromEstimate(String aliasId) async {
    await client.from('material_aliases').delete().eq('id', aliasId);
  }
}
