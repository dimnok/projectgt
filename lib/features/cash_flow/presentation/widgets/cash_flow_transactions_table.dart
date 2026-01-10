import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/core/widgets/gt_section_title.dart';
import 'package:projectgt/core/widgets/gt_context_menu.dart';
import 'package:projectgt/features/cash_flow/domain/entities/cash_flow_transaction.dart';
import 'package:projectgt/features/roles/application/permission_service.dart';
import 'package:projectgt/features/cash_flow/presentation/state/cash_flow_state.dart';

/// Виджет таблицы последних добавленных операций Cash Flow.
///
/// Отображает список транзакций в компактном табличном виде для правой панели.
class CashFlowTransactionsTable extends ConsumerStatefulWidget {
  /// Список транзакций для отображения.
  final List<CashFlowTransaction> transactions;

  /// Обратный вызов для редактирования.
  final void Function(CashFlowTransaction) onEdit;

  /// Обратный вызов для удаления.
  final void Function(CashFlowTransaction) onDelete;

  /// Создаёт таблицу транзакций.
  const CashFlowTransactionsTable({
    super.key,
    required this.transactions,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  ConsumerState<CashFlowTransactionsTable> createState() =>
      _CashFlowTransactionsTableState();
}

class _CashFlowTransactionsTableState
    extends ConsumerState<CashFlowTransactionsTable> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(cashFlowProvider.notifier).loadNextPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(cashFlowProvider);
    final hasTransactions = widget.transactions.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GTSectionTitle(title: 'Операции (${widget.transactions.length})'),
        const SizedBox(height: 16),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.1),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                // Заголовок таблицы - всегда показываем
                _buildHeader(theme),
                const Divider(height: 1, thickness: 1),
                // Контент таблицы
                Expanded(
                  child:
                      !hasTransactions && state.status != CashFlowStatus.loading
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Text(
                              'Операции отсутствуют',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.hintColor,
                              ),
                            ),
                          ),
                        )
                      : Scrollbar(
                          controller: _scrollController,
                          child: ListView.separated(
                            controller: _scrollController,
                            itemCount:
                                widget.transactions.length +
                                (state.hasMore ? 1 : 0),
                            separatorBuilder: (context, index) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              if (index == widget.transactions.length) {
                                return const Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Center(
                                    child: CupertinoActivityIndicator(),
                                  ),
                                );
                              }
                              return _TransactionRow(
                                transaction: widget.transactions[index],
                                onEdit: widget.onEdit,
                                onDelete: widget.onDelete,
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Строит заголовок таблицы.
  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: theme.colorScheme.onSurface.withValues(alpha: 0.03),
      child: Row(
        children: [
          const SizedBox(width: 24), // Место под иконку
          const SizedBox(width: 14),
          Expanded(flex: 2, child: _buildHeaderText('Дата', theme)),
          Expanded(flex: 3, child: _buildHeaderText('Статья', theme)),
          Expanded(flex: 3, child: _buildHeaderText('Объект', theme)),
          Expanded(flex: 3, child: _buildHeaderText('Контрагент', theme)),
          Expanded(flex: 2, child: _buildHeaderText('Договор', theme)),
          Expanded(
            flex: 2,
            child: _buildHeaderText('Сумма', theme, align: TextAlign.right),
          ),
        ],
      ),
    );
  }

  /// Строит текст заголовка колонки.
  Widget _buildHeaderText(
    String text,
    ThemeData theme, {
    TextAlign align = TextAlign.left,
  }) {
    return Text(
      text,
      textAlign: align,
      style: theme.textTheme.labelSmall?.copyWith(
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
        fontSize: 11,
      ),
    );
  }
}

/// Строка транзакции с состоянием подсветки при открытом меню.
class _TransactionRow extends ConsumerStatefulWidget {
  final CashFlowTransaction transaction;
  final void Function(CashFlowTransaction) onEdit;
  final void Function(CashFlowTransaction) onDelete;

  const _TransactionRow({
    required this.transaction,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  ConsumerState<_TransactionRow> createState() => _TransactionRowState();
}

class _TransactionRowState extends ConsumerState<_TransactionRow> {
  bool _isMenuOpen = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isIncome = widget.transaction.type == CashFlowType.income;

    return InkWell(
      onTapDown: (details) {
        setState(() => _isMenuOpen = true);

        final permissionService = ref.read(permissionServiceProvider);
        final canUpdate = permissionService.can('cash_flow', 'update');
        final canDelete = permissionService.can('cash_flow', 'delete');

        GTContextMenu.show(
          context: context,
          tapPosition: details.globalPosition,
          onDismiss: () => setState(() => _isMenuOpen = false),
          items: [
            if (canUpdate)
              GTContextMenuItem(
                icon: CupertinoIcons.pencil,
                label: 'Редактировать',
                onTap: () => widget.onEdit(widget.transaction),
              ),
            if (canUpdate && canDelete)
              const Divider(height: 4, indent: 8, endIndent: 8),
            if (canDelete)
              GTContextMenuItem(
                icon: CupertinoIcons.trash,
                label: 'Удалить',
                isDestructive: true,
                onTap: () => widget.onDelete(widget.transaction),
              ),
          ],
        );
      },
      child: Container(
        color: _isMenuOpen
            ? theme.colorScheme.primary.withValues(alpha: 0.08)
            : null,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(
          children: [
            // Иконка типа
            Icon(
              isIncome
                  ? CupertinoIcons.plus_circle
                  : CupertinoIcons.minus_circle,
              size: 18,
              color: isIncome ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 14),
            // Дата
            Expanded(
              flex: 2,
              child: Text(
                formatRuDate(widget.transaction.date),
                style: theme.textTheme.bodySmall?.copyWith(fontSize: 12),
              ),
            ),
            // Статья
            Expanded(
              flex: 3,
              child: Text(
                widget.transaction.categoryName ?? '—',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Объект
            Expanded(
              flex: 3,
              child: Text(
                widget.transaction.objectName ?? '—',
                style: theme.textTheme.bodySmall?.copyWith(fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Контрагент
            Expanded(
              flex: 3,
              child: Text(
                widget.transaction.contractorName ?? '—',
                style: theme.textTheme.bodySmall?.copyWith(fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Договор
            Expanded(
              flex: 2,
              child: Text(
                widget.transaction.contractNumber ?? '—',
                style: theme.textTheme.bodySmall?.copyWith(fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Сумма
            Expanded(
              flex: 2,
              child: Text(
                formatCurrency(widget.transaction.amount),
                textAlign: TextAlign.right,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isIncome ? Colors.green : Colors.red,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
