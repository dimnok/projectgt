import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/core/widgets/app_snackbar.dart';
import 'package:projectgt/domain/entities/employee.dart';
import 'package:projectgt/features/timesheet/domain/entities/timesheet_entry.dart';
import 'package:projectgt/presentation/widgets/cupertino_dialog_widget.dart';
import 'package:projectgt/core/di/providers.dart';
import 'employee_attendance_dialog.dart';
import 'timesheet_employee_list_scope_segment.dart';
import 'timesheet_objects_bar_dropdown.dart';
import 'timesheet_filter_widget.dart';
import '../providers/timesheet_provider.dart';
import 'package:projectgt/features/roles/application/permission_service.dart';
import 'package:projectgt/features/roles/presentation/widgets/permission_guard.dart';

import 'timesheet_excel_action.dart';

/// Календарная сетка табеля: своя [Table], шапка закреплена над вертикальным скроллом,
/// горизонтальный скролл шапки и тела синхронизирован (как в таблице модуля «Подрядчики»).
///
/// Показывает активных сотрудников и уволенных, у которых есть часы в периоде.
/// Сегмент «Все / С часами / Без часов» ([TimesheetEmployeeListScopeSegment]) задаёт фильтр списка по сумме часов за период.
///
/// Слева от ФИО — чекбоксы выбора строки; в шапке — общий выбор (частичный / полный).
///
/// Если [employeeNameSearchQuery] не пустой, список строк ограничивается сотрудниками,
/// присутствующими в [entries] (например после клиентской фильтрации по ФИО).
class TimesheetCalendarView extends ConsumerStatefulWidget {
  /// Записи табеля.
  final List<TimesheetEntry> entries;

  /// Начало периода.
  final DateTime startDate;

  /// Конец периода.
  final DateTime endDate;

  /// Непустая строка — показывать только сотрудников из [entries] (поиск по ФИО).
  final String employeeNameSearchQuery;

  /// Создаёт сетку табеля.
  const TimesheetCalendarView({
    super.key,
    required this.entries,
    required this.startDate,
    required this.endDate,
    this.employeeNameSearchQuery = '',
  });

  @override
  ConsumerState<TimesheetCalendarView> createState() =>
      _TimesheetCalendarViewState();
}

class _TimesheetCalendarViewState extends ConsumerState<TimesheetCalendarView> {
  static const double _kSelectColWidth = 44;
  static const double _kEmployeeColWidth = 240;
  static const double _kDayColWidth = 40;
  static const double _kTotalColWidth = 64;
  static const double _kHeaderGap = 4;

  final ScrollController _verticalController = ScrollController();
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _headerHorizontalController = ScrollController();
  bool _isSyncingScroll = false;

  List<DateTime> _daysInRange = [];
  List<Employee> _allEmployees = [];

  /// Сотрудники после фильтров табеля (должность, объект, уволенные), без учёта поиска по ФИО.
  ///
  /// Заполняется в [_loadEmployees]; при вводе в поиск обновляется только [_allEmployees]
  /// через [_applyVisibleEmployeesFromCache] без повторного запроса списка сотрудников.
  List<Employee> _employeesBase = [];

  /// `employeeId` → (`yyyy-MM-dd` → записи за день).
  final Map<String, Map<String, List<TimesheetEntry>>> _entriesByEmployeeDay =
      {};

  /// `yyyy-MM-dd` → все записи за день (итоги по дням).
  final Map<String, List<TimesheetEntry>> _entriesByDay = {};

  ProviderSubscription<String>? _filtersSub;
  ProviderSubscription<TimesheetEmployeeListScope>? _employeeScopeSub;

  @override
  void initState() {
    super.initState();
    _horizontalController.addListener(_syncHeaderScroll);
    _buildDateRange();
    _rebuildEntryIndex();
    _loadEmployees();

    _filtersSub = ref.listenManual<String>(
      timesheetProvider.select((s) {
        return s.selectedObjectIds?.join('\x1e') ?? '';
      }),
      (previous, next) {
        if (previous != next) _loadEmployees();
      },
    );

    _employeeScopeSub = ref.listenManual<TimesheetEmployeeListScope>(
      timesheetEmployeeListScopeProvider,
      (previous, next) {
        if (previous != next) _loadEmployees();
      },
    );
  }

  @override
  void didUpdateWidget(TimesheetCalendarView oldWidget) {
    super.didUpdateWidget(oldWidget);
    var needsNetworkEmployeeReload = false;

    if (oldWidget.startDate != widget.startDate ||
        oldWidget.endDate != widget.endDate) {
      _buildDateRange();
      needsNetworkEmployeeReload = true;
    }

    final entriesChanged = !identical(oldWidget.entries, widget.entries) ||
        oldWidget.entries.length != widget.entries.length;

    final searchChanged =
        oldWidget.employeeNameSearchQuery != widget.employeeNameSearchQuery;

    if (entriesChanged) {
      _rebuildEntryIndex();
    }

    if (searchChanged) {
      _applyVisibleEmployeesFromCache();
    }

    if (needsNetworkEmployeeReload) {
      _loadEmployees();
    } else if (entriesChanged && !searchChanged) {
      // Обновились записи табеля с сервера при неизменной строке поиска.
      _loadEmployees();
    }
  }

  @override
  void dispose() {
    _filtersSub?.close();
    _employeeScopeSub?.close();
    _horizontalController.removeListener(_syncHeaderScroll);
    _verticalController.dispose();
    _horizontalController.dispose();
    _headerHorizontalController.dispose();
    super.dispose();
  }

  void _syncHeaderScroll() {
    if (_isSyncingScroll) return;
    if (!_headerHorizontalController.hasClients) return;
    _isSyncingScroll = true;
    _headerHorizontalController.jumpTo(_horizontalController.offset);
    _isSyncingScroll = false;
  }

  /// Строки таблицы по ФИО: подмножество [_employeesBase] по [widget.entries], если поиск не пустой.
  List<Employee> _computeVisibleEmployees() {
    if (_employeesBase.isEmpty) return const [];
    if (widget.employeeNameSearchQuery.trim().isEmpty) {
      return List<Employee>.from(_employeesBase);
    }
    final ids = widget.entries.map((e) => e.employeeId).toSet();
    return _employeesBase.where((e) => ids.contains(e.id)).toList();
  }

  /// Сужает [_allEmployees] после ввода в поиск без запроса [getEmployees].
  void _applyVisibleEmployeesFromCache() {
    if (!mounted) return;
    final visible = _computeVisibleEmployees();
    setState(() {
      _allEmployees = visible;
    });
    final sel = ref.read(timesheetGridSelectedEmployeeIdsProvider);
    ref.read(timesheetGridSelectedEmployeeIdsProvider.notifier).state =
        sel.where((id) => visible.any((e) => e.id == id)).toSet();
  }

  Future<void> _loadEmployees() async {
    final employeeRepository = ref.read(employeeRepositoryProvider);
    final timesheetState = ref.read(timesheetProvider);
    final allEmployees = await employeeRepository.getEmployees();

    // Идентификаторы с часами в периоде — из полного состояния табеля (поиск не должен
    // сужать набор для фильтра по объекту и для уволенных с часами).
    final employeeIdsWithHours = timesheetState.entries
        .map((entry) => entry.employeeId)
        .toSet();

    final hoursSumByEmployee = <String, num>{};
    for (final e in timesheetState.entries) {
      hoursSumByEmployee[e.employeeId] =
          (hoursSumByEmployee[e.employeeId] ?? 0) + e.hours;
    }
    final employeeIdsWithPositiveHours = hoursSumByEmployee.entries
        .where((e) => e.value > 0)
        .map((e) => e.key)
        .toSet();

    final listScope = ref.read(timesheetEmployeeListScopeProvider);

    final selectedObjectIds = timesheetState.selectedObjectIds;
    final hasObjectFilter =
        selectedObjectIds != null && selectedObjectIds.isNotEmpty;

    var baseFiltered = allEmployees.where((e) {
      if (hasObjectFilter) {
        return employeeIdsWithHours.contains(e.id);
      }

      if (e.status != EmployeeStatus.fired) {
        return true;
      }
      return employeeIdsWithHours.contains(e.id);
    }).toList();

    switch (listScope) {
      case TimesheetEmployeeListScope.withHours:
        baseFiltered = baseFiltered
            .where((e) => employeeIdsWithPositiveHours.contains(e.id))
            .toList();
      case TimesheetEmployeeListScope.withoutHours:
        baseFiltered = baseFiltered.where((e) {
          final sum = hoursSumByEmployee[e.id] ?? 0;
          return sum <= 0;
        }).toList();
      case TimesheetEmployeeListScope.all:
        break;
    }

    baseFiltered.sort((a, b) {
      final nameA = '${a.lastName} ${a.firstName} ${a.middleName ?? ''}';
      final nameB = '${b.lastName} ${b.firstName} ${b.middleName ?? ''}';
      return nameA.compareTo(nameB);
    });

    if (!mounted) return;
    setState(() {
      _employeesBase = baseFiltered;
      _allEmployees = _computeVisibleEmployees();
    });
    final visible = _allEmployees;
    final sel = ref.read(timesheetGridSelectedEmployeeIdsProvider);
    ref.read(timesheetGridSelectedEmployeeIdsProvider.notifier).state =
        sel.where((id) => visible.any((e) => e.id == id)).toSet();
  }

  /// Состояние чекбокса «все» в шапке: `null` — выбрана часть строк.
  bool? _headerSelectAllValue(Set<String> selectedIds) {
    if (_allEmployees.isEmpty) return false;
    final n = selectedIds.length;
    if (n == 0) return false;
    if (n == _allEmployees.length) return true;
    return null;
  }

  void _onHeaderSelectAllChanged(bool? value) {
    final notifier =
        ref.read(timesheetGridSelectedEmployeeIdsProvider.notifier);
    if (value == true) {
      notifier.state = _allEmployees.map((e) => e.id).toSet();
    } else {
      notifier.state = <String>{};
    }
  }

  void _onRowCheckboxChanged(Employee employee, bool? checked) {
    final notifier =
        ref.read(timesheetGridSelectedEmployeeIdsProvider.notifier);
    final next = Set<String>.from(
      ref.read(timesheetGridSelectedEmployeeIdsProvider),
    );
    if (checked == true) {
      next.add(employee.id);
    } else {
      next.remove(employee.id);
    }
    notifier.state = next;
  }

  /// Компактный чекбокс в стиле таблицы подрядчиков.
  Widget _compactCheckbox({
    required bool? value,
    required ValueChanged<bool?> onChanged,
    required String semanticLabel,
    bool tristate = false,
  }) {
    return Semantics(
      label: semanticLabel,
      child: SizedBox.square(
        dimension: 32,
        child: Center(
          child: SizedBox.square(
            dimension: 20,
            child: Checkbox(
              value: value,
              tristate: tristate,
              visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              overlayColor: const WidgetStatePropertyAll(Colors.transparent),
              splashRadius: 0,
              onChanged: onChanged,
            ),
          ),
        ),
      ),
    );
  }

  void _buildDateRange() {
    _daysInRange = [];
    var currentDate = widget.startDate;
    while (currentDate.isBefore(widget.endDate) ||
        currentDate.isAtSameMomentAs(widget.endDate)) {
      _daysInRange.add(currentDate);
      currentDate = currentDate.add(const Duration(days: 1));
    }
  }

  void _rebuildEntryIndex() {
    _entriesByEmployeeDay.clear();
    _entriesByDay.clear();
    for (final e in widget.entries) {
      final key = _dayKey(e.date);
      _entriesByDay.putIfAbsent(key, () => []).add(e);
      _entriesByEmployeeDay
          .putIfAbsent(e.employeeId, () => {})
          .putIfAbsent(key, () => [])
          .add(e);
    }
  }

  static String _dayKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  String _getEmployeeFullName(Employee employee) {
    if (employee.middleName != null && employee.middleName!.isNotEmpty) {
      return '${employee.lastName} ${employee.firstName} ${employee.middleName}';
    }
    return '${employee.lastName} ${employee.firstName}';
  }

  /// Подпись «Май-2026» для переключателя периода табеля.
  static String _timesheetMonthYearLabel(DateTime monthStart) {
    final s = formatMonthYear(monthStart);
    if (s.isEmpty) return '';
    return s.replaceFirst(RegExp(r'\s+'), '-');
  }

  void _shiftTableMonth(int monthsDelta) {
    final d = widget.startDate;
    final next = DateTime(d.year, d.month + monthsDelta, 1);
    final end = DateTime(next.year, next.month + 1, 0);
    ref.read(timesheetProvider.notifier).setDateRange(next, end);
  }

  /// Переключатель месяца/года и панель фильтров над таблицей.
  Widget _buildTimesheetTitleRow(ThemeData theme) {
    final scheme = theme.colorScheme;
    final label = _timesheetMonthYearLabel(widget.startDate);
    final iconColor = scheme.onSurface.withValues(alpha: 0.85);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          IconButton(
            tooltip: 'Предыдущий месяц',
            onPressed: () => _shiftTableMonth(-1),
            icon: Icon(
              Icons.chevron_left_rounded,
              color: iconColor,
              size: 28,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              label,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Следующий месяц',
            onPressed: () => _shiftTableMonth(1),
            icon: Icon(
              Icons.chevron_right_rounded,
              color: iconColor,
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          const TimesheetObjectsBarDropdown(),
          const SizedBox(width: 8),
          const TimesheetEmployeeListScopeSegment(),
          const Spacer(),
          const PermissionGuard(
            module: 'timesheet',
            permission: 'export',
            child: TimesheetExcelAction(),
          ),
        ],
      ),
    );
  }

  String _formatHours(num hours) => formatQuantity(hours);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gridSelectedIds = ref.watch(timesheetGridSelectedEmployeeIdsProvider);

    if (widget.entries.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTimesheetTitleRow(theme),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.event_busy,
                    size: 64,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Нет данных для отображения',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Попробуйте изменить фильтры или выбрать другой период',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTimesheetTitleRow(theme),
        Expanded(
          child: _allEmployees.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final availableWidth = constraints.maxWidth.isFinite
                        ? constraints.maxWidth
                        : MediaQuery.sizeOf(context).width;
                    final dayCount = _daysInRange.length;
                    final minTableWidth =
                        _kSelectColWidth +
                        _kEmployeeColWidth +
                        dayCount * _kDayColWidth +
                        _kTotalColWidth;
                    final minWidth = math.max(availableWidth, minTableWidth);

                    final dividerColor = theme.colorScheme.outline.withValues(
                      alpha: 0.18,
                    );
                    final columnWidths = _buildColumnWidths(dayCount);

                    Widget buildTable(List<TableRow> rows) {
                      return ConstrainedBox(
                        constraints: BoxConstraints(minWidth: minWidth),
                        child: Table(
                          defaultVerticalAlignment:
                              TableCellVerticalAlignment.middle,
                          border: TableBorder(
                            top: BorderSide(color: dividerColor, width: 1),
                            bottom: BorderSide(color: dividerColor, width: 1),
                            left: BorderSide(color: dividerColor, width: 1),
                            right: BorderSide(color: dividerColor, width: 1),
                            horizontalInside: BorderSide(
                              color: dividerColor,
                              width: 1,
                            ),
                            verticalInside: BorderSide(
                              color: dividerColor,
                              width: 1,
                            ),
                          ),
                          columnWidths: columnWidths,
                          children: rows,
                        ),
                      );
                    }

                    final headerRow = _buildHeaderRow(theme, gridSelectedIds);
                    final bodyRows = _buildDataRows(theme, gridSelectedIds);
                    final headerBackground = theme.brightness == Brightness.dark
                        ? theme.colorScheme.surfaceContainerHigh
                        : Colors.grey.shade200;

                    final header = ColoredBox(
                      color: headerBackground,
                      child: SingleChildScrollView(
                        controller: _headerHorizontalController,
                        physics: const NeverScrollableScrollPhysics(),
                        scrollDirection: Axis.horizontal,
                        child: buildTable([headerRow]),
                      ),
                    );

                    final body = Expanded(
                      child: Scrollbar(
                        controller: _verticalController,
                        thumbVisibility: true,
                        child: SingleChildScrollView(
                          controller: _verticalController,
                          child: Scrollbar(
                            controller: _horizontalController,
                            thumbVisibility: true,
                            notificationPredicate: (notification) =>
                                notification.depth == 1,
                            child: SingleChildScrollView(
                              controller: _horizontalController,
                              scrollDirection: Axis.horizontal,
                              child: buildTable(bodyRows),
                            ),
                          ),
                        ),
                      ),
                    );

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        header,
                        const SizedBox(height: _kHeaderGap),
                        body,
                      ],
                    );
                  },
                ),
        ),
      ],
    );
  }

  Map<int, TableColumnWidth> _buildColumnWidths(int dayCount) {
    final m = <int, TableColumnWidth>{
      0: const FixedColumnWidth(_kSelectColWidth),
      1: const FixedColumnWidth(_kEmployeeColWidth),
    };
    for (var i = 0; i < dayCount; i++) {
      m[i + 2] = const FixedColumnWidth(_kDayColWidth);
    }
    m[dayCount + 2] = const FixedColumnWidth(_kTotalColWidth);
    return m;
  }

  TableRow _buildHeaderRow(ThemeData theme, Set<String> selectedIds) {
    final headerStyle = theme.textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.bold,
    );

    return TableRow(
      children: [
        TableCell(
          verticalAlignment: TableCellVerticalAlignment.middle,
          child: Padding(
            padding: const EdgeInsets.only(
              left: 6,
              right: 2,
              top: 8,
              bottom: 8,
            ),
            child: Tooltip(
              message: 'Выбрать всех отображаемых сотрудников',
              child: _compactCheckbox(
                value: _headerSelectAllValue(selectedIds),
                tristate: true,
                semanticLabel: 'Выбрать всех сотрудников в таблице',
                onChanged: _onHeaderSelectAllChanged,
              ),
            ),
          ),
        ),
        TableCell(
          verticalAlignment: TableCellVerticalAlignment.middle,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Сотрудник', style: headerStyle),
            ),
          ),
        ),
        ..._daysInRange.map((day) => _dayHeaderCell(theme, day, headerStyle)),
        TableCell(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
            child: Center(
              child: Text(
                'Итого',
                style: headerStyle,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ],
    );
  }

  TableCell _dayHeaderCell(
    ThemeData theme,
    DateTime day,
    TextStyle? headerStyle,
  ) {
    final isWeekend =
        day.weekday == DateTime.saturday || day.weekday == DateTime.sunday;
    final scheme = theme.colorScheme;
    final dayColor = isWeekend
        ? scheme.error.withValues(alpha: 0.18)
        : scheme.surface.withValues(alpha: 0.5);
    final textColor = isWeekend
        ? scheme.error
        : theme.textTheme.bodySmall?.color;

    final weekdayLabel = formatRuWeekdayShort(day).toLowerCase();

    return TableCell(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${day.day}',
              style: headerStyle?.copyWith(fontSize: 15, color: textColor),
            ),
            const SizedBox(height: 2),
            DecoratedBox(
              decoration: BoxDecoration(
                color: dayColor,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Text(
                  weekdayLabel,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                    color: textColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<TableRow> _buildDataRows(ThemeData theme, Set<String> selectedIds) {
    final rows = <TableRow>[];
    final scheme = theme.colorScheme;

    for (final employee in _allEmployees) {
      final employeeName = _getEmployeeFullName(employee);
      final byDay = _entriesByEmployeeDay[employee.id] ?? {};

      num totalHours = 0;
      final dayCells = <Widget>[];

      for (final day in _daysInRange) {
        final key = _dayKey(day);
        final dayEntries = List<TimesheetEntry>.from(byDay[key] ?? const []);
        final dayHours = dayEntries.fold<num>(
          0,
          (sum, entry) => sum + entry.hours,
        );
        totalHours += dayHours;

        dayCells.add(
          TableCell(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  if (dayHours > 0) {
                    _showEntryDetails(dayEntries, employeeName, day);
                  }
                  HapticFeedback.selectionClick();
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 6,
                    horizontal: 2,
                  ),
                  child: SizedBox(
                    width: _kDayColWidth,
                    child: Center(
                      child: dayHours > 0
                          ? DecoratedBox(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: dayEntries.any((e) => e.isManualEntry)
                                    ? Border.all(
                                        color: scheme.primary,
                                        width: 2,
                                      )
                                    : null,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: Text(
                                  _formatHours(dayHours),
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }

      rows.add(
        TableRow(
          children: [
            TableCell(
              verticalAlignment: TableCellVerticalAlignment.middle,
              child: Padding(
                padding: const EdgeInsets.only(left: 6, right: 2),
                child: Tooltip(
                  message: 'Выбрать строку',
                  child: _compactCheckbox(
                    value: selectedIds.contains(employee.id),
                    semanticLabel: 'Выбрать $employeeName',
                    onChanged: (v) => _onRowCheckboxChanged(employee, v),
                  ),
                ),
              ),
            ),
            TableCell(
              verticalAlignment: TableCellVerticalAlignment.middle,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _showAttendanceDialog(employee),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                employeeName,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Icon(
                              Icons.edit_calendar_outlined,
                              size: 16,
                              color: scheme.primary.withValues(alpha: 0.6),
                            ),
                          ],
                        ),
                        if (employee.position != null &&
                            employee.position!.isNotEmpty)
                          Text(
                            employee.position!,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: scheme.onSurface.withValues(alpha: 0.72),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            ...dayCells,
            TableCell(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Center(
                  child: Text(
                    _formatHours(totalHours),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    rows.add(_buildTotalsRow(theme));
    return rows;
  }

  TableRow _buildTotalsRow(ThemeData theme) {
    final scheme = theme.colorScheme;
    num grandTotal = 0;
    final dayCells = <Widget>[];

    for (final day in _daysInRange) {
      final key = _dayKey(day);
      final dayEntries = _entriesByDay[key] ?? const <TimesheetEntry>[];
      final dayHours = dayEntries.fold<num>(
        0,
        (sum, entry) => sum + entry.hours,
      );
      grandTotal += dayHours;

      dayCells.add(
        TableCell(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Center(
              child: Text(
                _formatHours(dayHours),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return TableRow(
      children: [
        const TableCell(
          verticalAlignment: TableCellVerticalAlignment.middle,
          child: SizedBox.shrink(),
        ),
        TableCell(
          verticalAlignment: TableCellVerticalAlignment.middle,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: Text(
              'Итого по дням',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        ...dayCells,
        TableCell(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Center(
              child: Text(
                _formatHours(grandTotal),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: scheme.primary,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showEntryDetails(
    List<TimesheetEntry> entries,
    String employeeName,
    DateTime day,
  ) {
    if (entries.isEmpty) return;

    final title = '$employeeName · ${formatRuDate(day)}';
    final contentWidget = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...entries.map((entry) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Объект:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(entry.objectName ?? 'Н/Д')),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Text(
                      'Часы:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    Text(_formatHours(entry.hours)),
                  ],
                ),
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

    CupertinoDialogs.showMessageDialog(
      context: context,
      title: title,
      message: '',
      contentWidget: SingleChildScrollView(child: contentWidget),
      buttonText: 'Закрыть',
    );
  }

  Future<void> _showAttendanceDialog(Employee employee) async {
    final permissionService = ref.read(permissionServiceProvider);
    if (!permissionService.can('timesheet', 'create') &&
        !permissionService.can('timesheet', 'update')) {
      if (!mounted) return;
      AppSnackBar.show(
        context: context,
        message: 'Недостаточно прав для редактирования табеля',
        kind: AppSnackBarKind.error,
      );
      return;
    }

    if (employee.status != EmployeeStatus.working) {
      if (!mounted) return;

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

      AppSnackBar.show(
        context: context,
        message:
            'Нельзя проставить часы сотруднику «${employee.lastName} ${employee.firstName}». '
            'Сотрудник $statusText.',
        kind: AppSnackBarKind.warning,
      );
      return;
    }

    final objectRepository = ref.read(objectRepositoryProvider);
    final objects = await objectRepository.getObjects();

    if (!mounted) return;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => EmployeeAttendanceDialog(
        employee: employee,
        startDate: widget.startDate,
        endDate: widget.endDate,
        objects: objects,
      ),
    );

    if (result == true && mounted) {
      ref.read(timesheetProvider.notifier).loadTimesheet();
    }
  }
}
