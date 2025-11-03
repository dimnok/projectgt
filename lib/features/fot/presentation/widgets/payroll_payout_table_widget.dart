import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';
import '../../../../core/utils/formatters.dart';
import '../providers/payroll_providers.dart';
import 'payroll_payout_form_modal.dart';
import 'payroll_search_action.dart';
import '../../../../presentation/state/employee_state.dart';
import '../utils/payout_converters.dart';
import '../../data/models/payroll_payout_model.dart';

/// Таблица всех выплат по ФОТ.
class PayrollPayoutTableWidget extends ConsumerStatefulWidget {
  /// Конструктор [PayrollPayoutTableWidget].
  ///
  /// Используется для отображения таблицы всех выплат по ФОТ с фильтрацией по ФИО сотрудника.
  ///
  /// [key] — уникальный ключ виджета (опционально).
  const PayrollPayoutTableWidget({super.key});

  /// Создаёт состояние для виджета [PayrollPayoutTableWidget].
  ///
  /// Возвращает экземпляр [_PayrollPayoutTableWidgetState], реализующий логику построения таблицы выплат.
  @override
  ConsumerState<PayrollPayoutTableWidget> createState() =>
      _PayrollPayoutTableWidgetState();
}

class _PayrollPayoutTableWidgetState
    extends ConsumerState<PayrollPayoutTableWidget> {
  /// Контроллер для вертикального скролла.
  final ScrollController _verticalController = ScrollController();

  @override
  void dispose() {
    _verticalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final employeeState = ref.watch(employeeProvider);
    final employees = employeeState.employees;
    final payoutsAsync = ref.watch(allPayoutsProvider);
    final searchQuery = ref.watch(payrollSearchQueryProvider);

    return payoutsAsync.when(
      data: (allPayouts) {
        final payouts = filterPayoutsByEmployeeName(
          allPayouts,
          searchQuery,
          ref,
        );
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
                  'Нет выплат',
                  style: theme.textTheme.titleMedium,
                ),
              ],
            ),
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final dividerColor =
                theme.colorScheme.outline.withValues(alpha: 0.18);
            final headerBackgroundColor = theme.brightness == Brightness.dark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.06);

            Widget headerCell(String text, {TextAlign align = TextAlign.left}) {
              Alignment headerAlignment;
              switch (align) {
                case TextAlign.center:
                  headerAlignment = Alignment.center;
                  break;
                case TextAlign.right:
                  headerAlignment = Alignment.centerRight;
                  break;
                default:
                  headerAlignment = Alignment.centerLeft;
              }
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                alignment: headerAlignment,
                child: Text(
                  text,
                  textAlign: align,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }

            Widget bodyCell(
              Widget child, {
              Alignment align = Alignment.centerLeft,
              VoidCallback? onLongPress,
            }) {
              final content = Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                alignment: align,
                child: DefaultTextStyle(
                  style: theme.textTheme.bodyMedium!,
                  child: child,
                ),
              );

              if (onLongPress == null) {
                return content;
              }

              return MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onLongPress: onLongPress,
                  child: content,
                ),
              );
            }

            List<TableRow> buildRows() {
              final list = <TableRow>[];

              // Заголовок
              list.add(
                TableRow(
                  decoration: BoxDecoration(color: headerBackgroundColor),
                  children: [
                    headerCell('Дата', align: TextAlign.center),
                    headerCell('Сотрудник', align: TextAlign.center),
                    headerCell('Сумма', align: TextAlign.center),
                    headerCell('Способ', align: TextAlign.center),
                    headerCell('Тип', align: TextAlign.center),
                    headerCell('Комментарий', align: TextAlign.center),
                  ],
                ),
              );

              // Строки данных
              for (final payout in payouts) {
                list.add(
                  TableRow(
                    children: [
                      bodyCell(
                        Text(formatRuDate(payout.payoutDate)),
                        align: Alignment.center,
                      ),
                      bodyCell(
                        Text(_getEmployeeName(payout, employees)),
                        onLongPress: () => _handlePayoutAction(payout, context),
                      ),
                      bodyCell(
                        Text(formatCurrency(payout.amount)),
                        align: Alignment.centerRight,
                      ),
                      bodyCell(
                        Text(getPayoutMethodName(payout.method)),
                        align: Alignment.center,
                      ),
                      bodyCell(
                        Text(getPayoutTypeName(payout.type)),
                        align: Alignment.center,
                      ),
                      bodyCell(
                        Text(payout.comment ?? '—'),
                      ),
                    ],
                  ),
                );
              }

              return list;
            }

            return Scrollbar(
              controller: _verticalController,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: _verticalController,
                child: SizedBox(
                  width: constraints.maxWidth,
                  child: Table(
                    border: TableBorder(
                      top: BorderSide(color: dividerColor, width: 1),
                      bottom: BorderSide(color: dividerColor, width: 1),
                      left: BorderSide(color: dividerColor, width: 1),
                      right: BorderSide(color: dividerColor, width: 1),
                      horizontalInside:
                          BorderSide(color: dividerColor, width: 1),
                      verticalInside: BorderSide(color: dividerColor, width: 1),
                    ),
                    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                    columnWidths: const <int, TableColumnWidth>{
                      0: IntrinsicColumnWidth(),
                      1: IntrinsicColumnWidth(),
                      2: IntrinsicColumnWidth(),
                      3: IntrinsicColumnWidth(),
                      4: IntrinsicColumnWidth(),
                      5: FlexColumnWidth(1),
                    },
                    children: buildRows(),
                  ),
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(
        child: Text('Ошибка загрузки выплат: $e'),
      ),
    );
  }

  /// Получает ФИО сотрудника по ID выплаты.
  String _getEmployeeName(PayrollPayoutModel payout, List<dynamic> employees) {
    final employee =
        employees.firstWhereOrNull((e) => e.id == payout.employeeId);
    if (employee == null) return payout.employeeId;
    return [
      employee.lastName,
      employee.firstName,
      if (employee.middleName != null && employee.middleName!.isNotEmpty)
        employee.middleName!
    ].join(' ').trim();
  }

  /// Обрабатывает действие с выплатой (долгое нажатие).
  Future<void> _handlePayoutAction(
    PayrollPayoutModel payout,
    BuildContext context,
  ) async {
    final confirmed = await showCupertinoDialog<String?>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Действия'),
        content: const Text('Выберите действие'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Отмена'),
            onPressed: () => Navigator.pop(context, null),
          ),
          CupertinoDialogAction(
            child: const Text('Редактировать'),
            onPressed: () => Navigator.pop(context, 'edit'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Удалить'),
            onPressed: () => Navigator.pop(context, 'delete'),
          ),
        ],
      ),
    );

    if (!context.mounted) return;

    if (confirmed == 'edit') {
      final screenHeight = MediaQuery.of(context).size.height;
      final topPadding = MediaQuery.of(context).padding.top;

      if (!context.mounted) return;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        constraints: BoxConstraints(
          maxHeight: screenHeight - topPadding - kToolbarHeight,
        ),
        builder: (ctx) => PayrollPayoutFormModal(payout: payout),
      );
    } else if (confirmed == 'delete') {
      try {
        final deleteUseCase = ref.read(deletePayoutUseCaseProvider);
        await deleteUseCase(payout.id);

        ref.invalidate(allPayoutsProvider);
        ref.invalidate(payoutsByEmployeeAndMonthFIFOProvider);

        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Выплата удалена')),
        );
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка удаления: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
