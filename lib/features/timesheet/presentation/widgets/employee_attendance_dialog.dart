import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:projectgt/core/widgets/gt_dropdown.dart';
import 'package:projectgt/domain/entities/employee.dart';
import 'package:projectgt/domain/entities/object.dart' as project_object;
import '../../domain/entities/employee_attendance_entry.dart';
import '../providers/repositories_providers.dart';

/// Модальное окно для управления посещаемостью сотрудника (вне смен).
///
/// Позволяет:
/// - Выбрать объект, к которому привязаны расходы на ФОТ
/// - Проставить часы в календарном виде за выбранный месяц
/// - Сохранить данные массово
class EmployeeAttendanceDialog extends ConsumerStatefulWidget {
  /// Сотрудник, для которого вводятся данные
  final Employee employee;

  /// Начальная дата периода (обычно - начало месяца)
  final DateTime startDate;

  /// Конечная дата периода (обычно - конец месяца)
  final DateTime endDate;

  /// Список доступных объектов
  final List<project_object.ObjectEntity> objects;

  /// Создает модальное окно управления посещаемостью.
  const EmployeeAttendanceDialog({
    super.key,
    required this.employee,
    required this.startDate,
    required this.endDate,
    required this.objects,
  });

  @override
  ConsumerState<EmployeeAttendanceDialog> createState() =>
      _EmployeeAttendanceDialogState();
}

class _EmployeeAttendanceDialogState
    extends ConsumerState<EmployeeAttendanceDialog> {
  /// Выбранный объект
  String? _selectedObjectId;

  /// Карта часов по датам: {дата: часы}
  final Map<DateTime, num> _hoursMap = {};

  /// Все загруженные записи по объектам: {objectId: {дата: часы}}
  final Map<String, Map<DateTime, num>> _allRecordsByObject = {};

  /// Карта часов из смен (только для чтения): {дата: часы}
  final Map<DateTime, num> _shiftHoursMap = {};

  /// Загружаемые данные
  bool _isLoading = true;

  /// Сохранение данных
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  /// Загружает существующие данные посещаемости
  Future<void> _loadExistingData() async {
    try {
      // Загружаем часы из ручного ввода (employee_attendance)
      final attendanceRepository =
          ref.read(employeeAttendanceRepositoryProvider);
      final records = await attendanceRepository.getAttendanceRecords(
        employeeId: widget.employee.id,
        startDate: widget.startDate,
        endDate: widget.endDate,
      );

      // Загружаем часы из смен (work_hours через timesheet)
      final timesheetRepository = ref.read(timesheetRepositoryProvider);
      final shiftEntries = await timesheetRepository.getTimesheetEntries(
        startDate: widget.startDate,
        endDate: widget.endDate,
        employeeId: widget.employee.id,
      );

      if (mounted) {
        setState(() {
          // Группируем записи ручного ввода по объектам
          for (final record in records) {
            final date =
                DateTime(record.date.year, record.date.month, record.date.day);

            if (!_allRecordsByObject.containsKey(record.objectId)) {
              _allRecordsByObject[record.objectId] = {};
            }
            _allRecordsByObject[record.objectId]![date] = record.hours;

            // Устанавливаем объект из первой найденной записи
            _selectedObjectId ??= record.objectId;
          }

          // Сохраняем часы из смен (они защищены от редактирования)
          // Фильтруем только записи из смен, исключая ручной ввод
          for (final entry in shiftEntries) {
            if (!entry.isManualEntry) {
              final date =
                  DateTime(entry.date.year, entry.date.month, entry.date.day);
              _shiftHoursMap[date] = entry.hours;
            }
          }

          // Загружаем часы для первого объекта
          if (_selectedObjectId != null) {
            _loadHoursForObject(_selectedObjectId!);
          }

          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Загружает часы для выбранного объекта
  void _loadHoursForObject(String objectId) {
    _hoursMap.clear();
    if (_allRecordsByObject.containsKey(objectId)) {
      _hoursMap.addAll(_allRecordsByObject[objectId]!);
    }
  }

  /// Сохраняет данные посещаемости
  Future<void> _saveData() async {
    if (_selectedObjectId == null) {
      _showError('Выберите объект');
      return;
    }

    if (_hoursMap.isEmpty) {
      _showError('Проставьте часы хотя бы на один день');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final repository = ref.read(employeeAttendanceRepositoryProvider);
      final entries = _hoursMap.entries.map((entry) {
        return EmployeeAttendanceEntry(
          id: '', // Пустой ID - БД сама сгенерирует или обновит через onConflict
          employeeId: widget.employee.id,
          objectId: _selectedObjectId!,
          date: entry.key,
          hours: entry.value,
          attendanceType: AttendanceType.work,
        );
      }).toList();

      await repository.batchUpsertAttendance(entries);

      // Обновляем кэш после успешного сохранения
      _allRecordsByObject[_selectedObjectId!] = Map.from(_hoursMap);

      if (mounted) {
        Navigator.of(context).pop(true); // Возвращаем true как сигнал об успехе
      }
    } catch (e) {
      if (mounted) {
        _showError('Ошибка при сохранении: $e');
        setState(() => _isSaving = false);
      }
    }
  }

  /// Показывает ошибку
  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final employeeName =
        '${widget.employee.lastName} ${widget.employee.firstName}${widget.employee.middleName != null && widget.employee.middleName!.isNotEmpty ? ' ${widget.employee.middleName}' : ''}';

    // Фильтруем объекты - показываем только те, что есть у сотрудника
    final employeeObjects = widget.objects
        .where((obj) => widget.employee.objectIds.contains(obj.id))
        .toList();

    return Dialog(
      backgroundColor: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 700, maxHeight: 650),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Заголовок
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Посещаемость сотрудника',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        employeeName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      if (widget.employee.position != null)
                        Text(
                          widget.employee.position!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.6),
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Выбор объекта
            GTDropdown<project_object.ObjectEntity>(
              items: employeeObjects,
              itemDisplayBuilder: (obj) => obj.name,
              labelText: 'Объект',
              hintText: 'Выберите объект для учёта ФОТ',
              selectedItem: _selectedObjectId != null
                  ? employeeObjects
                      .where((obj) => obj.id == _selectedObjectId)
                      .firstOrNull
                  : null,
              onSelectionChanged: (selectedObj) {
                if (!_isLoading && !_isSaving && selectedObj != null) {
                  setState(() {
                    _selectedObjectId = selectedObj.id;
                    _loadHoursForObject(selectedObj.id);
                  });
                }
              },
              readOnly: _isLoading || _isSaving,
            ),
            const SizedBox(height: 16),

            // Календарь с часами
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildCalendar(theme),
            ),

            const SizedBox(height: 16),

            // Кнопки действий
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed:
                      _isSaving ? null : () => Navigator.of(context).pop(),
                  child: const Text('Отмена'),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: _isSaving ? null : _saveData,
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Сохранить'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Строит календарь с полями для ввода часов
  Widget _buildCalendar(ThemeData theme) {
    final calendarCells = _buildCalendarCells();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Заголовок: Период
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Text(
              'Период: ${DateFormat.yMMMM('ru').format(widget.startDate)}',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // Календарная сетка с заголовками дней недели
          Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: theme.dividerColor.withValues(alpha: 0.3),
              ),
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(8)),
            ),
            child: Column(
              children: [
                // Заголовки дней недели
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 7,
                  childAspectRatio: 2.5,
                  children: [
                    _buildWeekdayHeader('Пн', theme),
                    _buildWeekdayHeader('Вт', theme),
                    _buildWeekdayHeader('Ср', theme),
                    _buildWeekdayHeader('Чт', theme),
                    _buildWeekdayHeader('Пт', theme),
                    _buildWeekdayHeader('Сб', theme),
                    _buildWeekdayHeader('Вс', theme),
                  ],
                ),
                // Ячейки с днями
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    childAspectRatio: 1.0,
                  ),
                  itemCount: calendarCells.length,
                  itemBuilder: (context, index) => calendarCells[index],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Подсказка
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Введите часы напрямую в ячейки дней.',
                        style:
                            theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.lock,
                      size: 12,
                      color: theme.colorScheme.tertiary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Дни с пометкой "смена" защищены от редактирования (часы из смен).',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 10,
                          color: theme.colorScheme.tertiary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Строит заголовок дня недели
  Widget _buildWeekdayHeader(String day, ThemeData theme) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.2),
        ),
        color: theme.colorScheme.surfaceContainerHighest,
      ),
      child: Text(
        day,
        style: theme.textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }

  /// Строит все ячейки календаря с учётом пустых ячеек для выравнивания
  List<Widget> _buildCalendarCells() {
    final theme = Theme.of(context);
    final cells = <Widget>[];

    // Находим первый понедельник (или день недели первого числа)
    final firstDay = widget.startDate;
    final firstWeekday = firstDay.weekday; // 1 = Monday, 7 = Sunday

    // Добавляем пустые ячейки в начале
    for (int i = 1; i < firstWeekday; i++) {
      cells.add(_buildEmptyCell(theme));
    }

    // Добавляем ячейки с днями
    DateTime currentDate = widget.startDate;
    while (currentDate.isBefore(widget.endDate) ||
        currentDate.isAtSameMomentAs(widget.endDate)) {
      final isWeekend = currentDate.weekday == DateTime.saturday ||
          currentDate.weekday == DateTime.sunday;
      cells.add(_buildDayCell(currentDate, isWeekend, theme));
      currentDate = currentDate.add(const Duration(days: 1));
    }

    return cells;
  }

  /// Строит пустую ячейку
  Widget _buildEmptyCell(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.1),
        ),
        color: theme.colorScheme.surface.withValues(alpha: 0.3),
      ),
    );
  }

  /// Строит ячейку дня с инлайн вводом часов
  Widget _buildDayCell(DateTime day, bool isWeekend, ThemeData theme) {
    // Проверяем, есть ли часы из смен (защищены от редактирования)
    final shiftHours = _shiftHoursMap[day];
    final hasShiftHours = shiftHours != null;

    final hours = hasShiftHours ? shiftHours : _hoursMap[day];

    final dayColor = isWeekend
        ? theme.colorScheme.error.withValues(alpha: 0.1)
        : hasShiftHours
            ? theme.colorScheme.tertiary
                .withValues(alpha: 0.1) // Особый цвет для смен
            : theme.colorScheme.surface;

    final textColor =
        isWeekend ? theme.colorScheme.error : theme.textTheme.bodyMedium?.color;

    final controller = TextEditingController(text: hours?.toString() ?? '');

    return Container(
      decoration: BoxDecoration(
        color: dayColor,
        border: Border.all(
          color: hasShiftHours
              ? theme.colorScheme.tertiary
                  .withValues(alpha: 0.5) // Подсветка границы
              : theme.dividerColor.withValues(alpha: 0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Число (с иконкой замка если из смены)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (hasShiftHours)
                  Padding(
                    padding: const EdgeInsets.only(right: 2),
                    child: Icon(
                      Icons.lock,
                      size: 10,
                      color: theme.colorScheme.tertiary,
                    ),
                  ),
                Text(
                  '${day.day}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            // Поле ввода часов (заблокировано если из смены)
            SizedBox(
              height: 30,
              child: TextField(
                controller: controller,
                enabled: !_isSaving &&
                    !hasShiftHours, // Блокируем если есть часы из смены
                textAlign: TextAlign.center,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                      RegExp(r'^\d{0,2}\.?\d{0,1}')),
                ],
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: hasShiftHours ? theme.colorScheme.tertiary : null,
                ),
                decoration: InputDecoration(
                  hintText: '—',
                  hintStyle: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 6,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: BorderSide(
                      color: theme.dividerColor.withValues(alpha: 0.3),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: BorderSide(
                      color: theme.dividerColor.withValues(alpha: 0.3),
                    ),
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: BorderSide(
                      color: theme.colorScheme.tertiary.withValues(alpha: 0.3),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: BorderSide(
                      color: theme.colorScheme.primary,
                      width: 1.5,
                    ),
                  ),
                  filled: true,
                  fillColor: hasShiftHours
                      ? theme.colorScheme.tertiary
                          .withValues(alpha: 0.2) // Особый цвет для смен
                      : hours != null && hours > 0
                          ? theme.colorScheme.primaryContainer
                              .withValues(alpha: 0.3)
                          : theme.colorScheme.surface,
                ),
                onChanged: hasShiftHours
                    ? null // Не обрабатываем изменения если из смены
                    : (value) {
                        if (value.isEmpty) {
                          setState(() => _hoursMap.remove(day));
                        } else {
                          final parsedHours = num.tryParse(value);
                          if (parsedHours != null &&
                              parsedHours >= 0 &&
                              parsedHours <= 24) {
                            setState(() => _hoursMap[day] = parsedHours);
                          }
                        }
                      },
              ),
            ),
            const SizedBox(height: 2),
            // Подпись "ч" или "смена"
            Text(
              hasShiftHours ? 'смена' : 'ч',
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: hasShiftHours ? 8 : 10,
                color: hasShiftHours
                    ? theme.colorScheme.tertiary.withValues(alpha: 0.8)
                    : textColor?.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
