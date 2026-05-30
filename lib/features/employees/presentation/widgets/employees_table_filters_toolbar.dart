import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/utils/employee_ui_utils.dart';
import 'package:projectgt/core/widgets/gt_text_action_link.dart';
import 'package:projectgt/domain/entities/employee.dart';
import 'package:projectgt/features/objects/domain/entities/object.dart';
import 'package:projectgt/presentation/state/employee_state.dart'
    as employee_state;

// --- Геометрия и цвета как у панели табеля ([TimesheetObjectsBarDropdown],
// [TimesheetEmployeeListScopeSegment]): высота 34, скругление 18. ---

const double _kBarHeight = 34;
const double _kBarRadius = 18;
const double _kFs = 14;
const double _kIcon = 18;
const double _kMenuMaxHeight = 220;
const double _kMenuWidth = 200;

/// Обводка и заливка триггеров — как в модуле «Табель».
Color _tsBorderColor(ColorScheme scheme) =>
    scheme.outline.withValues(alpha: 0.38);

Color _tsTrackFill(ColorScheme scheme) =>
    scheme.surfaceContainerHighest.withValues(alpha: 0.45);

/// Запас для порога «нужен горизонтальный скролл» (не добавляется к ширине дорожки при обнимании).
const double _kStatusTrackScrollSlack = 8;

/// Микрозапас ширины дорожки (hinting). Лишнее пространство визуально делится пополам за счёт
/// [MainAxisAlignment.center] у ряда сегментов.
const double _kStatusTrackHugMicroSlack = 2;

/// Внешняя ширина дорожки минус область под [Row]: обводка 1+1 и внутренний [Padding] 2+2.
const double _kStatusTrackInnerPadDeduction = 6;

/// Ширина дорожки статусов по реальным подписям (запас под bold и масштаб текста).
double _measureEmployeesStatusTrackWidth(
  BuildContext context,
  ThemeData theme,
  List<String> labels,
) {
  final scaler = MediaQuery.textScalerOf(context);
  final style = (theme.textTheme.labelLarge ?? theme.textTheme.bodyMedium!)
      .copyWith(fontWeight: FontWeight.w600, fontSize: 12.5, height: 1.1);
  var w = 4.0;
  for (var i = 0; i < labels.length; i++) {
    if (i > 0) {
      w += 2.0;
    }
    final tp = TextPainter(
      text: TextSpan(text: labels[i], style: style),
      maxLines: 1,
      textScaler: scaler,
      textDirection: Directionality.of(context),
    )..layout(maxWidth: double.infinity);
    // Каждый сегмент: horizontal padding 10+10 и Border.all(width: 1) слева/справа (+2).
    w += math.max(56.0, tp.width + 22.0);
  }
  return w + 2.0;
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
        return <String, dynamic>{'kind': 'object', 'objectId': _objectId};
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

/// Строка фильтров таблицы сотрудников (без GTTextField/GTDropdown).
///
/// Компоновка в духе админ-панелей: поиск с **ограниченной шириной** слева;
/// выпадающий список объектов и дорожка статусов **рядом** (зазор 8px);
/// при [canCreate]/[canExport] — текстовые ссылки «Добавить сотрудника» и «Экспорт»
/// справа в той же строке.
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
    this.canCreate = false,
    this.canExport = false,
    this.onAddEmployee,
    this.onExport,
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

  /// Показывать ссылку «Добавить сотрудника» справа в строке фильтров.
  final bool canCreate;

  /// Показывать ссылку «Экспорт» справа в строке фильтров.
  final bool canExport;

  /// Добавление сотрудника (если [canCreate]).
  final VoidCallback? onAddEmployee;

  /// Экспорт списка (если [canExport]).
  final VoidCallback? onExport;

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

  BoxDecoration _searchDecoration(ThemeData theme, {required bool focused}) {
    final scheme = theme.colorScheme;
    final borderColor = focused
        ? scheme.primary.withValues(alpha: 0.85)
        : _tsBorderColor(scheme);
    final width = focused ? 1.5 : 1.0;
    return BoxDecoration(
      borderRadius: BorderRadius.circular(_kBarRadius),
      border: Border.all(color: borderColor, width: width),
      color: _tsTrackFill(scheme),
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
    final scheme = theme.colorScheme;
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
          color: scheme.onSurface,
        ) ??
        TextStyle(fontSize: _kFs, color: scheme.onSurface);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final rowW = constraints.maxWidth;
          final showToolbarActions =
              (widget.canCreate && widget.onAddEmployee != null) ||
              (widget.canExport && widget.onExport != null);
          const gapsReserveBase = 212.0;
          // Резерв под «Добавить сотрудника» и «Экспорт» справа в строке.
          const trailingActionsReserve = 300.0;
          final gapsReserve =
              gapsReserveBase +
              (showToolbarActions ? trailingActionsReserve : 0);
          final computedSearch = rowW.isFinite
              ? math.min(380.0, math.max(220.0, rowW * 0.34))
              : 380.0;
          final searchW = rowW.isFinite
              ? math.min(computedSearch, math.max(160.0, rowW - gapsReserve))
              : computedSearch;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: searchW,
                child: _ToolbarSearch(
                  decoration: _searchDecoration(
                    theme,
                    focused: _searchFocus.hasFocus,
                  ),
                  controller: _searchController,
                  focusNode: _searchFocus,
                  textStyle: textStyle,
                  hintStyle: textStyle.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.42),
                  ),
                  onChanged: _syncSearch,
                ),
              ),
              const SizedBox(width: 12),
              _ToolbarObjectMenu(
                scheme: scheme,
                objectsLoading: widget.objectsLoading,
                selected: widget.objectFilter,
                items: items,
                labelFor: _objectLabel,
                onSelected: widget.onObjectFilterChanged,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 2),
                    child: _EmployeesStatusSegmentBar(
                      scheme: scheme,
                      theme: theme,
                      employees: widget.employeesForStatusCounts,
                      selectedStatus: widget.selectedStatus,
                      onStatusSelected: widget.onStatusSelected,
                    ),
                  ),
                ),
              ),
              if (showToolbarActions) ...[
                const SizedBox(width: 12),
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 16,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (widget.canCreate && widget.onAddEmployee != null)
                      GtTextActionLink(
                        label: 'Добавить сотрудника',
                        onTap: widget.onAddEmployee!,
                      ),
                    if (widget.canExport && widget.onExport != null)
                      GtTextActionLink(
                        label: 'Экспорт',
                        onTap: widget.onExport!,
                      ),
                  ],
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _ToolbarSearch extends StatelessWidget {
  const _ToolbarSearch({
    required this.decoration,
    required this.controller,
    required this.focusNode,
    required this.textStyle,
    required this.hintStyle,
    required this.onChanged,
  });

  final BoxDecoration decoration;
  final TextEditingController controller;
  final FocusNode focusNode;
  final TextStyle textStyle;
  final TextStyle hintStyle;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final iconMuted = scheme.onSurface.withValues(alpha: 0.55);
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final hasText = controller.text.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          height: _kBarHeight,
          decoration: decoration,
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(_kBarRadius),
            child: Row(
              children: [
                const SizedBox(width: 10),
                Icon(Icons.search_rounded, size: _kIcon, color: iconMuted),
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
                            width: _kBarHeight,
                            height: _kBarHeight,
                            child: Center(
                              child: Icon(
                                Icons.close_rounded,
                                size: 20,
                                color: scheme.onSurface.withValues(alpha: 0.45),
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
    required this.scheme,
    required this.objectsLoading,
    required this.selected,
    required this.items,
    required this.labelFor,
    required this.onSelected,
  });

  final ColorScheme scheme;
  final bool objectsLoading;
  final EmployeesObjectTableFilterValue selected;
  final List<EmployeesObjectTableFilterValue> items;
  final String Function(EmployeesObjectTableFilterValue) labelFor;
  final ValueChanged<EmployeesObjectTableFilterValue> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = _tsBorderColor(scheme);
    final fill = _tsTrackFill(scheme);
    final iconMuted = scheme.onSurface.withValues(alpha: 0.55);
    final label = labelFor(selected);
    final triggerTextStyle = theme.textTheme.labelLarge?.copyWith(
      fontWeight: FontWeight.w600,
      fontSize: 14,
      height: 1.2,
      color: scheme.onSurface,
    );

    return MenuAnchor(
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(scheme.surface),
        elevation: const WidgetStatePropertyAll(6),
        shadowColor: WidgetStatePropertyAll(
          scheme.shadow.withValues(alpha: 0.18),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: borderColor),
          ),
        ),
        padding: const WidgetStatePropertyAll(EdgeInsets.zero),
      ),
      menuChildren: [
        _EmployeesObjectFilterMenu(
          key: ValueKey(
            '${objectsLoading}_${items.length}_${selected.hashCode}',
          ),
          scheme: scheme,
          theme: theme,
          objectsLoading: objectsLoading,
          items: items,
          selected: selected,
          labelFor: labelFor,
          onPick: onSelected,
        ),
      ],
      builder: (context, menuController, _) {
        return Tooltip(
          message: 'Фильтр по объектам',
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(_kBarRadius),
            child: InkWell(
              borderRadius: BorderRadius.circular(_kBarRadius),
              onTap: objectsLoading
                  ? null
                  : () {
                      if (menuController.isOpen) {
                        menuController.close();
                      } else {
                        menuController.open();
                      }
                    },
              child: Ink(
                height: _kBarHeight,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(_kBarRadius),
                  border: Border.all(color: borderColor),
                  color: fill,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.apartment_outlined,
                        size: _kIcon,
                        color: iconMuted,
                      ),
                      const SizedBox(width: 6),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 168),
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: triggerTextStyle,
                        ),
                      ),
                      const SizedBox(width: 2),
                      if (objectsLoading)
                        const CupertinoActivityIndicator(radius: 9)
                      else
                        Icon(
                          menuController.isOpen
                              ? Icons.expand_less_rounded
                              : Icons.expand_more_rounded,
                          size: 20,
                          color: iconMuted,
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

/// Содержимое меню объектов: заголовок «ОБЪЕКТЫ» и строки как в табеле.
class _EmployeesObjectFilterMenu extends StatelessWidget {
  const _EmployeesObjectFilterMenu({
    super.key,
    required this.scheme,
    required this.theme,
    required this.objectsLoading,
    required this.items,
    required this.selected,
    required this.labelFor,
    required this.onPick,
  });

  final ColorScheme scheme;
  final ThemeData theme;
  final bool objectsLoading;
  final List<EmployeesObjectTableFilterValue> items;
  final EmployeesObjectTableFilterValue selected;
  final String Function(EmployeesObjectTableFilterValue) labelFor;
  final ValueChanged<EmployeesObjectTableFilterValue> onPick;

  @override
  Widget build(BuildContext context) {
    final headerStyle = theme.textTheme.labelMedium?.copyWith(
      fontWeight: FontWeight.w600,
      fontSize: 11,
      letterSpacing: 0.4,
      height: 1.1,
      color: scheme.onSurface.withValues(alpha: 0.65),
    );
    final rowTextStyle = theme.textTheme.bodyMedium?.copyWith(
      fontSize: 13.5,
      height: 1.15,
      color: scheme.onSurface,
    );

    Widget row({
      required String semanticLabel,
      required bool isSelected,
      required String text,
      required VoidCallback onTap,
    }) {
      return Semantics(
        button: true,
        selected: isSelected,
        label: semanticLabel,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: objectsLoading
                ? null
                : () {
                    onTap();
                    MenuController.maybeOf(context)?.close();
                  },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 22,
                    child: isSelected
                        ? Icon(
                            Icons.check_rounded,
                            size: 18,
                            color: scheme.primary,
                          )
                        : null,
                  ),
                  Expanded(
                    child: Text(
                      text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: rowTextStyle?.copyWith(
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
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

    return SizedBox(
      width: _kMenuWidth,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 6, 10, 4),
            child: Text('ОБЪЕКТЫ', style: headerStyle),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: _kMenuMaxHeight),
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final v in items)
                    row(
                      semanticLabel: labelFor(v),
                      isSelected: v == selected,
                      text: labelFor(v),
                      onTap: () => onPick(v),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Сегментированный фильтр статусов в одной дорожке (в стиле табеля).
class _EmployeesStatusSegmentBar extends StatelessWidget {
  const _EmployeesStatusSegmentBar({
    required this.scheme,
    required this.theme,
    required this.employees,
    required this.selectedStatus,
    required this.onStatusSelected,
  });

  final ColorScheme scheme;
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
    final borderColor = _tsBorderColor(scheme);
    final trackFill = _tsTrackFill(scheme);
    final selectedFill = scheme.surface;
    final outlineSelected = scheme.outline.withValues(alpha: 0.22);
    final shadowSoft = scheme.shadow.withValues(alpha: 0.1);

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

    final visibleStatuses = EmployeeStatus.values
        .where((s) => (counts[s] ?? 0) > 0 || selectedStatus == s)
        .toList(growable: false);

    final statusLabels = ['Все', ...visibleStatuses.map(_statusLabel)];

    TextStyle segmentText(bool selected) {
      final base = theme.textTheme.labelLarge ?? theme.textTheme.bodyMedium!;
      return base.copyWith(
        fontWeight: FontWeight.w600,
        fontSize: 12.5,
        height: 1.1,
        color: selected
            ? scheme.onSurface
            : scheme.onSurface.withValues(alpha: 0.52),
      );
    }

    Widget segment({
      required String label,
      required bool selected,
      required VoidCallback onTap,
      Color? statusAccent,
    }) {
      final bool tinted = selected && statusAccent != null;
      final Color fillColor;
      final Color outlineColor;
      final Color shadowColor;
      if (!selected) {
        fillColor = Colors.transparent;
        outlineColor = Colors.transparent;
        shadowColor = Colors.transparent;
      } else if (tinted) {
        final accent = statusAccent;
        final tintA = theme.brightness == Brightness.dark ? 0.26 : 0.18;
        fillColor = Color.alphaBlend(
          accent.withValues(alpha: tintA),
          scheme.surface,
        );
        outlineColor = accent.withValues(
          alpha: theme.brightness == Brightness.dark ? 0.58 : 0.48,
        );
        shadowColor = accent.withValues(alpha: 0.14);
      } else {
        fillColor = selectedFill;
        outlineColor = outlineSelected;
        shadowColor = shadowSoft;
      }

      return Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(_kBarRadius - 3),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOutCubic,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            constraints: const BoxConstraints(minWidth: 56),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(_kBarRadius - 3),
              color: fillColor,
              border: Border.all(color: outlineColor, width: 1),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: shadowColor,
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ]
                  : null,
            ),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: segmentText(selected),
            ),
          ),
        ),
      );
    }

    Widget segmentRow() {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          segment(
            label: 'Все',
            selected: selectedStatus == null,
            onTap: () => onStatusSelected(null),
            statusAccent: null,
          ),
          ...visibleStatuses.expand(
            (s) => [
              const SizedBox(width: 2),
              segment(
                label: _statusLabel(s),
                selected: selectedStatus == s,
                onTap: () => onStatusSelected(s),
                statusAccent: EmployeeUIUtils.getStatusInfo(s).$2,
              ),
            ],
          ),
        ],
      );
    }

    return Tooltip(
      message: 'Фильтр по статусу сотрудника',
      child: Semantics(
        label: 'Статусы сотрудников',
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxOuter = constraints.maxWidth;
            final intrinsicMeasured = _measureEmployeesStatusTrackWidth(
              context,
              theme,
              statusLabels,
            );
            final scrollThreshold =
                intrinsicMeasured + _kStatusTrackScrollSlack;
            final hasWidthCap =
                maxOuter.isFinite && maxOuter > 0 && maxOuter < double.infinity;
            final useScroll = hasWidthCap && scrollThreshold > maxOuter;
            final barWidth = hasWidthCap
                ? (useScroll
                      ? maxOuter
                      : math.min(
                          intrinsicMeasured + _kStatusTrackHugMicroSlack,
                          maxOuter,
                        ))
                : null;

            final inner = useScroll
                ? SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    clipBehavior: Clip.hardEdge,
                    primary: false,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minWidth: math.max(
                          0,
                          barWidth! - _kStatusTrackInnerPadDeduction,
                        ),
                      ),
                      child: segmentRow(),
                    ),
                  )
                : segmentRow();

            final decorated = DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(_kBarRadius),
                border: Border.all(color: borderColor),
                color: trackFill,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(_kBarRadius),
                child: Padding(padding: const EdgeInsets.all(2), child: inner),
              ),
            );

            if (barWidth == null) {
              return SizedBox(height: _kBarHeight, child: decorated);
            }
            return SizedBox(
              width: barWidth,
              height: _kBarHeight,
              child: decorated,
            );
          },
        ),
      ),
    );
  }
}
