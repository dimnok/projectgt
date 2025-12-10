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
  Future<List<EstimateModel>> importFromExcel(String filePath);

  /// Получает отчёт о выполнении смет с информацией о выполненных работах.
  Future<List<EstimateCompletionModel>> getEstimateCompletion();
}

/// Реализация EstimateDataSource через Supabase/PostgreSQL.
class SupabaseEstimateDataSource implements EstimateDataSource {
  /// Экземпляр клиента Supabase.
  final SupabaseClient client;

  /// Имя таблицы смет в базе данных.
  static const String table = 'estimates';

  /// Регулярное выражение для удаления пробелов (скомпилировано для производительности).
  static final RegExp _whitespaceRegex = RegExp(r'\s+');

  /// Создаёт экземпляр [SupabaseEstimateDataSource] с клиентом [client].
  const SupabaseEstimateDataSource(this.client);

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
          .from(table)
          .select('*')
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
    final response =
        await client.from(table).select('*').eq('id', id).maybeSingle();
    if (response == null) return null;
    return EstimateModel.fromJson(response);
  }

  @override
  Future<void> createEstimate(EstimateModel estimate) async {
    await client.from(table).insert(estimate.toJson());
  }

  @override
  Future<void> updateEstimate(EstimateModel estimate) async {
    if (estimate.id == null) throw Exception('id is required for update');
    await client.from(table).update(estimate.toJson()).eq('id', estimate.id!);
  }

  @override
  Future<void> deleteEstimate(String id) async {
    await client.from(table).delete().eq('id', id);
  }

  @override
  Future<List<EstimateModel>> importFromExcel(String filePath) async {
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

  @override
  Future<List<EstimateCompletionModel>> getEstimateCompletion() async {
    try {
      final response = await client.rpc('get_estimate_completion_report');

      if (response is! List) {
        return [];
      }

      return response
          .cast<Map<String, dynamic>>()
          .map((json) => EstimateCompletionModel.fromJson(json))
          .toList();
    } catch (e) {
      rethrow;
    }
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
