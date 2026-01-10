import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:projectgt/features/cash_flow/domain/entities/bank_import_template.dart';

part 'bank_import_template_model.freezed.dart';
part 'bank_import_template_model.g.dart';

/// Модель данных шаблона импорта банковской выписки для Supabase.
@freezed
abstract class BankImportTemplateModel with _$BankImportTemplateModel {
  /// Конструктор для создания модели шаблона.
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory BankImportTemplateModel({
    required String id,
    required String companyId,
    required String bankName,
    required Map<String, String> columnMapping,
    @Default(1) int startRow,
    @Default('dd.MM.yyyy') String dateFormat,
  }) = _BankImportTemplateModel;

  const BankImportTemplateModel._();

  /// Преобразует модель в JSON для сохранения в БД.
  @override
  Map<String, dynamic> toJson() =>
      _$BankImportTemplateModelToJson(this as _BankImportTemplateModel);

  /// Создаёт модель из JSON.
  factory BankImportTemplateModel.fromJson(Map<String, dynamic> json) =>
      _$BankImportTemplateModelFromJson(json);

  /// Создаёт модель на основе доменной сущности [BankImportTemplate].
  factory BankImportTemplateModel.fromDomain(BankImportTemplate template) =>
      BankImportTemplateModel(
        id: template.id,
        companyId: template.companyId,
        bankName: template.bankName,
        columnMapping: template.columnMapping,
        startRow: template.startRow,
        dateFormat: template.dateFormat,
      );

  /// Преобразует модель в доменную сущность [BankImportTemplate].
  BankImportTemplate toDomain() => BankImportTemplate(
        id: id,
        companyId: companyId,
        bankName: bankName,
        columnMapping: columnMapping,
        startRow: startRow,
        dateFormat: dateFormat,
      );
}

