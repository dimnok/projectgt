import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/widgets/gt_confirmation_dialog.dart';
import 'package:projectgt/features/settlements/domain/entities/settlement_operation.dart';
import 'package:projectgt/features/settlements/presentation/state/settlement_state.dart';

/// Ищет операцию в уже загруженных списках провайдеров.
///
/// Сначала проверяет список по [contractId], затем общий реестр.
SettlementOperation? findSettlementOperationInProviders(
  WidgetRef ref, {
  required String operationId,
  String? contractId,
}) {
  SettlementOperation? fromList(List<SettlementOperation> operations) {
    for (final operation in operations) {
      if (operation.id == operationId) return operation;
    }
    return null;
  }

  if (contractId != null && contractId.isNotEmpty) {
    final fromContract = fromList(
      ref.read(contractSettlementsProvider(contractId)).operations,
    );
    if (fromContract != null) return fromContract;
  }

  return fromList(ref.read(settlementListProvider).operations);
}

/// Синхронизирует общий реестр и список по договору после CRUD.
Future<void> syncSettlementProviders(
  WidgetRef ref, {
  required String contractId,
}) async {
  await Future.wait([
    ref.read(settlementListProvider.notifier).load(quiet: true),
    ref.read(contractSettlementsProvider(contractId).notifier).load(quiet: true),
  ]);
}

/// Диалог подтверждения удаления счёта.
Future<bool> showSettlementDeleteConfirmDialog(
  BuildContext context,
  SettlementOperation operation,
) async {
  final result = await GTConfirmationDialog.show(
    context: context,
    title: 'Удалить счёт?',
    message:
        'Счёт ${operation.invoiceNumber}, все прикреплённые файлы и оплаты будут удалены без возможности восстановления.',
    confirmText: 'Удалить',
    cancelText: 'Отмена',
    type: GTConfirmationType.danger,
  );
  return result == true;
}
