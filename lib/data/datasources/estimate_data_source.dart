import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:excel/excel.dart';
import 'dart:io';
import '../models/estimate_model.dart';
import '../models/estimate_completion_model.dart';
import '../models/vor_model.dart';
import '../../domain/entities/vor.dart';

/// Источник данных для работы со сметами (абстракция).
///
/// Определяет методы для CRUD-операций и импорта из Excel.
abstract class EstimateDataSource {
  /// Получает список всех смет.
  Future<List<EstimateModel>> getEstimates();

  /// Получает смету по идентификатору [id].
  Future<EstimateModel?> getEstimate(String id);

  /// Создаёт новую смету [estimate].
  Future<void> createEstimate(EstimateModel estimate);

  /// Обновляет существующую смету [estimate].
  Future<void> updateEstimate(EstimateModel estimate);

  /// Удаляет смету по идентификатору [id].
  Future<void> deleteEstimate(String id);

  /// Импортирует сметы из Excel-файла по [filePath].
  Future<List<EstimateModel>> importFromExcel(
    String filePath,
    String companyId,
  );

  /// Получает историю выполнения для конкретной позиции сметы.
  Future<List<Map<String, dynamic>>> getEstimateCompletionHistory(
    String estimateId,
  );

  /// Получает выполнение только для указанных ID сметных позиций.
  Future<List<EstimateCompletionModel>> getEstimateCompletionByIds(
    List<String> estimateIds,
  );

  /// Получает список уникальных систем из всех смет.
  Future<List<String>> getSystems({String? estimateTitle});

  /// Получает список уникальных подсистем из всех смет.
  Future<List<String>> getSubsystems({String? estimateTitle});

  /// Получает список уникальных единиц измерения из всех смет.
  Future<List<String>> getUnits({String? estimateTitle});

  /// Получает все сметные позиции по договору.
  Future<List<EstimateModel>> getEstimatesByContract(String contractId);

  /// Получает список всех ВОР по договору.
  Future<List<VorModel>> getVors(String contractId);

  /// Создает новую ведомость ВОР.
  Future<String> createVor({
    required String contractId,
    required DateTime startDate,
    required DateTime endDate,
    required List<String> systems,
  });

  /// Обновляет статус ведомости ВОР.
  Future<void> updateVorStatus(String vorId, VorStatus status, {String? comment});

  /// Удаляет ведомость ВОР.
  Future<void> deleteVor(String vorId);

  /// Наполняет состав ведомости ВОР фактически выполненными работами.
  Future<void> populateVorItems(String vorId);
}

/// Реализация EstimateDataSource через Supabase/PostgreSQL.
class SupabaseEstimateDataSource implements EstimateDataSource {
  /// Экземпляр клиента Supabase.
  final SupabaseClient client;

  /// ID активной компании.
  final String activeCompanyId;

  /// Имя таблицы смет в базе данных.
  static const String table = 'estimates';

  /// Имя представления для чтения смет с метаданными.
  static const String view = 'estimates_with_contracts';

  /// Регулярное выражение для удаления пробелов (скомпилировано для производительности).
  // ignore: deprecated_member_use
  static final Pattern _whitespaceRegex = RegExp(r'\s+');

  /// Создаёт экземпляр [SupabaseEstimateDataSource] с клиентом [client].
  const SupabaseEstimateDataSource(this.client, this.activeCompanyId);

  @override
  Future<List<EstimateModel>> getEstimates() async {
    final allEstimates = <EstimateModel>[];
    var offset = 0;
    const limit = 1000;
    var hasMore = true;

    // Загружаем данные порциями (чанками) по 1000 записей,
    // чтобы обойти ограничение Supabase на максимальное количество строк в одном ответе.
    while (hasMore) {
      final response = await client
          .from(view)
          .select('*')
          .eq('company_id', activeCompanyId)
          .order('system')
          .range(offset, offset + limit - 1);

      if (response.isEmpty) {
        hasMore = false;
        break;
      }

      final chunk = response
          .map((json) => EstimateModel.fromJson(json))
          .toList();

      allEstimates.addAll(chunk);

      // Если получено меньше лимита, значит это последняя порция данных
      if (chunk.length < limit) {
        hasMore = false;
      } else {
        offset += limit;
      }
    }

    return allEstimates;
  }

  @override
  Future<EstimateModel?> getEstimate(String id) async {
    final response = await client
        .from(view)
        .select('*')
        .eq('id', id)
        .eq('company_id', activeCompanyId)
        .maybeSingle();
    if (response == null) return null;
    return EstimateModel.fromJson(response);
  }

  @override
  Future<void> createEstimate(EstimateModel estimate) async {
    final json = estimate.toJson();
    json['company_id'] = activeCompanyId;
    await client.from(table).insert(json);
  }

  @override
  Future<void> updateEstimate(EstimateModel estimate) async {
    if (estimate.id == null) throw Exception('id is required for update');
    final json = estimate.toJson();
    json['company_id'] = activeCompanyId;
    await client
        .from(table)
        .update(json)
        .eq('id', estimate.id!)
        .eq('company_id', activeCompanyId);
  }

  @override
  Future<void> deleteEstimate(String id) async {
    await client
        .from(table)
        .delete()
        .eq('id', id)
        .eq('company_id', activeCompanyId);
  }

  @override
  Future<List<EstimateModel>> importFromExcel(
    String filePath,
    String companyId,
  ) async {
    final bytes = await File(filePath).readAsBytes();
    final excel = Excel.decodeBytes(bytes);

    if (excel.tables.isEmpty) return [];

    final sheet = excel.tables[excel.tables.keys.first];
    if (sheet == null) return [];

    final rows = sheet.rows.skip(1); // пропускаем заголовки

    return rows.map((row) {
      final quantity = _parseDouble(_getCell(row, 7));
      final price = _parseDouble(_getCell(row, 8));

      // Если сумма не указана, рассчитываем её
      final totalCell = _getCell(row, 9);
      final total = totalCell?.value != null
          ? _parseDouble(totalCell)
          : quantity * price;

      return EstimateModel(
        id: '', // генерировать на сервере или локально
        companyId: companyId,
        system: _parseString(_getCell(row, 0)),
        subsystem: _parseString(_getCell(row, 1)),
        number: _parseString(_getCell(row, 2)),
        name: _parseString(_getCell(row, 3)),
        article: _parseString(_getCell(row, 4)),
        manufacturer: _parseString(_getCell(row, 5)),
        unit: _parseString(_getCell(row, 6)),
        quantity: quantity,
        price: price,
        total: total,
      );
    }).toList();
  }

  /// Получает сгруппированный список смет (заголовки).
  ///
  /// ВАЖНО: Фильтрация по объектам пользователя выполняется на уровне БД
  /// через RPC функцию get_estimate_groups. Fallback удалён для безопасности,
  /// так как он обходил проверку прав на уровне объектов.
  Future<List<Map<String, dynamic>>> getEstimateGroups() async {
    // Вызываем RPC для получения легкого списка групп
    // Функция содержит полную логику фильтрации по правам и объектам
    final response = await client.rpc(
      'get_estimate_groups',
      params: {'p_company_id': activeCompanyId},
    );
    return (response as List).cast<Map<String, dynamic>>();
  }

  /// Получает позиции сметы по фильтру (заголовок + объект + договор).
  Future<List<EstimateModel>> getEstimatesByFile({
    required String estimateTitle,
    String? objectId,
    String? contractId,
  }) async {
    var query = client
        .from(view)
        .select('*')
        .eq('estimate_title', estimateTitle)
        .eq('company_id', activeCompanyId);

    if (objectId != null) {
      query = query.eq('object_id', objectId);
    }
    if (contractId != null) {
      query = query.eq('contract_id', contractId);
    }

    // Сортировка по системе
    final response = await query.order('system');

    return response.map((json) => EstimateModel.fromJson(json)).toList();
  }

  @override
  Future<List<EstimateCompletionModel>> getEstimateCompletionByIds(
    List<String> estimateIds,
  ) async {
    if (estimateIds.isEmpty) return [];

    try {
      final response = await client.rpc(
        'get_estimate_completion_by_ids',
        params: {
          'p_estimate_ids': estimateIds,
          'p_company_id': activeCompanyId,
        },
      );

      if (response is! List) return [];

      return response
          .cast<Map<String, dynamic>>()
          .map((json) => EstimateCompletionModel.fromJson(json))
          .toList();
    } catch (e) {
      // Fallback на пагинированную функцию с фильтром (если новый RPC недоступен)
      // Но это менее эффективно.
      rethrow;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getEstimateCompletionHistory(
    String estimateId,
  ) async {
    final response = await client
        .from('work_items')
        .select('quantity, section, floor, works!inner(date)')
        .eq('estimate_id', estimateId)
        .eq('company_id', activeCompanyId)
        .order('date', referencedTable: 'works', ascending: false);

    return (response as List).cast<Map<String, dynamic>>();
  }

  @override
  Future<List<String>> getSystems({String? estimateTitle}) async {
    var query = client
        .from(table)
        .select('system')
        .eq('company_id', activeCompanyId)
        .not('system', 'is', null);

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

  @override
  Future<List<String>> getSubsystems({String? estimateTitle}) async {
    var query = client
        .from(table)
        .select('subsystem')
        .eq('company_id', activeCompanyId)
        .not('subsystem', 'is', null);

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

  @override
  Future<List<String>> getUnits({String? estimateTitle}) async {
    var query = client
        .from(table)
        .select('unit')
        .eq('company_id', activeCompanyId)
        .not('unit', 'is', null);

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
  Future<List<EstimateModel>> getEstimatesByContract(String contractId) async {
    final response = await client
        .from(view)
        .select('*')
        .eq('contract_id', contractId)
        .eq('company_id', activeCompanyId)
        .order('system')
        .order('number');

    return (response as List)
        .map((json) => EstimateModel.fromJson(json))
        .toList();
  }

  @override
  Future<List<VorModel>> getVors(String contractId) async {
    final response = await client
        .from('vors')
        .select('*, excel_url, vor_systems(system_name), vor_status_history(*, user_profile:profiles(full_name)), created_by_profile:profiles!vors_created_by_fkey(full_name)')
        .eq('contract_id', contractId)
        .eq('company_id', activeCompanyId)
        .order('created_at', ascending: false);

    return (response as List).map((json) {
      final systems = (json['vor_systems'] as List?)
              ?.map((s) => s['system_name'] as String)
              .toList() ??
          [];
      
      final history = (json['vor_status_history'] as List?)
              ?.map((h) => VorStatusHistoryModel.fromJson(h).copyWith(
                    userName: h['user_profile']?['full_name'] as String?,
                  ))
              .toList() ??
          [];

      return VorModel.fromJson(json).copyWith(
        systems: systems,
        statusHistory: history,
        createdByName: json['created_by_profile']?['full_name'] as String?,
      );
    }).toList();
  }

  @override
  Future<String> createVor({
    required String contractId,
    required DateTime startDate,
    required DateTime endDate,
    required List<String> systems,
  }) async {
    // 1. Получаем следующий порядковый номер через RPC
    final nextNumber = await client.rpc('get_next_vor_number', params: {
      'p_company_id': activeCompanyId,
      'p_contract_id': contractId,
    });

    // 2. Создаем заголовок ВОР
    final vorResponse = await client.from('vors').insert({
      'company_id': activeCompanyId,
      'contract_id': contractId,
      'number': nextNumber,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'status': 'draft',
      'created_by': client.auth.currentUser?.id,
    }).select('id').single();

    final vorId = vorResponse['id'] as String;

    // 2. Добавляем системы
    if (systems.isNotEmpty) {
      await client.from('vor_systems').insert(
        systems.map((s) => {
          'vor_id': vorId,
          'company_id': activeCompanyId,
          'system_name': s,
        }).toList(),
      );
    }

    // 3. Добавляем начальную историю
    await client.from('vor_status_history').insert({
      'vor_id': vorId,
      'company_id': activeCompanyId,
      'status': 'draft',
      'user_id': client.auth.currentUser?.id,
      'comment': 'Создана ведомость',
    });

    return vorId;
  }

  @override
  Future<void> updateVorStatus(String vorId, VorStatus status, {String? comment}) async {
    // 1. Обновляем статус в заголовке
    await client.from('vors').update({
      'status': status.name,
    }).eq('id', vorId).eq('company_id', activeCompanyId);

    // 2. Добавляем запись в историю
    await client.from('vor_status_history').insert({
      'vor_id': vorId,
      'company_id': activeCompanyId,
      'status': status.name,
      'user_id': client.auth.currentUser?.id,
      'comment': comment,
    });
  }

  @override
  Future<void> deleteVor(String vorId) async {
    await client
        .from('vors')
        .delete()
        .eq('id', vorId)
        .eq('company_id', activeCompanyId)
        .eq('status', 'draft'); // Удаление разрешено только для черновиков
  }

  @override
  Future<void> populateVorItems(String vorId) async {
    await client.rpc('populate_vor_items', params: {'p_vor_id': vorId});
  }

  /// Получает ячейку безопасно по индексу
  Data? _getCell(List<Data?> row, int index) {
    if (index >= 0 && index < row.length) {
      return row[index];
    }
    return null;
  }

  /// Вспомогательный метод для парсинга строки из ячейки.
  String _parseString(Data? cell) {
    if (cell == null || cell.value == null) return '';

    final val = cell.value;
    if (val is DoubleCellValue) {
      final numValue = val.value;
      if (numValue == numValue.truncate()) {
        return numValue.toInt().toString();
      }
      return numValue.toString();
    }
    if (val is IntCellValue) {
      return val.value.toString();
    }

    return val.toString().trim();
  }

  /// Вспомогательный метод для парсинга числа (double) из ячейки.
  double _parseDouble(Data? cell) {
    if (cell == null || cell.value == null) return 0.0;

    final val = cell.value;
    if (val is DoubleCellValue) return val.value;
    if (val is IntCellValue) return val.value.toDouble();

    final rawStr = val
        .toString()
        .trim()
        .replaceAll(_whitespaceRegex, '')
        .replaceAll(',', '.');

    return double.tryParse(rawStr) ?? 0.0;
  }
}
