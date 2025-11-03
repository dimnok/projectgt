import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:projectgt/domain/entities/employee.dart';
import 'package:projectgt/features/timesheet/domain/entities/timesheet_entry.dart';
import 'package:projectgt/presentation/widgets/cupertino_dialog_widget.dart';
import 'package:projectgt/core/di/providers.dart';
import 'employee_attendance_dialog.dart';
import '../providers/timesheet_provider.dart';

/// Виджет для отображения табеля рабочего времени в календарном виде.
///
/// Отображает всех активных сотрудников (статус != 'fired'),
/// а также уволенных сотрудников, у которых есть часы в выбранном периоде.
class TimesheetCalendarView extends ConsumerStatefulWidget {
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
  ConsumerState<TimesheetCalendarView> createState() =>
      _TimesheetCalendarViewState();
}

class _TimesheetCalendarViewState extends ConsumerState<TimesheetCalendarView> {
  /// Список дат в диапазоне
  List<DateTime> _daysInRange = [];

  /// Список всех сотрудников для отображения
  List<Employee> _allEmployees = [];

  @override
  void initState() {
    super.initState();
    _buildDateRange();
    _loadEmployees();
  }

  @override
  void didUpdateWidget(TimesheetCalendarView oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Если изменились даты, пересчитываем диапазон
    if (oldWidget.startDate != widget.startDate ||
        oldWidget.endDate != widget.endDate) {
      _buildDateRange();
    }

    // Если изменились записи, перезагружаем список сотрудников
    // Используем сравнение по количеству и первым элементам для оптимизации
    if (oldWidget.entries.length != widget.entries.length ||
        (widget.entries.isNotEmpty &&
            oldWidget.entries.isNotEmpty &&
            oldWidget.entries.first.employeeId !=
                widget.entries.first.employeeId)) {
      _loadEmployees();
    }
  }

  /// Загружает список всех активных сотрудников и уволенных с часами
  /// с учетом фильтров по должностям
  Future<void> _loadEmployees() async {
    final employeeRepository = ref.read(employeeRepositoryProvider);
    final timesheetState = ref.read(timesheetProvider);
    final allEmployees = await employeeRepository.getEmployees();

    // Находим ID сотрудников, у которых есть часы в текущих записях
    final employeeIdsWithHours =
        widget.entries.map((entry) => entry.employeeId).toSet();

    // Применяем фильтр по должностям (если установлен)
    final selectedPositions = timesheetState.selectedPositions;

    // Фильтруем: активные сотрудники + уволенные с часами
    var filteredEmployees = allEmployees.where((e) {
      // Если установлен фильтр по должностям, применяем его
      if (selectedPositions != null &&
          selectedPositions.isNotEmpty &&
          (e.position == null ||
              e.position!.isEmpty ||
              !selectedPositions.contains(e.position))) {
        return false; // Пропускаем сотрудников, не соответствующих фильтру
      }

      if (e.status != EmployeeStatus.fired) {
        return true; // Все активные
      }
      return employeeIdsWithHours.contains(e.id); // Уволенные с часами
    }).toList();

    // Сортируем по ФИО
    filteredEmployees.sort((a, b) {
      final nameA = '${a.lastName} ${a.firstName} ${a.middleName ?? ''}';
      final nameB = '${b.lastName} ${b.firstName} ${b.middleName ?? ''}';
      return nameA.compareTo(nameB);
    });

    setState(() {
      _allEmployees = filteredEmployees;
    });
  }

  /// Строит диапазон дат между startDate и endDate
  void _buildDateRange() {
    _daysInRange = [];
    DateTime currentDate = widget.startDate;
    while (currentDate.isBefore(widget.endDate) ||
        currentDate.isAtSameMomentAs(widget.endDate)) {
      _daysInRange.add(currentDate);
      currentDate = currentDate.add(const Duration(days: 1));
    }
  }

  /// Возвращает сокращенное название дня недели
  String _getDayAbbreviation(int weekday) {
    switch (weekday) {
      case 1:
        return 'пн';
      case 2:
        return 'вт';
      case 3:
        return 'ср';
      case 4:
        return 'чт';
      case 5:
        return 'пт';
      case 6:
        return 'сб';
      case 7:
        return 'вс';
      default:
        return '';
    }
  }

  /// Формирует полное ФИО сотрудника
  String _getEmployeeFullName(Employee employee) {
    if (employee.middleName != null && employee.middleName!.isNotEmpty) {
      return '${employee.lastName} ${employee.firstName} ${employee.middleName}';
    }
    return '${employee.lastName} ${employee.firstName}';
  }

  /// Строит основную таблицу календаря
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final headerStyle =
        theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold);

    // Перезагружаем список сотрудников при изменении фильтров по должностям
    ref.listen<List<String>?>(
      timesheetProvider.select((state) => state.selectedPositions),
      (previous, next) {
        if (previous != next) {
          _loadEmployees();
        }
      },
    );

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
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(
                  Theme.of(context).colorScheme.surface,
                ),
                dataRowColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return Theme.of(context)
                        .colorScheme
                        .primaryContainer
                        .withValues(alpha: 0.2);
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
                    color:
                        Theme.of(context).dividerColor.withValues(alpha: 0.3),
                  ),
                  verticalInside: BorderSide(
                    width: 0.5,
                    color:
                        Theme.of(context).dividerColor.withValues(alpha: 0.3),
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
                    final isWeekend = day.weekday == DateTime.saturday ||
                        day.weekday == DateTime.sunday;
                    final dayColor = isWeekend
                        ? Theme.of(context)
                            .colorScheme
                            .error
                            .withValues(alpha: 0.18)
                        : Theme.of(context)
                            .colorScheme
                            .surface
                            .withValues(alpha: 0.5);
                    final textColor = isWeekend
                        ? Theme.of(context).colorScheme.error
                        : Theme.of(context).textTheme.bodySmall?.color;
                    return DataColumn(
                      label: Container(
                        constraints:
                            const BoxConstraints(minWidth: 40, maxWidth: 40),
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
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: dayColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _getDayAbbreviation(day.weekday),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
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
                      constraints:
                          const BoxConstraints(minWidth: 64, maxWidth: 64),
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

    // Если сотрудники еще не загружены, показываем loader
    if (_allEmployees.isEmpty) {
      return [];
    }

    // Добавляем строки для каждого сотрудника
    for (int i = 0; i < _allEmployees.length; i++) {
      final employee = _allEmployees[i];
      final employeeName = _getEmployeeFullName(employee);

      // Находим записи этого сотрудника по ID
      final employeeEntries = widget.entries
          .where((entry) => entry.employeeId == employee.id)
          .toList();

      // Создаем ячейки для всех дней
      final cells = <DataCell>[];

      // Ячейка с именем сотрудника (кликабельная для добавления часов вне смен)
      cells.add(
        DataCell(
          InkWell(
            onTap: () => _showAttendanceDialog(employee),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              constraints: const BoxConstraints(minWidth: 240),
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
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
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                employeeName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.edit_calendar_outlined,
                              size: 16,
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withValues(alpha: 0.6),
                            ),
                          ],
                        ),
                        if (employee.position != null &&
                            employee.position!.isNotEmpty)
                          Text(
                            employee.position!,
                            style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.7),
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
        final dayEntries = employeeEntries
            .where((entry) => _isSameDay(entry.date, day))
            .toList();

        // Суммируем часы за день
        final dayHours =
            dayEntries.fold<num>(0, (sum, entry) => sum + entry.hours);
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
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Показываем часы, если они есть
                    if (dayHours > 0)
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          // Синий кружок вокруг числа для ручного ввода
                          shape: BoxShape.circle,
                          border: dayEntries.any((e) => e.isManualEntry)
                              ? Border.all(
                                  color: Colors.blue,
                                  width: 2,
                                )
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          dayHours.toString(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
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
    if (_allEmployees.isNotEmpty) {
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
        final dayEntries = widget.entries
            .where((entry) => _isSameDay(entry.date, day))
            .toList();

        // Суммируем часы за день
        final dayHours =
            dayEntries.fold<num>(0, (sum, entry) => sum + entry.hours);
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
  void _showEntryDetails(
      List<TimesheetEntry> entries, String employeeName, DateTime day) {
    if (entries.isEmpty) return;

    // Создаем виджет содержимого для диалога
    final contentWidget = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
      message: '',
      contentWidget: SingleChildScrollView(
        child: contentWidget,
      ),
      buttonText: 'Закрыть',
    );
  }

  /// Проверяет, являются ли две даты одним и тем же днём
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  /// Показывает диалог для добавления/редактирования часов вне смен
  Future<void> _showAttendanceDialog(Employee employee) async {
    // Проверяем статус сотрудника
    if (employee.status != EmployeeStatus.working) {
      if (!mounted) return;

      // Определяем текст статуса
      String statusText;
      switch (employee.status) {
        case EmployeeStatus.vacation:
          statusText = 'в отпуске';
          break;
        case EmployeeStatus.sickLeave:
          statusText = 'на больничном';
          break;
        case EmployeeStatus.unpaidLeave:
          statusText = 'в отпуске без содержания';
          break;
        case EmployeeStatus.fired:
          statusText = 'уволен';
          break;
        default:
          statusText = 'не работает';
      }

      // Показываем предупреждение
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Нельзя проставить часы сотруднику "${employee.lastName} ${employee.firstName}". '
            'Сотрудник $statusText.',
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
      return;
    }

    // Получаем список объектов
    final objectRepository = ref.read(objectRepositoryProvider);
    final objects = await objectRepository.getObjects();

    if (!mounted) return;

    // Показываем диалог
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => EmployeeAttendanceDialog(
        employee: employee,
        startDate: widget.startDate,
        endDate: widget.endDate,
        objects: objects,
      ),
    );

    // Если данные были сохранены, обновляем таблицу
    if (result == true && mounted) {
      // Перезагружаем данные табеля
      ref.read(timesheetProvider.notifier).loadTimesheet();
    }
  }
}
