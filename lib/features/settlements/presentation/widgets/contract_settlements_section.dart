import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/core/widgets/gt_buttons.dart';
import 'package:projectgt/domain/entities/contract.dart';
import 'package:projectgt/features/roles/application/permission_service.dart';
import 'package:projectgt/features/roles/presentation/widgets/permission_guard.dart';
import 'package:projectgt/features/settlements/domain/entities/settlement_operation.dart';
import 'package:projectgt/features/settlements/presentation/state/settlement_state.dart';
import 'package:projectgt/features/settlements/presentation/widgets/settlement_form_dialog.dart';
import 'package:projectgt/features/settlements/presentation/widgets/settlements_operations_table.dart';
import 'package:projectgt/core/widgets/app_snackbar.dart';

/// Вкладка «Финансы» в карточке договора — таблица операций.
class ContractSettlementsSection extends ConsumerWidget {
  /// Договор.
  final Contract contract;

  /// Создаёт секцию.
  const ContractSettlementsSection({
    super.key,
    required this.contract,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final state = ref.watch(contractSettlementsProvider(contract.id));
    final canCreate =
        ref.watch(permissionServiceProvider).can('settlements', 'create');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _MiniStat(
                    label: 'Сумма счетов',
                    value: formatCurrency(state.totalAmount),
                  ),
                ],
              ),
            ),
            if (canCreate)
              GTPrimaryButton(
                text: 'Новый счёт',
                onPressed: () => SettlementFormDialog.show(
                  context,
                  presetContract: contract,
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (state.isLoading && state.operations.isEmpty)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CupertinoActivityIndicator()),
          )
        else if (state.error != null && state.operations.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              state.error!,
              style: theme.textTheme.bodyMedium?.copyWith(color: scheme.error),
            ),
          )
        else if (state.operations.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Text(
                'По этому договору пока нет счетов',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.55),
                ),
              ),
            ),
          )
        else
          SizedBox(
            height: (state.operations.length * 52.0 + 96)
                .clamp(200.0, 560.0)
                .toDouble(),
            child: SettlementsOperationsTable(
              operations: state.operations,
              compact: true,
              onRowTap: (op) => SettlementFormDialog.show(
                context,
                operation: op,
                presetContract: contract,
              ),
              onDelete: (op) => _delete(context, ref, op),
            ),
          ),
      ],
    );
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    SettlementOperation op,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить счёт?'),
        content: Text('Счёт ${op.invoiceNumber} будет удалён.'),
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
    if (ok != true || !context.mounted) return;
    final success = await ref
        .read(contractSettlementsProvider(contract.id).notifier)
        .delete(op.id);
    if (!context.mounted) return;
    ref.read(settlementListProvider.notifier).load(quiet: true);
    AppSnackBar.show(
      context: context,
      message: success ? 'Счёт удалён' : 'Не удалось удалить',
      kind: success ? AppSnackBarKind.success : AppSnackBarKind.error,
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;

  const _MiniStat({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: scheme.outline.withValues(alpha: 0.35),
        ),
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.55),
            ),
          ),
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
