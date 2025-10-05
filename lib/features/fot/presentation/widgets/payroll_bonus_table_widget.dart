import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart';
import '../providers/bonus_providers.dart';
import '../providers/balance_providers.dart';
import '../providers/payroll_providers.dart';
import '../providers/payroll_filter_providers.dart';
import '../../../../core/utils/snackbar_utils.dart';
import 'payroll_transaction_form_modal.dart';
import 'payroll_search_action.dart';
import '../../domain/entities/payroll_transaction.dart';
import 'package:flutter/cupertino.dart';
import '../../../../presentation/state/employee_state.dart';
import 'package:projectgt/core/di/providers.dart';

/// Виджет для отображения таблицы премий сотрудников за текущий месяц в модуле ФОТ.
///
/// Использует данные из провайдера filteredBonusesProvider и отображает премии с деталями по сотруднику, объекту, сумме, дате и примечанию.
/// Поддерживает адаптивную верстку (desktop/tablet/mobile), сортировку и действия (редактирование, удаление).
class PayrollBonusTableWidget extends ConsumerWidget {
  /// Конструктор [PayrollBonusTableWidget].
  ///
  /// [key] — уникальный ключ виджета (опционально).
  const PayrollBonusTableWidget({super.key});

  /// Строит UI таблицы премий сотрудников за выбранный месяц.
  ///
  /// [context] — BuildContext для доступа к теме и навигации.
  /// [ref] — WidgetRef для доступа к провайдерам состояния.
  ///
  /// Возвращает [Widget] с таблицей премий или сообщением об отсутствии данных.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final allBonuses = ref.watch(filteredBonusesProvider);
    final searchQuery = ref.watch(payrollSearchQueryProvider);

    // Применяем фильтрацию по поисковому запросу
    final bonuses = filterTransactionsByEmployeeName(
      allBonuses,
      searchQuery,
      ref,
    );

    final employeeState = ref.watch(employeeProvider);
    final objectState = ref.watch(objectProvider);
    final employees = employeeState.employees;
    final objects = objectState.objects;
    final filterState = ref.watch(payrollFilterProvider);

    // Проверяем, применен ли фильтр по периоду
    final now = DateTime.now();
    final isPeriodFiltered = filterState.selectedYear != now.year ||
        filterState.selectedMonth != now.month;

    final monthDate =
        DateTime(filterState.selectedYear, filterState.selectedMonth);
    final tableTitle = isPeriodFiltered
        ? 'Премии за ${DateFormat.yMMMM('ru').format(monthDate)}'
        : 'Премии (все)';

    if (bonuses.isEmpty) {
      return Center(
        child: Text(
            isPeriodFiltered
                ? 'Нет премий за ${DateFormat.yMMMM('ru').format(monthDate)}'
                : 'Нет премий',
            style: theme.textTheme.titleMedium),
      );
    }
    final numberFormat =
        NumberFormat.currency(locale: 'ru_RU', symbol: '₽', decimalDigits: 2);
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
              final isTablet =
                  constraints.maxWidth >= 600 && constraints.maxWidth < 900;
              final minTableWidth = isDesktop
                  ? 700.0
                  : isTablet
                      ? 500.0
                      : 0.0;
              final tableWidth = constraints.maxWidth > minTableWidth
                  ? constraints.maxWidth
                  : minTableWidth;
              final needsHorizontalScroll = tableWidth > constraints.maxWidth;
              return Scrollbar(
                thumbVisibility: needsHorizontalScroll,
                controller: null,
                scrollbarOrientation: ScrollbarOrientation.bottom,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: tableWidth,
                      maxWidth: tableWidth,
                    ),
                    child: DataTable(
                      headingTextStyle: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                      dataTextStyle: theme.textTheme.bodyMedium,
                      border: TableBorder.all(
                        color: theme.colorScheme.outline.withValues(alpha: 0.2),
                        width: 1,
                      ),
                      columns: const [
                        DataColumn(label: Text('Сотрудник')),
                        DataColumn(label: Text('Объект')),
                        DataColumn(label: Text('Сумма'), numeric: true),
                        DataColumn(label: Text('Дата')),
                        DataColumn(label: Text('Примечание')),
                      ],
                      rows: [
                        for (int i = 0; i < bonuses.length; i++)
                          () {
                            final bonus = bonuses[i];
                            // Используем bonus.date (дата премии), fallback на createdAt если date == null
                            final displayDate = bonus.date ?? bonus.createdAt;
                            final dateStr = displayDate != null
                                ? DateFormat('dd.MM.yyyy').format(displayDate)
                                : '';
                            final employee = employees.firstWhereOrNull(
                                (e) => e.id == bonus.employeeId);
                            final fio = employee != null
                                ? [
                                    employee.lastName,
                                    employee.firstName,
                                    if (employee.middleName != null &&
                                        employee.middleName!.isNotEmpty)
                                      employee.middleName
                                  ].join(' ')
                                : bonus.employeeId;
                            final position = employee?.position ?? '';
                            final object = objects.firstWhereOrNull(
                                (o) => o.id == bonus.objectId);
                            final objectName = object != null
                                ? object.name
                                : (bonus.objectId ?? '');
                            final amount = bonus.amount;
                            final note = bonus.reason ?? '';
                            return DataRow(cells: [
                              DataCell(Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    '${i + 1}. ',
                                    style: theme.textTheme.bodyMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          fio.trim(),
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                                  fontWeight: FontWeight.w500),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (position.isNotEmpty)
                                          Text(
                                            position,
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                              color: theme
                                                  .colorScheme.onSurfaceVariant,
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
                                    onSelected: (value) async {
                                      if (value == 'edit') {
                                        showModalBottomSheet(
                                          context: context,
                                          isScrollControlled: true,
                                          backgroundColor: Colors.transparent,
                                          constraints: BoxConstraints(
                                            maxHeight: MediaQuery.of(context)
                                                    .size
                                                    .height -
                                                MediaQuery.of(context)
                                                    .padding
                                                    .top -
                                                kToolbarHeight,
                                          ),
                                          builder: (ctx) =>
                                              PayrollTransactionFormModal(
                                            transactionType:
                                                PayrollTransactionType.bonus,
                                            transaction: bonus,
                                          ),
                                        );
                                      } else if (value == 'delete') {
                                        showCupertinoDialog(
                                          context: context,
                                          builder: (ctx) =>
                                              CupertinoAlertDialog(
                                            title:
                                                const Text('Удалить премию?'),
                                            content: const Text(
                                                'Вы действительно хотите удалить эту премию?'),
                                            actions: [
                                              CupertinoDialogAction(
                                                child: const Text('Отмена'),
                                                onPressed: () =>
                                                    Navigator.of(ctx).pop(),
                                              ),
                                              CupertinoDialogAction(
                                                isDestructiveAction: true,
                                                child: const Text('Удалить'),
                                                onPressed: () async {
                                                  Navigator.of(ctx).pop();
                                                  try {
                                                    final deleteBonus = ref.read(
                                                        deleteBonusUseCaseProvider);
                                                    await deleteBonus(bonus.id);
                                                    ref.invalidate(
                                                        allBonusesProvider);
                                                    ref.invalidate(
                                                        employeeAggregatedBalanceProvider);
                                                    ref.invalidate(
                                                        payrollPayoutsByMonthProvider);
                                                    ref.invalidate(
                                                        filteredPayrollsProvider);
                                                    if (context.mounted) {
                                                      SnackBarUtils.showSuccess(
                                                          context,
                                                          'Премия удалена');
                                                    }
                                                  } catch (e) {
                                                    if (context.mounted) {
                                                      SnackBarUtils.showError(
                                                          context,
                                                          'Ошибка удаления: $e');
                                                    }
                                                  }
                                                },
                                              ),
                                            ],
                                          ),
                                        );
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      PopupMenuItem(
                                        value: 'edit',
                                        child: Row(
                                          children: [
                                            Icon(Icons.edit_outlined,
                                                color:
                                                    theme.colorScheme.primary,
                                                size: 20),
                                            const SizedBox(width: 8),
                                            const Text('Редактировать'),
                                          ],
                                        ),
                                      ),
                                      PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(Icons.delete_outline,
                                                color: theme.colorScheme.error,
                                                size: 20),
                                            const SizedBox(width: 8),
                                            Text('Удалить',
                                                style: TextStyle(
                                                    color: theme
                                                        .colorScheme.error)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              )),
                              DataCell(Text(objectName)),
                              DataCell(Text(numberFormat.format(amount))),
                              DataCell(Text(dateStr)),
                              DataCell(Text(note)),
                            ]);
                          }(),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
