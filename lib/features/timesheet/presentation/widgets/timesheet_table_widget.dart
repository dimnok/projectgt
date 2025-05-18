import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/timesheet_entry.dart';

/// Виджет для отображения табличных данных по часам сотрудников.
///
/// Поддерживает группировку по сотрудникам или по датам.
class TimesheetTableWidget extends StatelessWidget {
  /// Список записей табеля.
  final List<TimesheetEntry> entries;
  
  /// Флаг группировки по сотрудникам.
  final bool isGroupedByEmployee;
  
  /// Формат даты для отображения.
  final DateFormat _dateFormat = DateFormat('dd.MM.yyyy');

  /// Создаёт виджет таблицы для отображения данных табеля.
  TimesheetTableWidget({
    super.key,
    required this.entries,
    this.isGroupedByEmployee = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Если нет данных, показываем заглушку
    if (entries.isEmpty) {
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
    
    return isGroupedByEmployee
        ? _buildEmployeeGroupedTable(context)
        : _buildDateGroupedTable(context);
  }
  
  /// Строит таблицу с группировкой по сотрудникам.
  Widget _buildEmployeeGroupedTable(BuildContext context) {
    final theme = Theme.of(context);
    
    // Группируем записи по сотрудникам
    final Map<String, List<TimesheetEntry>> groupedEntries = {};
    for (final entry in entries) {
      if (!groupedEntries.containsKey(entry.employeeId)) {
        groupedEntries[entry.employeeId] = [];
      }
      groupedEntries[entry.employeeId]!.add(entry);
    }
    
    return Scrollbar(
      child: SingleChildScrollView(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingTextStyle: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            dataTextStyle: theme.textTheme.bodyMedium,
            headingRowColor: WidgetStateProperty.resolveWith<Color>((states) {
              return theme.colorScheme.surface;
            }),
            border: TableBorder.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
              width: 1,
            ),
            columnSpacing: 24,
            columns: const [
              DataColumn(label: Text('Сотрудник')),
              DataColumn(label: Text('Объект')),
              DataColumn(label: Text('Дата')),
              DataColumn(label: Text('Часы'), numeric: true),
              DataColumn(label: Text('Комментарий')),
            ],
            rows: _buildEmployeeGroupedRows(groupedEntries, theme),
          ),
        ),
      ),
    );
  }
  
  /// Строит строки таблицы для группировки по сотрудникам.
  List<DataRow> _buildEmployeeGroupedRows(
    Map<String, List<TimesheetEntry>> groupedEntries,
    ThemeData theme,
  ) {
    final rows = <DataRow>[];
    
    groupedEntries.forEach((employeeId, employeeEntries) {
      // Сортируем записи по дате
      employeeEntries.sort((a, b) => a.date.compareTo(b.date));
      
      // Основные записи сотрудника
      for (int i = 0; i < employeeEntries.length; i++) {
        final entry = employeeEntries[i];
        rows.add(DataRow(
          cells: [
            // Имя сотрудника (только в первой строке)
            DataCell(i == 0 
              ? Text(entry.employeeName ?? 'Сотрудник #${entry.employeeId}',
                  style: const TextStyle(fontWeight: FontWeight.bold))
              : const Text('')),
            // Объект
            DataCell(Text(entry.objectName ?? 'Объект #${entry.objectId}')),
            // Дата
            DataCell(Text(_dateFormat.format(entry.date))),
            // Часы
            DataCell(Text('${entry.hours}')),
            // Комментарий
            DataCell(Text(entry.comment ?? '')),
          ],
        ));
      }
      
      // Итоговая строка для сотрудника
      rows.add(DataRow(
        color: WidgetStateProperty.all(
          theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)),
        cells: const [
          DataCell(Text('Итого:', style: TextStyle(fontWeight: FontWeight.bold))),
          DataCell(Text('')),
          DataCell(Text('')),
          DataCell(Text('')),
          DataCell(Text('')),
        ],
      ));
      
      // Разделитель между сотрудниками
      rows.add(const DataRow(cells: [
        DataCell(Text('')),
        DataCell(Text('')),
        DataCell(Text('')),
        DataCell(Text('')),
        DataCell(Text('')),
      ]));
    });
    
    return rows;
  }
  
  /// Строит таблицу с группировкой по датам.
  Widget _buildDateGroupedTable(BuildContext context) {
    final theme = Theme.of(context);
    
    // Группируем записи по датам
    final Map<String, List<TimesheetEntry>> groupedEntries = {};
    for (final entry in entries) {
      final dateKey = _dateFormat.format(entry.date);
      if (!groupedEntries.containsKey(dateKey)) {
        groupedEntries[dateKey] = [];
      }
      groupedEntries[dateKey]!.add(entry);
    }
    
    return Scrollbar(
      child: SingleChildScrollView(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingTextStyle: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            dataTextStyle: theme.textTheme.bodyMedium,
            headingRowColor: WidgetStateProperty.resolveWith<Color>((states) {
              return theme.colorScheme.surface;
            }),
            border: TableBorder.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
              width: 1,
            ),
            columnSpacing: 24,
            columns: const [
              DataColumn(label: Text('Дата')),
              DataColumn(label: Text('Сотрудник')),
              DataColumn(label: Text('Объект')),
              DataColumn(label: Text('Часы'), numeric: true),
              DataColumn(label: Text('Комментарий')),
            ],
            rows: _buildDateGroupedRows(groupedEntries, theme),
          ),
        ),
      ),
    );
  }
  
  /// Строит строки таблицы для группировки по датам.
  List<DataRow> _buildDateGroupedRows(
    Map<String, List<TimesheetEntry>> groupedEntries,
    ThemeData theme,
  ) {
    final rows = <DataRow>[];
    
    // Сортируем даты
    final sortedDates = groupedEntries.keys.toList()
      ..sort((a, b) => _dateFormat.parse(a).compareTo(_dateFormat.parse(b)));
    
    for (final dateKey in sortedDates) {
      final dateEntries = groupedEntries[dateKey]!;
      
      // Сортируем записи по имени сотрудника
      dateEntries.sort((a, b) => (a.employeeName ?? '')
          .compareTo(b.employeeName ?? ''));
      
      // Основные записи дня
      for (int i = 0; i < dateEntries.length; i++) {
        final entry = dateEntries[i];
        rows.add(DataRow(
          cells: [
            // Дата (только в первой строке)
            DataCell(i == 0 
              ? Text(dateKey, style: const TextStyle(fontWeight: FontWeight.bold))
              : const Text('')),
            // Сотрудник
            DataCell(Text(entry.employeeName ?? 'Сотрудник #${entry.employeeId}')),
            // Объект
            DataCell(Text(entry.objectName ?? 'Объект #${entry.objectId}')),
            // Часы
            DataCell(Text('${entry.hours}')),
            // Комментарий
            DataCell(Text(entry.comment ?? '')),
          ],
        ));
      }
      
      // Итоговая строка за день
      rows.add(DataRow(
        color: WidgetStateProperty.all(
          theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)),
        cells: const [
          DataCell(Text('Итого:', style: TextStyle(fontWeight: FontWeight.bold))),
          DataCell(Text('')),
          DataCell(Text('')),
          DataCell(Text('')),
          DataCell(Text('')),
        ],
      ));
      
      // Разделитель между датами
      rows.add(const DataRow(cells: [
        DataCell(Text('')),
        DataCell(Text('')),
        DataCell(Text('')),
        DataCell(Text('')),
        DataCell(Text('')),
      ]));
    }
    
    return rows;
  }
} 