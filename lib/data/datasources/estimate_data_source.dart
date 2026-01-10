import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:excel/excel.dart';
import 'dart:io';
import '../models/estimate_model.dart';
import '../models/estimate_completion_model.dart';

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
  Future<List<EstimateModel>> importFromExcel(String filePath, String companyId);

  /// Получает отчёт о выполнении смет с информацией о выполненных работах.
  Future<List<EstimateCompletionModel>> getEstimateCompletion();

  /// Получает историю выполнения для конкретной позиции сметы.
  Future<List<Map<String, dynamic>>> getEstimateCompletionHistory(String estimateId);

  /// Получает список уникальных систем из всех смет.
  Future<List<String>> getSystems({String? estimateTitle});

  /// Получает список уникальных подсистем из всех смет.
  Future<List<String>> getSubsystems({String? estimateTitle});

  /// Получает список уникальных единиц измерения из всех смет.
  Future<List<String>> getUnits({String? estimateTitle});
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

      final chunk =
          response.map((json) => EstimateModel.fromJson(json)).toList();

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
  Future<List<EstimateModel>> importFromExcel(String filePath, String companyId) async {
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
      final total =
          totalCell?.value != null ? _parseDouble(totalCell) : quantity * price;

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
  Future<List<Map<String, dynamic>>> getEstimateGroups() async {
    try {
      // Вызываем RPC для получения легкого списка групп
      final response = await client.rpc('get_estimate_groups', params: {
        'p_company_id': activeCompanyId,
      });
      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      // Fallback: Если RPC недоступен, выполняем группировку на клиенте (старый метод)
      // Но это не оптимально, поэтому лучше убедиться что миграция применена
      // В качестве fallback можно попробовать получить уникальные записи через distinct
      // Но Supabase JS SDK не поддерживает DISTINCT ON легко без RPC.
      // Поэтому здесь мы просто пробрасываем ошибку или возвращаем пустой список,
      // или (в крайнем случае) грузим всё (чего мы хотим избежать).
      // Решение: загрузим только нужные поля для группировки
      final response = await client
          .from(view)
          .select('estimate_title, object_id, contract_id, contract_number, total')
          .eq('company_id', activeCompanyId);
      
      // Группируем на клиенте (Fallback)
      final groups = <String, Map<String, dynamic>>{};
      for (final item in response) {
        final key = '${item['estimate_title']}_${item['object_id']}_${item['contract_id']}';
        if (!groups.containsKey(key)) {
          groups[key] = {
            'estimate_title': item['estimate_title'],
            'object_id': item['object_id'],
            'contract_id': item['contract_id'],
            'contract_number': item['contract_number'],
            'items_count': 0,
            'total_amount': 0.0,
          };
        }
        groups[key]!['items_count'] = (groups[key]!['items_count'] as int) + 1;
        groups[key]!['total_amount'] = (groups[key]!['total_amount'] as double) + (item['total'] as num).toDouble();
      }
      return groups.values.toList();
    }
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

  /// Получает выполнение только для указанных ID сметных позиций.
  Future<List<EstimateCompletionModel>> getEstimateCompletionByIds(List<String> estimateIds) async {
    if (estimateIds.isEmpty) return [];
    
    try {
      final response = await client.rpc('get_estimate_completion_by_ids', params: {
        'p_estimate_ids': estimateIds,
        'p_company_id': activeCompanyId,
      });
      
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
  Future<List<EstimateCompletionModel>> getEstimateCompletion() async {
    final allItems = <EstimateCompletionModel>[];
    var offset = 0;
    const limit = 1000;
    var hasNext = true;

    try {
      // Пытаемся использовать пагинированную функцию
      while (hasNext) {
        try {
          final response =
              await client.rpc('get_estimate_completion_paginated', params: {
            'p_company_id': activeCompanyId,
            'p_offset': offset,
            'p_limit': limit,
          });

          // Если ответ не Map (ошибка формата новой функции), вызываем исключение, чтобы уйти в catch
          if (response is! Map) {
            throw const FormatException('Invalid response format');
          }

          final data = response['data'] as List;
          final next = response['has_next'] as bool;

          final chunk = data
              .cast<Map<String, dynamic>>()
              .map((json) => EstimateCompletionModel.fromJson(json))
              .toList();

          allItems.addAll(chunk);
          hasNext = next;
          offset += limit;
        } catch (e) {
          // Если ошибка на первой странице (например, функции нет), пробуем старый метод
          if (offset == 0) {
            final oldResponse =
                await client.rpc('get_estimate_completion_report');

            if (oldResponse is! List) {
              return [];
            }

            return oldResponse
                .cast<Map<String, dynamic>>()
                .map((json) => EstimateCompletionModel.fromJson(json))
                .toList();
          } else {
            // Если ошибка в середине пагинации, пробрасываем её
            rethrow;
          }
        }
      }
      return allItems;
    } catch (e) {
      // Если всё сломалось, пробуем старый метод как последний шанс (на случай если catch внутри while не сработал как надо)
      try {
        final oldResponse = await client.rpc('get_estimate_completion_report');
        if (oldResponse is List) {
          return oldResponse
              .cast<Map<String, dynamic>>()
              .map((json) => EstimateCompletionModel.fromJson(json))
              .toList();
        }
      } catch (_) {
        // Игнорируем ошибку старого метода, если он тоже не работает
      }
      rethrow;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getEstimateCompletionHistory(String estimateId) async {
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
