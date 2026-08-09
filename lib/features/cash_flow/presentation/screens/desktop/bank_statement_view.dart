import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/core/widgets/app_snackbar.dart';
import 'package:projectgt/core/widgets/desktop_dialog_content.dart';
import 'package:projectgt/features/cash_flow/presentation/state/cash_flow_state.dart';
import 'package:projectgt/features/company/presentation/providers/company_providers.dart';
import 'package:projectgt/core/widgets/gt_buttons.dart';
import 'package:projectgt/features/cash_flow/presentation/widgets/bank_statement_settings_dialog.dart';
import 'package:projectgt/features/cash_flow/presentation/widgets/bank_statement_table.dart';
import 'package:projectgt/features/cash_flow/presentation/widgets/cash_flow_form_dialog.dart';
import 'package:projectgt/features/contractors/presentation/state/contractor_state.dart';
import 'package:projectgt/features/settlements/presentation/state/settlement_state.dart';

/// Экран банковской выписки.
///
/// Позволяет просматривать и обрабатывать загруженные банковские выписки.
class BankStatementView extends ConsumerStatefulWidget {
  /// Создаёт экран банковской выписки.
  const BankStatementView({super.key});

  @override
  ConsumerState<BankStatementView> createState() => _BankStatementViewState();
}

class _BankStatementViewState extends ConsumerState<BankStatementView> {
  String? _lastMatchedAccountId;
  int _lastMatchedEntriesCount = -1;

  Future<void> _refreshMatchesIfNeeded() async {
    final state = ref.read(cashFlowProvider);
    final accountId = state.selectedBankAccountId;
    final entriesCount = state.bankStatementEntries.length;

    if (accountId == null || entriesCount == 0) {
      _lastMatchedAccountId = accountId;
      _lastMatchedEntriesCount = entriesCount;
      return;
    }

    if (_lastMatchedAccountId == accountId &&
        _lastMatchedEntriesCount == entriesCount &&
        state.bankStatementMatches.isNotEmpty) {
      return;
    }

    final contractors = ref.read(contractorNotifierProvider).contractors;
    final contracts = ref.read(contractProvider).contracts;

    await ref.read(cashFlowProvider.notifier).computeBankStatementMatches(
          contractors: contractors,
          contracts: contracts,
        );

    _lastMatchedAccountId = accountId;
    _lastMatchedEntriesCount = entriesCount;
  }

  Future<void> _batchProcessReady() async {
    final companyId = ref.read(activeCompanyIdProvider);
    if (companyId == null) return;

    final readyCount = ref.read(cashFlowProvider).autoProcessableBankStatementCount;
    if (readyCount == 0) {
      AppSnackBar.show(
        context: context,
        message: 'Нет строк готовых к автоматической обработке',
        kind: AppSnackBarKind.error,
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Обработать готовые строки?'),
        content: Text(
          'Будет автоматически перенесено $readyCount операций с полным сопоставлением '
          '(контрагент, статья, договор). Остальные строки останутся для ручной проверки.',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Обработать'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      final result = await ref
          .read(cashFlowProvider.notifier)
          .batchProcessReadyBankStatementEntries(companyId: companyId);

      await ref.read(settlementListProvider.notifier).load(quiet: true);

      if (!mounted) return;

      _lastMatchedEntriesCount = -1;
      await _refreshMatchesIfNeeded();

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(24),
          child: DesktopDialogContent(
            title: 'Пакетная обработка',
            footer: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                GTPrimaryButton(
                  text: 'Понятно',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Успешно обработано: ${result.processed}'),
                if (result.failedCount > 0) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Ошибки: ${result.failedCount}',
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(
          context: context,
          message: e.toString(),
          kind: AppSnackBarKind.error,
          persistent: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(cashFlowProvider);
    final bankAccountsAsync = ref.watch(companyBankAccountsProvider);

  ref.listen(cashFlowProvider, (previous, next) {
      if (previous?.bankStatementEntries.length !=
              next.bankStatementEntries.length ||
          previous?.selectedBankAccountId != next.selectedBankAccountId) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _refreshMatchesIfNeeded();
        });
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshMatchesIfNeeded();
    });

    return bankAccountsAsync.when(
      data: (accounts) {
        if (accounts.isEmpty) {
          return const Center(child: Text('Нет доступных счетов'));
        }

        final selectedAccount = accounts.firstWhere(
          (a) => a.id == state.selectedBankAccountId,
          orElse: () {
            return accounts.firstWhere(
              (a) => a.isPrimary,
              orElse: () => accounts.first,
            );
          },
        );

        final readyCount = state.autoProcessableBankStatementCount;

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      selectedAccount.isPrimary
                          ? CupertinoIcons.star_fill
                          : CupertinoIcons.doc_text,
                      size: 32,
                      color: selectedAccount.isPrimary
                          ? Colors.orange
                          : theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selectedAccount.bankName,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Счет № ${selectedAccount.accountNumber}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.textTheme.bodySmall?.color,
                            fontFamily: 'monospace',
                          ),
                        ),
                        if (state.bankStatementEntries.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Готово к автообработке: $readyCount из ${state.bankStatementEntries.length}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: readyCount > 0
                                  ? Colors.green.shade700
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => const Dialog(
                          backgroundColor: Colors.transparent,
                          child: BankStatementSettingsDialog(),
                        ),
                      );
                    },
                    icon: const Icon(CupertinoIcons.settings),
                    tooltip: 'Настройки',
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  if (readyCount > 0)
                    GTSecondaryButton(
                      text: 'Обработать готовые ($readyCount)',
                      icon: CupertinoIcons.bolt_fill,
                      onPressed: _batchProcessReady,
                    ),
                  if (readyCount > 0) const SizedBox(width: 8),
                  GTPrimaryButton(
                    text: 'Загрузить выписку',
                    icon: CupertinoIcons.cloud_upload,
                    onPressed: () async {
                      try {
                        final company = ref.read(companyProfileProvider).value;
                        final stats = await ref
                            .read(cashFlowProvider.notifier)
                            .pickAndParseBankStatement(
                              account: selectedAccount,
                              targetInn: company?.inn,
                            );

                        if (stats == null) return;

                        _lastMatchedEntriesCount = -1;

                        if (context.mounted) {
                          if (stats.total == 0) {
                            AppSnackBar.show(
                              context: context,
                              message:
                                  'В файле не найдено данных для импорта',
                              kind: AppSnackBarKind.error,
                              persistent: true,
                            );
                          } else {
                            showDialog(
                              context: context,
                              builder: (context) => Dialog(
                                backgroundColor: Colors.transparent,
                                insetPadding: const EdgeInsets.all(24),
                                child: DesktopDialogContent(
                                  title: 'Результаты импорта',
                                  footer: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      GTPrimaryButton(
                                        text: 'Понятно',
                                        onPressed: () =>
                                            Navigator.of(context).pop(),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildResultRow(
                                        context,
                                        'Всего записей в файле:',
                                        '${stats.total}',
                                        CupertinoIcons.doc_text,
                                      ),
                                      const SizedBox(height: 16),
                                      _buildResultRow(
                                        context,
                                        'Добавлено новых:',
                                        '${stats.added}',
                                        CupertinoIcons.plus_circle,
                                        valueColor: Colors.green,
                                      ),
                                      const SizedBox(height: 16),
                                      _buildResultRow(
                                        context,
                                        'Пропущено (дубликаты):',
                                        '${stats.skipped}',
                                        CupertinoIcons.doc_on_doc,
                                        valueColor:
                                            theme.colorScheme.secondary,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }
                        }
                      } catch (e) {
                        if (context.mounted) {
                          AppSnackBar.show(
                            context: context,
                            message: e.toString(),
                            kind: AppSnackBarKind.error,
                            persistent: true,
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: BankStatementTable(
                  entries: state.filteredBankStatementEntries,
                  matchResults: state.bankStatementMatches,
                  onEntryTap: (entry) {
                    showDialog(
                      context: context,
                      builder: (context) => Dialog(
                        backgroundColor: Colors.transparent,
                        child: CashFlowFormDialog(initialEntry: entry),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CupertinoActivityIndicator()),
      error: (e, s) => Center(child: Text('Ошибка: $e')),
    );
  }

  Widget _buildResultRow(
    BuildContext context,
    String label,
    String value,
    IconData icon, {
    Color? valueColor,
  }) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: valueColor ?? theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
