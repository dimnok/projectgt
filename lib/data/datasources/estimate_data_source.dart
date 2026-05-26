import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:excel/excel.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import '../models/estimate_model.dart';
import '../models/estimate_completion_model.dart';
import '../models/vor_model.dart';
import '../../domain/entities/estimate_bulk_update.dart';
import '../../domain/entities/estimate_revision.dart';
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
    bool includeCombinedSheet = false,
  });

  /// Обновляет статус ведомости ВОР.
  Future<void> updateVorStatus(
    String vorId,
    VorStatus status, {
    String? comment,
  });

  /// Удаляет ведомость ВОР.
  Future<void> deleteVor(String vorId);

  /// Наполняет состав ведомости ВОР фактически выполненными работами.
  Future<void> populateVorItems(String vorId);

  /// Пересчитывает состав черновика ВОР без удаления ведомости.
  Future<void> recalculateVor(String vorId);

  /// Флаги необходимости пересчёта черновиков ВОР по договору.
  Future<Map<String, bool>> getDraftVorNeedsRecalc(String contractId);

  /// Отличия состава ВОР для окна подтверждения пересчёта.
  Future<List<Map<String, dynamic>>> getVorRecalcChangesRaw(String vorId);

  /// Загружает подписанный PDF-файл для ведомости ВОР.
  Future<void> uploadVorPdf({
    required String vorId,
    required File file,
    required String fileName,
  });

  /// Создает временную ссылку для просмотра PDF-файла ведомости ВОР.
  Future<String> getVorPdfViewUrl(String vorId);

  /// Возвращает текущие строки сметы для Excel-шаблона LC / ДС.
  Future<List<EstimateAddendumTemplateRow>> getAddendumTemplateRows({
    required String estimateTitle,
    required String contractId,
    String? objectId,
  });

  /// Возвращает готовый Excel-файл шаблона LC / ДС, сгенерированный на сервере.
  Future<Map<String, dynamic>> getAddendumTemplateFile({
    required String estimateTitle,
    required String contractId,
    String? objectId,
  });

  /// Excel со сметой по договору и колонками ДС (Edge Function `export-contract-estimate-addenda`).
  Future<Map<String, dynamic>> exportContractEstimateWithAddendaExcel({
    required String estimateTitle,
    required String contractId,
    String? objectId,
  });

  /// Excel со сметой по договору и колонками выполнения (Edge Function `export-contract-estimate-execution`).
  Future<Map<String, dynamic>> exportContractEstimateWithExecutionExcel({
    required String estimateTitle,
    required String contractId,
    String? objectId,
  });

  /// Read-only история позиции по базовой ревизии и ДС ([estimate_revision_items]).
  Future<List<EstimatePositionAddendumHistoryEntry>>
  getEstimatePositionAddendumHistory({
    required String contractId,
    required String estimateTitle,
    required String estimateRowId,
  });

  /// Создаёт ревизию LC / ДС в новых таблицах (сразу в статусе «согласовано»).
  Future<EstimateRevisionDraftResult> createEstimateRevisionDraft({
    required String estimateTitle,
    required String contractId,
    String? objectId,
    required String fileName,
    required Uint8List fileBytes,
    required List<EstimateAddendumImportRow> rows,
    DateTime? effectiveFrom,
    String? userDescription,
  });

  /// Переносит снимок ревизии ДС в таблицу [estimates] (приоритет данных ДС).
  Future<EstimateBulkUpdateResult> applyAddendumRevisionToEstimates({
    required String revisionId,
  });

  /// Обновляет дату действия и краткое описание ревизии ДС.
  Future<void> updateEstimateRevisionMetadata({
    required String revisionId,
    DateTime? effectiveFrom,
    String? userDescription,
  });

  /// Удаляет ревизию LC/ДС при соблюдении условий целостности (см. реализацию).
  Future<void> deleteAddendumRevision({required String revisionId});

  /// Возвращает строки текущей сметы для Excel-файла массового обновления.
  Future<List<EstimateBulkUpdateTemplateRow>> getBulkUpdateTemplateRows({
    required String estimateTitle,
    required String contractId,
    String? objectId,
  });

  /// Возвращает готовый Excel-файл массового обновления, сгенерированный на сервере.
  Future<Map<String, dynamic>> getBulkUpdateTemplateFile({
    required String estimateTitle,
    required String contractId,
    String? objectId,
  });

  /// Пустой Excel-шаблон импорта сметы (заголовки и пример строки), сгенерированный на сервере.
  ///
  /// [contractId] — если задан и договор доступен, в имя файла включается номер договора и дата.
  Future<Map<String, dynamic>> getEstimateImportTemplateFile({
    String? contractId,
  });

  /// Проверяет или применяет массовое обновление сметы через RPC.
  Future<EstimateBulkUpdateResult> runBulkUpdate({
    required String estimateTitle,
    required String contractId,
    String? objectId,
    required List<EstimateBulkUpdateImportRow> rows,
    required bool dryRun,
    String? sourceFileName,
  });
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

  /// Максимум строк в одном ответе PostgREST; без пагинации дальнейшие строки отбрасываются.
  static const int _postgrestPageSize = 1000;

  /// Регулярное выражение для удаления пробелов (скомпилировано для производительности).
  // ignore: deprecated_member_use
  static final Pattern _whitespaceRegex = RegExp(r'\s+');

  /// Создаёт экземпляр [SupabaseEstimateDataSource] с клиентом [client].
  const SupabaseEstimateDataSource(this.client, this.activeCompanyId);

  /// Убирает дубликаты позиций по `id` (первое вхождение сохраняется).
  static List<EstimateModel> dedupeEstimatesById(List<EstimateModel> items) {
    final seen = <String>{};
    final unique = <EstimateModel>[];
    for (final item in items) {
      final id = item.id;
      if (id == null || id.isEmpty) {
        unique.add(item);
        continue;
      }
      if (seen.add(id)) {
        unique.add(item);
      }
    }
    return unique;
  }

  @override
  Future<List<EstimateModel>> getEstimates() async {
    final allEstimates = <EstimateModel>[];
    var offset = 0;
    var hasMore = true;

    // Загружаем данные порциями, чтобы обойти max-rows PostgREST.
    while (hasMore) {
      final response = await client
          .from(view)
          .select('*')
          .eq('company_id', activeCompanyId)
          .order('system')
          .order('number')
          .order('id')
          .range(offset, offset + _postgrestPageSize - 1);

      if (response.isEmpty) {
        hasMore = false;
        break;
      }

      final chunk = response
          .map((json) => EstimateModel.fromJson(json))
          .toList();

      allEstimates.addAll(chunk);

      if (chunk.length < _postgrestPageSize) {
        hasMore = false;
      } else {
        offset += _postgrestPageSize;
      }
    }

    return dedupeEstimatesById(allEstimates);
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

  /// Удаляет из [json] поля, которых нет в таблице `estimates` (есть только во view).
  static void _stripEstimateTableReadOnlyKeys(Map<String, dynamic> json) {
    json.remove('contract_number');
  }

  @override
  Future<void> createEstimate(EstimateModel estimate) async {
    final json = estimate.toJson();
    _stripEstimateTableReadOnlyKeys(json);
    json['company_id'] = activeCompanyId;
    await client.from(table).insert(json);
  }

  @override
  Future<void> updateEstimate(EstimateModel estimate) async {
    if (estimate.id == null) throw Exception('id is required for update');
    final json = estimate.toJson();
    _stripEstimateTableReadOnlyKeys(json);
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
        visibleInEstimatesModule: true,
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
    PostgrestFilterBuilder baseQuery() {
      var q = client
          .from(view)
          .select('*')
          .eq('estimate_title', estimateTitle)
          .eq('company_id', activeCompanyId)
          .eq('visible_in_estimates_module', true);
      if (objectId != null) {
        q = q.eq('object_id', objectId);
      }
      if (contractId != null) {
        q = q.eq('contract_id', contractId);
      }
      return q;
    }

    final all = <EstimateModel>[];
    var offset = 0;
    var hasMore = true;
    while (hasMore) {
      final response = await baseQuery()
          .order('system')
          .order('number')
          .order('id')
          .range(offset, offset + _postgrestPageSize - 1);
      if (response.isEmpty) {
        break;
      }
      final chunk = (response as List)
          .map((json) => EstimateModel.fromJson(json as Map<String, dynamic>))
          .toList();
      all.addAll(chunk);
      if (chunk.length < _postgrestPageSize) {
        hasMore = false;
      } else {
        offset += _postgrestPageSize;
      }
    }
    return dedupeEstimatesById(all);
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
    final all = <EstimateModel>[];
    var offset = 0;
    var hasMore = true;
    while (hasMore) {
      final response = await client
          .from(view)
          .select('*')
          .eq('contract_id', contractId)
          .eq('company_id', activeCompanyId)
          .order('system')
          .order('number')
          .order('id')
          .range(offset, offset + _postgrestPageSize - 1);
      if (response.isEmpty) {
        break;
      }
      final chunk = (response as List)
          .map((json) => EstimateModel.fromJson(json as Map<String, dynamic>))
          .toList();
      all.addAll(chunk);
      if (chunk.length < _postgrestPageSize) {
        hasMore = false;
      } else {
        offset += _postgrestPageSize;
      }
    }
    return dedupeEstimatesById(all);
  }

  @override
  Future<Map<String, dynamic>> getAddendumTemplateFile({
    required String estimateTitle,
    required String contractId,
    String? objectId,
  }) async {
    final response = await client.functions.invoke(
      'generate_estimate_addendum_template',
      body: {
        'estimateTitle': estimateTitle,
        'contractId': contractId,
        'companyId': activeCompanyId,
        if (objectId != null) 'objectId': objectId,
      },
    );

    if (response.status != 200) {
      throw Exception(
        'Ошибка сервера при генерации шаблона: ${response.data['error'] ?? response.status}',
      );
    }

    final data = response.data as Map<String, dynamic>;
    final fileBase64 = data['file'] as String;
    final filename = data['filename'] as String? ?? 'template.xlsx';
    final bytes = Uint8List.fromList(
      base64Decode(fileBase64.replaceAll(RegExp(r'\s+'), '')),
    );

    return {'bytes': bytes, 'filename': filename};
  }

  @override
  Future<List<EstimateAddendumTemplateRow>> getAddendumTemplateRows({
    required String estimateTitle,
    required String contractId,
    String? objectId,
  }) async {
    try {
      final result = await getAddendumTemplateFile(
        estimateTitle: estimateTitle,
        contractId: contractId,
        objectId: objectId,
      );
      final bytes = result['bytes'] as Uint8List;

      // Декодируем Excel локально только для того, чтобы вернуть список строк
      // (это нужно для совместимости с текущим интерфейсом репозитория,
      // хотя UI может просто скачивать файл).
      final excel = Excel.decodeBytes(bytes);
      final sheet = excel.tables.values.first;
      final rows = sheet.rows.skip(1); // Пропускаем заголовок

      return rows.map((row) {
        return EstimateAddendumTemplateRow(
          positionId: _parseString(row[0]),
          system: _parseString(row[1]),
          subsystem: _parseString(row[2]),
          number: _parseString(row[3]),
          name: _parseString(row[4]),
          article: _parseString(row[5]),
          manufacturer: _parseString(row[6]),
          unit: _parseString(row[7]),
          quantity: _parseDouble(row[8]),
          price: _parseDouble(row[9]),
          total: _parseDouble(row[10]),
        );
      }).toList();
    } catch (e) {
      // Если Edge Function не сработала, используем fallback на локальную логику
      final rows = await _getEstimateRowsForAddendum(
        estimateTitle: estimateTitle,
        contractId: contractId,
        objectId: objectId,
      );

      return rows.map((row) {
        return EstimateAddendumTemplateRow(
          positionId: row['position_id'] as String,
          system: row['system']?.toString() ?? '',
          subsystem: row['subsystem']?.toString() ?? '',
          number: row['number']?.toString() ?? '',
          name: row['name']?.toString() ?? '',
          article: row['article']?.toString() ?? '',
          manufacturer: row['manufacturer']?.toString() ?? '',
          unit: row['unit']?.toString() ?? '',
          quantity: _toDouble(row['quantity']),
          price: _toDouble(row['price']),
          total: _toDouble(row['total']),
        );
      }).toList();
    }
  }

  @override
  Future<Map<String, dynamic>> exportContractEstimateWithAddendaExcel({
    required String estimateTitle,
    required String contractId,
    String? objectId,
  }) async {
    final trimmedTitle = estimateTitle.trim();
    if (trimmedTitle.isEmpty) {
      throw Exception('Не задан заголовок сметы для выгрузки');
    }

    final response = await client.functions.invoke(
      'export-contract-estimate-addenda',
      body: <String, dynamic>{
        'companyId': activeCompanyId,
        'contractId': contractId,
        'estimateTitle': trimmedTitle,
        if (objectId != null && objectId.isNotEmpty) 'objectId': objectId,
      },
      headers: <String, String>{
        'Authorization':
            'Bearer ${client.auth.currentSession?.accessToken ?? ''}',
        'Content-Type': 'application/json',
      },
    );

    final raw = response.data;
    if (raw is! Map) {
      throw Exception('Некорректный ответ сервера');
    }
    final data = Map<String, dynamic>.from(raw);
    final success = data['success'] as bool? ?? false;
    if (!success) {
      throw Exception(
        data['message']?.toString() ?? 'Не удалось сформировать Excel',
      );
    }

    final base64File = data['base64']?.toString();
    if (base64File == null || base64File.isEmpty) {
      throw Exception('Ответ сервера не содержит Excel-файл');
    }

    return {
      'bytes': Uint8List.fromList(
        base64Decode(base64File.replaceAll(RegExp(r'\s+'), '')),
      ),
      'filename': data['filename'] as String? ?? 'Смета.xlsx',
    };
  }

  @override
  Future<Map<String, dynamic>> exportContractEstimateWithExecutionExcel({
    required String estimateTitle,
    required String contractId,
    String? objectId,
  }) async {
    final trimmedTitle = estimateTitle.trim();
    if (trimmedTitle.isEmpty) {
      throw Exception('Не задан заголовок сметы для выгрузки');
    }

    final response = await client.functions.invoke(
      'export-contract-estimate-execution',
      body: <String, dynamic>{
        'companyId': activeCompanyId,
        'contractId': contractId,
        'estimateTitle': trimmedTitle,
        if (objectId != null && objectId.isNotEmpty) 'objectId': objectId,
      },
      headers: <String, String>{
        'Authorization':
            'Bearer ${client.auth.currentSession?.accessToken ?? ''}',
        'Content-Type': 'application/json',
      },
    );

    final raw = response.data;
    if (raw is! Map) {
      throw Exception('Некорректный ответ сервера');
    }
    final data = Map<String, dynamic>.from(raw);
    final success = data['success'] as bool? ?? false;
    if (!success) {
      throw Exception(
        data['message']?.toString() ?? 'Не удалось сформировать Excel',
      );
    }

    final base64File = data['base64']?.toString();
    if (base64File == null || base64File.isEmpty) {
      throw Exception('Ответ сервера не содержит Excel-файл');
    }

    return {
      'bytes': Uint8List.fromList(
        base64Decode(base64File.replaceAll(RegExp(r'\s+'), '')),
      ),
      'filename': data['filename'] as String? ?? 'Смета_выполнение.xlsx',
    };
  }

  @override
  Future<List<EstimatePositionAddendumHistoryEntry>>
  getEstimatePositionAddendumHistory({
    required String contractId,
    required String estimateTitle,
    required String estimateRowId,
  }) async {
    final trimmedTitle = estimateTitle.trim();
    if (trimmedTitle.isEmpty) {
      return const [];
    }

    final est = await client
        .from(table)
        .select('position_id, quantity, price, total, updated_at')
        .eq('id', estimateRowId)
        .eq('company_id', activeCompanyId)
        .eq('contract_id', contractId)
        .maybeSingle();

    if (est == null) {
      return const [];
    }

    final positionId = est['position_id']?.toString();
    if (positionId == null || positionId.isEmpty) {
      return _estimateHistoryCurrentOnly(est);
    }

    final revResponse = await client
        .from('estimate_revisions')
        .select(
          'id, revision_label, revision_type, revision_no, status, created_at, effective_from, approved_at',
        )
        .eq('company_id', activeCompanyId)
        .eq('contract_id', contractId)
        .eq('estimate_title', trimmedTitle)
        .order('revision_no', ascending: true);

    final allRevs = (revResponse as List).cast<Map<String, dynamic>>();
    final revList = allRevs.where((r) {
      final t = (r['revision_type'] as String?)?.trim() ?? '';
      return t == 'original' || t == 'addendum';
    }).toList();

    if (revList.isEmpty) {
      return _estimateHistoryCurrentOnly(est);
    }

    final revIds = <String>[];
    for (final r in revList) {
      final id = r['id']?.toString();
      if (id != null && id.isNotEmpty) {
        revIds.add(id);
      }
    }
    if (revIds.isEmpty) {
      return _estimateHistoryCurrentOnly(est);
    }

    final itemsByRevision = <String, Map<String, dynamic>>{};
    const chunk = 20;
    for (var i = 0; i < revIds.length; i += chunk) {
      final slice = revIds.sublist(
        i,
        i + chunk > revIds.length ? revIds.length : i + chunk,
      );
      final itemsResponse = await client
          .from('estimate_revision_items')
          .select('revision_id, quantity, total, price, change_type')
          .eq('company_id', activeCompanyId)
          .eq('position_id', positionId)
          .inFilter('revision_id', slice);

      for (final row in itemsResponse as List) {
        final m = row as Map<String, dynamic>;
        final rid = m['revision_id']?.toString();
        if (rid != null && rid.isNotEmpty) {
          itemsByRevision[rid] = m;
        }
      }
    }

    DateTime? parseDateOnly(dynamic v) {
      if (v == null) return null;
      final s = v.toString().trim();
      if (s.isEmpty) return null;
      final normalized = s.length <= 10 ? '${s}T00:00:00' : s;
      return DateTime.tryParse(normalized);
    }

    DateTime displayDateForRev(Map<String, dynamic> r) {
      final eff = parseDateOnly(r['effective_from']);
      if (eff != null) {
        return DateTime(eff.year, eff.month, eff.day);
      }
      final approved = r['approved_at'];
      if (approved != null) {
        final d = DateTime.tryParse(approved.toString());
        if (d != null) return d;
      }
      final c = r['created_at'];
      return DateTime.tryParse(c?.toString() ?? '') ?? DateTime.now();
    }

    final out = <EstimatePositionAddendumHistoryEntry>[];
    for (final r in revList) {
      final rid = r['id']?.toString() ?? '';
      if (rid.isEmpty) continue;
      final item = itemsByRevision[rid];
      if (item == null) continue;

      final type = (r['revision_type'] as String?)?.trim() ?? '';
      final labelRaw = r['revision_label']?.toString().trim();
      final label = labelRaw != null && labelRaw.isNotEmpty
          ? labelRaw
          : (type == 'original' ? 'Основная' : 'ДС');

      out.add(
        EstimatePositionAddendumHistoryEntry(
          revisionId: rid,
          revisionLabel: label,
          kind: type.isNotEmpty ? type : 'addendum',
          displayDate: displayDateForRev(r),
          quantity: _toDouble(item['quantity']),
          price: _toDouble(item['price']),
          total: _toDouble(item['total']),
          changeType: (item['change_type'] as String?)?.trim() ?? '',
        ),
      );
    }

    out.add(_estimateHistorySyntheticCurrent(est));

    return out;
  }

  EstimatePositionAddendumHistoryEntry _estimateHistorySyntheticCurrent(
    Map<String, dynamic> est,
  ) {
    final updatedAt = est['updated_at'];
    final curDate = updatedAt != null
        ? DateTime.tryParse(updatedAt.toString()) ?? DateTime.now()
        : DateTime.now();
    return EstimatePositionAddendumHistoryEntry(
      revisionId: '',
      revisionLabel: 'Сейчас в договорной смете (estimates)',
      kind: 'current',
      displayDate: curDate,
      quantity: _toDouble(est['quantity']),
      price: _toDouble(est['price']),
      total: _toDouble(est['total']),
      changeType: 'current',
    );
  }

  List<EstimatePositionAddendumHistoryEntry> _estimateHistoryCurrentOnly(
    Map<String, dynamic> est,
  ) {
    return [_estimateHistorySyntheticCurrent(est)];
  }

  @override
  Future<EstimateRevisionDraftResult> createEstimateRevisionDraft({
    required String estimateTitle,
    required String contractId,
    String? objectId,
    required String fileName,
    required Uint8List fileBytes,
    required List<EstimateAddendumImportRow> rows,
    DateTime? effectiveFrom,
    String? userDescription,
  }) async {
    if (rows.isEmpty) {
      throw Exception('Файл LC / ДС не содержит строк для импорта');
    }

    final currentUserId = client.auth.currentUser?.id;
    if (currentUserId == null) {
      throw Exception('Не удалось определить текущего пользователя');
    }

    final storagePath = await _uploadEstimateRevisionSourceFile(
      contractId: contractId,
      fileName: fileName,
      fileBytes: fileBytes,
    );

    final estimateRows = await _getEstimateRowsForAddendum(
      estimateTitle: estimateTitle,
      contractId: contractId,
      objectId: objectId,
    );

    if (estimateRows.isEmpty) {
      throw Exception(
        'Не удалось подготовить базовую смету для LC / ДС: текущие позиции не найдены',
      );
    }

    final revisionRows = await client
        .from('estimate_revisions')
        .select('id, revision_no, status, revision_type')
        .eq('company_id', activeCompanyId)
        .eq('contract_id', contractId)
        .eq('estimate_title', estimateTitle)
        .order('revision_no', ascending: false);

    final parsedRevisionRows = (revisionRows as List)
        .cast<Map<String, dynamic>>();

    final latestApprovedRevision = parsedRevisionRows.firstWhere(
      (row) => row['status'] == 'approved',
      orElse: () => <String, dynamic>{},
    );

    final baseOriginalRevision = parsedRevisionRows.firstWhere(
      (row) =>
          ((row['revision_no'] as num?)?.toInt() ?? -1) == 0 &&
          row['revision_type'] == 'original',
      orElse: () => <String, dynamic>{},
    );

    late final String baseRevisionId;
    var baseRevisionCreated = false;

    if (baseOriginalRevision.isNotEmpty) {
      baseRevisionId = baseOriginalRevision['id'] as String;
    } else {
      // Compatibility note:
      // для старых договоров, где revision-flow еще не запускался, создаём
      // базовую "Основную" ревизию из текущей таблицы `estimates`.
      baseRevisionId = await _createBaseEstimateRevision(
        contractId: contractId,
        estimateTitle: estimateTitle,
        currentUserId: currentUserId,
        estimateRows: estimateRows,
      );
      baseRevisionCreated = true;
    }

    await _ensureBaseRevisionItemsSeeded(
      revisionId: baseRevisionId,
      estimateRows: estimateRows,
    );

    if (baseOriginalRevision.isNotEmpty &&
        baseOriginalRevision['status'] == 'draft') {
      await _promoteBaseRevisionToApproved(baseRevisionId);
    }

    final basedOnRevisionId = latestApprovedRevision.isNotEmpty
        ? latestApprovedRevision['id'] as String
        : baseRevisionId;

    final existingRevisionRows =
        (await client
                .from('estimate_revisions')
                .select('id, revision_no')
                .eq('company_id', activeCompanyId)
                .eq('contract_id', contractId)
                .eq('estimate_title', estimateTitle))
            as List;

    var nextRevisionNo = 1;
    if (existingRevisionRows.isNotEmpty) {
      final maxRevisionNo = existingRevisionRows
          .map((row) => (row['revision_no'] as num?)?.toInt() ?? 0)
          .reduce((a, b) => a > b ? a : b);
      nextRevisionNo = maxRevisionNo + 1;
    }

    final effective = effectiveFrom ?? DateTime.now();
    final sqlDate = _revisionEffectiveDateOnly(effective);
    final trimmedDescription = userDescription?.trim();
    final descriptionValue =
        trimmedDescription == null || trimmedDescription.isEmpty
        ? null
        : trimmedDescription;

    final draftRevisionResponse = await client
        .from('estimate_revisions')
        .insert({
          'company_id': activeCompanyId,
          'contract_id': contractId,
          'estimate_title': estimateTitle,
          'revision_no': nextRevisionNo,
          'revision_label': 'ДС-$nextRevisionNo',
          'revision_type': 'addendum',
          'status': 'approved',
          'based_on_revision_id': basedOnRevisionId,
          'source_file_path': storagePath,
          'created_by': currentUserId,
          'approved_at': DateTime.now().toUtc().toIso8601String(),
          'effective_from': sqlDate,
          'user_description': descriptionValue,
        })
        .select('id, revision_no, revision_label')
        .single();

    final draftRevisionId = draftRevisionResponse['id'] as String;
    final basedOnItems = await _getRevisionItemsByRevisionId(basedOnRevisionId);

    final estimateIdByPosition = {
      for (final row in estimateRows)
        row['position_id'] as String: row['id'] as String?,
    };

    final importedPositionIds = <String>{};
    const uuid = Uuid();
    final revisionItemsToInsert = <Map<String, dynamic>>[];

    for (final row in rows) {
      final normalizedPositionId = row.positionId?.trim();
      final hasPositionId =
          normalizedPositionId != null && normalizedPositionId.isNotEmpty;
      final resolvedPositionId = hasPositionId
          ? normalizedPositionId
          : uuid.v4();

      if (hasPositionId) {
        importedPositionIds.add(resolvedPositionId);
      }

      final basedOnItem = basedOnItems[resolvedPositionId];
      final changeType = hasPositionId
          ? _resolveRevisionItemChangeType(basedOnItem, row)
          : 'added';

      revisionItemsToInsert.add({
        'company_id': activeCompanyId,
        'revision_id': draftRevisionId,
        'position_id': resolvedPositionId,
        'source_estimate_id': estimateIdByPosition[resolvedPositionId],
        'row_no': row.rowNo,
        'system': row.system,
        'subsystem': row.subsystem,
        'number': row.number,
        'name': row.name,
        'article': row.article,
        'manufacturer': row.manufacturer,
        'unit': row.unit,
        'quantity': row.quantity,
        'price': row.price,
        'total': row.total,
        'change_type': changeType,
      });
    }

    // Для полного файла LC / ДС помечаем строки, которых больше нет в Excel,
    // как removed, но не удаляем историю физически.
    for (final entry in basedOnItems.entries) {
      if (importedPositionIds.contains(entry.key)) continue;

      final row = entry.value;
      revisionItemsToInsert.add({
        'company_id': activeCompanyId,
        'revision_id': draftRevisionId,
        'position_id': entry.key,
        'source_estimate_id':
            row['source_estimate_id'] ?? estimateIdByPosition[entry.key],
        'row_no': ((row['row_no'] as num?)?.toInt() ?? 0) + 100000,
        'system': row['system']?.toString() ?? '',
        'subsystem': row['subsystem']?.toString() ?? '',
        'number': row['number']?.toString() ?? '',
        'name': row['name']?.toString() ?? '',
        'article': row['article']?.toString() ?? '',
        'manufacturer': row['manufacturer']?.toString() ?? '',
        'unit': row['unit']?.toString() ?? '',
        'quantity': _toDouble(row['quantity']),
        'price': _toDouble(row['price']),
        'total': _toDouble(row['total']),
        'change_type': 'removed',
      });
    }

    if (revisionItemsToInsert.isNotEmpty) {
      await client
          .from('estimate_revision_items')
          .insert(revisionItemsToInsert);
    }

    return EstimateRevisionDraftResult(
      revisionId: draftRevisionId,
      revisionNo: (draftRevisionResponse['revision_no'] as num).toInt(),
      revisionLabel: draftRevisionResponse['revision_label'] as String,
      itemsCount: revisionItemsToInsert.length,
      baseRevisionCreated: baseRevisionCreated,
    );
  }

  @override
  Future<List<EstimateBulkUpdateTemplateRow>> getBulkUpdateTemplateRows({
    required String estimateTitle,
    required String contractId,
    String? objectId,
  }) async {
    var query = client
        .from(table)
        .select(
          'id, position_id, updated_at, system, subsystem, number, name, article, manufacturer, unit, quantity, price, total',
        )
        .eq('company_id', activeCompanyId)
        .eq('contract_id', contractId)
        .eq('estimate_title', estimateTitle);

    if (objectId == null) {
      query = query.isFilter('object_id', null);
    } else {
      query = query.eq('object_id', objectId);
    }

    final response = await query.order('system').order('number');
    return (response as List).cast<Map<String, dynamic>>().map((row) {
      return EstimateBulkUpdateTemplateRow(
        id: row['id']?.toString() ?? '',
        positionId: row['position_id']?.toString() ?? '',
        updatedAt: DateTime.parse(row['updated_at'].toString()),
        system: row['system']?.toString() ?? '',
        subsystem: row['subsystem']?.toString() ?? '',
        number: row['number']?.toString() ?? '',
        name: row['name']?.toString() ?? '',
        article: row['article']?.toString() ?? '',
        manufacturer: row['manufacturer']?.toString() ?? '',
        unit: row['unit']?.toString() ?? '',
        quantity: _toDouble(row['quantity']),
        price: _toDouble(row['price']),
        total: _toDouble(row['total']),
      );
    }).toList();
  }

  @override
  Future<Map<String, dynamic>> getBulkUpdateTemplateFile({
    required String estimateTitle,
    required String contractId,
    String? objectId,
  }) async {
    final response = await client.functions.invoke(
      'export-estimate-bulk-update-template',
      body: {
        'companyId': activeCompanyId,
        'contractId': contractId,
        'estimateTitle': estimateTitle,
        if (objectId != null) 'objectId': objectId,
      },
      headers: {
        'Authorization':
            'Bearer ${client.auth.currentSession?.accessToken ?? ''}',
        'Content-Type': 'application/json',
      },
    );

    final data = response.data;
    if (data is! Map) {
      throw Exception('Некорректный ответ сервера');
    }
    final error = data['error'];
    if (error != null) {
      throw Exception(error.toString());
    }

    final fileBase64 = data['file'] as String?;
    if (fileBase64 == null || fileBase64.isEmpty) {
      throw Exception('Ответ сервера не содержит Excel-файл');
    }

    return {
      'bytes': Uint8List.fromList(
        base64Decode(fileBase64.replaceAll(RegExp(r'\s+'), '')),
      ),
      'filename': data['filename'] as String? ?? 'estimate_update.xlsx',
    };
  }

  @override
  Future<Map<String, dynamic>> getEstimateImportTemplateFile({
    String? contractId,
  }) async {
    final response = await client.functions.invoke(
      'generate-estimate-import-template',
      body: {
        'companyId': activeCompanyId,
        if (contractId != null && contractId.isNotEmpty)
          'contractId': contractId,
      },
      headers: {
        'Authorization':
            'Bearer ${client.auth.currentSession?.accessToken ?? ''}',
        'Content-Type': 'application/json',
      },
    );

    final data = response.data;
    if (data is! Map) {
      throw Exception('Некорректный ответ сервера');
    }
    final error = data['error'];
    if (error != null) {
      throw Exception(error.toString());
    }

    final fileBase64 = data['file'] as String?;
    if (fileBase64 == null || fileBase64.isEmpty) {
      throw Exception('Ответ сервера не содержит Excel-файл');
    }

    return {
      'bytes': Uint8List.fromList(
        base64Decode(fileBase64.replaceAll(RegExp(r'\s+'), '')),
      ),
      'filename': data['filename'] as String? ?? 'estimate_template.xlsx',
    };
  }

  @override
  Future<EstimateBulkUpdateResult> runBulkUpdate({
    required String estimateTitle,
    required String contractId,
    String? objectId,
    required List<EstimateBulkUpdateImportRow> rows,
    required bool dryRun,
    String? sourceFileName,
  }) async {
    final response = await client.rpc(
      'apply_estimate_bulk_update',
      params: {
        'p_company_id': activeCompanyId,
        'p_contract_id': contractId,
        'p_estimate_title': estimateTitle,
        'p_rows': rows.map((row) => row.toRpcJson()).toList(),
        'p_dry_run': dryRun,
        'p_object_id': objectId,
        'p_source_file_name': sourceFileName,
      },
    );

    if (response is! Map) {
      throw Exception('Некорректный ответ сервера при обновлении сметы');
    }

    return EstimateBulkUpdateResult.fromJson(response.cast<String, dynamic>());
  }

  /// Календарная дата для колонки `effective_from` (тип DATE).
  String _revisionEffectiveDateOnly(DateTime d) {
    final l = DateTime(d.year, d.month, d.day);
    final y = l.year.toString().padLeft(4, '0');
    final m = l.month.toString().padLeft(2, '0');
    final day = l.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  Future<List<Map<String, dynamic>>> _getEstimateRowsRaw({
    required String estimateTitle,
    required String contractId,
    String? objectId,
  }) async {
    var q = client
        .from(table)
        .select('id, position_id, updated_at')
        .eq('company_id', activeCompanyId)
        .eq('contract_id', contractId)
        .eq('estimate_title', estimateTitle);
    if (objectId == null || objectId.isEmpty) {
      q = q.isFilter('object_id', null);
    } else {
      q = q.eq('object_id', objectId);
    }
    final response = await q;
    return (response as List).cast<Map<String, dynamic>>();
  }

  @override
  Future<EstimateBulkUpdateResult> applyAddendumRevisionToEstimates({
    required String revisionId,
  }) async {
    final rev = await client
        .from('estimate_revisions')
        .select(
          'id, company_id, contract_id, estimate_title, revision_type, applied_to_estimates_at',
        )
        .eq('id', revisionId)
        .eq('company_id', activeCompanyId)
        .maybeSingle();

    if (rev == null) {
      throw Exception('Ревизия не найдена');
    }
    if (rev['revision_type'] != 'addendum') {
      throw Exception(
        'К основной смете можно применить только доп. соглашение (addendum)',
      );
    }
    if (rev['applied_to_estimates_at'] != null) {
      throw Exception('Это доп. соглашение уже перенесено в основную смету');
    }

    final contractId = rev['contract_id'] as String;
    final estimateTitle = rev['estimate_title'] as String;

    final contractRow = await client
        .from('contracts')
        .select('object_id')
        .eq('id', contractId)
        .eq('company_id', activeCompanyId)
        .maybeSingle();
    if (contractRow == null) {
      throw Exception('Договор не найден');
    }
    final objectId = contractRow['object_id'] as String?;

    final items = await client
        .from('estimate_revision_items')
        .select(
          'position_id, source_estimate_id, change_type, system, subsystem, number, name, article, manufacturer, unit, quantity, price, total, row_no',
        )
        .eq('revision_id', revisionId)
        .eq('company_id', activeCompanyId)
        .order('row_no');

    final itemList = (items as List).cast<Map<String, dynamic>>();
    if (itemList.isEmpty) {
      throw Exception('В ревизии нет строк для применения');
    }

    final estRows = await _getEstimateRowsRaw(
      estimateTitle: estimateTitle,
      contractId: contractId,
      objectId: objectId,
    );

    final byPosition = <String, Map<String, dynamic>>{};
    for (final er in estRows) {
      final pid = er['position_id']?.toString();
      if (pid != null && pid.isNotEmpty) {
        byPosition[pid] = er;
      }
    }

    final toDelete = <String>{};
    final bulkRows = <EstimateBulkUpdateImportRow>[];
    var rowNo = 0;

    for (final it in itemList) {
      final changeType = it['change_type'] as String? ?? '';
      if (changeType == 'removed') {
        final sid = it['source_estimate_id']?.toString();
        if (sid != null && sid.isNotEmpty) {
          toDelete.add(sid);
        }
        continue;
      }

      rowNo++;
      final posId = it['position_id']?.toString();
      if (posId == null || posId.isEmpty) {
        throw Exception('У строки ревизии отсутствует position_id');
      }

      final ex = byPosition[posId];
      final srcId = it['source_estimate_id'] as String?;
      final String? existingId;
      if (srcId != null && srcId.trim().isNotEmpty) {
        existingId = srcId.trim();
      } else if (ex != null && ex['id'] != null) {
        existingId = ex['id'] as String;
      } else {
        existingId = null;
      }

      bulkRows.add(
        EstimateBulkUpdateImportRow(
          rowNo: rowNo,
          id: existingId,
          positionId: posId,
          updatedAt: null,
          system: it['system']?.toString() ?? '',
          subsystem: it['subsystem']?.toString() ?? '',
          number: it['number']?.toString() ?? '',
          name: it['name']?.toString() ?? '',
          article: it['article']?.toString() ?? '',
          manufacturer: it['manufacturer']?.toString() ?? '',
          unit: it['unit']?.toString() ?? '',
          quantity: (it['quantity'] as num?)?.toDouble() ?? 0.0,
          price: (it['price'] as num?)?.toDouble() ?? 0.0,
        ),
      );
    }

    EstimateBulkUpdateResult? appliedResult;
    if (bulkRows.isNotEmpty) {
      final preview = await runBulkUpdate(
        estimateTitle: estimateTitle,
        contractId: contractId,
        objectId: objectId,
        rows: bulkRows,
        dryRun: true,
        sourceFileName: 'apply_revision:$revisionId',
      );
      if (preview.summary.conflicts > 0) {
        throw Exception(
          'Нельзя применить ДС: ${preview.summary.conflicts} конфликт(ов). '
          'Возможно, позиции сметы изменились после создания ревизии. '
          'Повторите попытку или приведите смету в соответствие с ревизией.',
        );
      }

      appliedResult = await runBulkUpdate(
        estimateTitle: estimateTitle,
        contractId: contractId,
        objectId: objectId,
        rows: bulkRows,
        dryRun: false,
        sourceFileName: 'apply_revision:$revisionId',
      );
    }

    for (final delId in toDelete) {
      await deleteEstimate(delId);
    }

    final uid = client.auth.currentUser?.id;
    await client
        .from('estimate_revisions')
        .update({
          'applied_to_estimates_at': DateTime.now().toUtc().toIso8601String(),
          if (uid != null) 'applied_by': uid,
        })
        .eq('id', revisionId)
        .eq('company_id', activeCompanyId);

    return appliedResult ??
        EstimateBulkUpdateResult.fromJson(const <String, dynamic>{
          'dry_run': false,
          'applied': true,
          'summary': <String, dynamic>{
            'total': 0,
            'updated': 0,
            'inserted': 0,
            'skipped': 0,
            'conflicts': 0,
          },
          'items': <dynamic>[],
        });
  }

  @override
  Future<void> updateEstimateRevisionMetadata({
    required String revisionId,
    DateTime? effectiveFrom,
    String? userDescription,
  }) async {
    final patch = <String, dynamic>{};
    if (effectiveFrom != null) {
      patch['effective_from'] = _revisionEffectiveDateOnly(effectiveFrom);
    }
    if (userDescription != null) {
      final t = userDescription.trim();
      patch['user_description'] = t.isEmpty ? null : t;
    }
    if (patch.isEmpty) {
      return;
    }
    await client
        .from('estimate_revisions')
        .update(patch)
        .eq('id', revisionId)
        .eq('company_id', activeCompanyId);
  }

  @override
  Future<void> deleteAddendumRevision({required String revisionId}) async {
    final rev = await client
        .from('estimate_revisions')
        .select('id, revision_type, applied_to_estimates_at, source_file_path')
        .eq('id', revisionId)
        .eq('company_id', activeCompanyId)
        .maybeSingle();

    if (rev == null) {
      throw Exception('Ревизия не найдена');
    }
    if (rev['revision_type'] != 'addendum') {
      throw Exception(
        'Удалять можно только дополнительное соглашение (addendum)',
      );
    }
    if (rev['applied_to_estimates_at'] != null) {
      throw Exception('Нельзя удалить ДС, уже перенесённое в основную смету');
    }

    final dependent = await client
        .from('estimate_revisions')
        .select('id')
        .eq('company_id', activeCompanyId)
        .eq('based_on_revision_id', revisionId)
        .limit(1);

    final depList = dependent as List;
    if (depList.isNotEmpty) {
      throw Exception(
        'Нельзя удалить это ДС: есть следующее по цепочке. Сначала удалите более поздние ДС.',
      );
    }

    final path = rev['source_file_path']?.toString().trim();
    if (path != null && path.isNotEmpty) {
      try {
        await client.storage.from('estimates').remove([path]);
      } catch (_) {
        // Файл мог отсутствовать или быть недоступен по политике bucket.
      }
    }

    await client
        .from('estimate_revisions')
        .delete()
        .eq('id', revisionId)
        .eq('company_id', activeCompanyId);
  }

  @override
  Future<List<VorModel>> getVors(String contractId) async {
    final response = await client
        .from('vors')
        .select(
          '*, excel_url, vor_systems(system_name), vor_status_history(*, user_profile:profiles(full_name)), created_by_profile:profiles!vors_created_by_fkey(full_name)',
        )
        .eq('contract_id', contractId)
        .eq('company_id', activeCompanyId)
        .order('created_at', ascending: false);

    return (response as List).map((json) {
      final systems =
          (json['vor_systems'] as List?)
              ?.map((s) => s['system_name'] as String)
              .toList() ??
          [];

      final history =
          (json['vor_status_history'] as List?)
              ?.map(
                (h) => VorStatusHistoryModel.fromJson(h).copyWith(
                  userName: h['user_profile']?['full_name'] as String?,
                ),
              )
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
    bool includeCombinedSheet = false,
  }) async {
    // 1. Получаем следующий порядковый номер через RPC
    final nextNumber = await client.rpc(
      'get_next_vor_number',
      params: {'p_company_id': activeCompanyId, 'p_contract_id': contractId},
    );

    // 2. Создаем заголовок ВОР
    final vorResponse = await client
        .from('vors')
        .insert({
          'company_id': activeCompanyId,
          'contract_id': contractId,
          'number': nextNumber,
          'start_date': startDate.toIso8601String(),
          'end_date': endDate.toIso8601String(),
          'status': 'draft',
          'include_combined_sheet': includeCombinedSheet,
          'created_by': client.auth.currentUser?.id,
        })
        .select('id')
        .single();

    final vorId = vorResponse['id'] as String;

    // 2. Добавляем системы
    if (systems.isNotEmpty) {
      await client
          .from('vor_systems')
          .insert(
            systems
                .map(
                  (s) => {
                    'vor_id': vorId,
                    'company_id': activeCompanyId,
                    'system_name': s,
                  },
                )
                .toList(),
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
  Future<void> updateVorStatus(
    String vorId,
    VorStatus status, {
    String? comment,
  }) async {
    // 1. Обновляем статус в заголовке
    await client
        .from('vors')
        .update({'status': status.name})
        .eq('id', vorId)
        .eq('company_id', activeCompanyId);

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

  @override
  Future<void> recalculateVor(String vorId) async {
    await client.rpc('recalculate_vor', params: {'p_vor_id': vorId});
  }

  @override
  Future<Map<String, bool>> getDraftVorNeedsRecalc(String contractId) async {
    final response = await client.rpc(
      'get_draft_vor_needs_recalc',
      params: {'p_contract_id': contractId},
    );

    final rows = response as List<dynamic>;
    return {
      for (final row in rows)
        row['vor_id'] as String: row['needs_recalc'] as bool? ?? false,
    };
  }

  @override
  Future<List<Map<String, dynamic>>> getVorRecalcChangesRaw(
    String vorId,
  ) async {
    final response = await client.rpc(
      'get_vor_recalc_changes',
      params: {'p_vor_id': vorId},
    );

    if (response == null) return const [];

    final List<dynamic> rows;
    if (response is List) {
      rows = response;
    } else if (response is String) {
      final decoded = jsonDecode(response);
      if (decoded is! List) return const [];
      rows = decoded;
    } else if (response is Map && response['changes'] is List) {
      rows = response['changes'] as List<dynamic>;
    } else {
      return const [];
    }

    return rows.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  @override
  Future<void> uploadVorPdf({
    required String vorId,
    required File file,
    required String fileName,
  }) async {
    final vorData = await client
        .from('vors')
        .select('contract_id, pdf_url, status')
        .eq('id', vorId)
        .eq('company_id', activeCompanyId)
        .single();

    final status = vorData['status'] as String?;
    if (status != VorStatus.approved.name) {
      throw Exception('PDF можно загрузить только для подписанной ВОР');
    }

    final contractId = vorData['contract_id'] as String;
    final previousPdfPath = vorData['pdf_url'] as String?;
    final safeName = _buildSafeStorageFileName(fileName);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final storagePath = '$contractId/$vorId/${timestamp}_$safeName';

    await client.storage
        .from('vor_documents')
        .upload(
          storagePath,
          file,
          fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
        );

    try {
      await client.rpc(
        'set_vor_pdf_document',
        params: {
          'p_vor_id': vorId,
          'p_company_id': activeCompanyId,
          'p_pdf_url': storagePath,
        },
      );

      await client.from('vor_status_history').insert({
        'vor_id': vorId,
        'company_id': activeCompanyId,
        'status': VorStatus.approved.name,
        'user_id': client.auth.currentUser?.id,
        'comment': 'Загружен подписанный ВОР PDF',
      });
    } catch (error) {
      await client.storage.from('vor_documents').remove([storagePath]);
      rethrow;
    }

    if (previousPdfPath != null &&
        previousPdfPath.isNotEmpty &&
        previousPdfPath != storagePath) {
      await client.storage.from('vor_documents').remove([previousPdfPath]);
    }
  }

  @override
  Future<String> getVorPdfViewUrl(String vorId) async {
    final vorData = await client
        .from('vors')
        .select('pdf_url')
        .eq('id', vorId)
        .eq('company_id', activeCompanyId)
        .single();

    final pdfPath = vorData['pdf_url'] as String?;
    if (pdfPath == null || pdfPath.isEmpty) {
      throw Exception('PDF-файл для этой ВОР еще не загружен');
    }

    return client.storage.from('vor_documents').createSignedUrl(pdfPath, 3600);
  }

  Future<List<Map<String, dynamic>>> _getEstimateRowsForAddendum({
    required String estimateTitle,
    required String contractId,
    String? objectId,
  }) async {
    var query = client
        .from(table)
        .select(
          'id, position_id, system, subsystem, number, name, article, manufacturer, unit, quantity, price, total',
        )
        .eq('company_id', activeCompanyId)
        .eq('contract_id', contractId)
        .eq('estimate_title', estimateTitle);

    if (objectId != null) {
      query = query.eq('object_id', objectId);
    }

    final response = await query.order('system').order('number');
    return (response as List).cast<Map<String, dynamic>>();
  }

  Future<String> _createBaseEstimateRevision({
    required String contractId,
    required String estimateTitle,
    required String currentUserId,
    required List<Map<String, dynamic>> estimateRows,
  }) async {
    final baseRevisionResponse = await client
        .from('estimate_revisions')
        .insert({
          'company_id': activeCompanyId,
          'contract_id': contractId,
          'estimate_title': estimateTitle,
          'revision_no': 0,
          'revision_label': 'Основная',
          'revision_type': 'original',
          'status': 'draft',
          'created_by': currentUserId,
        })
        .select('id')
        .single();

    final baseRevisionId = baseRevisionResponse['id'] as String;
    await _seedRevisionItemsFromEstimateRows(
      revisionId: baseRevisionId,
      estimateRows: estimateRows,
    );

    await client
        .from('estimate_revisions')
        .update({
          'status': 'approved',
          'effective_from': DateTime.now().toIso8601String(),
          'approved_at': DateTime.now().toIso8601String(),
        })
        .eq('id', baseRevisionId)
        .eq('company_id', activeCompanyId)
        .eq('status', 'draft');

    return baseRevisionId;
  }

  Future<void> _ensureBaseRevisionItemsSeeded({
    required String revisionId,
    required List<Map<String, dynamic>> estimateRows,
  }) async {
    final existingItems = await client
        .from('estimate_revision_items')
        .select('id')
        .eq('revision_id', revisionId)
        .eq('company_id', activeCompanyId)
        .limit(1);

    if ((existingItems as List).isNotEmpty) {
      return;
    }

    await _seedRevisionItemsFromEstimateRows(
      revisionId: revisionId,
      estimateRows: estimateRows,
    );
  }

  Future<void> _seedRevisionItemsFromEstimateRows({
    required String revisionId,
    required List<Map<String, dynamic>> estimateRows,
  }) async {
    final baseItems = <Map<String, dynamic>>[];

    for (var i = 0; i < estimateRows.length; i++) {
      final row = estimateRows[i];
      baseItems.add({
        'company_id': activeCompanyId,
        'revision_id': revisionId,
        'position_id': row['position_id'],
        'source_estimate_id': row['id'],
        'row_no': i + 1,
        'system': row['system']?.toString() ?? '',
        'subsystem': row['subsystem']?.toString() ?? '',
        'number': row['number']?.toString() ?? '',
        'name': row['name']?.toString() ?? '',
        'article': row['article']?.toString() ?? '',
        'manufacturer': row['manufacturer']?.toString() ?? '',
        'unit': row['unit']?.toString() ?? '',
        'quantity': _toDouble(row['quantity']),
        'price': _toDouble(row['price']),
        'total': _toDouble(row['total']),
        'change_type': 'unchanged',
      });
    }

    if (baseItems.isEmpty) {
      return;
    }

    await client.from('estimate_revision_items').insert(baseItems);
  }

  Future<void> _promoteBaseRevisionToApproved(String revisionId) async {
    await client
        .from('estimate_revisions')
        .update({
          'status': 'approved',
          'effective_from': DateTime.now().toIso8601String(),
          'approved_at': DateTime.now().toIso8601String(),
        })
        .eq('id', revisionId)
        .eq('company_id', activeCompanyId)
        .eq('status', 'draft');
  }

  Future<Map<String, Map<String, dynamic>>> _getRevisionItemsByRevisionId(
    String? revisionId,
  ) async {
    if (revisionId == null || revisionId.isEmpty) {
      return {};
    }

    final response = await client
        .from('estimate_revision_items')
        .select(
          'position_id, source_estimate_id, row_no, system, subsystem, number, name, article, manufacturer, unit, quantity, price, total',
        )
        .eq('revision_id', revisionId)
        .eq('company_id', activeCompanyId);

    return {
      for (final row in response as List)
        row['position_id'] as String: (row as Map<String, dynamic>),
    };
  }

  Future<String> _uploadEstimateRevisionSourceFile({
    required String contractId,
    required String fileName,
    required Uint8List fileBytes,
  }) async {
    final safeName = _buildSafeStorageFileName(fileName);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final storagePath = 'addendums/$contractId/${timestamp}_$safeName';

    await client.storage
        .from('estimates')
        .uploadBinary(
          storagePath,
          fileBytes,
          fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
        );

    return storagePath;
  }

  String _resolveRevisionItemChangeType(
    Map<String, dynamic>? basedOnItem,
    EstimateAddendumImportRow row,
  ) {
    if (basedOnItem == null) {
      return 'added';
    }

    final baseQuantity = _toDouble(basedOnItem['quantity']);
    final basePrice = _toDouble(basedOnItem['price']);

    if ((baseQuantity - row.quantity).abs() > 0.000001) {
      return 'qty_changed';
    }

    if ((basePrice - row.price).abs() > 0.000001) {
      return 'price_changed';
    }

    return 'unchanged';
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString().replaceAll(',', '.')) ?? 0.0;
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

  /// Подготавливает имя файла для безопасного хранения в Supabase Storage.
  ///
  /// Убирает пробелы и любые символы, которые могут сделать storage key
  /// невалидным на стороне backend.
  String _buildSafeStorageFileName(String fileName) {
    final normalized = fileName.trim();
    final dotIndex = normalized.lastIndexOf('.');
    final hasExtension = dotIndex > 0 && dotIndex < normalized.length - 1;

    final rawBaseName = hasExtension
        ? normalized.substring(0, dotIndex)
        : normalized;
    final rawExtension = hasExtension
        ? normalized.substring(dotIndex + 1).toLowerCase()
        : 'pdf';

    final safeBaseName = rawBaseName
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^[._-]+|[._-]+$'), '');

    final safeExtension = rawExtension
        .replaceAll(RegExp(r'[^A-Za-z0-9]+'), '')
        .toLowerCase();

    final resolvedBaseName = safeBaseName.isEmpty ? 'signed_vor' : safeBaseName;
    final resolvedExtension = safeExtension.isEmpty ? 'pdf' : safeExtension;

    return '$resolvedBaseName.$resolvedExtension';
  }
}
