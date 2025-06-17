import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart';
import '../providers/payroll_providers.dart';
import '../providers/payroll_payout_filter_provider.dart';
import '../providers/payroll_filter_provider.dart';
import '../providers/balance_providers.dart';
import '../utils/balance_utils.dart';
import '../../../../core/utils/snackbar_utils.dart';
import 'payroll_payout_form_modal.dart';

/// Таблица выплат по ФОТ за выбранный период.
class PayrollPayoutTableWidget extends ConsumerStatefulWidget {
  /// Конструктор [PayrollPayoutTableWidget].
  /// 
  /// Используется для отображения таблицы выплат по ФОТ за выбранный период.
  /// 
  /// [key] — уникальный ключ виджета (опционально).
  const PayrollPayoutTableWidget({super.key});

  /// Создаёт состояние для виджета [PayrollPayoutTableWidget].
  /// 
  /// Возвращает экземпляр [_PayrollPayoutTableWidgetState], реализующий логику построения таблицы выплат.
  @override
  ConsumerState<PayrollPayoutTableWidget> createState() => _PayrollPayoutTableWidgetState();
}

class _PayrollPayoutTableWidgetState extends ConsumerState<PayrollPayoutTableWidget> {
  /// Контроллер для вертикального скролла.
  final ScrollController _verticalController = ScrollController();
  
  /// Контроллер для горизонтального скролла.
  final ScrollController _horizontalController = ScrollController();
  
  @override
  void dispose() {
    _verticalController.dispose();
    _horizontalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filterState = ref.watch(payrollPayoutFilterProvider);
    // Используем сотрудников из основного провайдера фильтров ФОТ для консистентности
    final payrollFilterState = ref.watch(payrollFilterProvider);
    final employees = payrollFilterState.employees;
    
    // Используем новый провайдер отфильтрованных выплат
    final payoutsAsync = ref.watch(filteredPayrollPayoutsProvider);
    final balanceAsync = ref.watch(employeeAggregatedBalanceProvider);
    final numberFormat = NumberFormat.currency(locale: 'ru_RU', symbol: '₽', decimalDigits: 2);

    return payoutsAsync.when(
      data: (payouts) {
        if (payouts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.payment_outlined,
                  size: 64,
                  color: theme.colorScheme.outline,
                ),
                const SizedBox(height: 16),
                Text(
                  'Нет выплат за выбранный период',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
          );
        }

        return balanceAsync.when(
          data: (balanceMap) {
            final tableTitle = 'Выплаты ${DateFormat('dd.MM.yyyy').format(filterState.startDate)} - ${DateFormat('dd.MM.yyyy').format(filterState.endDate)}';
            
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tableTitle,
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isDesktop = constraints.maxWidth >= 900;
                      final isTablet = constraints.maxWidth >= 600 && constraints.maxWidth < 900;
                      final minTableWidth = isDesktop ? 800.0 : isTablet ? 600.0 : 0.0;
                      final tableWidth = constraints.maxWidth > minTableWidth ? constraints.maxWidth : minTableWidth;
                      final needsHorizontalScroll = tableWidth > constraints.maxWidth;

                      return Scrollbar(
                        controller: _verticalController,
                        thumbVisibility: true,
                        child: SingleChildScrollView(
                          controller: _verticalController,
                          child: Scrollbar(
                            controller: _horizontalController,
                            thumbVisibility: needsHorizontalScroll,
                            scrollbarOrientation: ScrollbarOrientation.bottom,
                            child: SingleChildScrollView(
                              controller: _horizontalController,
                              scrollDirection: Axis.horizontal,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minWidth: tableWidth,
                                  maxWidth: tableWidth,
                                ),
                                child: DataTable(
                                  headingTextStyle: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                                  dataTextStyle: theme.textTheme.bodyMedium,
                                  border: TableBorder.all(
                                    color: theme.colorScheme.outline.withValues(alpha: 0.2),
                                    width: 1,
                                  ),
                                  columns: const [
                                    DataColumn(label: Text('Сотрудник')),
                                    DataColumn(label: Text('Баланс до выплаты'), numeric: true),
                                    DataColumn(label: Text('Сумма выплаты'), numeric: true),
                                    DataColumn(label: Text('Дата выплаты')),
                                    DataColumn(label: Text('Тип')),
                                    DataColumn(label: Text('Способ')),
                                  ],
                                  rows: [
                                    for (int i = 0; i < payouts.length; i++)
                                      () {
                                        final payout = payouts[i];
                                        final employee = employees.firstWhereOrNull((e) => e.id == payout.employeeId);
                                        final fio = employee != null
                                            ? [employee.lastName, employee.firstName, if (employee.middleName != null && employee.middleName.isNotEmpty) employee.middleName].join(' ')
                                            : payout.employeeId;
                                        final position = employee?.position ?? '';
                                        final balance = balanceMap[payout.employeeId] ?? 0.0;
                                        final dateStr = DateFormat('dd.MM.yyyy').format(payout.payoutDate);
                                        final methodStr = _getPayoutMethodName(payout.method);
                                        final typeStr = _getPayoutTypeName(payout.type);

                                        return DataRow(cells: [
                                          DataCell(Row(
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
                                              Text(
                                                '${i + 1}. ',
                                                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                                              ),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      fio.trim(),
                                                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                    if (position.isNotEmpty)
                                                      Text(
                                                        position,
                                                        style: theme.textTheme.bodySmall?.copyWith(
                                                          color: theme.colorScheme.onSurfaceVariant,
                                                          height: 1.2,
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                  ],
                                                ),
                                              ),
                                              PopupMenuButton<String>(
                                                icon: const Icon(Icons.more_vert),
                                                tooltip: 'Действия',
                                                itemBuilder: (context) => [
                                                  PopupMenuItem(
                                                    value: 'edit',
                                                    child: Row(
                                                      children: [
                                                        Icon(Icons.edit_outlined, color: theme.colorScheme.primary, size: 20),
                                                        const SizedBox(width: 8),
                                                        const Text('Редактировать'),
                                                      ],
                                                    ),
                                                  ),
                                                  PopupMenuItem(
                                                    value: 'delete',
                                                    child: Row(
                                                      children: [
                                                        Icon(Icons.delete_outline, color: theme.colorScheme.error, size: 20),
                                                        const SizedBox(width: 8),
                                                        Text('Удалить', style: TextStyle(color: theme.colorScheme.error)),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                                onSelected: (value) async {
                                                  if (value == 'edit') {
                                                    showModalBottomSheet(
                                                      context: context,
                                                      isScrollControlled: true,
                                                      backgroundColor: Colors.transparent,
                                                      constraints: BoxConstraints(
                                                        maxHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top - kToolbarHeight,
                                                      ),
                                                      builder: (ctx) => PayrollPayoutFormModal(payout: payout),
                                                    );
                                                  } else if (value == 'delete') {
                                                    final confirmed = await showCupertinoDialog<bool>(
                                                      context: context,
                                                      builder: (context) => CupertinoAlertDialog(
                                                        title: const Text('Подтверждение'),
                                                        content: const Text('Вы уверены, что хотите удалить эту выплату?'),
                                                        actions: [
                                                          CupertinoDialogAction(
                                                            child: const Text('Отмена'),
                                                            onPressed: () => Navigator.pop(context, false),
                                                          ),
                                                          CupertinoDialogAction(
                                                            isDestructiveAction: true,
                                                            child: const Text('Удалить'),
                                                            onPressed: () => Navigator.pop(context, true),
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                    
                                                    if (confirmed == true && context.mounted) {
                                                      try {
                                                        final deleteUseCase = ref.read(deletePayoutUseCaseProvider);
                                                        await deleteUseCase(payout.id);
                                                        
                                                        ref.invalidate(filteredPayrollPayoutsProvider);
                                                        ref.invalidate(employeeAggregatedBalanceProvider);
                                                        ref.invalidate(payrollPayoutsByMonthProvider);
                                                        
                                                        if (context.mounted) {
                                                          SnackBarUtils.showSuccess(context, 'Выплата удалена');
                                                        }
                                                      } catch (e) {
                                                        if (context.mounted) {
                                                          SnackBarUtils.showError(context, 'Ошибка удаления: $e');
                                                        }
                                                      }
                                                    }
                                                  }
                                                },
                                              ),
                                            ],
                                          )),
                                          DataCell(
                                            BalanceUtils.buildBalanceWidget(
                                              balance,
                                              theme,
                                              showIcon: true,
                                              showDescription: false,
                                              textStyle: theme.textTheme.bodyMedium?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          DataCell(Text(
                                            numberFormat.format(payout.amount),
                                            style: theme.textTheme.bodyMedium?.copyWith(
                                              color: Colors.blue.shade600,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          )),
                                          DataCell(Text(dateStr)),
                                          DataCell(Text(typeStr)),
                                          DataCell(Text(methodStr)),
                                        ]);
                                      }(),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => Center(
            child: Text('Ошибка загрузки баланса: $e'),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(
        child: Text('Ошибка загрузки выплат: $e'),
      ),
    );
  }

  String _getPayoutMethodName(String method) {
    switch (method) {
      case 'cash':
        return 'Наличные';
      case 'bank_transfer':
        return 'Банковский перевод';
      case 'card':
        return 'Карта';
      default:
        return method;
    }
  }

  String _getPayoutTypeName(String type) {
    switch (type) {
      case 'salary':
        return 'Зарплата';
      case 'advance':
        return 'Аванс';
      default:
        return type;
    }
  }
} 