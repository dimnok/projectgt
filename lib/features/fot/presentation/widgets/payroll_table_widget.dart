import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/payroll_calculation.dart';
import '../providers/payroll_filter_provider.dart';
import '../../../../presentation/state/employee_state.dart';
import 'package:projectgt/core/utils/responsive_utils.dart';
import '../providers/payroll_providers.dart';
import '../providers/balance_providers.dart';
import 'payroll_table_cells.dart';
import 'payroll_table_row_builder.dart';

/// Виджет для отображения табличных данных расчётов ФОТ.
///
/// Поддерживает группировку по сотрудникам с детальной стилизацией.
/// Оптимизирован для производительности и соответствует Clean Architecture.
class PayrollTableWidget extends ConsumerStatefulWidget {
  /// Список расчётов ФОТ.
  final List<PayrollCalculation> payrolls;

  /// Флаг группировки по сотрудникам.
  final bool isGroupedByEmployee;

  /// Создаёт виджет таблицы для отображения данных ФОТ.
  const PayrollTableWidget({
    super.key,
    required this.payrolls,
    this.isGroupedByEmployee = true,
  });

  @override
  ConsumerState<PayrollTableWidget> createState() => _PayrollTableWidgetState();
}

class _PayrollTableWidgetState extends ConsumerState<PayrollTableWidget> {
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

    // Оптимизировано: слушаем только нужные поля фильтра
    final year = ref.watch(payrollFilterProvider.select((s) => s.year));
    final month = ref.watch(payrollFilterProvider.select((s) => s.month));
    final monthDate = DateTime(year, month);

    // Получаем только список сотрудников (без лишних полей)
    final employees = ref.watch(employeeProvider.select((s) => s.employees));

    // Используем независимые данные work_hours вместо timesheetEntries
    final workHoursAsync = ref.watch(payrollWorkHoursProvider);
    final workHours = workHoursAsync.asData?.value ?? [];

    // Получаем выплаты за месяц
    final payrollPayoutsAsync =
        ref.watch(payrollPayoutsByMonthProvider(monthDate));
    final payrollPayouts = payrollPayoutsAsync.asData?.value ?? [];
    final payoutsByEmployee = <String, double>{};
    for (final payout in payrollPayouts) {
      payoutsByEmployee[payout.employeeId] =
          (payoutsByEmployee[payout.employeeId] ?? 0) +
              payout.amount.toDouble();
    }

    // Получаем оптимизированный агрегированный баланс
    final aggregatedBalanceAsync = ref.watch(employeeAggregatedBalanceProvider);
    final aggregatedBalance = aggregatedBalanceAsync.asData?.value ?? {};

    if (widget.payrolls.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_late_outlined,
              size: 64,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'Нет данных для отображения',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Попробуйте изменить фильтры или выбрать другой период',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Text(
            'ФОТ ${DateFormat.yMMMM('ru').format(monthDate)}',
            style: theme.textTheme.headlineSmall,
          ),
        ),
        Expanded(
          child: _buildEmployeeGroupedTable(
            context,
            employees,
            workHours, // Используем независимые данные work_hours
            payoutsByEmployee,
            aggregatedBalance,
          ),
        ),
      ],
    );
  }

  /// Строит таблицу с группировкой по сотрудникам с полным соответствием стилю табеля.
  Widget _buildEmployeeGroupedTable(
    BuildContext context,
    List<dynamic> employees,
    List<dynamic> workHours, // Изменили тип с timesheetEntries на workHours
    Map<String, double> payoutsByEmployee,
    Map<String, double> aggregatedBalance,
  ) {
    final theme = Theme.of(context);

    // Группируем записи по сотрудникам (учитывая, что employeeId может быть null)
    final Map<String?, List<PayrollCalculation>> groupedPayrolls = {};

    try {
      for (final payroll in widget.payrolls) {
        final employeeKey = payroll.employeeId ?? 'unknown';

        if (!groupedPayrolls.containsKey(employeeKey)) {
          groupedPayrolls[employeeKey] = [];
        }
        groupedPayrolls[employeeKey]!.add(payroll);
      }
    } catch (e) {
      // Игнорируем ошибку группировки
    }

    // Используем LayoutBuilder для определения доступной ширины
    return LayoutBuilder(
      builder: (context, constraints) {
        // Определяем, является ли устройство мобильным, планшетом или десктопом
        final isMobile = ResponsiveUtils.isMobile(context);
        final isTablet = ResponsiveUtils.isTablet(context);
        final isDesktop = ResponsiveUtils.isDesktop(context);

        // Определяем минимальную ширину для таблицы на основе типа устройства
        final double minTableWidth = isDesktop
            ? 1200
            : isTablet
                ? 900
                : constraints.maxWidth;

        // Определяем, нужно ли использовать горизонтальный скролл
        final needsHorizontalScroll = minTableWidth > constraints.maxWidth;

        // Определяем колонки таблицы на основе типа устройства
        final columns = _buildAdaptiveColumns(isDesktop, isTablet, isMobile);

        // Создаём объект для хранения итогов
        final totals = PayrollTotals();

        // Строим строки таблицы используя новый строитель
        final rows = PayrollTableRowBuilder.buildDataRows(
          groupedPayrolls: groupedPayrolls,
          theme: theme,
          employees: employees,
          timesheetEntries:
              workHours, // Передаём workHours как timesheetEntries для совместимости
          payoutsByEmployee: payoutsByEmployee,
          aggregatedBalance: aggregatedBalance,
          isMobile: isMobile,
          isTablet: isTablet,
          isDesktop: isDesktop,
          totals: totals,
        );

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
                    minWidth: needsHorizontalScroll
                        ? minTableWidth
                        : constraints.maxWidth,
                  ),
                  child: DataTable(
                    // Стилизация заголовка - точно как в табеле
                    headingTextStyle: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    dataTextStyle: theme.textTheme.bodyMedium,
                    headingRowColor:
                        WidgetStateProperty.resolveWith<Color>((states) {
                      return theme.colorScheme.surface;
                    }),
                    // Границы таблицы с прозрачностью 0.2 как в табеле
                    border: TableBorder.all(
                      color: theme.colorScheme.outline.withValues(alpha: 0.2),
                      width: 1,
                    ),
                    // Отступы между колонками - адаптивные
                    columnSpacing: ResponsiveUtils.adaptiveValue(
                      context: context,
                      mobile: PayrollTableConstants.mobileColumnSpacing,
                      tablet: PayrollTableConstants.tabletColumnSpacing,
                      desktop: PayrollTableConstants.desktopColumnSpacing,
                    ),
                    // Высота строк и заголовка - как в календаре табеля
                    headingRowHeight: 48,
                    dataRowMinHeight: 52,
                    dataRowMaxHeight: 52,
                    // Горизонтальный отступ - адаптивный
                    horizontalMargin: ResponsiveUtils.adaptiveValue(
                      context: context,
                      mobile: 6,
                      tablet: 8,
                      desktop: 12,
                    ),
                    // Разделитель строк
                    dividerThickness: 0.5,
                    columns: columns,
                    rows: rows,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Строит адаптивные колонки таблицы в зависимости от типа устройства
  List<DataColumn> _buildAdaptiveColumns(
      bool isDesktop, bool isTablet, bool isMobile) {
    final List<DataColumn> columns = [
      DataColumn(
        label: Container(
          constraints: BoxConstraints(
            minWidth: isDesktop
                ? 200
                : isTablet
                    ? 150
                    : 120,
          ),
          child: const Text('Сотрудник'),
        ),
      ),
    ];

    if (isDesktop) {
      columns.addAll([
        const DataColumn(label: Text('Часы'), numeric: true),
        const DataColumn(label: Text('Ставка'), numeric: true),
        const DataColumn(label: Text('Базовая сумма'), numeric: true),
        const DataColumn(label: Text('Премии'), numeric: true),
        const DataColumn(label: Text('Штрафы'), numeric: true),
        const DataColumn(label: Text('Командировочные'), numeric: true),
        DataColumn(
          label: Container(
            constraints: BoxConstraints(
              minWidth: isDesktop
                  ? 120
                  : isTablet
                      ? 100
                      : 80,
            ),
            child: const Text('К выплате',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          numeric: true,
        ),
        const DataColumn(label: Text('Выплаты'), numeric: true),
        const DataColumn(label: Text('Баланс'), numeric: true),
      ]);
    } else if (isTablet) {
      columns.addAll([
        const DataColumn(label: Text('Часы'), numeric: true),
        const DataColumn(label: Text('Базовая сумма'), numeric: true),
        if (!isMobile) const DataColumn(label: Text('Премии'), numeric: true),
        const DataColumn(label: Text('Командировочные'), numeric: true),
        DataColumn(
          label: Container(
            constraints: BoxConstraints(
              minWidth: isDesktop
                  ? 120
                  : isTablet
                      ? 100
                      : 80,
            ),
            child: const Text('К выплате',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          numeric: true,
        ),
        const DataColumn(label: Text('Выплаты'), numeric: true),
        const DataColumn(label: Text('Баланс'), numeric: true),
      ]);
    } else {
      columns.addAll([
        const DataColumn(label: Text('Часы'), numeric: true),
        const DataColumn(label: Text('Командировочные'), numeric: true),
        DataColumn(
          label: Container(
            constraints: BoxConstraints(
              minWidth: isDesktop
                  ? 120
                  : isTablet
                      ? 100
                      : 80,
            ),
            child: const Text('К выплате',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          numeric: true,
        ),
        const DataColumn(label: Text('Выплаты'), numeric: true),
        const DataColumn(label: Text('Баланс'), numeric: true),
      ]);
    }

    return columns;
  }
}
