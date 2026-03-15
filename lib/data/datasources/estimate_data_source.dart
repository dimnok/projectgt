import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:excel/excel.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import '../models/estimate_model.dart';
import '../models/estimate_completion_model.dart';
import '../models/vor_model.dart';
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

  /// Создаёт черновик ревизии LC / ДС в новых таблицах.
  Future<EstimateRevisionDraftResult> createEstimateRevisionDraft({
    required String estimateTitle,
    required String contractId,
    String? objectId,
    required String fileName,
    required Uint8List fileBytes,
    required List<EstimateAddendumImportRow> rows,
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
  Future<EstimateRevisionDraftResult> createEstimateRevisionDraft({
    required String estimateTitle,
    required String contractId,
    String? objectId,
    required String fileName,
    required Uint8List fileBytes,
    required List<EstimateAddendumImportRow> rows,
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

    final draftRevisionResponse = await client
        .from('estimate_revisions')
        .insert({
          'company_id': activeCompanyId,
          'contract_id': contractId,
          'estimate_title': estimateTitle,
          'revision_no': nextRevisionNo,
          'revision_label': 'ДС-$nextRevisionNo',
          'revision_type': 'addendum',
          'status': 'draft',
          'based_on_revision_id': basedOnRevisionId,
          'source_file_path': storagePath,
          'created_by': currentUserId,
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
