import 'dart:convert';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:projectgt/core/utils/attachment_file_save.dart';
import 'package:projectgt/core/utils/formatters.dart';

/// Номер и дата одного дополнительного соглашения для шапки КС-2 (тело запроса к Edge Function).
///
/// Пустая пара (и номер, и дата отсутствуют) не попадает в JSON.
class Ks2HeaderAddendumInput {
  /// Создаёт значения одного доп. соглашения.
  const Ks2HeaderAddendumInput({this.number, this.date});

  /// Номер доп. соглашения.
  final String? number;

  /// Дата доп. соглашения (на сервер уходит ISO `yyyy-mm-dd`).
  final DateTime? date;
}

/// Результат генерации Excel черновика КС-2 на сервере.
class Ks2GeneratedExcelFile {
  /// Создаёт результат с байтами и именем файла для сохранения.
  const Ks2GeneratedExcelFile({
    required this.bytes,
    required this.fileName,
  });

  /// Содержимое `.xlsx`.
  final Uint8List bytes;

  /// Имя файла (латиница/кириллица — для диалога сохранения).
  final String fileName;
}

/// Выгрузка черновика формы КС-2 (шапка и при [vorId] — таблица работ), сформированного на сервере
/// (Edge Function [export-ks2-form-header]).
///
/// Шаблон берётся из Storage (`ks2_templates` / `ks2_template.xlsx`); ответ — JSON с
/// полями `file` (base64) и `filename`.
class Ks2FormHeaderExportService {
  Ks2FormHeaderExportService._();

  /// Вызывает Edge Function и сохраняет `.xlsx` на устройстве пользователя.
  static Future<void> exportDraftHeaderToDevice({
    required SupabaseClient client,
    required String companyId,
    required String contractId,
    String? actNumber,
    DateTime? actDocDate,
    DateTime? reportingPeriodFrom,
    DateTime? reportingPeriodTo,
    List<Ks2HeaderAddendumInput> addenda = const [],
    String? vorId,
    int maxAddenda = 50,
  }) async {
    final generated = await generateDraftHeaderExcel(
      client: client,
      companyId: companyId,
      contractId: contractId,
      actNumber: actNumber,
      actDocDate: actDocDate,
      reportingPeriodFrom: reportingPeriodFrom,
      reportingPeriodTo: reportingPeriodTo,
      addenda: addenda,
      vorId: vorId,
      maxAddenda: maxAddenda,
    );

    await saveFileBytesToUserDevice(
      fileName: generated.fileName,
      bytes: generated.bytes,
    );
  }

  /// Генерирует Excel на сервере и возвращает байты (для Storage или локального сохранения).
  static Future<Ks2GeneratedExcelFile> generateDraftHeaderExcel({
    required SupabaseClient client,
    required String companyId,
    required String contractId,
    String? actNumber,
    DateTime? actDocDate,
    DateTime? reportingPeriodFrom,
    DateTime? reportingPeriodTo,
    List<Ks2HeaderAddendumInput> addenda = const [],
    String? vorId,
    int maxAddenda = 50,
  }) async {
    final map = await _invokeExportFunction(
      client: client,
      companyId: companyId,
      contractId: contractId,
      actNumber: actNumber,
      actDocDate: actDocDate,
      reportingPeriodFrom: reportingPeriodFrom,
      reportingPeriodTo: reportingPeriodTo,
      addenda: addenda,
      vorId: vorId,
      maxAddenda: maxAddenda,
    );

    final fileBase64 = map['file'] as String?;
    if (fileBase64 == null || fileBase64.isEmpty) {
      throw Exception('Ответ сервера не содержит Excel-файл');
    }

    final filename = map['filename'] as String? ?? 'КС-2_черновик.xlsx';
    final bytes = base64Decode(fileBase64.replaceAll(RegExp(r'\s+'), ''));

    return Ks2GeneratedExcelFile(
      bytes: Uint8List.fromList(bytes),
      fileName: filename,
    );
  }

  static Future<Map<String, dynamic>> _invokeExportFunction({
    required SupabaseClient client,
    required String companyId,
    required String contractId,
    String? actNumber,
    DateTime? actDocDate,
    DateTime? reportingPeriodFrom,
    DateTime? reportingPeriodTo,
    List<Ks2HeaderAddendumInput> addenda = const [],
    String? vorId,
    int maxAddenda = 50,
  }) async {
    final token = client.auth.currentSession?.accessToken;
    if (token == null || token.isEmpty) {
      throw Exception('Нет сессии: войдите в приложение заново');
    }

    final body = <String, dynamic>{
      'companyId': companyId,
      'contractId': contractId,
    };
    final trimmedAct = actNumber?.trim();
    if (trimmedAct != null && trimmedAct.isNotEmpty) {
      body['actNumber'] = trimmedAct;
    }
    if (actDocDate != null) {
      body['actDocDate'] = GtFormatters.formatDateForApi(actDocDate);
    }
    if (reportingPeriodFrom != null) {
      body['reportingPeriodFrom'] =
          GtFormatters.formatDateForApi(reportingPeriodFrom);
    }
    if (reportingPeriodTo != null) {
      body['reportingPeriodTo'] =
          GtFormatters.formatDateForApi(reportingPeriodTo);
    }

    final cap = maxAddenda < 1 ? 1 : maxAddenda;
    final addendaPayload = <Map<String, dynamic>>[];
    for (final a in addenda) {
      if (addendaPayload.length >= cap) break;
      final n = a.number?.trim();
      final hasNumber = n != null && n.isNotEmpty;
      final d = a.date;
      if (!hasNumber && d == null) continue;
      final item = <String, dynamic>{};
      if (hasNumber) {
        item['number'] = n;
      }
      if (d != null) {
        item['date'] = GtFormatters.formatDateForApi(d);
      }
      addendaPayload.add(item);
    }
    if (addendaPayload.isNotEmpty) {
      body['addenda'] = addendaPayload;
    }

    final trimmedVorId = vorId?.trim();
    if (trimmedVorId != null && trimmedVorId.isNotEmpty) {
      body['vorId'] = trimmedVorId;
    }

    final response = await client.functions.invoke(
      'export-ks2-form-header',
      body: body,
      headers: <String, String>{
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    final data = response.data;
    if (data is! Map) {
      throw Exception('Некорректный ответ сервера');
    }
    final map = Map<String, dynamic>.from(data);
    final err = map['error'];
    if (err != null) {
      throw Exception(err.toString());
    }
    return map;
  }
}
