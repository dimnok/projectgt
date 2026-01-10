import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:projectgt/features/cash_flow/domain/entities/cash_flow_transaction.dart';

part 'cash_flow_transaction_model.freezed.dart';
part 'cash_flow_transaction_model.g.dart';

/// Модель данных финансовой операции для Supabase.
@freezed
abstract class CashFlowTransactionModel with _$CashFlowTransactionModel {
  /// Конструктор для создания модели финансовой операции.
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory CashFlowTransactionModel({
    required String id,
    required String companyId,
    @JsonKey(toJson: _dateOnlyToJson) required DateTime date,
    required CashFlowType type,
    required double amount,
    String? objectId,
    String? contractId,
    String? contractorId,
    String? contractorName,
    String? contractorInn,
    String? categoryId,
    String? comment,
    DateTime? createdAt,
    String? createdBy,
    String? operationHash,

    // Поля из join-запросов (не для записи в БД)
    @JsonKey(includeToJson: false) String? objectName,
    @JsonKey(includeToJson: false) String? contractNumber,
    @JsonKey(includeToJson: false) String? categoryName,
    @JsonKey(includeToJson: false) String? createdByName,
  }) = _CashFlowTransactionModel;

  const CashFlowTransactionModel._();

  /// Преобразует модель в JSON для сохранения в БД.
  Map<String, dynamic> toJson() =>
      _$CashFlowTransactionModelToJson(this as _CashFlowTransactionModel);

  /// Создаёт модель из JSON ответа Supabase с поддержкой join-полей.
  factory CashFlowTransactionModel.fromJson(Map<String, dynamic> json) {
    return _$CashFlowTransactionModelFromJson({
      ...json,
      'object_name': json['objects']?['name'],
      'contract_number': json['contracts']?['number'],
      // Приоритет: данные из таблицы contractors (через join), иначе текстовое поле из cash_flow
      'contractor_name': json['contractors']?['short_name'] ?? json['contractor_name'],
      'category_name': json['cash_flow_categories']?['name'],
      'created_by_name': json['profiles']?['short_name'],
    });
  }

  /// Создаёт модель на основе доменной сущности [CashFlowTransaction].
  factory CashFlowTransactionModel.fromDomain(
    CashFlowTransaction transaction,
  ) => CashFlowTransactionModel(
    id: transaction.id,
    companyId: transaction.companyId,
    date: transaction.date,
    type: transaction.type,
    amount: transaction.amount,
    objectId: transaction.objectId,
    contractId: transaction.contractId,
    contractorId: transaction.contractorId,
    contractorName: transaction.contractorName,
    contractorInn: transaction.contractorInn,
    categoryId: transaction.categoryId,
    comment: transaction.comment,
    createdAt: transaction.createdAt,
    createdBy: transaction.createdBy,
    operationHash: transaction.operationHash,
  );

  /// Преобразует модель в доменную сущность [CashFlowTransaction].
  CashFlowTransaction toDomain() => CashFlowTransaction(
    id: id,
    companyId: companyId,
    date: date,
    type: type,
    amount: amount,
    objectId: objectId,
    objectName: objectName,
    contractId: contractId,
    contractNumber: contractNumber,
    contractorId: contractorId,
    contractorName: contractorName,
    contractorInn: contractorInn,
    categoryId: categoryId,
    categoryName: categoryName,
    comment: comment,
    createdAt: createdAt,
    createdBy: createdBy,
    createdByName: createdByName,
    operationHash: operationHash,
  );
}

String _dateOnlyToJson(DateTime date) =>
    date.toIso8601String().split('T').first;
