import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:projectgt/features/settlements/domain/entities/settlement_operation.dart';

part 'settlement_operation_model.freezed.dart';
part 'settlement_operation_model.g.dart';

/// Модель операции взаиморасчётов для Supabase.
@freezed
abstract class SettlementOperationModel with _$SettlementOperationModel {
  /// Создаёт модель.
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory SettlementOperationModel({
    required String id,
    required String companyId,
    required SettlementOperationType operationType,
    required String objectId,
    required String contractorId,
    required String contractId,
    @JsonKey(toJson: _dateOnlyToJson) DateTime? periodFrom,
    @JsonKey(toJson: _dateOnlyToJson) DateTime? periodTo,
    String? actNumber,
    @JsonKey(toJson: _dateOnlyToJson) DateTime? actDate,
    required String invoiceNumber,
    @JsonKey(toJson: _dateOnlyToJson) required DateTime invoiceDate,
    required double amount,
    @Default(true) bool isVatIncluded,
    double? vatRate,
    @Default(0) double vatAmount,
    @Default(0) double advanceRetention,
    @Default(0) double warrantyRetention,
    @Default(0) double totalToPay,
    @Default(0) double paidAmount,
    @Default(SettlementPaymentStatus.unpaid)
    SettlementPaymentStatus paymentStatus,
    String? purpose,
    String? note,
    DateTime? createdAt,
    String? createdBy,
    @JsonKey(includeToJson: false) String? objectName,
    @JsonKey(includeToJson: false) String? contractorName,
    @JsonKey(includeToJson: false) String? contractNumber,
  }) = _SettlementOperationModel;

  const SettlementOperationModel._();

  /// JSON для записи в БД.
  Map<String, dynamic> toJson() =>
      _$SettlementOperationModelToJson(this as _SettlementOperationModel);

  /// Из JSON с поддержкой join-полей.
  factory SettlementOperationModel.fromJson(Map<String, dynamic> json) {
    return _$SettlementOperationModelFromJson({
      ...json,
      'object_name': json['objects']?['name'],
      'contractor_name': json['contractors']?['short_name'],
      'contract_number': json['contracts']?['number'],
    });
  }

  /// Из доменной сущности.
  factory SettlementOperationModel.fromDomain(SettlementOperation op) =>
      SettlementOperationModel(
        id: op.id,
        companyId: op.companyId,
        operationType: op.operationType,
        objectId: op.objectId,
        contractorId: op.contractorId,
        contractId: op.contractId,
        periodFrom: op.periodFrom,
        periodTo: op.periodTo,
        actNumber: op.actNumber,
        actDate: op.actDate,
        invoiceNumber: op.invoiceNumber,
        invoiceDate: op.invoiceDate,
        amount: op.amount,
        isVatIncluded: op.isVatIncluded,
        vatRate: op.vatRate,
        vatAmount: op.vatAmount,
        advanceRetention: op.advanceRetention,
        warrantyRetention: op.warrantyRetention,
        totalToPay: op.totalToPay,
        paidAmount: op.paidAmount,
        paymentStatus: op.paymentStatus,
        purpose: op.purpose,
        note: op.note,
        createdAt: op.createdAt,
        createdBy: op.createdBy,
        objectName: op.objectName,
        contractorName: op.contractorName,
        contractNumber: op.contractNumber,
      );

  /// В доменную сущность.
  SettlementOperation toDomain() {
    final resolved = computeSettlementPaymentStatus(
      totalToPay: totalToPay,
      paidAmount: paidAmount,
    );
    return SettlementOperation(
        id: id,
        companyId: companyId,
        operationType: operationType,
        objectId: objectId,
        objectName: objectName,
        contractorId: contractorId,
        contractorName: contractorName,
        contractId: contractId,
        contractNumber: contractNumber,
        periodFrom: periodFrom,
        periodTo: periodTo,
        actNumber: actNumber,
        actDate: actDate,
        invoiceNumber: invoiceNumber,
        invoiceDate: invoiceDate,
        amount: amount,
        isVatIncluded: isVatIncluded,
        vatRate: vatRate,
        vatAmount: vatAmount,
        advanceRetention: advanceRetention,
        warrantyRetention: warrantyRetention,
        totalToPay: totalToPay,
        paidAmount: paidAmount,
        paymentStatus: resolved,
        purpose: purpose,
        note: note,
        createdAt: createdAt,
        createdBy: createdBy,
      );
  }

  /// JSON для insert/update без generated/id-полей.
  Map<String, dynamic> toWriteJson({required bool includeId}) {
    final json = toJson();
    json.remove('total_to_pay');
    json.remove('payment_status');
    json.remove('created_at');
    json.remove('created_by');
    if (!includeId || id.isEmpty) {
      json.remove('id');
    }
    return json;
  }
}

String? _dateOnlyToJson(DateTime? date) {
  if (date == null) return null;
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}
