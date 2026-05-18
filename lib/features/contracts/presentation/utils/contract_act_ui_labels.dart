import 'package:flutter/cupertino.dart';
import 'package:projectgt/domain/entities/contract_act_payment_status.dart';
import 'package:projectgt/domain/entities/contract_act_workflow_status.dart';

/// Подпись статуса согласования акта для UI.
String contractActWorkflowStatusLabel(ContractActWorkflowStatus value) {
  return switch (value) {
    ContractActWorkflowStatus.pendingApproval => 'На согласовании',
    ContractActWorkflowStatus.approved => 'Согласован',
    ContractActWorkflowStatus.signed => 'Подписан',
  };
}

/// Подпись статуса оплаты акта для UI.
String contractActPaymentStatusLabel(ContractActPaymentStatus value) {
  return switch (value) {
    ContractActPaymentStatus.paid => 'Оплачен',
    ContractActPaymentStatus.partial => 'Частично оплачен',
    ContractActPaymentStatus.unpaid => 'Не оплачен',
  };
}

/// Иконка строки акта в списке.
IconData contractActRowIcon() => CupertinoIcons.doc_text_fill;
