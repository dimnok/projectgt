import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:projectgt/features/timesheet/domain/entities/timesheet_entry.dart';
import 'package:projectgt/presentation/widgets/cupertino_dialog_widget.dart';

/// Виджет для отображения табеля рабочего времени в календарном виде.
class TimesheetCalendarView extends StatefulWidget {
  /// Список записей табеля
  final List<TimesheetEntry> entries;
  
  /// Начальная дата диапазона
  final DateTime startDate;
  
  /// Конечная дата диапазона
  final DateTime endDate;
  
  /// Создает виджет календарного представления табеля.
  const TimesheetCalendarView({
    super.key,
    required this.entries,
    required this.startDate,
    required this.endDate,
  });

  @override
  State<TimesheetCalendarView> createState() => _TimesheetCalendarViewState();
}

class _TimesheetCalendarViewState extends State<TimesheetCalendarView> {
  /// Контроллер прокрутки для дат (горизонтальный)
  late ScrollController _dateScrollController;
  
  /// Контроллер прокрутки для сотрудников (вертикальный)
  late ScrollController _employeeScrollController;
  
  /// Список уникальных сотрудников
  List<String> _uniqueEmployees = [];
  
  /// Список дат в диапазоне
  List<DateTime> _daysInRange = [];
  
  @override
  void initState() {
    super.initState();
    
    // Инициализируем контроллеры прокрутки
    _dateScrollController = ScrollController();
    _employeeScrollController = ScrollController();
    
    // Строим диапазон дат
    _daysInRange = [];
    DateTime currentDate = widget.startDate;
    while (currentDate.isBefore(widget.endDate) || currentDate.isAtSameMomentAs(widget.endDate)) {
      _daysInRange.add(currentDate);
      currentDate = currentDate.add(const Duration(days: 1));
    }
    
    // После построения виджета прокрутим к текущему дню
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToToday();
    });
  }
  
  @override
  void dispose() {
    _dateScrollController.dispose();
    _employeeScrollController.dispose();
    super.dispose();
  }
  
  /// Возвращает сокращенное название дня недели
  String _getDayAbbreviation(int weekday) {
    switch (weekday) {
      case 1: return 'пн';
      case 2: return 'вт';
      case 3: return 'ср';
      case 4: return 'чт';
      case 5: return 'пт';
      case 6: return 'сб';
      case 7: return 'вс';
      default: return '';
    }
  }

  /// Обновляет список уникальных сотрудников на основе записей
  void _updateUniqueEmployees() {
    final employeeNames = widget.entries
        .map((e) => e.employeeName)
        .where((name) => name != null)
        .map((name) => name!)
        .toSet()
        .toList();
    employeeNames.sort(); // Сортируем по алфавиту
    _uniqueEmployees = employeeNames;
  }
  
  /// Метод для прокрутки к текущему дню
  void _scrollToToday() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // Находим индекс текущего дня
    final index = _daysInRange.indexWhere((date) => 
      date.year == today.year && date.month == today.month && date.day == today.day);
    
    // Если текущий день есть в диапазоне, прокручиваем к нему
    if (index >= 0) {
      // Рассчитываем положение для прокрутки (с учетом ширины ячейки)
      final offset = (index + 1) * 68.0;  // 60 (ширина) + 8 (отступ)
      
      // Прокручиваем с анимацией
      if (_dateScrollController.hasClients) {
        _dateScrollController.animateTo(
          offset,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  /// Строит основную таблицу календаря
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final headerStyle = theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold);
    
    // Заполняем список уникальных сотрудников
    _updateUniqueEmployees();
    
    // Если нет данных, показываем сообщение
    if (widget.entries.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy,
              size: 64,
              color: null, // цвет задаётся ниже
            ),
            SizedBox(height: 16),
            Text(
              'Нет данных для отображения',
            ),
            SizedBox(height: 8),
            Text(
              'Попробуйте изменить фильтры или выбрать другой период',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    
    // Строим таблицу
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Заголовок и фильтры
        Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Text(
            'Табель ${DateFormat.yMMMM('ru').format(widget.startDate)}',
            style: theme.textTheme.headlineSmall,
          ),
        ),
        
        // Таблица с данными
        Expanded(
          child: SingleChildScrollView(
            controller: _employeeScrollController,
            child: SingleChildScrollView(
              controller: _dateScrollController,
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(
                  Theme.of(context).colorScheme.surface,
                ),
                dataRowColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.2);
                  }
                  return null;
                }),
                headingRowHeight: 60, // Уменьшенная высота заголовка
                dataRowMinHeight: 50, // Минимальная высота строк сотрудников
                dataRowMaxHeight: 50, // Максимальная высота строк сотрудников
                horizontalMargin: 8,
                columnSpacing: 4,
                dividerThickness: 0.5,
                border: TableBorder(
                  horizontalInside: BorderSide(
                    width: 0.5,
                    color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
                  ),
                  verticalInside: BorderSide(
                    width: 0.5,
                    color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                columns: [
                  // Колонка для имени сотрудника
                  DataColumn(
                    label: Container(
                      constraints: const BoxConstraints(minWidth: 240),
                      child: Text('№ Сотрудник', style: headerStyle),
                    ),
                  ),
                  
                  // Колонки для дней месяца
                  ..._daysInRange.map((day) {
                    final isWeekend = day.weekday == DateTime.saturday || day.weekday == DateTime.sunday;
                    final dayColor = isWeekend
                        ? Theme.of(context).colorScheme.error.withValues(alpha: 0.18)
                        : Theme.of(context).colorScheme.surface.withValues(alpha: 0.5);
                    final textColor = isWeekend
                        ? Theme.of(context).colorScheme.error
                        : Theme.of(context).textTheme.bodySmall?.color;
                    return DataColumn(
                      label: Container(
                        constraints: const BoxConstraints(minWidth: 40, maxWidth: 40),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              DateFormat.d().format(day),
                              style: headerStyle?.copyWith(
                                fontSize: 16,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: dayColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _getDayAbbreviation(day.weekday),
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: textColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  
                  // Колонка для итогов по сотруднику
                  DataColumn(
                    label: Container(
                      constraints: const BoxConstraints(minWidth: 64, maxWidth: 64),
                      child: Text('Итого', style: headerStyle),
                    ),
                  ),
                ],
                rows: _buildTableRows(theme),
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  /// Создает строки таблицы
  List<DataRow> _buildTableRows(ThemeData theme) {
    final rows = <DataRow>[];
    
    // Добавляем строки для каждого сотрудника
    for (int i = 0; i < _uniqueEmployees.length; i++) {
      final employeeName = _uniqueEmployees[i];
      
      // Находим записи этого сотрудника
      final employeeEntries = widget.entries.where((entry) => 
        entry.employeeName == employeeName).toList();
      
      // Создаем ячейки для всех дней
      final cells = <DataCell>[];
      
      // Ячейка с именем сотрудника
      cells.add(
        DataCell(
          InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
            },
            child: Container(
              constraints: const BoxConstraints(minWidth: 240),
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${i + 1}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold, 
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          employeeName,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (_getEmployeePosition(employeeName) != null)
                          Text(
                            _getEmployeePosition(employeeName) ?? '',
                            style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      
      // Рассчитываем общую сумму часов сотрудника
      num totalHours = 0;
      
      // Ячейки для каждого дня
      for (final day in _daysInRange) {
        // Находим записи для этого сотрудника и этого дня
        final dayEntries = employeeEntries.where((entry) => 
          entry.date.year == day.year && 
          entry.date.month == day.month && 
          entry.date.day == day.day
        ).toList();
        
        // Суммируем часы за день
        final dayHours = dayEntries.fold<num>(0, (sum, entry) => sum + entry.hours);
        totalHours += dayHours;
        
        // Создаем ячейку для текущего дня и сотрудника
        cells.add(
          DataCell(
            InkWell(
              onTap: () {
                // Если ячейка содержит часы, показываем детали
                if (dayHours > 0) {
                  _showEntryDetails(dayEntries, employeeName, day);
                }
                
                HapticFeedback.selectionClick();
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 40,
                padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Показываем часы, если они есть
                    if (dayHours > 0)
                      Text(
                        dayHours.toString(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      }
      
      // Добавляем ячейку с суммой часов
      cells.add(
        DataCell(
          Container(
            constraints: const BoxConstraints(minWidth: 64, maxWidth: 64),
            padding: const EdgeInsets.symmetric(vertical: 4),
            alignment: Alignment.center,
            child: Text(
              '$totalHours',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      );
      
      // Добавляем строку в таблицу
      rows.add(DataRow(cells: cells));
    }
    
    // Добавляем строку с итогами по дням
    if (_uniqueEmployees.isNotEmpty) {
      final totalCells = <DataCell>[];
      
      // Заголовок строки итогов
      totalCells.add(
        DataCell(
          Container(
            constraints: const BoxConstraints(minWidth: 240),
            padding: const EdgeInsets.symmetric(vertical: 8),
            alignment: Alignment.centerLeft,
            child: const Padding(
              padding: EdgeInsets.only(left: 32),
              child: Text(
                'Итого по дням',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      );
      
      // Итоги по каждому дню
      num grandTotal = 0;
      
      for (final day in _daysInRange) {
        // Находим все записи для этого дня
        final dayEntries = widget.entries.where((entry) => 
          entry.date.year == day.year && 
          entry.date.month == day.month && 
          entry.date.day == day.day
        ).toList();
        
        // Суммируем часы за день
        final dayHours = dayEntries.fold<num>(0, (sum, entry) => sum + entry.hours);
        grandTotal += dayHours;
        
        totalCells.add(
          DataCell(
            Container(
              width: 40,
              padding: const EdgeInsets.symmetric(vertical: 4),
              alignment: Alignment.center,
              child: Text(
                '$dayHours',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        );
      }
      
      // Общий итог
      totalCells.add(
        DataCell(
          Container(
            constraints: const BoxConstraints(minWidth: 64, maxWidth: 64),
            padding: const EdgeInsets.symmetric(vertical: 4),
            alignment: Alignment.center,
            child: Text(
              '$grandTotal',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      );
      
      rows.add(DataRow(cells: totalCells));
    }
    
    return rows;
  }
  
  /// Показывает диалог с детальной информацией о записи
  void _showEntryDetails(List<TimesheetEntry> entries, String employeeName, DateTime day) {
    if (entries.isEmpty) return;
    
    // Создаем виджет содержимого для диалога
    final contentWidget = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 8.0),
          child: Text(
            '', // '$employeeName, ${DateFormat('dd.MM.yyyy').format(day)}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.normal,
            ),
          ),
        ),
        const SizedBox(height: 8),
        ...entries.map((entry) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Объект
                Row(
                  children: [
                    const Text(
                      'Объект:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(entry.objectName ?? 'Н/Д'),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                
                // Часы
                Row(
                  children: [
                    const Text(
                      'Часы:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    Text('${entry.hours}'),
                  ],
                ),
                
                // Комментарий, если есть
                if (entry.comment != null && entry.comment!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  const Text(
                    'Комментарий:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(entry.comment!),
                ],
              ],
            ),
          );
        }),
      ],
    );
    
    // Показываем Cupertino диалог
    CupertinoDialogs.showMessageDialog(
      context: context,
      title: 'Детали записи',
      message: '',  // Сообщение заменяется виджетом контента
      contentWidget: SingleChildScrollView(
        child: contentWidget,
      ),
      buttonText: 'Закрыть',
    );
  }

  String? _getEmployeePosition(String employeeName) {
    // Проверяем, что список записей не пуст
    if (widget.entries.isEmpty) {
      return null;
    }
    
    // Находим первую запись для этого сотрудника
    final entry = widget.entries.firstWhere(
      (entry) => entry.employeeName == employeeName,
      orElse: () => widget.entries.first,
    );
    
    // Возвращаем должность, если она доступна
    return entry.employeePosition;
  }
} 