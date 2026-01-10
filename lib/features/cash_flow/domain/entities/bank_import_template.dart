import 'package:freezed_annotation/freezed_annotation.dart';

part 'bank_import_template.freezed.dart';

/// Сущность "Шаблон импорта банковской выписки".
/// 
/// Описывает правила сопоставления колонок из Excel-файла банка 
/// с полями системы.
@freezed
abstract class BankImportTemplate with _$BankImportTemplate {
  /// Создает экземпляр [BankImportTemplate].
  const factory BankImportTemplate({
    /// Уникальный идентификатор шаблона.
    required String id,
    /// Идентификатор компании, которой принадлежит шаблон.
    required String companyId,
    /// Название банка или шаблона (например, "Тинькофф", "Сбер").
    required String bankName,
    /// Маппинг колонок: ключ - поле системы, значение - название колонки в Excel.
    /// 
    /// Ключи: date, amount, type, contractor_inn, contractor_name, comment, transaction_number.
    required Map<String, String> columnMapping,
    /// Номер строки, с которой начинаются данные (по умолчанию 1).
    @Default(1) int startRow,
    /// Формат даты в файле (по умолчанию dd.MM.yyyy).
    @Default('dd.MM.yyyy') String dateFormat,
  }) = _BankImportTemplate;
}

