import 'dart:convert';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/features/cash_flow/domain/entities/bank_import_template.dart';
import 'package:projectgt/features/cash_flow/domain/entities/bank_statement_entry.dart';
import 'package:projectgt/features/cash_flow/domain/entities/cash_flow_transaction.dart';
import 'package:uuid/uuid.dart';

/// Сервис для парсинга банковских выписок через Edge Function.
class BankStatementParser {
  /// Парсит байты Excel-файла удаленно через Edge Function `bank_parse`.
  static Future<List<BankStatementEntry>> parse({
    required Uint8List bytes,
    required BankImportTemplate template,
    required String companyId,
    required String bankAccountId,
    String? targetInn,
    String? targetAccountNumber,
  }) async {
    const uuid = Uuid();

    final payload = {
      'file': base64Encode(bytes),
      'companyId': companyId,
      'bankAccountId': bankAccountId,
      'targetInn': targetInn,
      'targetAccountNumber': targetAccountNumber,
      'mapping': {
        'startRow': template.startRow,
        'columnMapping': template.columnMapping,
        'dateFormat': template.dateFormat,
      },
    };

    try {
      final response = await Supabase.instance.client.functions.invoke(
        'bank_parse',
        body: payload,
      );

      if (response.data == null) {
        throw 'Ошибка при вызове функции парсинга: нет данных';
      }

      if (response.data is Map && response.data['error'] != null) {
        throw response.data['error'];
      }

      final List<dynamic> items = response.data['items'] ?? [];
      final entries = <BankStatementEntry>[];

      for (final item in items) {
        final map = item as Map<String, dynamic>;

        final rawDate = map['date'];
        final rawAmount = map['amount'];

        // Парсинг даты (ожидаем dd.MM.yyyy от сервера)
        DateTime? date;
        if (rawDate != null && rawDate is String) {
          date =
              GtFormatters.parseDate(rawDate, 'dd.MM.yyyy') ??
              DateTime.tryParse(rawDate) ??
              GtFormatters.parseDate(rawDate, template.dateFormat);
        }

        if (date == null) {
          throw 'Не удалось распознать дату "$rawDate" в строке выписки. Проверьте формат.';
        }

        // Парсинг суммы
        double amount = 0.0;
        if (rawAmount != null) {
          if (rawAmount is num) {
            amount = rawAmount.toDouble();
          } else if (rawAmount is String) {
            amount = GtFormatters.parseAmount(rawAmount) ?? 0.0;
          }
        }

        // Определение типа
        CashFlowType type = map['type'] == 'income'
            ? CashFlowType.income
            : CashFlowType.expense;

        amount = amount.abs();

        entries.add(
          BankStatementEntry(
            id: uuid.v4(),
            companyId: companyId,
            bankAccountId: bankAccountId,
            date: date,
            amount: amount,
            type: type,
            contractorName: map['contractor_name']?.toString(),
            contractorInn: map['contractor_inn']?.toString(),
            comment: map['comment']?.toString(),
            transactionNumber: map['transaction_number']?.toString(),
            operationHash: map['operation_hash']?.toString(),
          ),
        );
      }

      return entries;
    } on FunctionException catch (e) {
      // Пытаемся достать чистое сообщение об ошибке из JSON ответа или деталей
      final details = e.details;
      String? errorMessage;

      if (details is Map) {
        errorMessage =
            details['error']?.toString() ?? details['message']?.toString();
      } else if (details is String) {
        // Иногда детали приходят как строка, пытаемся распарсить или очистить
        errorMessage = details;
        if (errorMessage.contains('"error":"')) {
          final match = RegExp(r'"error":"([^"]+)"').firstMatch(errorMessage);
          if (match != null) errorMessage = match.group(1);
        }
      }

      throw errorMessage ?? e.reasonPhrase ?? 'Ошибка сервера (${e.status})';
    } catch (e) {
      rethrow;
    }
  }
}
