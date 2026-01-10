import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/core/widgets/app_snackbar.dart';
import 'package:projectgt/features/cash_flow/presentation/widgets/cash_flow_form_dialog.dart';
import 'package:projectgt/features/cash_flow/presentation/widgets/cash_flow_transactions_table.dart';
import 'package:projectgt/features/cash_flow/presentation/state/cash_flow_state.dart';

/// Виджет детальной панели модуля Cash Flow.
///
/// Отображает либо сводную таблицу ДДС (если ничего не выбрано),
/// либо детали конкретной выбранной финансовой операции.
class CashFlowDetailsPanel extends ConsumerWidget {
  /// Создаёт панель деталей Cash Flow.
  const CashFlowDetailsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(cashFlowProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Заголовок панели (сводный отчет)
        _buildHeader(
          theme,
          title: 'Движение денежных средств',
          subtitle: 'Сводный отчет по финансовым операциям',
          icon: CupertinoIcons.money_dollar_circle,
        ),
        const Divider(height: 1),
        // Контент с таблицей
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCashFlowTable(theme, state),
                const SizedBox(height: 32),
                Expanded(
                  child: CashFlowTransactionsTable(
                    transactions: state.transactions,
                    onEdit: (t) {
                      showDialog(
                        context: context,
                        builder: (context) => Dialog(
                          backgroundColor: Colors.transparent,
                          insetPadding: const EdgeInsets.all(24),
                          child: CashFlowFormDialog(transaction: t),
                        ),
                      );
                    },
                    onDelete: (t) {
                      showDialog(
                        context: context,
                        builder: (context) => CupertinoAlertDialog(
                          title: const Text('Удаление операции'),
                          content: const Text(
                            'Вы уверены, что хотите удалить эту финансовую операцию? Это действие нельзя отменить.',
                          ),
                          actions: [
                            CupertinoDialogAction(
                              child: const Text('Отмена'),
                              onPressed: () => Navigator.pop(context),
                            ),
                            CupertinoDialogAction(
                              isDestructiveAction: true,
                              onPressed: () async {
                                final messenger = Navigator.of(context);
                                await ref
                                    .read(cashFlowProvider.notifier)
                                    .deleteTransaction(t.id);

                                if (context.mounted) {
                                  final state = ref.read(cashFlowProvider);
                                  if (state.status == CashFlowStatus.error) {
                                    AppSnackBar.show(
                                      context: context,
                                      message:
                                          state.errorMessage ??
                                          'Ошибка при удалении',
                                      kind: AppSnackBarKind.error,
                                    );
                                  } else {
                                    AppSnackBar.show(
                                      context: context,
                                      message: 'Операция удалена',
                                      kind: AppSnackBarKind.success,
                                    );
                                  }
                                  messenger.pop();
                                }
                              },
                              child: const Text('Удалить'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Строит заголовок панели.
  Widget _buildHeader(
    ThemeData theme, {
    required String title,
    required String subtitle,
    required IconData icon,
    Widget? trailing,
  }) {
    return Padding(
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
            child: Icon(icon, size: 32, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  /// Строит заголовок раздела.
  Widget _buildSectionTitle(String title, ThemeData theme) {
    return Text(
      title.toUpperCase(),
      style: theme.textTheme.labelMedium?.copyWith(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
    );
  }

  /// Строит горизонтально-прокручиваемую таблицу движения денежных средств.
  Widget _buildCashFlowTable(ThemeData theme, CashFlowState state) {
    final analytics = state.yearlyAnalytics;

    if (analytics.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(theme, 'Аналитика по месяцам', state),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(32),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.1),
              ),
            ),
            child: Text(
              'Нет данных для аналитики',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ),
        ],
      );
    }

    final totalIncome = analytics.fold(0.0, (a, b) => a + b.income);
    final totalExpense = analytics.fold(0.0, (a, b) => a + b.expense);

    // Собираем все уникальные названия категорий для детального вида
    final allIncomeCategories =
        analytics.expand((a) => a.categoryIncomes.keys).toSet().toList()
          ..sort();
    final allExpenseCategories =
        analytics.expand((a) => a.categoryExpenses.keys).toSet().toList()
          ..sort();

    const double labelWidth = 160.0;
    const double monthWidth = 120.0;
    const double totalWidth = 130.0;
    const double rowHeight = 36.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(theme, 'Аналитика по месяцам', state),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.1),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Row(
            children: [
              // Левая колонка - Заголовки строк
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCell(
                    'Статья',
                    labelWidth,
                    rowHeight,
                    theme,
                    isHeader: true,
                  ),
                  const Divider(height: 1, thickness: 1),
                  _buildCell(
                    'ПРИХОД',
                    labelWidth,
                    rowHeight,
                    theme,
                    isBold: true,
                  ),
                  if (state.isDetailedAnalytics)
                    for (final cat in allIncomeCategories)
                      _buildCell(
                        '  $cat',
                        labelWidth,
                        rowHeight,
                        theme,
                        isSubRow: true,
                      ),
                  const Divider(height: 1),
                  _buildCell(
                    'РАСХОД',
                    labelWidth,
                    rowHeight,
                    theme,
                    isBold: true,
                  ),
                  if (state.isDetailedAnalytics)
                    for (final cat in allExpenseCategories)
                      _buildCell(
                        '  $cat',
                        labelWidth,
                        rowHeight,
                        theme,
                        isSubRow: true,
                      ),
                  const Divider(height: 1, thickness: 1),
                  _buildCell(
                    'ИТОГО (САЛЬДО)',
                    labelWidth,
                    rowHeight,
                    theme,
                    isBold: true,
                  ),
                  const Divider(height: 1),
                ],
              ),
              _buildVerticalDivider(theme),
              // Центральная часть - Данные по месяцам (прокручиваемая)
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final item in analytics) ...[
                        Column(
                          children: [
                            _buildCell(
                              item.monthYear,
                              monthWidth,
                              rowHeight,
                              theme,
                              isHeader: true,
                            ),
                            const Divider(height: 1, thickness: 1),
                            _buildCell(
                              formatCurrency(item.income),
                              monthWidth,
                              rowHeight,
                              theme,
                              valueColor: item.income > 0 ? Colors.green : null,
                              isBold: true,
                            ),
                            if (state.isDetailedAnalytics)
                              for (final cat in allIncomeCategories)
                                _buildCell(
                                  formatCurrency(
                                    item.categoryIncomes[cat] ?? 0,
                                  ),
                                  monthWidth,
                                  rowHeight,
                                  theme,
                                  isSubRow: true,
                                ),
                            const Divider(height: 1),
                            _buildCell(
                              formatCurrency(item.expense),
                              monthWidth,
                              rowHeight,
                              theme,
                              valueColor: item.expense > 0 ? Colors.red : null,
                              isBold: true,
                            ),
                            if (state.isDetailedAnalytics)
                              for (final cat in allExpenseCategories)
                                _buildCell(
                                  formatCurrency(
                                    item.categoryExpenses[cat] ?? 0,
                                  ),
                                  monthWidth,
                                  rowHeight,
                                  theme,
                                  isSubRow: true,
                                ),
                            const Divider(height: 1, thickness: 1),
                            _buildCell(
                              formatCurrency(item.total),
                              monthWidth,
                              rowHeight,
                              theme,
                              isBold: true,
                              valueColor: item.total >= 0
                                  ? Colors.green
                                  : Colors.red,
                            ),
                            const Divider(height: 1),
                          ],
                        ),
                        _buildVerticalDivider(theme),
                      ],
                    ],
                  ),
                ),
              ),
              // Правая колонка - Итого за год
              Column(
                children: [
                  _buildCell(
                    'Всего за год',
                    totalWidth,
                    rowHeight,
                    theme,
                    isHeader: true,
                  ),
                  const Divider(height: 1, thickness: 1),
                  _buildCell(
                    formatCurrency(totalIncome),
                    totalWidth,
                    rowHeight,
                    theme,
                    isBold: true,
                    valueColor: Colors.green,
                  ),
                  if (state.isDetailedAnalytics)
                    for (final cat in allIncomeCategories)
                      _buildCell(
                        formatCurrency(
                          analytics.fold(
                            0.0,
                            (a, b) => a + (b.categoryIncomes[cat] ?? 0),
                          ),
                        ),
                        totalWidth,
                        rowHeight,
                        theme,
                        isSubRow: true,
                      ),
                  const Divider(height: 1),
                  _buildCell(
                    formatCurrency(totalExpense),
                    totalWidth,
                    rowHeight,
                    theme,
                    isBold: true,
                    valueColor: Colors.red,
                  ),
                  if (state.isDetailedAnalytics)
                    for (final cat in allExpenseCategories)
                      _buildCell(
                        formatCurrency(
                          analytics.fold(
                            0.0,
                            (a, b) => a + (b.categoryExpenses[cat] ?? 0),
                          ),
                        ),
                        totalWidth,
                        rowHeight,
                        theme,
                        isSubRow: true,
                      ),
                  const Divider(height: 1, thickness: 1),
                  _buildCell(
                    formatCurrency(totalIncome - totalExpense),
                    totalWidth,
                    rowHeight,
                    theme,
                    isBold: true,
                    valueColor: (totalIncome - totalExpense) >= 0
                        ? Colors.green
                        : Colors.red,
                  ),
                  const Divider(height: 1),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Заголовок секции аналитики с кнопкой переключения режима.
  Widget _buildSectionHeader(
    ThemeData theme,
    String title,
    CashFlowState state,
  ) {
    return Consumer(
      builder: (context, ref, _) {
        return Row(
          children: [
            _buildSectionTitle(title, theme),
            const Spacer(),
            CupertinoButton(
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 0),
              onPressed: () =>
                  ref.read(cashFlowProvider.notifier).toggleDetailedAnalytics(),
              child: Row(
                children: [
                  Text(
                    state.isDetailedAnalytics ? 'Свернуть' : 'Детально',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    state.isDetailedAnalytics
                        ? CupertinoIcons.chevron_up
                        : CupertinoIcons.chevron_down,
                    size: 14,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  /// Строит ячейку таблицы.
  Widget _buildCell(
    String text,
    double width,
    double height,
    ThemeData theme, {
    bool isHeader = false,
    bool isBold = false,
    bool isSubRow = false,
    Color? valueColor,
  }) {
    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.centerLeft,
      color: isHeader
          ? theme.colorScheme.onSurface.withValues(alpha: 0.03)
          : null,
      child: Text(
        text,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: isHeader || isBold ? FontWeight.bold : FontWeight.normal,
          color:
              valueColor ??
              (isHeader || isSubRow
                  ? theme.colorScheme.onSurface.withValues(
                      alpha: isSubRow ? 0.5 : 0.7,
                    )
                  : null),
          fontSize: isHeader ? 11 : (isSubRow ? 10 : 12),
          fontStyle: isSubRow ? FontStyle.italic : null,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  /// Строит вертикальный разделитель для таблицы.
  Widget _buildVerticalDivider(ThemeData theme) {
    return Container(
      width: 1,
      color: theme.colorScheme.outline.withValues(alpha: 0.1),
    );
  }
}
