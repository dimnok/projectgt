import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/widgets/app_snackbar.dart';
import 'package:projectgt/core/widgets/desktop_dialog_content.dart';
import 'package:projectgt/features/cash_flow/presentation/state/cash_flow_state.dart';
import 'package:projectgt/features/company/presentation/providers/company_providers.dart';
import 'package:projectgt/core/widgets/gt_buttons.dart';
import 'package:projectgt/features/cash_flow/presentation/widgets/bank_statement_settings_dialog.dart';
import 'package:projectgt/features/cash_flow/presentation/widgets/bank_statement_table.dart';
import 'package:projectgt/features/cash_flow/presentation/widgets/cash_flow_form_dialog.dart';

/// Экран банковской выписки.
///
/// Позволяет просматривать и обрабатывать загруженные банковские выписки.
class BankStatementView extends ConsumerWidget {
  /// Создаёт экран банковской выписки.
  const BankStatementView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(cashFlowProvider);
    final bankAccountsAsync = ref.watch(companyBankAccountsProvider);

    return bankAccountsAsync.when(
      data: (accounts) {
        // Проверяем пустоту списка ПЕРЕД попыткой получить элемент
        if (accounts.isEmpty) {
          return const Center(child: Text('Нет доступных счетов'));
        }

        // Теперь безопасно выбираем счет
        final selectedAccount = accounts.firstWhere(
          (a) => a.id == state.selectedBankAccountId,
          orElse: () {
            // Сначала пытаемся найти основной счет
            return accounts.firstWhere(
              (a) => a.isPrimary,
              orElse: () {
                // Если основного нет, берем первый (список гарантированно не пустой)
                return accounts.first;
              },
            );
          },
        );

        return Column(
          children: [
            // Заголовок и информация о счете
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
                    tooltip: 'Настройки парсинга',
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
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

                        if (context.mounted) {
                          if (stats.total == 0) {
                            AppSnackBar.show(
                              context: context,
                              message: 'В файле не найдено данных для импорта',
                              kind: AppSnackBarKind.error,
                              persistent: true,
                            );
                          } else {
                            // Показываем модальное окно с результатами через системный виджет проекта
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
                                        valueColor: theme.colorScheme.secondary,
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

            // Контент
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: BankStatementTable(
                  entries: state.bankStatementEntries,
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
