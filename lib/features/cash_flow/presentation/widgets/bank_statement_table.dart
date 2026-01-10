import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/core/widgets/gt_section_title.dart';
import 'package:projectgt/core/widgets/gt_context_menu.dart';
import 'package:projectgt/features/cash_flow/domain/entities/bank_statement_entry.dart';
import 'package:projectgt/features/cash_flow/domain/entities/cash_flow_transaction.dart';
import 'package:projectgt/features/roles/application/permission_service.dart';
import 'package:projectgt/features/cash_flow/presentation/state/cash_flow_state.dart';

/// Виджет таблицы для отображения записей банковской выписки.
///
/// Предназначен для предпросмотра данных, распарсенных из файла,
/// перед их окончательным импортом в систему.
class BankStatementTable extends ConsumerStatefulWidget {
  /// Список записей банковской выписки для отображения.
  final List<BankStatementEntry> entries;

  /// Обратный вызов при нажатии на запись.
  final void Function(BankStatementEntry) onEntryTap;

  /// Создаёт таблицу записей банковской выписки.
  const BankStatementTable({
    super.key,
    required this.entries,
    required this.onEntryTap,
  });

  @override
  ConsumerState<BankStatementTable> createState() => _BankStatementTableState();
}

class _BankStatementTableState extends ConsumerState<BankStatementTable> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasEntries = widget.entries.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GTSectionTitle(title: 'Записи выписки (${widget.entries.length})'),
        const SizedBox(height: 16),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.1),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              clipBehavior: Clip.antiAlias,
              child: Container(
                color: theme.colorScheme.surface,
                child: Column(
                  children: [
                    // Заголовок таблицы
                    _buildHeader(theme),
                    const Divider(height: 1, thickness: 1),
                    // Контент таблицы
                    Expanded(
                      child: !hasEntries
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32.0),
                                child: Text(
                                  'Список записей выписки пуст',
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
                                itemCount: widget.entries.length,
                                separatorBuilder: (context, index) =>
                                    const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final entry = widget.entries[index];
                                  final isDuplicate = ref
                                      .watch(cashFlowProvider)
                                      .transactions
                                      .any(
                                        (t) =>
                                            t.operationHash != null &&
                                            t.operationHash ==
                                                entry.operationHash,
                                      );

                                  return _BankStatementEntryRow(
                                    entry: entry,
                                    isDuplicate: isDuplicate,
                                    onTap: () => widget.onEntryTap(entry),
                                  );
                                },
                              ),
                            ),
                    ),
                  ],
                ),
              ),
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
          Expanded(flex: 1, child: _buildHeaderText('Дата', theme)),
          Expanded(
            flex: 2,
            child: _buildHeaderText('Сумма', theme, align: TextAlign.right),
          ),
          const SizedBox(width: 16), // Отступ между суммой и контрагентом
          Expanded(flex: 4, child: _buildHeaderText('Контрагент', theme)),
          Expanded(flex: 2, child: _buildHeaderText('ИНН', theme)),
          Expanded(
            flex: 8,
            child: _buildHeaderText('Назначение платежа', theme),
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

/// Строка записи банковской выписки с состоянием подсветки при открытом меню.
class _BankStatementEntryRow extends ConsumerStatefulWidget {
  final BankStatementEntry entry;
  final bool isDuplicate;
  final VoidCallback onTap;

  const _BankStatementEntryRow({
    required this.entry,
    required this.isDuplicate,
    required this.onTap,
  });

  @override
  ConsumerState<_BankStatementEntryRow> createState() =>
      _BankStatementEntryRowState();
}

class _BankStatementEntryRowState
    extends ConsumerState<_BankStatementEntryRow> {
  bool _isMenuOpen = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isIncome = widget.entry.type == CashFlowType.income;
    final isAlreadyImported = widget.entry.isImported || widget.isDuplicate;

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
                icon: CupertinoIcons.arrow_right_arrow_left,
                label: 'Обработать',
                enabled: !isAlreadyImported,
                onTap: widget.onTap,
              ),
            if (canUpdate) const Divider(height: 4, indent: 8, endIndent: 8),
            GTContextMenuItem(
              icon: CupertinoIcons.info,
              label: 'Детали',
              onTap: () {
                // Вызов деталей
              },
            ),
            if (canDelete) ...[
              const Divider(height: 4, indent: 8, endIndent: 8),
              GTContextMenuItem(
                icon: CupertinoIcons.trash,
                label: 'Удалить',
                isDestructive: true,
                onTap: () {
                  // Удаление
                },
              ),
            ],
          ],
        );
      },
      child: Opacity(
        opacity: isAlreadyImported ? 0.5 : 1.0,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          color: _isMenuOpen
              ? theme.colorScheme.primary.withValues(alpha: 0.08)
              : widget.isDuplicate
              ? theme.colorScheme.error.withValues(alpha: 0.05)
              : null,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Иконка типа
              widget.isDuplicate
                  ? const Tooltip(
                      message: 'Эта операция уже есть в системе (дубликат)',
                      child: Icon(
                        CupertinoIcons.exclamationmark_triangle_fill,
                        size: 18,
                        color: Colors.orange,
                      ),
                    )
                  : Icon(
                      isIncome
                          ? CupertinoIcons.plus_circle
                          : CupertinoIcons.minus_circle,
                      size: 18,
                      color: isIncome ? Colors.green : Colors.red,
                    ),
              const SizedBox(width: 14),
              // Дата
              Expanded(
                flex: 1,
                child: Text(
                  formatRuDate(widget.entry.date),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ),
              // Сумма
              Expanded(
                flex: 2,
                child: Text(
                  formatCurrency(widget.entry.amount),
                  textAlign: TextAlign.right,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isIncome ? Colors.green : Colors.red,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(width: 16), // Отступ между суммой и контрагентом
              // Контрагент
              Expanded(
                flex: 4,
                child: Text(
                  widget.entry.contractorName ?? '—',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ),
              // ИНН
              Expanded(
                flex: 2,
                child: Text(
                  widget.entry.contractorInn ?? '—',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ),
              // Назначение платежа
              Expanded(
                flex: 8,
                child: Text(
                  widget.entry.comment ?? '—',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
