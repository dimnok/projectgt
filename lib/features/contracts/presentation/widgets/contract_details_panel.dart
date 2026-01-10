import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/domain/entities/contract.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/core/utils/snackbar_utils.dart';
import 'package:projectgt/features/roles/presentation/widgets/permission_guard.dart';
import 'package:projectgt/features/contracts/presentation/widgets/contract_costs_info.dart';
import 'package:projectgt/features/contracts/presentation/widgets/contract_files_section.dart';
import 'package:projectgt/presentation/widgets/app_badge.dart';
import 'contract_list_shared.dart';

/// Панель детальной информации о договоре.
///
/// Отображает все ключевые параметры договора: объект, статус, даты, финансовые условия,
/// а также разделы с файлами, дополнительными соглашениями и актами КС-2.
/// Включает визуализацию Cash Flow по договору.
class ContractDetailsPanel extends ConsumerWidget {
  /// Сущность договора, данные которой необходимо отобразить.
  final Contract contract;

  /// Функция обратного вызова для перехода к форме редактирования договора.
  final VoidCallback onEdit;

  /// Создает экземпляр панели деталей договора.
  const ContractDetailsPanel({
    super.key,
    required this.contract,
    required this.onEdit,
  });

  Future<void> _handleDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (BuildContext context) => CupertinoAlertDialog(
        title: const Text('Удалить договор?'),
        content: Text(
          'Вы уверены, что хотите удалить договор № ${contract.number}?',
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(contractProvider.notifier).deleteContract(contract.id);
        if (!context.mounted) return;
        SnackBarUtils.showSuccess(context, 'Договор удален');
      } catch (e) {
        if (!context.mounted) return;
        SnackBarUtils.showError(context, 'Ошибка при удалении: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
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
                        CupertinoIcons.doc_text,
                        size: 32,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Договор № ${contract.number}',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            contract.contractorName ?? 'Без контрагента',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.textTheme.bodySmall?.color,
                            ),
                          ),
                          const SizedBox(height: 8),
                          AppBadge(
                            text: ContractStatusHelper.getStatusInfo(
                              contract.status,
                              theme,
                            ).$1,
                            color: ContractStatusHelper.getStatusInfo(
                              contract.status,
                              theme,
                            ).$2,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  PermissionGuard(
                    module: 'contracts',
                    permission: 'update',
                    child: CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: onEdit,
                      child: const Icon(
                        CupertinoIcons.pencil,
                        size: 22,
                        color: Colors.amber,
                      ),
                    ),
                  ),
                  PermissionGuard(
                    module: 'contracts',
                    permission: 'delete',
                    child: CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => _handleDelete(context, ref),
                      child: Icon(
                        CupertinoIcons.trash,
                        size: 22,
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // Content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCashFlowSection(theme),
                const SizedBox(height: 24),
                _buildSectionTitle('Основная информация', theme),
                const SizedBox(height: 8),
                _buildDataRow(
                  'Объект',
                  contract.objectName ?? '',
                  theme,
                  icon: CupertinoIcons.building_2_fill,
                ),
                _buildDataRow(
                  'Статус',
                  ContractStatusHelper.getStatusInfo(contract.status, theme).$1,
                  theme,
                  icon: CupertinoIcons.info_circle,
                ),
                _buildDataRow(
                  'Дата начала',
                  formatRuDate(contract.date),
                  theme,
                  icon: CupertinoIcons.calendar,
                ),
                _buildDataRow(
                  'Дата окончания',
                  contract.endDate != null
                      ? formatRuDate(contract.endDate!)
                      : '',
                  theme,
                  icon: CupertinoIcons.calendar_badge_minus,
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('Финансовые условия', theme),
                const SizedBox(height: 8),
                _buildDataRow(
                  'Сумма договора',
                  formatCurrency(contract.amount),
                  theme,
                  icon: CupertinoIcons.money_rubl,
                ),
                _buildDataRow(
                  contract.isVatIncluded
                      ? 'НДС ${contract.vatRate.toStringAsFixed(0)}% (вкл.)'
                      : 'НДС ${contract.vatRate.toStringAsFixed(0)}% (сверху)',
                  formatCurrency(contract.vatAmount),
                  theme,
                  icon: CupertinoIcons.percent,
                ),
                _buildDataRow(
                  'Аванс',
                  formatCurrency(contract.advanceAmount),
                  theme,
                  icon: CupertinoIcons.money_rubl_circle,
                ),
                _buildDataRow(
                  contract.warrantyPeriodMonths > 0
                      ? 'Гарантийные ${contract.warrantyRetentionRate.toStringAsFixed(0)}% (${contract.warrantyPeriodMonths} мес.)'
                      : 'Гарантийные',
                  formatCurrency(contract.warrantyRetentionAmount),
                  theme,
                  icon: CupertinoIcons.shield,
                ),
                _buildDataRow(
                  contract.generalContractorFeeRate > 0
                      ? 'Генподрядные ${contract.generalContractorFeeRate.toStringAsFixed(0)}%'
                      : 'Генподрядные',
                  formatCurrency(contract.generalContractorFeeAmount),
                  theme,
                  icon: CupertinoIcons.briefcase,
                ),
                const SizedBox(height: 24),
                ContractFilesSection(contract: contract),
                const SizedBox(height: 24),
                _buildAddendumsSection(theme),
                const SizedBox(height: 24),
                _buildActsSection(theme),
                const SizedBox(height: 24),
                _buildSectionTitle('Выполнение и остатки', theme),
                const SizedBox(height: 16),
                ContractCostsInfo(
                  contractId: contract.id,
                  objectId: contract.objectId,
                  contractAmount: contract.amount,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCashFlowSection(ThemeData theme) {
    final months = [
      'Янв 2024',
      'Фев 2024',
      'Мар 2024',
      'Апр 2024',
      'Май 2024',
      'Июн 2024',
      'Июл 2024',
      'Авг 2024',
      'Сен 2024',
      'Окт 2024',
      'Ноя 2024',
      'Дек 2024',
    ];
    final incomes = [
      450000.0,
      0.0,
      800000.0,
      300000.0,
      1200000.0,
      0.0,
      500000.0,
      0.0,
      750000.0,
      400000.0,
      0.0,
      900000.0,
    ];
    final expenses = [
      320000.0,
      150000.0,
      400000.0,
      550000.0,
      200000.0,
      100000.0,
      300000.0,
      250000.0,
      350000.0,
      450000.0,
      120000.0,
      500000.0,
    ];

    final totalIncome = incomes.fold(0.0, (a, b) => a + b);
    final totalExpense = expenses.fold(0.0, (a, b) => a + b);
    final totalBalance = totalIncome - totalExpense;

    const double labelWidth = 100.0;
    const double monthWidth = 120.0;
    const double totalWidth = 130.0;
    const double rowHeight = 40.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Движение денежных средств (Cash Flow)', theme),
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
              // 1. Fixed Left Column (Labels)
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
                  _buildCell('Приход', labelWidth, rowHeight, theme),
                  const Divider(height: 1),
                  _buildCell('Расход', labelWidth, rowHeight, theme),
                  const Divider(height: 1, thickness: 1),
                  _buildCell(
                    'Итого',
                    labelWidth,
                    rowHeight,
                    theme,
                    isBold: true,
                  ),
                  const Divider(height: 1),
                ],
              ),
              _buildVerticalDivider(theme, height: (rowHeight + 1) * 4),

              // 2. Scrollable Middle (Months)
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (int i = 0; i < months.length; i++) ...[
                        Column(
                          children: [
                            _buildCell(
                              months[i],
                              monthWidth,
                              rowHeight,
                              theme,
                              isHeader: true,
                            ),
                            const Divider(height: 1, thickness: 1),
                            _buildCell(
                              incomes[i] != 0
                                  ? formatCurrency(incomes[i])
                                  : formatCurrency(0),
                              monthWidth,
                              rowHeight,
                              theme,
                              valueColor: incomes[i] > 0 ? Colors.green : null,
                            ),
                            const Divider(height: 1),
                            _buildCell(
                              expenses[i] != 0
                                  ? formatCurrency(expenses[i])
                                  : formatCurrency(0),
                              monthWidth,
                              rowHeight,
                              theme,
                              valueColor: expenses[i] > 0 ? Colors.red : null,
                            ),
                            const Divider(height: 1, thickness: 1),
                            _buildCell(
                              formatCurrency(incomes[i] - expenses[i]),
                              monthWidth,
                              rowHeight,
                              theme,
                              isBold: true,
                              valueColor: (incomes[i] - expenses[i]) >= 0
                                  ? Colors.green
                                  : Colors.red,
                            ),
                            const Divider(height: 1),
                          ],
                        ),
                        _buildVerticalDivider(
                          theme,
                          height: (rowHeight + 1) * 4,
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // 3. Fixed Right Column (Totals)
              Column(
                children: [
                  _buildCell(
                    'ИТОГО',
                    totalWidth,
                    rowHeight,
                    theme,
                    isHeader: true,
                    isTotalColumn: true,
                  ),
                  const Divider(height: 1, thickness: 1),
                  _buildCell(
                    formatCurrency(totalIncome),
                    totalWidth,
                    rowHeight,
                    theme,
                    valueColor: Colors.green,
                    isTotalColumn: true,
                  ),
                  const Divider(height: 1),
                  _buildCell(
                    formatCurrency(totalExpense),
                    totalWidth,
                    rowHeight,
                    theme,
                    valueColor: Colors.red,
                    isTotalColumn: true,
                  ),
                  const Divider(height: 1, thickness: 1),
                  _buildCell(
                    formatCurrency(totalBalance),
                    totalWidth,
                    rowHeight,
                    theme,
                    isBold: true,
                    valueColor: totalBalance >= 0 ? Colors.green : Colors.red,
                    isTotalColumn: true,
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

  Widget _buildCell(
    String text,
    double width,
    double height,
    ThemeData theme, {
    bool isHeader = false,
    bool isBold = false,
    Color? valueColor,
    bool isTotalColumn = false,
  }) {
    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: isHeader
            ? (isTotalColumn
                  ? theme.colorScheme.primary.withValues(alpha: 0.05)
                  : theme.colorScheme.onSurface.withValues(alpha: 0.02))
            : (isTotalColumn
                  ? theme.colorScheme.primary.withValues(alpha: 0.02)
                  : null),
      ),
      child: Text(
        text,
        style: theme.textTheme.bodySmall?.copyWith(
          fontWeight: (isHeader || isBold || isTotalColumn)
              ? FontWeight.bold
              : FontWeight.normal,
          color: isHeader
              ? (isTotalColumn
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withValues(alpha: 0.5))
              : valueColor,
          fontSize: isHeader ? 11 : (isTotalColumn ? 12 : 11),
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildVerticalDivider(ThemeData theme, {double? height}) {
    return Container(
      width: 1,
      height: height,
      color: theme.colorScheme.outline.withValues(alpha: 0.1),
    );
  }

  Widget _buildAddendumsSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: _buildSectionTitle('Дополнительные соглашения', theme),
            ),
            PermissionGuard(
              module: 'contracts',
              permission: 'update',
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  // TODO: Реализовать создание ДС
                },
                child: const Icon(CupertinoIcons.plus_circle, size: 20),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildAddendumRow(
          '1',
          '15.01.2024',
          'Продление срока выполнения работ до 31.12.2024',
          null,
          theme,
        ),
        _buildAddendumRow(
          '2',
          '20.02.2024',
          'Увеличение суммы договора (доп. работы по 2 этажу)',
          150000,
          theme,
        ),
      ],
    );
  }

  Widget _buildAddendumRow(
    String number,
    String date,
    String description,
    double? amount,
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
                CupertinoIcons.doc_append,
                size: 18,
                color: theme.colorScheme.primary.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Доп. соглашение №$number',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          date,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.7,
                        ),
                      ),
                    ),
                    if (amount != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '+ ${formatCurrency(amount)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {},
                    child: const Icon(
                      CupertinoIcons.eye,
                      size: 18,
                      color: Colors.blue,
                    ),
                  ),
                  PermissionGuard(
                    module: 'contracts',
                    permission: 'update',
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: () {},
                          child: const Icon(
                            CupertinoIcons.pencil,
                            size: 18,
                            color: Colors.amber,
                          ),
                        ),
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: () {},
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

  Widget _buildActsSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: _buildSectionTitle('Акты КС-2', theme)),
            PermissionGuard(
              module: 'contracts',
              permission: 'update',
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  // TODO: Реализовать создание акта
                },
                child: const Icon(CupertinoIcons.plus_circle, size: 20),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildActRow(
          '1',
          '01.03.2024',
          '01.02.2024 - 29.02.2024',
          250000,
          'signed',
          theme,
        ),
        _buildActRow(
          '2',
          '01.04.2024',
          '01.03.2024 - 31.03.2024',
          450000,
          'paid',
          theme,
        ),
        _buildActRow(
          '3',
          '05.05.2024',
          '01.04.2024 - 30.04.2024',
          120000,
          'draft',
          theme,
        ),
      ],
    );
  }

  Widget _buildActRow(
    String number,
    String date,
    String period,
    double amount,
    String status,
    ThemeData theme,
  ) {
    Color statusColor;
    String statusText;
    switch (status) {
      case 'paid':
        statusColor = Colors.green;
        statusText = 'Оплачен';
        break;
      case 'signed':
        statusColor = Colors.blue;
        statusText = 'Подписан';
        break;
      default:
        statusColor = Colors.orange;
        statusText = 'Черновик';
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                CupertinoIcons.doc_checkmark,
                size: 18,
                color: theme.colorScheme.primary.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Акт №$number',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          date,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Период: $period',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.7,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          formatCurrency(amount),
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        AppBadge(text: statusText, color: statusColor),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {},
                    child: const Icon(
                      CupertinoIcons.eye,
                      size: 18,
                      color: Colors.blue,
                    ),
                  ),
                  PermissionGuard(
                    module: 'contracts',
                    permission: 'update',
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: () {},
                          child: const Icon(
                            CupertinoIcons.pencil,
                            size: 18,
                            color: Colors.amber,
                          ),
                        ),
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: () {},
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

  Widget _buildSectionTitle(String title, ThemeData theme) {
    return ContractSectionTitle(title: title);
  }

  Widget _buildDataRow(
    String label,
    String value,
    ThemeData theme, {
    IconData? icon,
  }) {
    final displayValue = value.isEmpty ? '—' : value;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 16,
                  color: theme.colorScheme.primary.withValues(alpha: 0.5),
                ),
                const SizedBox(width: 12),
              ],
              SizedBox(
                width: 250,
                child: Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: SelectableText(
                  displayValue,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        Divider(
          height: 1,
          thickness: 0.5,
          indent: icon != null ? 40 : 12,
          endIndent: 12,
          color: theme.colorScheme.outline.withValues(alpha: 0.08),
        ),
      ],
    );
  }
}
