import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/features/contractors/domain/entities/contractor_bank_account.dart';
import 'package:projectgt/features/contractors/presentation/state/contractor_bank_account_state.dart';
import 'package:projectgt/features/roles/presentation/widgets/permission_guard.dart';
import 'package:projectgt/core/widgets/gt_buttons.dart';
import 'contractor_bank_account_form_dialog.dart';
import 'contractor_list_shared.dart';

/// Виджет списка банковских счетов контрагента.
///
/// Отображает все счета, позволяет добавлять, редактировать и удалять их.
/// Автоматически подстраивается под mobile/desktop (диалог добавления).
class ContractorBankAccountsList extends ConsumerWidget {
  /// Идентификатор контрагента.
  final String contractorId;

  /// Создает список банковских счетов.
  const ContractorBankAccountsList({super.key, required this.contractorId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final accountsState = ref.watch(
      contractorBankAccountNotifierProvider(contractorId),
    );

    return ContractorSection(
      title: 'Банковские счета',
      items: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            PermissionGuard(
              module: 'contractors',
              permission: 'update',
              child: GTTextButton(
                icon: CupertinoIcons.plus_circle,
                text: 'Добавить счет',
                onPressed: () => _showBankAccountDialog(context, ref),
              ),
            ),
          ],
        ),
        if (accountsState.status == BankAccountStatus.loading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          )
        else if (accountsState.accounts.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Счета не добавлены',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          )
        else
          ...accountsState.accounts.map(
            (account) => _buildBankAccountRow(context, ref, account, theme),
          ),
      ],
    );
  }

  Widget _buildBankAccountRow(
    BuildContext context,
    WidgetRef ref,
    ContractorBankAccount account,
    ThemeData theme,
  ) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                account.isPrimary
                    ? CupertinoIcons.star_fill
                    : CupertinoIcons.creditcard,
                size: 16,
                color: account.isPrimary
                    ? Colors.amber
                    : theme.colorScheme.primary.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                account.bankName,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (account.bankCity != null &&
                                  account.bankCity!.isNotEmpty)
                                Text(
                                  account.bankCity!,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.5),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (account.bik != null)
                          Text(
                            'БИК: ${account.bik}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.5,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    SelectableText(
                      'Р/С: ${account.accountNumber}',
                      style: theme.textTheme.bodyMedium,
                    ),
                    if (account.corrAccount != null)
                      SelectableText(
                        'К/С: ${account.corrAccount}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              PermissionGuard(
                module: 'contractors',
                permission: 'update',
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => _showBankAccountDialog(
                        context,
                        ref,
                        account: account,
                      ),
                      child: const Icon(
                        CupertinoIcons.pencil,
                        size: 18,
                        color: Colors.amber,
                      ),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () =>
                          _handleDeleteAccount(context, ref, account),
                      child: Icon(
                        CupertinoIcons.trash,
                        size: 18,
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Divider(
          height: 1,
          thickness: 0.5,
          indent: 40,
          endIndent: 12,
          color: theme.colorScheme.outline.withValues(alpha: 0.08),
        ),
      ],
    );
  }

  Future<void> _handleDeleteAccount(
    BuildContext context,
    WidgetRef ref,
    ContractorBankAccount account,
  ) async {
    final confirmed = await ContractorDialogs.showConfirmDelete(
      context: context,
      title: 'Удалить счет?',
      message:
          'Вы уверены, что хотите удалить счет в банке "${account.bankName}"?',
    );

    if (confirmed == true) {
      await ref
          .read(contractorBankAccountNotifierProvider(contractorId).notifier)
          .deleteAccount(account.id);
    }
  }

  Future<void> _showBankAccountDialog(
    BuildContext context,
    WidgetRef ref, {
    ContractorBankAccount? account,
  }) async {
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    if (isDesktop) {
      await showDialog(
        context: context,
        barrierColor: Colors.black.withValues(alpha: 0.4),
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          child: ContractorBankAccountFormDialog(
            contractorId: contractorId,
            account: account,
          ),
        ),
      );
    } else {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (context) => ContractorBankAccountFormDialog(
          contractorId: contractorId,
          account: account,
        ),
      );
    }
  }
}
