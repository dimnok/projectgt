import 'package:flutter/material.dart';
import 'package:projectgt/domain/entities/contract_act.dart';
import 'package:projectgt/domain/entities/contract_act_payment_status.dart';
import 'package:projectgt/domain/entities/contract_act_workflow_status.dart';
import 'package:projectgt/domain/entities/ks2_act.dart';

/// Подпись статуса акта КС-2 в строке списка (как статус согласования у реестра).
String ks2ActWorkflowStatusLabel(Ks2Status status) {
  return switch (status) {
    Ks2Status.draft => 'Черновик',
    Ks2Status.signed => 'Подписан',
    Ks2Status.paid => 'Оплачен',
  };
}

/// Цвет статуса КС-2 в строке списка.
Color ks2ActWorkflowStatusColor(ThemeData theme, Ks2Status status) {
  final dark = theme.brightness == Brightness.dark;
  return switch (status) {
    Ks2Status.draft => theme.colorScheme.onSurfaceVariant,
    Ks2Status.signed => theme.colorScheme.primary,
    Ks2Status.paid => dark ? const Color(0xFF69F0AE) : const Color(0xFF1B5E20),
  };
}

/// Модель строки реестра для [ContractActRowCard] (только отображение).
ContractAct ks2ActToRegistryRowModel(Ks2Act act) {
  final vor = act.vorNumber?.trim();
  return ContractAct(
    id: act.id,
    companyId: act.companyId,
    contractId: act.contractId,
    title: 'КС-2',
    number: act.number,
    actDate: act.date,
    periodFrom: act.periodFrom,
    periodTo: act.periodTo,
    amount: act.totalAmount,
    vatAmount: 0,
    advanceRetention: 0,
    warrantyRetention: 0,
    otherRetentions: 0,
    totalToPay: act.totalAmount,
    note: vor != null && vor.isNotEmpty ? 'ВОР № $vor' : null,
    workflowStatus: _workflowStatusForKs2(act.status),
    paymentStatus: act.status == Ks2Status.paid
        ? ContractActPaymentStatus.paid
        : ContractActPaymentStatus.unpaid,
  );
}

ContractActWorkflowStatus _workflowStatusForKs2(Ks2Status status) {
  return switch (status) {
    Ks2Status.draft => ContractActWorkflowStatus.pendingApproval,
    Ks2Status.signed => ContractActWorkflowStatus.signed,
    Ks2Status.paid => ContractActWorkflowStatus.approved,
  };
}
