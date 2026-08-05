import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/widgets/gt_confirmation_dialog.dart';
import 'package:projectgt/features/settlements/domain/entities/settlement_operation.dart';
import 'package:projectgt/features/settlements/presentation/state/settlement_state.dart';

/// Синхронизирует общий реестр и список по договору после CRUD.
void syncSettlementProviders(WidgetRef ref, {required String contractId}) {
  ref.read(settlementListProvider.notifier).load(quiet: true);
  ref.read(contractSettlementsProvider(contractId).notifier).load(quiet: true);
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
        'Счёт ${operation.invoiceNumber} и все связанные оплаты будут удалены без возможности восстановления.',
    confirmText: 'Удалить',
    cancelText: 'Отмена',
    type: GTConfirmationType.danger,
  );
  return result == true;
}
