import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:projectgt/domain/entities/contract_act.dart';
import 'package:projectgt/domain/entities/contract_act_kind.dart';
import 'package:projectgt/domain/entities/contract_act_payment_status.dart';
import 'package:projectgt/domain/entities/contract_act_workflow_status.dart';

part 'contract_act_model.freezed.dart';
part 'contract_act_model.g.dart';

/// DTO акта договора для Supabase (`contract_acts`).
@freezed
abstract class ContractActModel with _$ContractActModel {
  const ContractActModel._();

  /// Поля строки `contract_acts` из PostgREST.
  const factory ContractActModel({
    required String id,
    @JsonKey(name: 'company_id') required String companyId,
    @JsonKey(name: 'contract_id') required String contractId,
    @JsonKey(name: 'act_kind') @Default('manual') String actKind,
    required String title,
    required String number,
    @JsonKey(name: 'act_date') required DateTime actDate,
    @JsonKey(name: 'period_from') required DateTime periodFrom,
    @JsonKey(name: 'period_to') required DateTime periodTo,
    required double amount,
    @JsonKey(name: 'vat_amount') required double vatAmount,
    @JsonKey(name: 'advance_retention') required double advanceRetention,
    @JsonKey(name: 'warranty_retention') required double warrantyRetention,
    @JsonKey(name: 'other_retentions') required double otherRetentions,
    @JsonKey(name: 'total_to_pay') required double totalToPay,
    @JsonKey(name: 'amount_source') @Default('manual') String amountSource,
    String? note,
    @JsonKey(name: 'workflow_status') required String workflowStatus,
    @JsonKey(name: 'payment_status') required String paymentStatus,
    @JsonKey(name: 'vor_id') String? vorId,
    @JsonKey(name: 'excel_path') String? excelPath,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
    @JsonKey(name: 'created_by') String? createdBy,
    @JsonKey(includeFromJson: false, includeToJson: false) String? vorNumber,
  }) = _ContractActModel;

  /// Десериализация из JSON строки таблицы `contract_acts`.
  factory ContractActModel.fromJson(Map<String, dynamic> json) =>
      _$ContractActModelFromJson(json);

  /// Разбор строки с join `vors(number)`.
  factory ContractActModel.fromJsonWithVorJoin(Map<String, dynamic> json) {
    final row = Map<String, dynamic>.from(json);
    String? vorNumber;
    final nested = row.remove('vors');
    if (nested is Map<String, dynamic> && nested['number'] != null) {
      vorNumber = nested['number'].toString();
    }
    return ContractActModel.fromJson(row).copyWith(vorNumber: vorNumber);
  }

  /// Преобразует строки статусов из API в доменную сущность.
  ContractAct toEntity() {
    return ContractAct(
      id: id,
      companyId: companyId,
      contractId: contractId,
      actKind: ContractActKindApi.parse(actKind),
      title: title,
      number: number,
      actDate: actDate,
      periodFrom: periodFrom,
      periodTo: periodTo,
      amount: amount,
      vatAmount: vatAmount,
      advanceRetention: advanceRetention,
      warrantyRetention: warrantyRetention,
      otherRetentions: otherRetentions,
      totalToPay: totalToPay,
      amountSource: ContractActAmountSourceApi.parse(amountSource),
      note: note,
      workflowStatus: _parseWorkflow(workflowStatus),
      paymentStatus: _parsePayment(paymentStatus),
      vorId: vorId,
      vorNumber: vorNumber,
      excelPath: excelPath,
      createdAt: createdAt,
      updatedAt: updatedAt,
      createdBy: createdBy,
    );
  }

  static ContractActWorkflowStatus _parseWorkflow(String raw) {
    return ContractActWorkflowStatus.values.firstWhere(
      (e) => e.apiValue == raw,
      orElse: () => ContractActWorkflowStatus.pendingApproval,
    );
  }

  static ContractActPaymentStatus _parsePayment(String raw) {
    return ContractActPaymentStatus.values.firstWhere(
      (e) => e.apiValue == raw,
      orElse: () => ContractActPaymentStatus.unpaid,
    );
  }
}

/// Значение колонки `workflow_status` в API.
extension ContractActWorkflowStatusApi on ContractActWorkflowStatus {
  /// Строка для Supabase.
  String get apiValue => switch (this) {
        ContractActWorkflowStatus.pendingApproval => 'pending_approval',
        ContractActWorkflowStatus.approved => 'approved',
        ContractActWorkflowStatus.signed => 'signed',
      };
}

/// Значение колонки `payment_status` в API.
extension ContractActPaymentStatusApi on ContractActPaymentStatus {
  /// Строка для Supabase.
  String get apiValue => switch (this) {
        ContractActPaymentStatus.paid => 'paid',
        ContractActPaymentStatus.partial => 'partial',
        ContractActPaymentStatus.unpaid => 'unpaid',
      };
}
