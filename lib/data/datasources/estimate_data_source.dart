import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:excel/excel.dart';
import 'dart:io';
import '../models/estimate_model.dart';

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
}

/// Реализация EstimateDataSource через Supabase/PostgreSQL.
class SupabaseEstimateDataSource implements EstimateDataSource {
  /// Экземпляр клиента Supabase.
  final SupabaseClient client;
  /// Имя таблицы смет в базе данных.
  static const String table = 'estimates';

  /// Создаёт экземпляр [SupabaseEstimateDataSource] с клиентом [client].
  SupabaseEstimateDataSource(this.client);

  @override
  Future<List<EstimateModel>> getEstimates() async {
    final response = await client.from(table).select('*').order('system');
    return response.map<EstimateModel>((json) => EstimateModel.fromJson(json)).toList();
  }

  @override
  Future<EstimateModel?> getEstimate(String id) async {
    final response = await client.from(table).select('*').eq('id', id).maybeSingle();
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
    final sheet = excel.tables[excel.tables.keys.first]!;
    final rows = sheet.rows.skip(1); // пропускаем заголовки
    
    return rows.map((row) {
      // Обработка номера: если числовой - преобразуем правильно
      String number = '';
      if (row.length > 2 && row[2]?.value != null) {
        final cellValue = row[2]!.value;
        if (cellValue != null) {
          if (cellValue is DoubleCellValue) {
            final numValue = cellValue.value;
            // Если целое число - убираем десятичную часть
            if (numValue == numValue.truncate()) {
              number = numValue.toInt().toString();
            } else {
              // Если число с десятичной частью, сохраняем формат
              number = numValue.toString();
            }
          } else if (cellValue is IntCellValue) {
            number = cellValue.value.toString();
          } else {
            // Любое другое значение преобразуем в строку
            number = cellValue.toString().trim();
          }
        }
      }
      
      // Обработка количества: если числовой - преобразуем правильно
      double quantity = 0;
      if (row.length > 7 && row[7]?.value != null) {
        final cellValue = row[7]!.value;
        if (cellValue != null) {
          if (cellValue is DoubleCellValue) {
            quantity = cellValue.value;
          } else if (cellValue is IntCellValue) {
            quantity = cellValue.value.toDouble();
          } else {
            final rawStr = cellValue.toString().trim()
                .replaceAll(RegExp(r'\s+'), '')
                .replaceAll(',', '.');
            quantity = double.tryParse(rawStr) ?? 0;
          }
        }
      }
      
      // Обработка цены: если числовой - преобразуем правильно
      double price = 0;
      if (row.length > 8 && row[8]?.value != null) {
        final cellValue = row[8]!.value;
        if (cellValue != null) {
          if (cellValue is DoubleCellValue) {
            price = cellValue.value;
          } else if (cellValue is IntCellValue) {
            price = cellValue.value.toDouble();
          } else {
            final rawStr = cellValue.toString().trim()
                .replaceAll(RegExp(r'\s+'), '')
                .replaceAll(',', '.');
            price = double.tryParse(rawStr) ?? 0;
          }
        }
      }
      
      // Обработка суммы: если числовой - преобразуем правильно
      double total = 0;
      if (row.length > 9 && row[9]?.value != null) {
        final cellValue = row[9]!.value;
        if (cellValue != null) {
          if (cellValue is DoubleCellValue) {
            total = cellValue.value;
          } else if (cellValue is IntCellValue) {
            total = cellValue.value.toDouble();
          } else {
            final rawStr = cellValue.toString().trim()
                .replaceAll(RegExp(r'\s+'), '')
                .replaceAll(',', '.');
            total = double.tryParse(rawStr) ?? 0;
          }
        }
      } else {
        // Если сумма не указана, рассчитываем её
        total = quantity * price;
      }
      
      return EstimateModel(
        id: '', // генерировать на сервере или локально
        system: row.isNotEmpty && row[0]?.value != null ? row[0]!.value.toString() : '',
        subsystem: row.length > 1 && row[1]?.value != null ? row[1]!.value.toString() : '',
        number: number,
        name: row.length > 3 && row[3]?.value != null ? row[3]!.value.toString() : '',
        article: row.length > 4 && row[4]?.value != null ? row[4]!.value.toString() : '',
        manufacturer: row.length > 5 && row[5]?.value != null ? row[5]!.value.toString() : '',
        unit: row.length > 6 && row[6]?.value != null ? row[6]!.value.toString() : '',
        quantity: quantity,
        price: price,
        total: total,
      );
    }).toList();
  }
} 