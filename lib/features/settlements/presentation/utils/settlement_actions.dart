import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/features/roles/presentation/widgets/permission_guard.dart';
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
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Удалить счёт?'),
      content: Text(
        'Счёт ${operation.invoiceNumber} будет удалён без возможности восстановления.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Отмена'),
        ),
        PermissionGuard(
          module: 'settlements',
          permission: 'delete',
          child: TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Удалить'),
          ),
        ),
      ],
    ),
  );
  return result == true;
}
