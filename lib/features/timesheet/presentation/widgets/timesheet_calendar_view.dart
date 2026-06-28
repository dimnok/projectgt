import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/core/widgets/app_snackbar.dart';
import 'package:projectgt/domain/entities/employee.dart';
import 'package:projectgt/features/timesheet/domain/entities/timesheet_entry.dart';
import 'package:projectgt/features/timesheet/domain/timesheet_employee_visibility.dart';
import 'package:projectgt/features/timesheet/domain/timesheet_hours_index.dart';
import 'package:projectgt/features/timesheet/domain/timesheet_position_filter.dart';
import 'package:projectgt/features/timesheet/domain/timesheet_today_open_shift.dart';
import 'package:projectgt/presentation/state/employee_state.dart' as employee_state;
import 'package:projectgt/presentation/widgets/cupertino_dialog_widget.dart';
import 'employee_attendance_dialog.dart';
import '../providers/timesheet_filters_providers.dart';
import 'timesheet_list_filter_dropdown.dart';
import 'timesheet_objects_bar_dropdown.dart';
import 'timesheet_positions_bar_dropdown.dart';
import 'timesheet_filter_widget.dart';
import '../providers/timesheet_provider.dart';
import '../state/timesheet_state.dart';
import 'package:projectgt/features/employees/presentation/providers/employees_module_objects_provider.dart';
import 'package:projectgt/features/employees/presentation/utils/employees_layout_utils.dart';
import 'package:projectgt/features/employees/presentation/widgets/employee_details_modal.dart';
import 'package:projectgt/features/employees/presentation/widgets/employees_mobile_employee_details_sheet.dart';
import 'package:projectgt/features/roles/application/permission_service.dart';
import 'package:projectgt/features/roles/presentation/widgets/permission_guard.dart';
import 'package:projectgt/features/timesheet/presentation/widgets/timesheet_filters_toolbar.dart';

import 'timesheet_calendar_grid.dart';
import 'timesheet_attendance_stats.dart';
import 'timesheet_excel_action.dart';

/// Календарная сетка табеля: своя [Table], шапка закреплена над вертикальным скроллом,
/// горизонтальный скролл шапки и тела синхронизирован (как в таблице модуля «Подрядчики»).
///
/// Показывает активных сотрудников и уволенных, у которых есть часы в периоде.
/// Сегмент «Все / С часами / Без часов» и фильтр смены — [TimesheetListFilterDropdown].
///
/// Слева от ФИО — чекбоксы выбора строки; в шапке — общий выбор (частичный / полный).
///
/// Строки сетки — из справочника ([timesheetProvider].employees) с правилами
/// [visibleTimesheetGridEmployees] и [filterEmployeesByTimesheetNameSearch].
///
/// [entries] — записи за период (фильтр объектов — на сервере при загрузке).
/// Поиск по ФИО — только строки ([timesheetSearchQueryProvider]).
/// Часы в ячейках и «Итого по дням» — для отображаемых строк после поиска.
class TimesheetCalendarView extends ConsumerStatefulWidget {
  /// Записи табеля (фильтр объектов — на [TimesheetScreen]).
  final List<TimesheetEntry> entries;

  /// Начало периода.
  final DateTime startDate;

  /// Конец периода.
  final DateTime endDate;

  /// Создаёт сетку табеля.
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
  final ScrollController _verticalController = ScrollController();
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _headerHorizontalController = ScrollController();
  bool _isSyncingScroll = false;

  List<DateTime> _daysInRange = [];
  List<Employee> _allEmployees = [];

  /// Сотрудники после фильтров табеля (объект, сегмент, уволенные), без учёта поиска по ФИО.
  ///
  /// Заполняется в [_syncEmployeeRows]; поиск сужает [_allEmployees] в [_applySearchFilter].
  List<Employee> _employeesBase = [];

  /// `employeeId` → (`yyyy-MM-dd` → записи за день).
  final Map<String, Map<String, List<TimesheetEntry>>> _entriesByEmployeeDay =
      {};

  /// `yyyy-MM-dd` → все записи за день (итоги по дням).
  final Map<String, List<TimesheetEntry>> _entriesByDay = {};

  /// После [_syncEmployeeRows] список строк актуален (не путать с загрузкой).
  bool _employeeRowsSynced = false;

  ProviderSubscription<TimesheetState>? _timesheetSub;
  ProviderSubscription<TimesheetEmployeeListScope>? _employeeScopeSub;
  ProviderSubscription<TimesheetOpenShiftFilterScope>? _openShiftFilterSub;
  ProviderSubscription<Set<String>>? _positionFilterSub;
  ProviderSubscription<String>? _searchSub;

  @override
  void initState() {
    super.initState();
    _horizontalController.addListener(_syncHeaderScroll);
    _buildDateRange();
    _scheduleSyncEmployeeRows();

    _timesheetSub = ref.listenManual<TimesheetState>(timesheetProvider, (
      previous,
      next,
    ) {
      if (previous?.employees != next.employees ||
          previous?.entries != next.entries ||
          previous?.selectedObjectIds != next.selectedObjectIds ||
          previous?.todayOpenShift != next.todayOpenShift) {
        _scheduleSyncEmployeeRows();
      }
    });

    _employeeScopeSub = ref.listenManual<TimesheetEmployeeListScope>(
      timesheetEmployeeListScopeProvider,
      (previous, next) {
        if (previous != next) _scheduleSyncEmployeeRows();
      },
    );

    _openShiftFilterSub = ref.listenManual<TimesheetOpenShiftFilterScope>(
      timesheetOpenShiftFilterScopeProvider,
      (previous, next) {
        if (previous != next) _scheduleSyncEmployeeRows();
      },
    );

    _positionFilterSub = ref.listenManual<Set<String>>(
      timesheetSelectedPositionKeysProvider,
      (previous, next) {
        if (previous == next) return;
        _scheduleSyncEmployeeRows();
      },
    );

    _searchSub = ref.listenManual<String>(timesheetSearchQueryProvider, (
      previous,
      next,
    ) {
      if (previous == next) return;
      _applySearchFilter();
    });
  }

  @override
  void didUpdateWidget(TimesheetCalendarView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.startDate != widget.startDate ||
        oldWidget.endDate != widget.endDate) {
      _buildDateRange();
      final periodContainsToday = timesheetPeriodContainsToday(
        start: widget.startDate,
        end: widget.endDate,
      );
      if (!periodContainsToday &&
          ref.read(timesheetOpenShiftFilterScopeProvider) !=
              TimesheetOpenShiftFilterScope.all) {
        ref.read(timesheetOpenShiftFilterScopeProvider.notifier).state =
            TimesheetOpenShiftFilterScope.all;
      }
    }

    if (!identical(oldWidget.entries, widget.entries) ||
        oldWidget.entries.length != widget.entries.length) {
      _scheduleSyncEmployeeRows();
    }
  }

  @override
  void dispose() {
    _timesheetSub?.close();
    _employeeScopeSub?.close();
    _openShiftFilterSub?.close();
    _positionFilterSub?.close();
    _searchSub?.close();
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

  List<Employee> _employeesMatchingSearch(List<Employee> source) {
    if (source.isEmpty) return const [];
    return filterEmployeesByTimesheetNameSearch(
      source,
      ref.read(timesheetSearchQueryProvider),
    );
  }

  /// Откладывает [_syncEmployeeRows] после кадра (нельзя менять провайдеры в life-cycle).
  ///
  /// Сетка остаётся на экране с прежними строками до завершения пересчёта —
  /// без кратковременного скрытия всей таблицы.
  void _scheduleSyncEmployeeRows() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _syncEmployeeRows();
    });
  }

  /// Пересчёт строк и индекса часов при смене поиска (без пересчёта сегмента/объектов).
  void _applySearchFilter() {
    if (!mounted) return;
    final visible = _employeesMatchingSearch(_employeesBase);
    _rebuildEntryIndex(visible.map((e) => e.id).toSet());
    setState(() => _allEmployees = visible);
    _trimGridSelectionTo(visible);
  }

  void _trimGridSelectionTo(List<Employee> visible) {
    final visibleIds = visible.map((e) => e.id).toSet();
    final sel = ref.read(timesheetGridSelectedEmployeeIdsProvider);
    ref.read(timesheetGridSelectedEmployeeIdsProvider.notifier).state = sel
        .where(visibleIds.contains)
        .toSet();
  }

  /// Пересчитывает строки таблицы из [widget.entries] и [timesheetProvider] (без сети).
  void _syncEmployeeRows() {
    final timesheetState = ref.read(timesheetProvider);
    final allEmployees = timesheetState.employees;
    final entries = widget.entries;

    final hoursIndex = TimesheetHoursIndex.fromEntries(entries);
    final listScope = ref.read(timesheetEmployeeListScopeProvider);
    final openShiftScope = ref.read(timesheetOpenShiftFilterScopeProvider);
    final hasObjectFilter =
        timesheetState.selectedObjectIds?.isNotEmpty ?? false;
    final periodContainsToday = timesheetPeriodContainsToday(
      start: widget.startDate,
      end: widget.endDate,
    );
    final todayOpenShift = timesheetState.todayOpenShift;
    final positionKeys = ref.read(timesheetSelectedPositionKeysProvider);

    final List<Employee> baseFiltered;

    if (periodContainsToday &&
        openShiftScope == TimesheetOpenShiftFilterScope.inOpenShift) {
      var pool = employeesInTodayOpenShift(
        allEmployees: allEmployees,
        todayOpenShift: todayOpenShift,
        positionKeys: positionKeys,
        selectedObjectIds: timesheetState.selectedObjectIds,
      );
      pool = filterEmployeesByTimesheetListScope(pool, hoursIndex, listScope);
      pool.sort((a, b) {
        final nameA = formatFullName(a.lastName, a.firstName, a.middleName);
        final nameB = formatFullName(b.lastName, b.firstName, b.middleName);
        return nameA.compareTo(nameB);
      });
      baseFiltered = pool;
    } else {
      final scopeFiltered = visibleTimesheetGridEmployees(
        employees: allEmployees,
        hoursIndex: hoursIndex,
        hasObjectFilter: hasObjectFilter,
        listScope: listScope,
      );

      final positionFiltered = filterEmployeesByTimesheetPositionKeys(
        scopeFiltered,
        positionKeys,
      );

      if (periodContainsToday &&
          openShiftScope == TimesheetOpenShiftFilterScope.notInOpenShift) {
        baseFiltered = filterEmployeesByOpenShiftScope(
          positionFiltered,
          todayOpenShift: todayOpenShift,
          scope: TimesheetOpenShiftFilterScope.notInOpenShift,
          periodContainsToday: true,
        );
      } else {
        baseFiltered = _mergeTodayOpenShiftEmployees(
          positionFiltered,
          allEmployees: allEmployees,
          todayOpenShift: todayOpenShift,
          positionKeys: positionKeys,
          selectedObjectIds: timesheetState.selectedObjectIds,
          hoursIndex: hoursIndex,
          listScope: listScope,
        );
      }
    }

    final visible = _employeesMatchingSearch(baseFiltered);

    if (!mounted) return;
    _rebuildEntryIndex(visible.map((e) => e.id).toSet());
    setState(() {
      _employeesBase = baseFiltered;
      _allEmployees = visible;
      _employeeRowsSynced = true;
    });
    _trimGridSelectionTo(visible);
  }

  /// Добавляет в сетку назначенных в открытые смены сегодня (контроль выхода).
  ///
  /// Учитывает фильтры объектов, должностей и сегмент «С часами / Без часов».
  List<Employee> _mergeTodayOpenShiftEmployees(
    List<Employee> employees, {
    required List<Employee> allEmployees,
    required TimesheetTodayOpenShiftIndex todayOpenShift,
    required Set<String> positionKeys,
    required List<String>? selectedObjectIds,
    required TimesheetHoursIndex hoursIndex,
    required TimesheetEmployeeListScope listScope,
  }) {
    if (!timesheetPeriodContainsToday(
          start: widget.startDate,
          end: widget.endDate,
        ) ||
        todayOpenShift.employeeIds.isEmpty) {
      return employees;
    }

    final presentIds = employees.map((e) => e.id).toSet();
    final objectFilter = selectedObjectIds
        ?.where((id) => id.isNotEmpty)
        .toSet();

    var extras = allEmployees
        .where(
          (e) => todayOpenShift.contains(e.id) && !presentIds.contains(e.id),
        )
        .toList();

    extras = filterEmployeesByTimesheetPositionKeys(extras, positionKeys);

    if (objectFilter != null && objectFilter.isNotEmpty) {
      extras = extras
          .where(
            (e) => todayOpenShift.objectIdsFor(e.id).any(objectFilter.contains),
          )
          .toList();
    }

    extras = filterEmployeesByTimesheetListScope(extras, hoursIndex, listScope);

    if (extras.isEmpty) return employees;

    final merged = [...employees, ...extras];
    merged.sort((a, b) {
      final nameA = formatFullName(a.lastName, a.firstName, a.middleName);
      final nameB = formatFullName(b.lastName, b.firstName, b.middleName);
      return nameA.compareTo(nameB);
    });
    return merged;
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
    final notifier = ref.read(
      timesheetGridSelectedEmployeeIdsProvider.notifier,
    );
    if (value == true) {
      notifier.state = _allEmployees.map((e) => e.id).toSet();
    } else {
      notifier.state = <String>{};
    }
  }

  void _onRowCheckboxChanged(Employee employee, bool? checked) {
    final notifier = ref.read(
      timesheetGridSelectedEmployeeIdsProvider.notifier,
    );
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

  void _buildDateRange() {
    _daysInRange = [];
    var currentDate = widget.startDate;
    while (currentDate.isBefore(widget.endDate) ||
        currentDate.isAtSameMomentAs(widget.endDate)) {
      _daysInRange.add(currentDate);
      currentDate = currentDate.add(const Duration(days: 1));
    }
  }

  void _rebuildEntryIndex(Set<String> visibleEmployeeIds) {
    _entriesByEmployeeDay.clear();
    _entriesByDay.clear();
    for (final e in widget.entries) {
      if (!visibleEmployeeIds.contains(e.employeeId)) continue;
      final key = _dayKey(e.date);
      _entriesByDay.putIfAbsent(key, () => []).add(e);
      _entriesByEmployeeDay
          .putIfAbsent(e.employeeId, () => {})
          .putIfAbsent(key, () => [])
          .add(e);
    }
  }

  static String _dayKey(DateTime d) => TimesheetGridLayout.dayKey(d);

  /// Пустой список строк после синхронизации (фильтры / поиск / сегмент).
  Widget _buildEmptyEmployeesState(ThemeData theme) {
    final timesheetState = ref.read(timesheetProvider);
    final search = ref.read(timesheetSearchQueryProvider).trim();
    final scope = ref.read(timesheetEmployeeListScopeProvider);
    final openShiftScope = ref.read(timesheetOpenShiftFilterScopeProvider);
    final periodContainsToday = timesheetPeriodContainsToday(
      start: widget.startDate,
      end: widget.endDate,
    );
    final hasObjectFilter =
        timesheetState.selectedObjectIds?.isNotEmpty ?? false;
    final hasPositionFilter = hasActiveTimesheetPositionFilter(
      ref.read(timesheetSelectedPositionKeysProvider),
    );

    final String title;
    final String subtitle;

    if (search.isNotEmpty) {
      title = 'Никого не найдено';
      subtitle = 'Измените поиск или сбросьте фильтры';
    } else if (periodContainsToday &&
        openShiftScope == TimesheetOpenShiftFilterScope.inOpenShift) {
      title = 'Никого в открытых сменах';
      subtitle = hasObjectFilter
          ? 'На выбранных объектах сегодня нет назначений в смену'
          : 'Сегодня нет назначений в открытые смены или сбросьте фильтры';
    } else if (periodContainsToday &&
        openShiftScope == TimesheetOpenShiftFilterScope.notInOpenShift) {
      title = 'Нет сотрудников вне смены';
      subtitle = 'Все отображаемые сотрудники назначены в открытые смены сегодня';
    } else if (hasObjectFilter) {
      title = 'Нет сотрудников на выбранных объектах';
      subtitle = 'Выберите другие объекты или сбросьте фильтр';
    } else if (hasPositionFilter) {
      title = 'Нет сотрудников с выбранными должностями';
      subtitle = 'Выберите другие должности или сбросьте фильтр';
    } else {
      switch (scope) {
        case TimesheetEmployeeListScope.withHours:
          title = 'Нет сотрудников с часами';
          subtitle = 'За период ни у кого нет отработанных часов';
        case TimesheetEmployeeListScope.withoutHours:
          title = 'Нет сотрудников без часов';
          subtitle = 'У всех отображаемых сотрудников есть часы за период';
        case TimesheetEmployeeListScope.all:
          title = 'Нет сотрудников для отображения';
          subtitle = 'Проверьте состав компании или выберите другой период';
      }
    }

    final variant = theme.colorScheme.onSurfaceVariant;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: variant),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: variant),
            ),
          ],
        ),
      ),
    );
  }

  /// Одна строка: месяц, поиск (на ПК), фильтры и экспорт.
  ///
  /// На телефоне поиск в шапке экрана; здесь — компактный месяц и фильтры.
  Widget _buildTimesheetTitleRow(ThemeData theme) {
    final useMobileList = EmployeesLayoutUtils.useEmployeesMobileList(context);
    final periodContainsToday = timesheetPeriodContainsToday(
      start: widget.startDate,
      end: widget.endDate,
    );

    Widget toolbarRow({required bool includeSearch}) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final rowW = constraints.maxWidth;
          final searchW = includeSearch
              ? timesheetToolbarSearchWidth(rowW, hasMonthSwitcher: true)
              : 0.0;

          const trailingActions = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TimesheetAttendanceStatsAction(),
              SizedBox(width: 8),
              PermissionGuard(
                module: 'timesheet',
                permission: 'export',
                child: TimesheetExcelAction(),
              ),
            ],
          );

          final filters = Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const TimesheetCompactMonthSwitcher(),
              if (includeSearch) ...[
                const SizedBox(width: 12),
                SizedBox(width: searchW, child: const TimesheetToolbarSearch()),
              ],
              const SizedBox(width: 8),
              const TimesheetObjectsBarDropdown(),
              const SizedBox(width: 8),
              const TimesheetPositionsBarDropdown(),
              const SizedBox(width: 8),
              TimesheetListFilterDropdown(
                periodContainsToday: periodContainsToday,
              ),
            ],
          );

          if (!useMobileList) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                filters,
                const Spacer(),
                trailingActions,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: filters,
                ),
              ),
              const SizedBox(width: 12),
              trailingActions,
            ],
          );
        },
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: toolbarRow(includeSearch: !useMobileList),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gridSelectedIds = ref.watch(timesheetGridSelectedEmployeeIdsProvider);
    final isLoading = ref.watch(timesheetProvider.select((s) => s.isLoading));
    final todayOpenShift = ref.watch(
      timesheetProvider.select((s) => s.todayOpenShift),
    );
    final canViewEmployees = ref
        .watch(permissionServiceProvider)
        .can('employees', 'read');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTimesheetTitleRow(theme),
        Expanded(
          child: _allEmployees.isEmpty && (isLoading || !_employeeRowsSynced)
              ? const SizedBox.shrink()
              : _allEmployees.isEmpty
              ? _buildEmptyEmployeesState(theme)
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final dayCount = _daysInRange.length;
                    final viewportWidth = constraints.maxWidth.isFinite
                        ? constraints.maxWidth
                        : MediaQuery.sizeOf(context).width;
                    final layoutWidth = TimesheetGridLayout.layoutWidth(
                      dayCount,
                      viewportWidth,
                    );
                    final dividerColor = theme.colorScheme.outline.withValues(
                      alpha: 0.18,
                    );
                    final headerBackground = theme.brightness == Brightness.dark
                        ? theme.colorScheme.surfaceContainerHigh
                        : Colors.grey.shade200;

                    final header = SingleChildScrollView(
                      controller: _headerHorizontalController,
                      physics: const NeverScrollableScrollPhysics(),
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: layoutWidth,
                        child: TimesheetGridHeader(
                          daysInRange: _daysInRange,
                          dividerColor: dividerColor,
                          headerBackground: headerBackground,
                          selectAllValue: _headerSelectAllValue(
                            gridSelectedIds,
                          ),
                          onSelectAllChanged: _onHeaderSelectAllChanged,
                        ),
                      ),
                    );

                    final body = Expanded(
                      child: Scrollbar(
                        controller: _horizontalController,
                        thumbVisibility: true,
                        notificationPredicate: (n) => n.depth == 0,
                        child: SingleChildScrollView(
                          controller: _horizontalController,
                          scrollDirection: Axis.horizontal,
                          child: SizedBox(
                            width: layoutWidth,
                            child: Scrollbar(
                              controller: _verticalController,
                              thumbVisibility: true,
                              child: CustomScrollView(
                                controller: _verticalController,
                                primary: false,
                                slivers: [
                                  SliverFixedExtentList(
                                    itemExtent:
                                        TimesheetGridLayout.dataRowHeight,
                                    delegate: SliverChildBuilderDelegate(
                                      (context, index) {
                                        final employee = _allEmployees[index];
                                        return TimesheetGridEmployeeRow(
                                          employee: employee,
                                          daysInRange: _daysInRange,
                                          entriesByDayKey:
                                              _entriesByEmployeeDay[employee
                                                  .id] ??
                                              const {},
                                          todayOpenShift: todayOpenShift,
                                          isSelected: gridSelectedIds.contains(
                                            employee.id,
                                          ),
                                          dividerColor: dividerColor,
                                          onSelectionChanged: (v) =>
                                              _onRowCheckboxChanged(
                                                employee,
                                                v,
                                              ),
                                          onEmployeeNameTap: canViewEmployees
                                              ? () => _showEmployeeDetails(
                                                  employee,
                                                )
                                              : null,
                                          onAttendanceTap: () =>
                                              _showAttendanceDialog(employee),
                                          onDayWithHoursTap: _showEntryDetails,
                                        );
                                      },
                                      childCount: _allEmployees.length,
                                      addRepaintBoundaries: true,
                                    ),
                                  ),
                                  SliverToBoxAdapter(
                                    child: TimesheetGridTotalsRow(
                                      daysInRange: _daysInRange,
                                      entriesByDayKey: _entriesByDay,
                                      dividerColor: dividerColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        header,
                        const SizedBox(height: TimesheetGridLayout.headerGap),
                        body,
                      ],
                    );
                  },
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
                    Text(formatQuantity(entry.hours)),
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

  Future<void> _showEmployeeDetails(Employee employee) async {
    unawaited(
      ref
          .read(employee_state.employeeProvider.notifier)
          .ensureEmployeeCardDetails(employee),
    );
    if (!mounted) return;

    final objects = ref.read(employeesModuleObjectsProvider);

    if (EmployeesLayoutUtils.useEmployeesDesktopModal(context)) {
      await EmployeeDetailsModal.show(
        context,
        employee: employee,
        objects: objects,
      );
    } else {
      await EmployeesMobileEmployeeDetailsSheet.show(
        context,
        employee: employee,
        objects: objects,
      );
    }
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

    final objects = ref.read(availableObjectsForTimesheetProvider);

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
      await ref.read(timesheetProvider.notifier).reloadHoursEntries();
    }
  }
}
