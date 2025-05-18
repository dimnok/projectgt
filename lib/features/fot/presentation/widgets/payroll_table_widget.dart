import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';
import '../../domain/entities/payroll_calculation.dart';
import '../providers/payroll_filter_provider.dart';
import '../../../../presentation/state/employee_state.dart';
import 'package:projectgt/features/timesheet/presentation/providers/timesheet_provider.dart';
import 'package:projectgt/core/utils/responsive_utils.dart';

/// Виджет для отображения табличных данных расчётов ФОТ.
///
/// Поддерживает группировку по сотрудникам или объектам с детальной стилизацией.
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
  
  /// Форматтер чисел для отображения сумм.
  final NumberFormat _numberFormat = NumberFormat.currency(
    locale: 'ru_RU',
    symbol: '₽',
    decimalDigits: 2,
  );
  
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
    // Получаем только записи табеля (без лишних полей)
    final timesheetEntries = ref.watch(timesheetProvider.select((s) => s.entries));
    // Получаем payrolls из пропса
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
          child: widget.isGroupedByEmployee
              ? _buildEmployeeGroupedTable(context, employees, timesheetEntries)
              : _buildEmployeeGroupedTable(context, employees, timesheetEntries),
        ),
      ],
    );
  }
  
  /// Строит таблицу с группировкой по сотрудникам с полным соответствием стилю табеля.
  Widget _buildEmployeeGroupedTable(BuildContext context, List<dynamic> employees, List<dynamic> timesheetEntries) {
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
      print('Ошибка при группировке данных ФОТ: $e');
    }
    
    // Сортировка сотрудников по алфавиту (по ФИО)
    final sortedEmployeeKeys = groupedPayrolls.keys.toList()
      ..sort((a, b) {
        if (a == null) return 1;
        if (b == null) return -1;
        final empA = employees.firstWhereOrNull((emp) => emp.id == a);
        final empB = employees.firstWhereOrNull((emp) => emp.id == b);
        final nameA = empA != null ? ('${empA.lastName} ${empA.firstName} ${empA.middleName ?? ''}').trim().toLowerCase() : '';
        final nameB = empB != null ? ('${empB.lastName} ${empB.firstName} ${empB.middleName ?? ''}').trim().toLowerCase() : '';
        return nameA.compareTo(nameB);
      });
    
    // Используем LayoutBuilder для определения доступной ширины
    return LayoutBuilder(
      builder: (context, constraints) {
        // Определяем, является ли устройство мобильным, планшетом или десктопом
        final isMobile = ResponsiveUtils.isMobile(context);
        final isTablet = ResponsiveUtils.isTablet(context);
        final isDesktop = ResponsiveUtils.isDesktop(context);
        
        // Определяем минимальную ширину для таблицы на основе типа устройства
        final double minTableWidth = isDesktop ? 1200 : isTablet ? 900 : constraints.maxWidth;
        
        // Определяем, нужно ли использовать горизонтальный скролл
        final needsHorizontalScroll = minTableWidth > constraints.maxWidth;
        
        // Определяем колонки таблицы на основе типа устройства
        final columns = _buildAdaptiveColumns(isDesktop, isTablet, isMobile);
        
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
                    minWidth: needsHorizontalScroll ? minTableWidth : constraints.maxWidth,
                  ),
                  child: DataTable(
                    // Стилизация заголовка - точно как в табеле
                    headingTextStyle: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    dataTextStyle: theme.textTheme.bodyMedium,
                    headingRowColor: WidgetStateProperty.resolveWith<Color>((states) {
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
                      mobile: 12,
                      tablet: 16,
                      desktop: 24,
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
                    rows: _buildEmployeeGroupedRows(
                      groupedPayrolls, 
                      theme, 
                      employees, 
                      timesheetEntries,
                      isMobile,
                      isTablet,
                      isDesktop,
                    ),
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
  List<DataColumn> _buildAdaptiveColumns(bool isDesktop, bool isTablet, bool isMobile) {
    // Базовые колонки, которые показываем на всех устройствах
    final List<DataColumn> columns = [
      // Колонка для сотрудника с увеличенной шириной
      DataColumn(
        label: Container(
          constraints: BoxConstraints(
            minWidth: isDesktop ? 200 : isTablet ? 150 : 120,
          ),
          child: const Text('Сотрудник'),
        ),
      ),
    ];
    
    // Добавляем колонки в зависимости от размера экрана
    if (isDesktop) {
      // На десктопе показываем все колонки
      columns.addAll([
        const DataColumn(label: Text('Ставка'), numeric: true),
        const DataColumn(label: Text('Часы'), numeric: true),
        const DataColumn(label: Text('Базовая сумма'), numeric: true),
        const DataColumn(label: Text('Премии'), numeric: true),
        const DataColumn(label: Text('Штрафы'), numeric: true),
        const DataColumn(label: Text('Командировочные'), numeric: true),
      ]);
    } else if (isTablet) {
      // На планшете убираем некоторые колонки
      columns.addAll([
        const DataColumn(label: Text('Часы'), numeric: true),
        const DataColumn(label: Text('Базовая сумма'), numeric: true),
        if (!isMobile) const DataColumn(label: Text('Премии'), numeric: true),
        const DataColumn(label: Text('Командировочные'), numeric: true),
      ]);
    } else {
      // На мобильном оставляем только самые важные
      columns.addAll([
        const DataColumn(label: Text('Часы'), numeric: true),
        const DataColumn(label: Text('Командировочные'), numeric: true),
      ]);
    }
    
    // Итоговая колонка всегда присутствует
    columns.add(
      DataColumn(
        label: Container(
          constraints: BoxConstraints(
            minWidth: isDesktop ? 120 : isTablet ? 100 : 80,
          ),
          child: const Text('К выплате', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        numeric: true,
      ),
    );
    
    return columns;
  }
  
  /// Строит строки таблицы для группировки по сотрудникам.
  List<DataRow> _buildEmployeeGroupedRows(
    Map<String?, List<PayrollCalculation>> groupedPayrolls,
    ThemeData theme,
    List<dynamic> employees,
    List<dynamic> timesheetEntries,
    bool isMobile,
    bool isTablet,
    bool isDesktop,
  ) {
    final rows = <DataRow>[];
    
    // Для итога по всей таблице
    double totalHours = 0;
    double totalBase = 0;
    double totalBonus = 0;
    double totalPenalty = 0;
    double totalAmount = 0;
    double totalTrip = 0;
    
    // Счетчик сотрудников для нумерации
    int employeeCounter = 1;
    
    try {
      // Создаем отображение employeeId -> position из записей табеля для должностей
      final employeePositions = <String, String>{};
      for (final entry in timesheetEntries) {
        if (entry.employeeId != null && entry.employeePosition != null && entry.employeePosition!.isNotEmpty) {
          employeePositions[entry.employeeId] = entry.employeePosition!;
        }
      }
      
      // Сортировка сотрудников по алфавиту (по ФИО)
      final sortedEmployeeKeys = groupedPayrolls.keys.toList()
        ..sort((a, b) {
          if (a == null) return 1;
          if (b == null) return -1;
          final empA = employees.firstWhereOrNull((emp) => emp.id == a);
          final empB = employees.firstWhereOrNull((emp) => emp.id == b);
          final nameA = empA != null ? ('${empA.lastName} ${empA.firstName} ${empA.middleName ?? ''}').trim().toLowerCase() : '';
          final nameB = empB != null ? ('${empB.lastName} ${empB.firstName} ${empB.middleName ?? ''}').trim().toLowerCase() : '';
          return nameA.compareTo(nameB);
        });
      
      for (final employeeId in sortedEmployeeKeys) {
        final employeePayrolls = groupedPayrolls[employeeId]!;
        // Ищем сотрудника в списке сотрудников
        dynamic employee;
        String employeeName = 'Неизвестный сотрудник';
        String employeePosition = '';
        
        if (employeeId != null && employeeId != 'unknown') {
          // Находим сотрудника в списке
          employee = employees.firstWhereOrNull((emp) => emp.id == employeeId);
          if (employee != null) {
            employeeName = '${employee.lastName} ${employee.firstName} ${employee.middleName ?? ''}';
            
            // Пробуем получить должность из данных сотрудника
            if (employee.position != null && employee.position.isNotEmpty) {
              employeePosition = employee.position;
            } 
            // Если нет, пробуем получить из записей табеля
            else if (employeePositions.containsKey(employeeId)) {
              employeePosition = employeePositions[employeeId]!;
            }
          } else {
            employeeName = 'Сотрудник #$employeeId';
            
            // Пробуем получить должность из записей табеля
            if (employeePositions.containsKey(employeeId)) {
              employeePosition = employeePositions[employeeId]!;
            }
          }
        }
        
        // Суммируем для общего итога по всем сотрудникам
        for (int i = 0; i < employeePayrolls.length; i++) {
          final payroll = employeePayrolls[i];
          
          // Суммируем для общего итога
          totalHours += payroll.hoursWorked;
          totalBase += payroll.baseSalary;
          totalBonus += payroll.bonusesTotal;
          totalPenalty += payroll.penaltiesTotal;
          totalAmount += payroll.netSalary;
          totalTrip += payroll.businessTripTotal;
          
          // Создаем ячейки в зависимости от размера экрана
          final List<DataCell> cells = [];
          
          // Ячейка с данными сотрудника - всегда показывается
          cells.add(
            DataCell(Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (!isMobile) Container(
                  width: 24,
                  height: 24,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      employeeCounter.toString(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        employeeName.trim(),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (employeePosition.isNotEmpty && !isMobile)
                        Text(
                          employeePosition,
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
              ],
            ))
          );
          
          // Добавляем ячейки на основе типа устройства
          if (isDesktop) {
            // Десктоп - добавляем все колонки
            cells.addAll([
              // Ставка
              DataCell(Text(_numberFormat.format(payroll.hourlyRate))),
              // Отработанные часы
              DataCell(Text(
                payroll.hoursWorked % 1 == 0
                    ? payroll.hoursWorked.toInt().toString()
                    : payroll.hoursWorked.toStringAsFixed(1),
              )),
              // Базовая сумма
              DataCell(Text(_numberFormat.format(payroll.baseSalary))),
              // Премии
              DataCell(
                Text(
                  payroll.bonusesTotal > 0 
                      ? _numberFormat.format(payroll.bonusesTotal) 
                      : '—',
                  style: payroll.bonusesTotal > 0
                      ? theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.green[700],
                          fontWeight: FontWeight.w500,
                        )
                      : null,
                ),
              ),
              // Штрафы
              DataCell(
                Text(
                  payroll.penaltiesTotal > 0 
                      ? _numberFormat.format(payroll.penaltiesTotal) 
                      : '—',
                  style: payroll.penaltiesTotal > 0
                      ? theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.red[700],
                          fontWeight: FontWeight.w500,
                        )
                      : null,
                ),
              ),
              // Командировочные
              DataCell(Text(
                _numberFormat.format(payroll.businessTripTotal),
                style: theme.textTheme.bodyMedium,
              )),
            ]);
          } else if (isTablet) {
            // Планшет - убираем некоторые колонки
            cells.addAll([
              // Отработанные часы
              DataCell(Text(
                payroll.hoursWorked % 1 == 0
                    ? payroll.hoursWorked.toInt().toString()
                    : payroll.hoursWorked.toStringAsFixed(1),
              )),
              // Базовая сумма
              DataCell(Text(_numberFormat.format(payroll.baseSalary))),
              // Премии (только если не мобильное устройство)
              if (!isMobile) DataCell(
                Text(
                  payroll.bonusesTotal > 0 
                      ? _numberFormat.format(payroll.bonusesTotal) 
                      : '—',
                  style: payroll.bonusesTotal > 0
                      ? theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.green[700],
                          fontWeight: FontWeight.w500,
                        )
                      : null,
                ),
              ),
              // Командировочные
              DataCell(Text(
                _numberFormat.format(payroll.businessTripTotal),
                style: theme.textTheme.bodyMedium,
              )),
            ]);
          } else {
            // Мобильная версия - минимум колонок
            cells.addAll([
              // Отработанные часы
              DataCell(Text(
                payroll.hoursWorked % 1 == 0
                    ? payroll.hoursWorked.toInt().toString()
                    : payroll.hoursWorked.toStringAsFixed(1),
              )),
              // Командировочные
              DataCell(Text(
                _numberFormat.format(payroll.businessTripTotal),
                style: theme.textTheme.bodyMedium,
              )),
            ]);
          }
          
          // К выплате (итоговая сумма) - всегда показывается
          cells.add(
            DataCell(
              Text(
                _numberFormat.format(payroll.netSalary),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          );
          
          rows.add(DataRow(cells: cells));
        }
        
        employeeCounter++;
      }
      
      // Добавляем строку итога внизу таблицы с адаптивным количеством ячеек
      final List<DataCell> totalCells = [];
      
      // Первая ячейка - "ИТОГО" - всегда показывается
      totalCells.add(
        DataCell(Row(
          children: [
            const SizedBox(width: 32),
            Text(
              'ИТОГО',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ))
      );
      
      // Добавляем ячейки итогов по размеру экрана
      if (isDesktop) {
        // Для ставки не показываем итог
        totalCells.add(const DataCell(Text('')));
        
        // Итого часов
        totalCells.add(
          DataCell(
            Text(
              totalHours % 1 == 0
                  ? totalHours.toInt().toString()
                  : totalHours.toStringAsFixed(1),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
        
        // Итого базовая сумма
        totalCells.add(
          DataCell(
            Text(
              _numberFormat.format(totalBase),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
        
        // Итого премии
        totalCells.add(
          DataCell(
            Text(
              totalBonus > 0 ? _numberFormat.format(totalBonus) : '—',
              style: totalBonus > 0
                  ? theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.green[700],
                      fontWeight: FontWeight.bold,
                    )
                  : theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
            ),
          ),
        );
        
        // Итого штрафы
        totalCells.add(
          DataCell(
            Text(
              totalPenalty > 0 ? _numberFormat.format(totalPenalty) : '—',
              style: totalPenalty > 0
                  ? theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.red[700],
                      fontWeight: FontWeight.bold,
                    )
                  : theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
            ),
          ),
        );
        
        // Итого командировочные
        totalCells.add(
          DataCell(
            Text(
              _numberFormat.format(totalTrip),
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
        );
      } else if (isTablet) {
        // Итого часов
        totalCells.add(
          DataCell(
            Text(
              totalHours % 1 == 0
                  ? totalHours.toInt().toString()
                  : totalHours.toStringAsFixed(1),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
        
        // Итого базовая сумма
        totalCells.add(
          DataCell(
            Text(
              _numberFormat.format(totalBase),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
        
        // Итого премии (только если не мобильное)
        if (!isMobile) {
          totalCells.add(
            DataCell(
              Text(
                totalBonus > 0 ? _numberFormat.format(totalBonus) : '—',
                style: totalBonus > 0
                    ? theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.green[700],
                        fontWeight: FontWeight.bold,
                      )
                    : theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
              ),
            ),
          );
        }
        
        // Итого командировочные
        totalCells.add(
          DataCell(
            Text(
              _numberFormat.format(totalTrip),
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
        );
      } else {
        // Итого часов (мобильная версия)
        totalCells.add(
          DataCell(
            Text(
              totalHours % 1 == 0
                  ? totalHours.toInt().toString()
                  : totalHours.toStringAsFixed(1),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
        
        // Итого командировочные
        totalCells.add(
          DataCell(
            Text(
              _numberFormat.format(totalTrip),
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
        );
      }
      
      // Итого к выплате - всегда показывается
      totalCells.add(
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              _numberFormat.format(totalAmount),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ),
      );
      
      rows.add(DataRow(cells: totalCells));
    } catch (e) {
      print('Ошибка при построении строк таблицы ФОТ: $e');
      
      // Добавляем строку с ошибкой
      final errorCells = <DataCell>[];
      errorCells.add(
        DataCell(Text(
          'Ошибка отображения данных: $e',
          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.red),
        )),
      );
      
      // Заполняем пустыми ячейками в зависимости от типа устройства
      int totalColumns = isDesktop ? 7 : isTablet ? (isMobile ? 3 : 4) : 2;
      for (int i = 1; i < totalColumns; i++) {
        errorCells.add(const DataCell(Text('')));
      }
      
      rows.add(DataRow(cells: errorCells));
    }
    
    return rows;
  }
} 