import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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

/// Цвет подписи статуса согласования в UI.
Color contractActWorkflowStatusColor(
  ThemeData theme,
  ContractActWorkflowStatus status,
) {
  final dark = theme.brightness == Brightness.dark;
  return switch (status) {
    ContractActWorkflowStatus.signed => theme.colorScheme.primary,
    ContractActWorkflowStatus.approved => dark
        ? const Color(0xFF80D8FF)
        : const Color(0xFF006978),
    ContractActWorkflowStatus.pendingApproval =>
      theme.colorScheme.onSurfaceVariant,
  };
}

/// Цвет подписи статуса оплаты в UI.
Color contractActPaymentStatusColor(
  ThemeData theme,
  ContractActPaymentStatus status,
) {
  final dark = theme.brightness == Brightness.dark;
  return switch (status) {
    ContractActPaymentStatus.paid =>
      dark ? const Color(0xFF69F0AE) : const Color(0xFF1B5E20),
    ContractActPaymentStatus.partial =>
      dark ? const Color(0xFFFFB74D) : const Color(0xFFE65100),
    ContractActPaymentStatus.unpaid =>
      theme.colorScheme.onSurface.withValues(alpha: 0.5),
  };
}
