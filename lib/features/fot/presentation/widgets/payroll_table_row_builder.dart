import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import '../../domain/entities/payroll_calculation.dart';
import 'payroll_table_cells.dart';

/// Строитель строк для таблицы ФОТ с адаптивной логикой
class PayrollTableRowBuilder {
  /// Создаёт строки данных для таблицы ФОТ
  static List<DataRow> buildDataRows({
    required Map<String?, List<PayrollCalculation>> groupedPayrolls,
    required ThemeData theme,
    required List<dynamic> employees,
    required List<dynamic> timesheetEntries,
    required Map<String, double> payoutsByEmployee,
    required Map<String, double> aggregatedBalance,
    required bool isMobile,
    required bool isTablet,
    required bool isDesktop,
    required PayrollTotals totals,
  }) {
    final rows = <DataRow>[];
    int employeeCounter = 1;

    // Создаем отображение employeeId -> position из записей табеля
    final employeePositions = _buildEmployeePositionsMap(timesheetEntries);

    // Сортируем сотрудников по алфавиту
    final sortedEmployeeKeys =
        _sortEmployeeKeys(groupedPayrolls.keys.toList(), employees);

    // Создаём строки для каждого сотрудника
    for (final employeeId in sortedEmployeeKeys) {
      final employeePayrolls = groupedPayrolls[employeeId]!;

      for (final payroll in employeePayrolls) {
        // Обновляем итоги
        _updateTotals(totals, payroll, payoutsByEmployee, aggregatedBalance);

        // Получаем информацию о сотруднике
        final employeeInfo = _getEmployeeInfo(
          employeeId,
          employees,
          employeePositions,
          employeeCounter,
        );

        // Создаём строку данных
        final cells = _buildRowCells(
          payroll: payroll,
          employeeInfo: employeeInfo,
          payoutsByEmployee: payoutsByEmployee,
          aggregatedBalance: aggregatedBalance,
          theme: theme,
          isMobile: isMobile,
          isTablet: isTablet,
          isDesktop: isDesktop,
        );

        rows.add(DataRow(cells: cells));
      }

      employeeCounter++;
    }

    // Добавляем итоговую строку
    rows.add(_buildTotalRow(totals, theme, isMobile, isTablet, isDesktop,
        groupedPayrolls, aggregatedBalance));

    return rows;
  }

  /// Создаёт отображение employeeId -> position
  static Map<String, String> _buildEmployeePositionsMap(
      List<dynamic> timesheetEntries) {
    final employeePositions = <String, String>{};
    for (final entry in timesheetEntries) {
      // Проверяем, что entry имеет нужные поля
      if (entry.employeeId != null &&
          entry.employeePosition != null &&
          entry.employeePosition!.isNotEmpty) {
        employeePositions[entry.employeeId] = entry.employeePosition!;
      }
    }
    return employeePositions;
  }

  /// Сортирует ключи сотрудников по алфавиту
  static List<String?> _sortEmployeeKeys(
      List<String?> keys, List<dynamic> employees) {
    return keys
      ..sort((a, b) {
        if (a == null) return 1;
        if (b == null) return -1;

        final empA = employees.firstWhereOrNull((emp) => emp.id == a);
        final empB = employees.firstWhereOrNull((emp) => emp.id == b);

        final nameA = empA != null
            ? ('${empA.lastName} ${empA.firstName} ${empA.middleName ?? ''}')
                .trim()
                .toLowerCase()
            : '';
        final nameB = empB != null
            ? ('${empB.lastName} ${empB.firstName} ${empB.middleName ?? ''}')
                .trim()
                .toLowerCase()
            : '';

        return nameA.compareTo(nameB);
      });
  }

  /// Получает информацию о сотруднике
  static EmployeeInfo _getEmployeeInfo(
    String? employeeId,
    List<dynamic> employees,
    Map<String, String> employeePositions,
    int counter,
  ) {
    String employeeName = 'Неизвестный сотрудник';
    String employeePosition = '';

    if (employeeId != null && employeeId != 'unknown') {
      final employee =
          employees.firstWhereOrNull((emp) => emp.id == employeeId);
      if (employee != null) {
        employeeName =
            '${employee.lastName} ${employee.firstName} ${employee.middleName ?? ''}';
        employeePosition =
            employee.position ?? employeePositions[employeeId] ?? '';
      } else {
        employeeName = 'Сотрудник #$employeeId';
        employeePosition = employeePositions[employeeId] ?? '';
      }
    }

    return EmployeeInfo(
      name: employeeName,
      position: employeePosition,
      index: counter,
    );
  }

  /// Обновляет итоги
  static void _updateTotals(
    PayrollTotals totals,
    PayrollCalculation payroll,
    Map<String, double> payoutsByEmployee,
    Map<String, double> aggregatedBalance,
  ) {
    totals.hours += payroll.hoursWorked;
    totals.base += payroll.baseSalary;
    totals.bonus += payroll.bonusesTotal;
    totals.penalty += payroll.penaltiesTotal;
    totals.amount += payroll.netSalary;
    totals.trip += payroll.businessTripTotal;
    totals.payout += payoutsByEmployee[payroll.employeeId] ?? 0;
    totals.remainder +=
        payroll.netSalary - (payoutsByEmployee[payroll.employeeId] ?? 0);
    totals.balance += (aggregatedBalance[payroll.employeeId ?? ''] ?? 0) +
        payroll.netSalary -
        (payoutsByEmployee[payroll.employeeId] ?? 0);
  }

  /// Создаёт ячейки строки в зависимости от типа устройства
  static List<DataCell> _buildRowCells({
    required PayrollCalculation payroll,
    required EmployeeInfo employeeInfo,
    required Map<String, double> payoutsByEmployee,
    required Map<String, double> aggregatedBalance,
    required ThemeData theme,
    required bool isMobile,
    required bool isTablet,
    required bool isDesktop,
  }) {
    final cells = <DataCell>[];

    // Ячейка сотрудника - всегда первая
    cells.add(PayrollTableCellBuilder.buildEmployeeCell(
      index: employeeInfo.index,
      employeeName: employeeInfo.name,
      position: employeeInfo.position,
      theme: theme,
      isMobile: isMobile,
    ));

    if (isDesktop) {
      cells.addAll(_buildDesktopCells(
          payroll, payoutsByEmployee, aggregatedBalance, theme));
    } else if (isTablet) {
      cells.addAll(_buildTabletCells(
          payroll, payoutsByEmployee, aggregatedBalance, theme, isMobile));
    } else {
      cells.addAll(_buildMobileCells(
          payroll, payoutsByEmployee, aggregatedBalance, theme));
    }

    return cells;
  }

  /// Создаёт ячейки для десктопа (все колонки)
  static List<DataCell> _buildDesktopCells(
    PayrollCalculation payroll,
    Map<String, double> payoutsByEmployee,
    Map<String, double> aggregatedBalance,
    ThemeData theme,
  ) {
    return [
      PayrollTableCellBuilder.buildHoursCell(payroll.hoursWorked),
      PayrollTableCellBuilder.buildCurrencyCell(payroll.hourlyRate),
      PayrollTableCellBuilder.buildCurrencyCell(payroll.baseSalary),
      PayrollTableCellBuilder.buildBonusCell(payroll.bonusesTotal, theme),
      PayrollTableCellBuilder.buildPenaltyCell(payroll.penaltiesTotal, theme),
      PayrollTableCellBuilder.buildCurrencyCell(payroll.businessTripTotal),
      PayrollTableCellBuilder.buildNetSalaryCell(payroll.netSalary, theme),
      PayrollTableCellBuilder.buildPayoutCell(
          payoutsByEmployee[payroll.employeeId], theme),
      PayrollTableCellBuilder.buildRemainderCell(
          payroll.netSalary - (payoutsByEmployee[payroll.employeeId] ?? 0),
          theme),
      PayrollTableCellBuilder.buildBalanceCell(
          aggregatedBalance[payroll.employeeId ?? ''] ?? 0, theme),
    ];
  }

  /// Создаёт ячейки для планшета (сокращённый набор)
  static List<DataCell> _buildTabletCells(
    PayrollCalculation payroll,
    Map<String, double> payoutsByEmployee,
    Map<String, double> aggregatedBalance,
    ThemeData theme,
    bool isMobile,
  ) {
    final cells = [
      PayrollTableCellBuilder.buildHoursCell(payroll.hoursWorked),
      PayrollTableCellBuilder.buildCurrencyCell(payroll.baseSalary),
    ];

    if (!isMobile) {
      cells.add(
          PayrollTableCellBuilder.buildBonusCell(payroll.bonusesTotal, theme));
    }

    cells.addAll([
      PayrollTableCellBuilder.buildCurrencyCell(payroll.businessTripTotal),
      PayrollTableCellBuilder.buildNetSalaryCell(payroll.netSalary, theme),
      PayrollTableCellBuilder.buildPayoutCell(
          payoutsByEmployee[payroll.employeeId], theme),
      PayrollTableCellBuilder.buildRemainderCell(
          payroll.netSalary - (payoutsByEmployee[payroll.employeeId] ?? 0),
          theme),
      PayrollTableCellBuilder.buildBalanceCell(
          aggregatedBalance[payroll.employeeId ?? ''] ?? 0, theme),
    ]);

    return cells;
  }

  /// Создаёт ячейки для мобильного (минимальный набор)
  static List<DataCell> _buildMobileCells(
    PayrollCalculation payroll,
    Map<String, double> payoutsByEmployee,
    Map<String, double> aggregatedBalance,
    ThemeData theme,
  ) {
    return [
      PayrollTableCellBuilder.buildHoursCell(payroll.hoursWorked),
      PayrollTableCellBuilder.buildCurrencyCell(payroll.businessTripTotal),
      PayrollTableCellBuilder.buildNetSalaryCell(payroll.netSalary, theme),
      PayrollTableCellBuilder.buildPayoutCell(
          payoutsByEmployee[payroll.employeeId], theme),
      PayrollTableCellBuilder.buildRemainderCell(
          payroll.netSalary - (payoutsByEmployee[payroll.employeeId] ?? 0),
          theme),
      PayrollTableCellBuilder.buildBalanceCell(
          aggregatedBalance[payroll.employeeId ?? ''] ?? 0, theme),
    ];
  }

  /// Создаёт итоговую строку
  static DataRow _buildTotalRow(
    PayrollTotals totals,
    ThemeData theme,
    bool isMobile,
    bool isTablet,
    bool isDesktop,
    Map<String?, List<PayrollCalculation>> groupedPayrolls,
    Map<String, double> aggregatedBalance,
  ) {
    final totalCells = <DataCell>[];

    // Ячейка "ИТОГО"
    totalCells.add(DataCell(Row(
      children: [
        const SizedBox(width: 32),
        Text(
          'ИТОГО',
          style:
              theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    )));

    if (isDesktop) {
      totalCells.addAll(_buildDesktopTotalCells(
          totals, theme, groupedPayrolls, aggregatedBalance));
    } else if (isTablet) {
      totalCells.addAll(_buildTabletTotalCells(
          totals, theme, isMobile, groupedPayrolls, aggregatedBalance));
    } else {
      totalCells.addAll(_buildMobileTotalCells(
          totals, theme, groupedPayrolls, aggregatedBalance));
    }

    return DataRow(cells: totalCells);
  }

  /// Создаёт итоговые ячейки для десктопа
  static List<DataCell> _buildDesktopTotalCells(
    PayrollTotals totals,
    ThemeData theme,
    Map<String?, List<PayrollCalculation>> groupedPayrolls,
    Map<String, double> aggregatedBalance,
  ) {
    final totalBalance = groupedPayrolls.keys
        .where((id) => id != null)
        .map((id) => aggregatedBalance[id ?? ''] ?? 0)
        .fold<double>(0, (sum, b) => sum + b);

    return [
      PayrollTableCellBuilder.buildHoursCell(totals.hours),
      const DataCell(Text('')), // Ставка - итог не нужен
      PayrollTableCellBuilder.buildCurrencyCell(totals.base,
          fontWeight: FontWeight.bold),
      PayrollTableCellBuilder.buildBonusCell(totals.bonus, theme),
      PayrollTableCellBuilder.buildPenaltyCell(totals.penalty, theme),
      PayrollTableCellBuilder.buildCurrencyCell(totals.trip,
          fontWeight: FontWeight.bold),
      PayrollTableCellBuilder.buildTotalCell(totals.amount, theme),
      PayrollTableCellBuilder.buildTotalCell(totals.payout, theme,
          backgroundColor: Colors.blue[50]),
      PayrollTableCellBuilder.buildRemainderCell(totals.remainder, theme),
      PayrollTableCellBuilder.buildTotalBalanceCell(totalBalance, theme),
    ];
  }

  /// Создаёт итоговые ячейки для планшета
  static List<DataCell> _buildTabletTotalCells(
    PayrollTotals totals,
    ThemeData theme,
    bool isMobile,
    Map<String?, List<PayrollCalculation>> groupedPayrolls,
    Map<String, double> aggregatedBalance,
  ) {
    final totalBalance = groupedPayrolls.keys
        .where((id) => id != null)
        .map((id) => aggregatedBalance[id ?? ''] ?? 0)
        .fold<double>(0, (sum, b) => sum + b);

    final cells = [
      PayrollTableCellBuilder.buildHoursCell(totals.hours),
      PayrollTableCellBuilder.buildCurrencyCell(totals.base,
          fontWeight: FontWeight.bold),
    ];

    if (!isMobile) {
      cells.add(PayrollTableCellBuilder.buildBonusCell(totals.bonus, theme));
    }

    cells.addAll([
      PayrollTableCellBuilder.buildCurrencyCell(totals.trip,
          fontWeight: FontWeight.bold),
      PayrollTableCellBuilder.buildTotalCell(totals.amount, theme),
      PayrollTableCellBuilder.buildTotalCell(totals.payout, theme,
          backgroundColor: Colors.blue[50]),
      PayrollTableCellBuilder.buildRemainderCell(totals.remainder, theme),
      PayrollTableCellBuilder.buildTotalBalanceCell(totalBalance, theme),
    ]);

    return cells;
  }

  /// Создаёт итоговые ячейки для мобильного
  static List<DataCell> _buildMobileTotalCells(
    PayrollTotals totals,
    ThemeData theme,
    Map<String?, List<PayrollCalculation>> groupedPayrolls,
    Map<String, double> aggregatedBalance,
  ) {
    final totalBalance = groupedPayrolls.keys
        .where((id) => id != null)
        .map((id) => aggregatedBalance[id ?? ''] ?? 0)
        .fold<double>(0, (sum, b) => sum + b);

    return [
      PayrollTableCellBuilder.buildHoursCell(totals.hours),
      PayrollTableCellBuilder.buildCurrencyCell(totals.trip,
          fontWeight: FontWeight.bold),
      PayrollTableCellBuilder.buildTotalCell(totals.amount, theme),
      PayrollTableCellBuilder.buildTotalCell(totals.payout, theme,
          backgroundColor: Colors.blue[50]),
      PayrollTableCellBuilder.buildRemainderCell(totals.remainder, theme),
      PayrollTableCellBuilder.buildTotalBalanceCell(totalBalance, theme),
    ];
  }
}

/// Информация о сотруднике для отображения в строке таблицы ФОТ.
///
/// Используется для передачи ФИО, должности и порядкового номера сотрудника
/// при построении строк таблицы расчёта фонда оплаты труда.
class EmployeeInfo {
  /// Полное имя сотрудника (ФИО), отображаемое в таблице.
  final String name;

  /// Должность сотрудника на момент расчёта (может быть пустой строкой, если не указана).
  final String position;

  /// Порядковый номер сотрудника в таблице (используется для индексации и сортировки).
  final int index;

  /// Конструктор [EmployeeInfo].
  ///
  /// [name] — ФИО сотрудника.
  /// [position] — должность сотрудника.
  /// [index] — порядковый номер сотрудника в таблице.
  const EmployeeInfo({
    required this.name,
    required this.position,
    required this.index,
  });
}

/// Класс для хранения агрегированных итогов по всем строкам таблицы ФОТ.
///
/// Используется для вычисления и отображения суммарных значений по ключевым метрикам:
/// отработанные часы, базовая сумма, премии, штрафы, суточные, выплаты, баланс.
class PayrollTotals {
  /// Суммарное количество отработанных часов по всем сотрудникам.
  double hours = 0;

  /// Суммарная базовая сумма начислений (без премий, штрафов и суточных).
  double base = 0;

  /// Суммарная сумма премий по всем сотрудникам.
  double bonus = 0;

  /// Суммарная сумма штрафов по всем сотрудникам.
  double penalty = 0;

  /// Суммарная сумма к выплате (netSalary) по всем сотрудникам.
  double amount = 0;

  /// Суммарная сумма суточных выплат по всем сотрудникам.
  double trip = 0;

  /// Суммарная сумма фактических выплат по всем сотрудникам.
  double payout = 0;

  /// Суммарный остаток (к выплате минус выплачено за текущий месяц) по всем сотрудникам.
  double remainder = 0;

  /// Суммарный баланс (начислено минус выплачено) по всем сотрудникам.
  double balance = 0;
}
