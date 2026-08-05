import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:projectgt/features/settlements/domain/entities/settlement_payment.dart';

part 'settlement_payment_model.freezed.dart';
part 'settlement_payment_model.g.dart';

/// Модель оплаты по счёту для Supabase.
@freezed
abstract class SettlementPaymentModel with _$SettlementPaymentModel {
  /// Создаёт модель.
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory SettlementPaymentModel({
    required String id,
    required String companyId,
    required String settlementOperationId,
    @JsonKey(toJson: _dateOnlyToJson) required DateTime paymentDate,
    required double amount,
    String? note,
    String? cashFlowTransactionId,
    DateTime? createdAt,
    String? createdBy,
  }) = _SettlementPaymentModel;

  const SettlementPaymentModel._();

  /// JSON для записи в БД.
  factory SettlementPaymentModel.fromJson(Map<String, dynamic> json) =>
      _$SettlementPaymentModelFromJson(json);

  /// Из доменной сущности.
  factory SettlementPaymentModel.fromDomain(SettlementPayment payment) =>
      SettlementPaymentModel(
        id: payment.id,
        companyId: payment.companyId,
        settlementOperationId: payment.settlementOperationId,
        paymentDate: payment.paymentDate,
        amount: payment.amount,
        note: payment.note,
        cashFlowTransactionId: payment.cashFlowTransactionId,
        createdAt: payment.createdAt,
        createdBy: payment.createdBy,
      );

  /// В доменную сущность.
  SettlementPayment toDomain() => SettlementPayment(
        id: id,
        companyId: companyId,
        settlementOperationId: settlementOperationId,
        paymentDate: paymentDate,
        amount: amount,
        note: note,
        cashFlowTransactionId: cashFlowTransactionId,
        createdAt: createdAt,
        createdBy: createdBy,
      );

  /// JSON для insert/update.
  Map<String, dynamic> toWriteJson({required bool includeId}) {
    final json = toJson();
    json.remove('created_at');
    json.remove('created_by');
    json.remove('cash_flow_transaction_id');
    if (!includeId || id.isEmpty) {
      json.remove('id');
    }
    return json;
  }

  /// JSON для update — только редактируемые поля.
  Map<String, dynamic> toUpdateJson() => {
        'payment_date': _dateOnlyToJson(paymentDate),
        'amount': amount,
        'note': note,
      };
}

String _dateOnlyToJson(DateTime date) {
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}
