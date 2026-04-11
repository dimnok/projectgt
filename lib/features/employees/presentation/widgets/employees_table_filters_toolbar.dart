import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/domain/entities/employee.dart';
import 'package:projectgt/features/objects/domain/entities/object.dart';
import 'package:projectgt/presentation/state/employee_state.dart'
    as employee_state;

// --- Единая геометрия строки фильтров (без GTTextField / GTDropdown) ---

const double _kH = 42;
const double _kR = 11;
const double _kFs = 14;
const double _kIcon = 18;
const double _kChipGap = 8;

/// Максимальная ширина триггера «Объект» (компактное поле).
const double _kObjectMaxWidth = 196;

/// Соотношение ширины: поиск / чипы статусов (объект фиксирован по [_kObjectMaxWidth]).
/// Поиск ≈ на треть уже прежнего (4:6 вместо 6:4) — освобождённая доля у чипов.
const int _kFlexSearch = 4;
const int _kFlexStatusChips = 6;

const double _kPanelRadius = 16;
const double _kPanelPaddingH = 16;
const double _kPanelPaddingV = 14;
const double _kDividerGap = 12;

Color _filtersFill(ThemeData theme) {
  final d = theme.brightness == Brightness.dark;
  return d ? Colors.white.withValues(alpha: 0.06) : Colors.white;
}

Color _filtersBorder(ThemeData theme, {required bool strong}) {
  final d = theme.brightness == Brightness.dark;
  if (strong) return d ? Colors.white : Colors.black;
  return d
      ? Colors.white.withValues(alpha: 0.14)
      : Colors.black.withValues(alpha: 0.1);
}

Color _panelBackdrop(ThemeData theme) {
  final d = theme.brightness == Brightness.dark;
  return d
      ? Colors.white.withValues(alpha: 0.04)
      : Colors.black.withValues(alpha: 0.02);
}

List<BoxShadow> _fieldShadows(ThemeData theme) {
  final d = theme.brightness == Brightness.dark;
  return [
    BoxShadow(
      color: Colors.black.withValues(alpha: d ? 0.35 : 0.06),
      blurRadius: d ? 10 : 6,
      offset: const Offset(0, 2),
    ),
  ];
}

BoxDecoration _panelDecoration(ThemeData theme) {
  return BoxDecoration(
    color: _panelBackdrop(theme),
    borderRadius: BorderRadius.circular(_kPanelRadius),
    border: Border.all(color: _filtersBorder(theme, strong: false)),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(
          alpha: theme.brightness == Brightness.dark ? 0.4 : 0.07,
        ),
        blurRadius: 20,
        offset: const Offset(0, 6),
        spreadRadius: -2,
      ),
    ],
  );
}

Widget _toolbarDivider(ThemeData theme) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: _kDividerGap / 2),
    child: Center(
      child: Container(
        width: 1,
        height: 26,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(1),
          color: _filtersBorder(theme, strong: false).withValues(alpha: 0.65),
        ),
      ),
    ),
  );
}

/// Значение фильтра таблицы сотрудников по привязке к объектам ([Employee.objectIds]).
///
/// Используется на [EmployeesTableScreen] вместе с [EmployeesTableFiltersToolbar].
@immutable
class EmployeesObjectTableFilterValue {
  const EmployeesObjectTableFilterValue._(this._kind, [this._objectId]);

  /// Без фильтра по объекту.
  static const EmployeesObjectTableFilterValue all =
      EmployeesObjectTableFilterValue._(_kAll);

  /// Только без привязки к объектам.
  static const EmployeesObjectTableFilterValue unassigned =
      EmployeesObjectTableFilterValue._(_kUnassigned);

  /// Фильтр по конкретному объекту.
  factory EmployeesObjectTableFilterValue.forObject(String objectId) {
    return EmployeesObjectTableFilterValue._(_kObject, objectId);
  }

  static const int _kAll = 0;
  static const int _kUnassigned = 1;
  static const int _kObject = 2;

  final int _kind;
  final String? _objectId;

  /// Объект выбранного типа ещё есть в списке [objects].
  bool isStillValid(List<ObjectEntity> objects) {
    if (_kind != _kObject) return true;
    final id = _objectId;
    if (id == null) return false;
    return objects.any((o) => o.id == id);
  }

  /// Соответствие сотрудника текущему фильтру.
  bool matches(Employee employee) {
    switch (_kind) {
      case _kAll:
        return true;
      case _kUnassigned:
        return employee.objectIds.isEmpty;
      case _kObject:
        final id = _objectId;
        if (id == null) return false;
        return employee.objectIds.contains(id);
      default:
        return true;
    }
  }

  /// Тело поля `objectFilter` для Edge Function `export-employees`.
  ///
  /// Должно совпадать с логикой [matches].
  Map<String, dynamic> toExportFilterJson() {
    switch (_kind) {
      case _kAll:
        return <String, dynamic>{'kind': 'all'};
      case _kUnassigned:
        return <String, dynamic>{'kind': 'unassigned'};
      case _kObject:
        return <String, dynamic>{
          'kind': 'object',
          'objectId': _objectId,
        };
      default:
        return <String, dynamic>{'kind': 'all'};
    }
  }

  @override
  bool operator ==(Object other) {
    return other is EmployeesObjectTableFilterValue &&
        other._kind == _kind &&
        other._objectId == _objectId;
  }

  @override
  int get hashCode => Object.hash(_kind, _objectId);
}

/// Самостоятельная строка фильтров таблицы сотрудников (без GTTextField/GTDropdown).
///
/// Единые высота [_kH] и скругление [_kR] для поиска, меню объекта и чипов.
class EmployeesTableFiltersToolbar extends ConsumerStatefulWidget {
  /// Создаёт тулбар фильтров.
  const EmployeesTableFiltersToolbar({
    super.key,
    required this.employeesForStatusCounts,
    required this.objectsForFilter,
    required this.objectsLoading,
    required this.selectedStatus,
    required this.onStatusSelected,
    required this.objectFilter,
    required this.onObjectFilterChanged,
  });

  /// Сотрудники для счётчиков на чипах (после поиска и фильтра по объекту).
  final List<Employee> employeesForStatusCounts;

  /// Объекты для выпадающего списка.
  final List<ObjectEntity> objectsForFilter;

  /// Загрузка списка объектов.
  final bool objectsLoading;

  /// Выбранный статус; `null` — «Все».
  final EmployeeStatus? selectedStatus;

  /// Смена фильтра по статусу.
  final ValueChanged<EmployeeStatus?> onStatusSelected;

  /// Текущий фильтр по объекту.
  final EmployeesObjectTableFilterValue objectFilter;

  /// Смена фильтра по объекту.
  final ValueChanged<EmployeesObjectTableFilterValue> onObjectFilterChanged;

  @override
  ConsumerState<EmployeesTableFiltersToolbar> createState() =>
      _EmployeesTableFiltersToolbarState();
}

class _EmployeesTableFiltersToolbarState
    extends ConsumerState<EmployeesTableFiltersToolbar> {
  late final TextEditingController _searchController;
  late final FocusNode _searchFocus;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: ref.read(employee_state.employeeProvider).searchQuery,
    );
    _searchFocus = FocusNode()..addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchFocus.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _syncSearch(String query) {
    Future<void>(() {
      if (!mounted) return;
      ref.read(employee_state.employeeProvider.notifier).setSearchQuery(query);
    });
  }

  BoxDecoration _box(ThemeData theme, {required bool strongBorder}) {
    return BoxDecoration(
      color: _filtersFill(theme),
      borderRadius: BorderRadius.circular(_kR),
      border: Border.all(
        color: _filtersBorder(theme, strong: strongBorder),
        width: strongBorder ? 1.5 : 1,
      ),
      boxShadow: _fieldShadows(theme),
    );
  }

  String _objectLabel(EmployeesObjectTableFilterValue v) {
    if (v == EmployeesObjectTableFilterValue.all) return 'Все объекты';
    if (v == EmployeesObjectTableFilterValue.unassigned) return 'Без объекта';
    final id = v._objectId;
    if (id == null) return '—';
    for (final o in widget.objectsForFilter) {
      if (o.id == id) return o.name;
    }
    return '—';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = <EmployeesObjectTableFilterValue>[
      EmployeesObjectTableFilterValue.all,
      EmployeesObjectTableFilterValue.unassigned,
      ...widget.objectsForFilter.map(
        (o) => EmployeesObjectTableFilterValue.forObject(o.id),
      ),
    ];

    final textStyle =
        theme.textTheme.bodyMedium?.copyWith(
          fontSize: _kFs,
          height: 1.2,
          color: theme.colorScheme.onSurface,
        ) ??
        TextStyle(fontSize: _kFs, color: theme.colorScheme.onSurface);

    return DecoratedBox(
      decoration: _panelDecoration(theme),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: _kPanelPaddingH,
          vertical: _kPanelPaddingV,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: _kFlexSearch,
              child: _ToolbarSearch(
                height: _kH,
                radius: _kR,
                decoration: _box(theme, strongBorder: _searchFocus.hasFocus),
                controller: _searchController,
                focusNode: _searchFocus,
                textStyle: textStyle,
                hintStyle: textStyle.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.42),
                ),
                onChanged: _syncSearch,
              ),
            ),
            _toolbarDivider(theme),
            ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: _kObjectMaxWidth,
                minWidth: 120,
              ),
              child: _ToolbarObjectMenu(
                height: _kH,
                radius: _kR,
                decoration: _box(theme, strongBorder: false),
                textStyle: textStyle,
                theme: theme,
                objectsLoading: widget.objectsLoading,
                selected: widget.objectFilter,
                items: items,
                labelFor: _objectLabel,
                onSelected: widget.onObjectFilterChanged,
              ),
            ),
            _toolbarDivider(theme),
            Expanded(
              flex: _kFlexStatusChips,
              child: _ToolbarStatusChips(
                height: _kH,
                radius: _kR,
                theme: theme,
                employees: widget.employeesForStatusCounts,
                selectedStatus: widget.selectedStatus,
                onStatusSelected: widget.onStatusSelected,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolbarSearch extends StatelessWidget {
  const _ToolbarSearch({
    required this.height,
    required this.radius,
    required this.decoration,
    required this.controller,
    required this.focusNode,
    required this.textStyle,
    required this.hintStyle,
    required this.onChanged,
  });

  final double height;
  final double radius;
  final BoxDecoration decoration;
  final TextEditingController controller;
  final FocusNode focusNode;
  final TextStyle textStyle;
  final TextStyle hintStyle;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final hasText = controller.text.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          height: height,
          decoration: decoration,
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(radius),
            child: Row(
              children: [
                const SizedBox(width: 10),
                Icon(
                  CupertinoIcons.search,
                  size: _kIcon,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    style: textStyle,
                    cursorHeight: _kFs + 2,
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText: 'Поиск: ФИО, должность, телефон',
                      hintStyle: hintStyle,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: onChanged,
                  ),
                ),
                if (hasText)
                  Tooltip(
                    message: 'Очистить',
                    waitDuration: const Duration(milliseconds: 400),
                    child: Semantics(
                      button: true,
                      label: 'Очистить поиск',
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            controller.clear();
                            onChanged('');
                          },
                          child: SizedBox(
                            width: height,
                            height: height,
                            child: Center(
                              child: Icon(
                                CupertinoIcons.xmark,
                                size: 20,
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.45,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  const SizedBox(width: 10),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ToolbarObjectMenu extends StatelessWidget {
  const _ToolbarObjectMenu({
    required this.height,
    required this.radius,
    required this.decoration,
    required this.textStyle,
    required this.theme,
    required this.objectsLoading,
    required this.selected,
    required this.items,
    required this.labelFor,
    required this.onSelected,
  });

  final double height;
  final double radius;
  final BoxDecoration decoration;
  final TextStyle textStyle;
  final ThemeData theme;
  final bool objectsLoading;
  final EmployeesObjectTableFilterValue selected;
  final List<EmployeesObjectTableFilterValue> items;
  final String Function(EmployeesObjectTableFilterValue) labelFor;
  final ValueChanged<EmployeesObjectTableFilterValue> onSelected;

  @override
  Widget build(BuildContext context) {
    final label = labelFor(selected);

    return MenuAnchor(
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(theme.colorScheme.surface),
        elevation: const WidgetStatePropertyAll(8),
        shadowColor: WidgetStatePropertyAll(
          theme.colorScheme.shadow.withValues(alpha: 0.28),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_kR),
            side: BorderSide(color: _filtersBorder(theme, strong: false)),
          ),
        ),
        maximumSize: const WidgetStatePropertyAll(Size(double.infinity, 320)),
      ),
      menuChildren: [
        for (final v in items)
          MenuItemButton(
            onPressed: objectsLoading ? null : () => onSelected(v),
            leadingIcon: v == selected
                ? Icon(
                    CupertinoIcons.check_mark,
                    size: _kIcon,
                    color: theme.colorScheme.primary,
                  )
                : const SizedBox(width: _kIcon, height: _kIcon),
            child: Text(
              labelFor(v),
              style: textStyle,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
      builder: (context, controller, _) {
        return Tooltip(
          message: 'Объект · $label',
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(radius),
            child: InkWell(
              borderRadius: BorderRadius.circular(radius),
              onTap: objectsLoading
                  ? null
                  : () {
                      if (controller.isOpen) {
                        controller.close();
                      } else {
                        controller.open();
                      }
                    },
              child: Ink(
                height: height,
                decoration: decoration,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      Icon(
                        CupertinoIcons.layers,
                        size: _kIcon,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.55,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textStyle,
                        ),
                      ),
                      if (objectsLoading)
                        const Padding(
                          padding: EdgeInsets.only(left: 4),
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      else
                        Icon(
                          controller.isOpen
                              ? CupertinoIcons.chevron_up
                              : CupertinoIcons.chevron_down,
                          size: _kIcon,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.45,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ToolbarStatusChips extends StatelessWidget {
  const _ToolbarStatusChips({
    required this.height,
    required this.radius,
    required this.theme,
    required this.employees,
    required this.selectedStatus,
    required this.onStatusSelected,
  });

  final double height;
  final double radius;
  final ThemeData theme;
  final List<Employee> employees;
  final EmployeeStatus? selectedStatus;
  final ValueChanged<EmployeeStatus?> onStatusSelected;

  static String _statusLabel(EmployeeStatus status) {
    switch (status) {
      case EmployeeStatus.working:
        return 'Работает';
      case EmployeeStatus.vacation:
        return 'Отпуск';
      case EmployeeStatus.sickLeave:
        return 'Болеет';
      case EmployeeStatus.unpaidLeave:
        return 'Б/С';
      case EmployeeStatus.fired:
        return 'Уволен';
    }
  }

  @override
  Widget build(BuildContext context) {
    final counts = <EmployeeStatus?, int>{
      null: employees.length,
      EmployeeStatus.working: 0,
      EmployeeStatus.vacation: 0,
      EmployeeStatus.sickLeave: 0,
      EmployeeStatus.unpaidLeave: 0,
      EmployeeStatus.fired: 0,
    };
    for (final e in employees) {
      counts[e.status] = (counts[e.status] ?? 0) + 1;
    }

    // Статусы с ненулевым счётчиком; выбранный статус оставляем, чтобы можно
    // было снять фильтр через «Все», даже если после других фильтров счётчик 0.
    final visibleStatuses = EmployeeStatus.values
        .where(
          (s) => (counts[s] ?? 0) > 0 || selectedStatus == s,
        )
        .toList(growable: false);
    final chipCount = 1 + visibleStatuses.length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final w =
            (constraints.maxWidth - ((chipCount - 1) * _kChipGap)) / chipCount;

        Widget chip({
          required String label,
          required int count,
          required bool selected,
          required VoidCallback onTap,
        }) {
          final d = theme.brightness == Brightness.dark;
          final accent = selected
              ? (d ? Colors.white : Colors.black)
              : theme.colorScheme.onSurface;
          return SizedBox(
            width: w,
            height: height,
            child: Material(
              color: selected
                  ? (d
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.05))
                  : _filtersFill(theme),
              borderRadius: BorderRadius.circular(radius),
              child: InkWell(
                borderRadius: BorderRadius.circular(radius),
                onTap: onTap,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(radius),
                    border: Border.all(
                      color: selected
                          ? (d ? Colors.white : Colors.black)
                          : _filtersBorder(theme, strong: false),
                      width: selected ? 1.5 : 1,
                    ),
                    boxShadow: _fieldShadows(theme),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontSize: 12,
                              height: 1.1,
                              color: accent.withValues(
                                alpha: selected ? 1 : 0.65,
                              ),
                              fontWeight: selected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$count',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 12,
                            height: 1.1,
                            color: accent.withValues(
                              alpha: selected ? 0.85 : 0.4,
                            ),
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            chip(
              label: 'Все',
              count: counts[null]!,
              selected: selectedStatus == null,
              onTap: () => onStatusSelected(null),
            ),
            ...visibleStatuses.map(
              (s) => chip(
                label: _statusLabel(s),
                count: counts[s] ?? 0,
                selected: selectedStatus == s,
                onTap: () => onStatusSelected(s),
              ),
            ),
          ],
        );
      },
    );
  }
}
