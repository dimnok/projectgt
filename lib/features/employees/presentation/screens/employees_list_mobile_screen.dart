import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/utils/employee_ui_utils.dart';
import 'package:projectgt/domain/entities/employee.dart';
import 'package:projectgt/presentation/state/employee_state.dart' as emp_state;
import 'package:projectgt/presentation/widgets/app_drawer.dart';
import 'package:projectgt/features/roles/application/permission_service.dart';
import 'package:projectgt/features/employees/presentation/widgets/employees_mobile_search_field.dart';
import 'package:projectgt/features/employees/presentation/widgets/employees_mobile_add_employee_button.dart';
import 'package:projectgt/core/widgets/app_snackbar.dart';
import 'package:projectgt/core/widgets/gt_buttons.dart';
import 'package:projectgt/core/widgets/mobile_bottom_sheet_content.dart';
import 'package:projectgt/features/employees/presentation/widgets/employees_mobile_atmosphere.dart';
import 'package:projectgt/features/employees/presentation/widgets/employees_mobile_employee_card.dart';
import 'package:projectgt/features/employees/presentation/widgets/employees_mobile_employee_details_sheet.dart';
import 'package:projectgt/features/employees/presentation/widgets/employees_mobile_swipeable_employee_card.dart';
import 'package:projectgt/features/objects/domain/entities/object.dart';
import 'package:projectgt/core/di/providers.dart';

/// Возвращает строку названий объектов [employee] через запятую по списку [objects].
///
/// Если привязок нет или имена не найдены — «Объекты не указаны».
String _employeeObjectsLine(Employee employee, List<ObjectEntity> objects) {
  const fallback = ObjectEntity(id: '', companyId: '', name: '', address: '');
  if (employee.objectIds.isEmpty) {
    return 'Объекты не указаны';
  }
  final names = employee.objectIds
      .map(
        (id) =>
            objects.firstWhere((o) => o.id == id, orElse: () => fallback).name,
      )
      .where((n) => n.isNotEmpty)
      .toList();
  if (names.isEmpty) {
    return 'Объекты не указаны';
  }
  return names.join(', ');
}

/// Мобильный экран: список сотрудников карточками в отдельном визуальном стиле.
///
/// Предназначен только для узких экранов; маршрут `/employees` на десктопе ведёт на
/// [EmployeesTableScreen]. Загружает данные через [emp_state.employeeProvider].
class EmployeesListMobileScreen extends ConsumerStatefulWidget {
  /// Создаёт мобильный экран списка сотрудников.
  const EmployeesListMobileScreen({super.key});

  @override
  ConsumerState<EmployeesListMobileScreen> createState() =>
      _EmployeesListMobileScreenState();
}

class _EmployeesListMobileScreenState
    extends ConsumerState<EmployeesListMobileScreen> {
  /// Выбранный статус для фильтра списка; `null` — показать всех.
  EmployeeStatus? _statusFilter;

  /// Увеличивается при начале вертикального скролла списка — закрывает открытые свайпы.
  int _listSwipeDismissEpoch = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(emp_state.employeeProvider.notifier).getEmployees();
      ref.read(objectProvider.notifier).loadObjects();
    });
  }

  void _onStatusChipTap(EmployeeStatus status) {
    setState(() {
      _listSwipeDismissEpoch++;
      if (_statusFilter == status) {
        _statusFilter = null;
      } else {
        _statusFilter = status;
      }
    });
  }

  /// Закрывает «раскрытые» свайпы у всех карточек при начале прокрутки списка.
  bool _onListScrollNotification(ScrollNotification notification) {
    if (notification is ScrollStartNotification) {
      setState(() => _listSwipeDismissEpoch++);
    }
    return false;
  }

  /// Bottom sheet: привязка сотрудника к объектам (как меню объектов на десктопе).
  Future<void> _showEmployeeObjectsAssignmentSheet(
    BuildContext context,
    WidgetRef ref,
    Employee employee,
    List<ObjectEntity> objects,
  ) async {
    setState(() => _listSwipeDismissEpoch++);
    await WidgetsBinding.instance.endOfFrame;
    if (!context.mounted) return;

    final selectedIds = List<String>.from(employee.objectIds);
    var saving = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return MobileBottomSheetContent(
              title: 'Объекты',
              sheetBackdrop: const EmployeesMobileAtmosphereBackdrop(),
              footer: Row(
                children: [
                  Expanded(
                    child: GTSecondaryButton(
                      text: 'Отмена',
                      onPressed: saving
                          ? null
                          : () => Navigator.pop(sheetContext),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GTPrimaryButton(
                      text: 'Сохранить',
                      isLoading: saving,
                      onPressed: saving
                          ? null
                          : () async {
                              setModalState(() => saving = true);
                              try {
                                await ref
                                    .read(emp_state.employeeProvider.notifier)
                                    .updateEmployee(
                                      employee.copyWith(objectIds: selectedIds),
                                    );
                                if (sheetContext.mounted) {
                                  Navigator.pop(sheetContext);
                                }
                              } catch (err) {
                                if (context.mounted) {
                                  setModalState(() => saving = false);
                                }
                                if (sheetContext.mounted) {
                                  AppSnackBar.show(
                                    context: sheetContext,
                                    message: 'Ошибка: $err',
                                    kind: AppSnackBarKind.error,
                                  );
                                }
                              }
                            },
                    ),
                  ),
                ],
              ),
              child: objects.isEmpty
                  ? Text(
                      'Нет доступных объектов',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final o in objects)
                          InkWell(
                            onTap: () {
                              setModalState(() {
                                if (selectedIds.contains(o.id)) {
                                  selectedIds.remove(o.id);
                                } else {
                                  selectedIds.add(o.id);
                                }
                              });
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 10,
                                horizontal: 4,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    selectedIds.contains(o.id)
                                        ? Icons.check_box
                                        : Icons.check_box_outline_blank,
                                    size: 22,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      o.name,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyMedium,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
            );
          },
        );
      },
    );
  }

  /// Bottom sheet: смена статуса сотрудника (как меню статуса на десктопе).
  Future<void> _showEmployeeStatusSheet(
    BuildContext context,
    WidgetRef ref,
    Employee employee,
  ) async {
    setState(() => _listSwipeDismissEpoch++);
    await WidgetsBinding.instance.endOfFrame;
    if (!context.mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return MobileBottomSheetContent(
          title: 'Статус',
          scrollable: true,
          sheetBackdrop: const EmployeesMobileAtmosphereBackdrop(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final status in EmployeeStatus.values)
                InkWell(
                  onTap: () async {
                    if (status == employee.status) {
                      Navigator.pop(sheetContext);
                      return;
                    }
                    try {
                      await ref
                          .read(emp_state.employeeProvider.notifier)
                          .updateEmployee(employee.copyWith(status: status));
                      if (sheetContext.mounted) {
                        Navigator.pop(sheetContext);
                      }
                    } catch (err) {
                      if (sheetContext.mounted) {
                        AppSnackBar.show(
                          context: sheetContext,
                          message: 'Ошибка: $err',
                          kind: AppSnackBarKind.error,
                        );
                      }
                    }
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 4,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: EmployeeUIUtils.getStatusInfo(status).$2,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            EmployeeUIUtils.getStatusInfo(status).$1,
                            style: Theme.of(sheetContext).textTheme.bodyMedium,
                          ),
                        ),
                        if (employee.status == status)
                          Icon(
                            Icons.check,
                            size: 20,
                            color: Theme.of(sheetContext).colorScheme.primary,
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final permissions = ref.watch(permissionServiceProvider);

    if (!permissions.can('employees', 'read')) {
      return const Scaffold(
        body: Center(child: Text('У вас нет прав для просмотра этой страницы')),
      );
    }

    final appearance = EmployeesMobileAppearance.of(context);
    final employeeState = ref.watch(emp_state.employeeProvider);
    final objectState = ref.watch(objectProvider);
    final allEmployees = List<Employee>.from(employeeState.employees)
      ..sort((a, b) => a.lastName.compareTo(b.lastName));
    final afterSearch = List<Employee>.from(employeeState.filteredEmployees)
      ..sort((a, b) => a.lastName.compareTo(b.lastName));

    final isLoading =
        employeeState.status == emp_state.EmployeeStatus.loading &&
        allEmployees.isEmpty;

    final isDark = appearance.isDark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: appearance.atmosphereBase,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness: isDark
            ? Brightness.light
            : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: isDark
            ? appearance.atmosphereBase
            : Colors.transparent,
        drawer: const AppDrawer(activeRoute: AppRoute.employees),
        body: Stack(
          fit: StackFit.expand,
          children: [
            const EmployeesMobileAtmosphereBackdrop(),
            SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
                    child: Row(
                      children: [
                        Builder(
                          builder: (ctx) => Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                setState(() => _listSwipeDismissEpoch++);
                                Scaffold.of(ctx).openDrawer();
                              },
                              borderRadius: BorderRadius.circular(22),
                              child: Container(
                                width: 44,
                                height: 44,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: appearance.chromeFill,
                                  borderRadius: BorderRadius.circular(22),
                                  border: Border.all(
                                    color: appearance.chromeBorder,
                                  ),
                                ),
                                child: Icon(
                                  Icons.menu_rounded,
                                  size: 22,
                                  color: appearance.scheme.onSurface,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Expanded(child: EmployeesMobileSearchField()),
                        if (permissions.can('employees', 'create')) ...[
                          const SizedBox(width: 8),
                          EmployeesMobileAddEmployeeButton(
                            chromeFill: appearance.chromeFill,
                            chromeBorder: appearance.chromeBorder,
                            addIconColor: appearance.scheme.primary,
                            onBeforeOpen: () =>
                                setState(() => _listSwipeDismissEpoch++),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Expanded(
                    child: _buildBody(
                      context,
                      appearance,
                      isLoading,
                      employeeState.status == emp_state.EmployeeStatus.error,
                      employeeState.errorMessage,
                      allEmployees,
                      afterSearch,
                      objectState.objects,
                      permissions.can('employees', 'update'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    EmployeesMobileAppearance appearance,
    bool isLoading,
    bool hasError,
    String? errorMessage,
    List<Employee> allEmployees,
    List<Employee> afterSearch,
    List<ObjectEntity> objects,
    bool canUpdateEmployees,
  ) {
    final scheme = appearance.scheme;
    if (isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: scheme.primary,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Загружаем список',
              style: TextStyle(
                color: scheme.onSurfaceVariant.withValues(alpha: 0.95),
                fontSize: 14,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      );
    }

    if (hasError && allEmployees.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Text(
            errorMessage ?? 'Не удалось загрузить список',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              fontSize: 15,
              height: 1.4,
            ),
          ),
        ),
      );
    }

    if (allEmployees.isEmpty) {
      return Center(
        child: Text(
          'Нет сотрудников',
          style: TextStyle(
            color: scheme.onSurfaceVariant.withValues(alpha: 0.9),
            fontSize: 15,
          ),
        ),
      );
    }

    if (afterSearch.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Text(
            'По запросу ничего не найдено',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: scheme.onSurfaceVariant.withValues(alpha: 0.95),
              fontSize: 15,
              height: 1.35,
            ),
          ),
        ),
      );
    }

    if (_statusFilter != null &&
        afterSearch.every((e) => e.status != _statusFilter)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _statusFilter = null);
      });
    }

    final filtered = _statusFilter == null
        ? afterSearch
        : afterSearch.where((e) => e.status == _statusFilter).toList();

    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildStatusChipsBar(appearance, allEmployees),
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Text(
                      'Нет сотрудников с этим статусом',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: scheme.onSurfaceVariant.withValues(alpha: 0.95),
                        fontSize: 15,
                        height: 1.35,
                      ),
                    ),
                  ),
                )
              : NotificationListener<ScrollNotification>(
                  onNotification: _onListScrollNotification,
                  child: ListView.builder(
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    padding: EdgeInsets.fromLTRB(10, 6, 10, 28 + bottomInset),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final e = filtered[index];
                      final positionLine =
                          (e.position?.trim().isNotEmpty ?? false)
                          ? e.position!.trim()
                          : 'Должность не указана';
                      final (statusLabel, statusColor) =
                          EmployeeUIUtils.getStatusInfo(e.status);
                      final card = EmployeesMobileEmployeeCard(
                        style: EmployeesMobileEmployeeCardStyle(
                          scheme: appearance.scheme,
                          cardTop: appearance.cardTop,
                          cardBottom: appearance.cardBottom,
                          cardBorder: appearance.cardBorder,
                          cardHighlight: appearance.cardHighlight,
                          cardShadows: appearance.cardShadows,
                        ),
                        photoUrl: e.photoUrl,
                        displayName: e.fullName,
                        positionLine: positionLine,
                        objectsLine: _employeeObjectsLine(e, objects),
                        statusSemanticsLabel: statusLabel,
                        statusColor: statusColor,
                      );
                      final tappableCard = Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () async {
                            if (!context.mounted) return;
                            setState(() => _listSwipeDismissEpoch++);
                            await WidgetsBinding.instance.endOfFrame;
                            if (!context.mounted) return;
                            await EmployeesMobileEmployeeDetailsSheet.show(
                              context,
                              employee: e,
                              objects: objects,
                            );
                          },
                          child: card,
                        ),
                      );

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: canUpdateEmployees
                            ? EmployeesMobileSwipeableEmployeeCard(
                                listSwipeResetEpoch: _listSwipeDismissEpoch,
                                onObjectsPressed: () =>
                                    _showEmployeeObjectsAssignmentSheet(
                                      context,
                                      ref,
                                      e,
                                      objects,
                                    ),
                                onStatusPressed: () =>
                                    _showEmployeeStatusSheet(context, ref, e),
                                child: tappableCard,
                              )
                            : tappableCard,
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  /// Горизонтальные текстовые чипы статусов; чип показывается только если в данных есть такие сотрудники.
  Widget _buildStatusChipsBar(
    EmployeesMobileAppearance appearance,
    List<Employee> employees,
  ) {
    final statusesWithCount = EmployeeStatus.values
        .where((s) => employees.where((e) => e.status == s).isNotEmpty)
        .toList();

    if (statusesWithCount.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
        child: Row(
          children: [
            for (var i = 0; i < statusesWithCount.length; i++) ...[
              if (i > 0) const SizedBox(width: 22),
              _MobileStatusTextChip(
                scheme: appearance.scheme,
                label: appearance.statusPresentation(statusesWithCount[i]).$1,
                selected: _statusFilter == statusesWithCount[i],
                onTap: () => _onStatusChipTap(statusesWithCount[i]),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Текстовый чип статуса (без заливки): при выборе — подчёркивание на всю ширину текста.
class _MobileStatusTextChip extends StatelessWidget {
  const _MobileStatusTextChip({
    required this.scheme,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final ColorScheme scheme;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? scheme.primary : scheme.onSurfaceVariant;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            letterSpacing: 0.1,
            height: 1.35,
            decoration: selected
                ? TextDecoration.underline
                : TextDecoration.none,
            decorationColor: scheme.primary,
            decorationThickness: 2,
            decorationStyle: TextDecorationStyle.solid,
          ),
        ),
      ),
    );
  }
}
