import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/core/theme/theme_settings_provider.dart';
import 'package:projectgt/core/widgets/mobile_atmosphere_backdrop.dart';
import 'package:projectgt/core/widgets/mobile_atmosphere_card_style.dart';
import 'package:projectgt/core/widgets/mobile_atmosphere_screen_header.dart';
import 'package:projectgt/core/utils/employee_delete_error_mapper.dart';
import 'package:projectgt/core/widgets/app_snackbar.dart';
import 'package:projectgt/core/widgets/desktop_dialog_content.dart';
import 'package:projectgt/core/widgets/gt_buttons.dart';
import 'package:projectgt/core/widgets/gt_confirmation_dialog.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:projectgt/core/utils/employee_ui_utils.dart';
import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/domain/entities/employee.dart';
import 'package:projectgt/features/objects/domain/entities/object.dart';
import 'package:projectgt/features/objects/presentation/state/object_state.dart';
import 'package:projectgt/presentation/state/employee_state.dart' as state;
import 'package:projectgt/features/roles/application/permission_service.dart';
import 'package:projectgt/presentation/widgets/app_drawer.dart';
import 'package:projectgt/features/employees/presentation/widgets/add_employee_simple_dialog.dart';
import 'package:projectgt/features/employees/presentation/widgets/employees_table_actions_bar.dart';
import 'package:projectgt/features/company/presentation/providers/company_providers.dart';
import 'package:projectgt/features/employees/presentation/widgets/employees_table_filters_toolbar.dart';
import 'package:projectgt/features/employees/presentation/widgets/employee_details_modal.dart';
import 'package:projectgt/domain/entities/business_trip_rate.dart';
import 'package:projectgt/features/employees/presentation/providers/employees_module_objects_provider.dart';
import 'package:projectgt/features/employees/presentation/services/employee_server_excel_export_service.dart';

/// Отступы шапки и тела — как у экрана табеля ([TimesheetScreen]).
const _kEmployeesTableHeaderPadding = EdgeInsets.fromLTRB(16, 20, 16, 8);
const _kEmployeesTableBodyPadding = EdgeInsets.fromLTRB(16, 0, 16, 10);

/// Основная поверхность таблицы в визуальном языке атмосферы (градиент, тень, обводка).
class _EmployeesTableMainSurface extends StatelessWidget {
  const _EmployeesTableMainSurface({required this.child});

  final Widget child;

  static const double _outerRadius = 16;
  static const double _clipRadius = 15;

  @override
  Widget build(BuildContext context) {
    final appearance = MobileAtmosphereAppearance.of(context);
    final cardStyle = MobileAtmosphereCardStyle.fromAppearance(appearance);
    final hi = cardStyle.cardHighlight;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_outerRadius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [cardStyle.cardTop, cardStyle.cardBottom],
        ),
        boxShadow: cardStyle.cardShadows,
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_outerRadius),
        border: Border.fromBorderSide(
          BorderSide(
            color: cardStyle.cardBorder,
            width: 1,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_clipRadius),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          clipBehavior: Clip.antiAlias,
          children: [
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      hi.withValues(alpha: 0),
                      hi.withValues(alpha: 0.65),
                      hi.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
            Padding(padding: const EdgeInsets.all(16), child: child),
          ],
        ),
      ),
    );
  }
}

/// Экран управления сотрудниками в табличном виде.
///
/// Фон и шапка в стиле модуля «Табель»: [MobileAtmosphereBackdrop], круглая кнопка меню
/// и переключатель темы без стандартного AppBar; таблица внутри карточки [_EmployeesTableMainSurface].
class EmployeesTableScreen extends ConsumerStatefulWidget {
  /// Создаёт экран табличного управления сотрудниками.
  const EmployeesTableScreen({super.key});

  @override
  ConsumerState<EmployeesTableScreen> createState() =>
      _EmployeesTableScreenState();
}

class _EmployeesTableScreenState extends ConsumerState<EmployeesTableScreen> {
  final Set<String> _selectedEmployeeIds = {};
  bool _isAllSelected = false;
  EmployeeStatus? _selectedStatusFilter = EmployeeStatus.working;
  EmployeesObjectTableFilterValue _objectFilter =
      EmployeesObjectTableFilterValue.all;

  /// ID сотрудника, для которого сейчас открыто меню (для подсветки строки)
  String? _activeMenuEmployeeId;

  // Константы верстки для переиспользования
  static const _headerHeight = 56.0;
  static const _tableBorderRadius = 12.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final employeeNotifier = ref.read(state.employeeProvider.notifier);
      employeeNotifier.setSearchQuery('');
      employeeNotifier.getEmployees();
      ref.read(objectProvider.notifier).loadObjects();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final employeeState = ref.watch(state.employeeProvider);
    final objectState = ref.watch(objectProvider);
    final permissions = ref.watch(permissionServiceProvider);

    if (!permissions.can('employees', 'read')) {
      return const Scaffold(
        body: Center(child: Text('У вас нет прав для просмотра этой страницы')),
      );
    }

    final allFilteredBySearch = employeeState.filteredEmployees;

    final picklistObjects = ref.watch(employeesModuleObjectsProvider);

    ref.listen<List<ObjectEntity>>(employeesModuleObjectsProvider, (_, next) {
      if (_objectFilter == EmployeesObjectTableFilterValue.all) return;
      if (!_objectFilter.isStillValid(next)) {
        setState(() => _objectFilter = EmployeesObjectTableFilterValue.all);
      }
    });

    final afterObjectFilter = allFilteredBySearch
        .where((e) => _objectFilter.matches(e))
        .toList();

    // Оптимизированная фильтрация и сортировка
    final employees = afterObjectFilter.where((e) {
      if (_selectedStatusFilter == null) return true;
      return e.status == _selectedStatusFilter;
    }).toList()..sort((a, b) => a.lastName.compareTo(b.lastName));

    // Умный индикатор загрузки: только при пустом списке
    final isLoading =
        (employeeState.status == state.EmployeeStatus.loading &&
            employees.isEmpty) ||
        (objectState.status == ObjectStatus.loading &&
            picklistObjects.isEmpty);

    final appearance = MobileAtmosphereAppearance.of(context);
    final scheme = appearance.scheme;
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
            const MobileAtmosphereBackdrop(),
            SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: _kEmployeesTableHeaderPadding,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final narrow = constraints.maxWidth < 560;
                        final menuButton = Builder(
                          builder: (ctx) => MobileAtmosphereChromeCircleButton(
                            appearance: appearance,
                            tooltip: 'Меню',
                            icon: Icons.menu_rounded,
                            onTap: () => Scaffold.of(ctx).openDrawer(),
                          ),
                        );
                        final themeButton = MobileAtmosphereChromeCircleButton(
                          appearance: appearance,
                          tooltip: isDark ? 'Светлая тема' : 'Тёмная тема',
                          icon: isDark
                              ? Icons.light_mode_outlined
                              : Icons.dark_mode_outlined,
                          onTap: () {
                            ref
                                .read(themeSettingsProvider.notifier)
                                .setThemeMode(
                                  isDark ? ThemeMode.light : ThemeMode.dark,
                                );
                          },
                        );
                        final titleText =
                            'Управление сотрудниками (${employees.length})';

                        if (narrow) {
                          return MobileAtmosphereScreenHeader(
                            appearance: appearance,
                            title: titleText,
                            leading: menuButton,
                            trailing: themeButton,
                          );
                        }

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            menuButton,
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                titleText,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(color: scheme.onSurface),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: themeButton,
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: _kEmployeesTableBodyPadding,
                      child: _EmployeesTableMainSurface(
                        child: Column(
                          children: [
                            _buildFiltersRow(
                              context,
                              afterObjectFilter,
                              picklistObjects,
                              objectState.status == ObjectStatus.loading &&
                                  picklistObjects.isEmpty,
                              permissions,
                            ),
                            EmployeesTableActionsBar(
                              canCreate: false,
                              canExport: false,
                              onDeleteSelected:
                                  permissions.can('employees', 'delete') &&
                                      _selectedEmployeeIds.isNotEmpty
                                  ? () => _onDeleteSelectedEmployees(context)
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            Expanded(
                              child: _buildTableContainer(
                                theme,
                                employees,
                                picklistObjects,
                                isLoading,
                                permissions,
                              ),
                            ),
                          ],
                        ),
                      ),
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

  /// Подтверждение и удаление выбранных по чекбоксам сотрудников (desktop).
  Future<void> _onDeleteSelectedEmployees(BuildContext context) async {
    final ids = List<String>.from(_selectedEmployeeIds);
    if (ids.isEmpty) return;

    final confirmed = await GTConfirmationDialog.show(
      context: context,
      title: ids.length == 1 ? 'Удалить сотрудника?' : 'Удалить сотрудников?',
      message: ids.length == 1
          ? 'Запись будет удалена без возможности восстановления.'
          : 'Будет удалено сотрудников: ${ids.length}. Действие необратимо.',
      confirmText: 'Удалить',
      cancelText: 'Отмена',
      type: GTConfirmationType.danger,
    );
    if (confirmed != true || !context.mounted) return;

    final notifier = ref.read(state.employeeProvider.notifier);
    for (final id in ids) {
      await notifier.deleteEmployee(id);
      if (!context.mounted) return;
      final st = ref.read(state.employeeProvider);
      if (st.status == state.EmployeeStatus.error) {
        await _showEmployeeDeleteFailure(context, st.errorMessage);
        setState(() {
          _selectedEmployeeIds.clear();
          _isAllSelected = false;
        });
        return;
      }
    }

    if (!context.mounted) return;
    setState(() {
      _selectedEmployeeIds.clear();
      _isAllSelected = false;
    });
    AppSnackBar.show(
      context: context,
      message: ids.length == 1
          ? 'Сотрудник удалён'
          : 'Удалено сотрудников: ${ids.length}',
      kind: AppSnackBarKind.success,
    );
  }

  /// Ошибка удаления: при блокировке по связям — диалог со списком причин, иначе снекбар.
  Future<void> _showEmployeeDeleteFailure(
    BuildContext context,
    String? message,
  ) async {
    final text = message ?? 'Ошибка при удалении';
    if (!context.mounted) return;
    if (EmployeeDeleteErrorMapper.isStructuredBlock(text)) {
      final isDesktop = MediaQuery.of(context).size.width >= 900;
      await showDialog<void>(
        context: context,
        barrierColor: Colors.black.withValues(alpha: 0.6),
        builder: (dialogContext) {
          if (isDesktop) {
            return Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              insetPadding: const EdgeInsets.all(24),
              child: DesktopDialogContent(
                title: 'Удаление невозможно',
                width: 480,
                scrollable: true,
                footer: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GTPrimaryButton(
                      text: 'Понятно',
                      onPressed: () => Navigator.of(dialogContext).pop(),
                    ),
                  ],
                ),
                child: SelectableText(
                  text,
                  style: Theme.of(dialogContext).textTheme.bodyLarge,
                ),
              ),
            );
          }
          return AlertDialog(
            title: const Text('Удаление невозможно'),
            content: SingleChildScrollView(
              child: SelectableText(
                text,
                style: Theme.of(dialogContext).textTheme.bodyLarge,
              ),
            ),
            actions: [
              GTPrimaryButton(
                text: 'Понятно',
                onPressed: () => Navigator.of(dialogContext).pop(),
              ),
            ],
          );
        },
      );
      return;
    }
    if (!context.mounted) return;
    AppSnackBar.show(
      context: context,
      message: text,
      kind: AppSnackBarKind.error,
    );
  }

  Future<void> _exportEmployeesToExcel(BuildContext context) async {
    final companyId = ref.read(activeCompanyIdProvider);
    if (companyId == null || companyId.isEmpty) {
      if (!context.mounted) return;
      AppSnackBar.show(
        context: context,
        message: 'Не выбрана компания',
        kind: AppSnackBarKind.warning,
      );
      return;
    }

    final exportService = EmployeeServerExcelExportService(
      client: ref.read(supabaseClientProvider),
    );
    final searchQuery = ref.read(state.employeeProvider).searchQuery;

    try {
      final path = await exportService.exportEmployees(
        companyId: companyId,
        objectFilter: _objectFilter.toExportFilterJson(),
        statusFilter: _selectedStatusFilter?.name,
        searchQuery: searchQuery,
      );
      if (!context.mounted) return;
      if (path != null) {
        AppSnackBar.show(
          context: context,
          message: 'Файл сохранен: $path',
          kind: AppSnackBarKind.success,
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      AppSnackBar.show(
        context: context,
        message: 'Ошибка при экспорте: $e',
        kind: AppSnackBarKind.error,
      );
    }
  }

  Widget _buildFiltersRow(
    BuildContext context,
    List<Employee> employeesForStatusCounts,
    List<ObjectEntity> objectsForFilter,
    bool objectsLoading,
    PermissionService permissions,
  ) {
    return EmployeesTableFiltersToolbar(
      employeesForStatusCounts: employeesForStatusCounts,
      objectsForFilter: objectsForFilter,
      objectsLoading: objectsLoading,
      selectedStatus: _selectedStatusFilter,
      onStatusSelected: (status) =>
          setState(() => _selectedStatusFilter = status),
      objectFilter: _objectFilter,
      onObjectFilterChanged: (v) => setState(() => _objectFilter = v),
      canCreate: permissions.can('employees', 'create'),
      canExport: permissions.can('employees', 'export'),
      onAddEmployee: permissions.can('employees', 'create')
          ? () => AddEmployeeSimpleDialog.show(context)
          : null,
      onExport: permissions.can('employees', 'export')
          ? () => _exportEmployeesToExcel(context)
          : null,
    );
  }

  Widget _buildTableContainer(
    ThemeData theme,
    List<Employee> employees,
    List<ObjectEntity> objects,
    bool isLoading,
    PermissionService permissions,
  ) {
    if (isLoading) {
      return const Center(child: CupertinoActivityIndicator());
    }

    const columnWidths = {
      0: FixedColumnWidth(48),
      1: FlexColumnWidth(3),
      2: FlexColumnWidth(1.5),
      3: FlexColumnWidth(1.5),
      4: FlexColumnWidth(1.2),
      5: FlexColumnWidth(1.5),
      6: FlexColumnWidth(1.5),
      7: FlexColumnWidth(2),
    };

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
        borderRadius: BorderRadius.circular(_tableBorderRadius),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_tableBorderRadius),
        child: Column(
          children: [
            _buildStickyHeader(theme, employees, columnWidths),
            const Divider(height: 1, thickness: 1),
            Expanded(
              child: _buildScrollableBody(
                theme,
                employees,
                objects,
                columnWidths,
                permissions,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStickyHeader(
    ThemeData theme,
    List<Employee> employees,
    Map<int, TableColumnWidth> columnWidths,
  ) {
    return Container(
      height: _headerHeight,
      color: theme.brightness == Brightness.dark
          ? theme.colorScheme.surfaceContainerHighest
          : Colors.grey.shade100,
      child: Table(
        columnWidths: columnWidths,
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: [
          TableRow(
            children: [
              _buildHeaderCell(
                theme,
                padding: const EdgeInsets.only(left: 8),
                child: Checkbox(
                  value: _isAllSelected,
                  onChanged: (val) {
                    setState(() {
                      _isAllSelected = val ?? false;
                      if (_isAllSelected) {
                        _selectedEmployeeIds.addAll(employees.map((e) => e.id));
                      } else {
                        _selectedEmployeeIds.clear();
                      }
                    });
                  },
                ),
              ),
              _buildHeaderCell(theme, child: const Text('Сотрудник')),
              _buildHeaderCell(theme, child: const Text('Статус')),
              _buildHeaderCell(theme, child: const Text('Дата приема')),
              _buildHeaderCell(theme, child: const Text('Вид')),
              _buildHeaderCell(theme, child: const Text('Ставка')),
              _buildHeaderCell(theme, child: const Text('Суточные')),
              _buildHeaderCell(theme, child: const Text('Объект')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScrollableBody(
    ThemeData theme,
    List<Employee> employees,
    List<ObjectEntity> objects,
    Map<int, TableColumnWidth> columnWidths,
    PermissionService permissions,
  ) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Table(
        columnWidths: columnWidths,
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: employees
            .map(
              (emp) => _buildDataRow(
                emp,
                objects,
                theme,
                employees.length,
                permissions,
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildHeaderCell(
    ThemeData theme, {
    required Widget child,
    EdgeInsetsGeometry? padding,
  }) {
    return Padding(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 12),
      child: DefaultTextStyle(
        style:
            theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ) ??
            const TextStyle(fontWeight: FontWeight.bold),
        child: child,
      ),
    );
  }

  TableRow _buildDataRow(
    Employee emp,
    List<ObjectEntity> objects,
    ThemeData theme,
    int totalCount,
    PermissionService permissions,
  ) {
    final (statusText, statusColor) = EmployeeUIUtils.getStatusInfo(emp.status);
    final isSelected = _selectedEmployeeIds.contains(emp.id);
    final isMenuActive = _activeMenuEmployeeId == emp.id;

    return TableRow(
      key: ValueKey(emp.id),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.1)),
        ),
        color: isMenuActive
            ? theme.colorScheme.primary.withValues(
                alpha: 0.08,
              ) // Подсветка при открытом меню
            : (isSelected ? Colors.green.withValues(alpha: 0.05) : null),
      ),
      children: [
        _buildCheckboxCell(emp.id, isSelected, totalCount),
        _buildEmployeeInfoCell(theme, emp, objects),
        _buildStatusCell(theme, emp, statusText, statusColor, permissions),
        _buildTextCell(
          emp.employmentDate != null ? formatRuDate(emp.employmentDate!) : '—',
        ),
        _buildTextCell(
          EmployeeUIUtils.getEmploymentTypeText(emp.employmentType),
        ),
        _buildTextCell(
          emp.currentHourlyRate != null
              ? formatCurrency(emp.currentHourlyRate!)
              : '—',
        ),
        _BusinessTripCell(employee: emp, objects: objects),
        _ObjectCell(
          employee: emp,
          objects: objects,
          permissions: permissions,
          theme: theme,
          onShowMenu: _showObjectMenu,
        ),
      ],
    );
  }

  Widget _buildCheckboxCell(String id, bool isSelected, int totalCount) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Checkbox(
        value: isSelected,
        onChanged: (val) {
          setState(() {
            if (val == true) {
              _selectedEmployeeIds.add(id);
            } else {
              _selectedEmployeeIds.remove(id);
            }
            _isAllSelected = _selectedEmployeeIds.length == totalCount;
          });
        },
      ),
    );
  }

  Widget _buildEmployeeInfoCell(ThemeData theme, Employee emp, List<ObjectEntity> objects) {
    final hasPhone = emp.phone != null && emp.phone!.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => EmployeeDetailsModal.show(context, employee: emp, objects: objects),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                child: emp.photoUrl != null && emp.photoUrl!.trim().isNotEmpty
                    ? ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: emp.photoUrl!,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          errorWidget: (context, url, error) => Icon(
                            CupertinoIcons.person,
                            size: 22,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      )
                    : Icon(
                        CupertinoIcons.person,
                        color: theme.colorScheme.primary,
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            emp.fullName,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (hasPhone) ...[
                          const SizedBox(width: 6),
                          Tooltip(
                            message: formatPhone(emp.phone),
                            waitDuration: const Duration(milliseconds: 400),
                            child: Icon(
                              CupertinoIcons.phone,
                              size: 15,
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (emp.position != null)
                      Text(
                        emp.position!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCell(
    ThemeData theme,
    Employee emp,
    String text,
    Color color,
    PermissionService permissions,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: _InteractiveCellWrapper(
        theme: theme,
        text: text,
        color: color,
        onTap: permissions.can('employees', 'update')
            ? (context) => _showStatusMenu(context, theme, emp)
            : null,
      ),
    );
  }

  void _showStatusMenu(BuildContext context, ThemeData theme, Employee emp) {
    setState(() => _activeMenuEmployeeId = emp.id); // Включаем подсветку строки

    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final Offset offset = renderBox.localToGlobal(Offset.zero);

    showMenu<EmployeeStatus>(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx,
        offset.dy + renderBox.size.height,
        offset.dx + renderBox.size.width,
        offset.dy,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      items: EmployeeStatus.values.map((status) {
        final (statusText, statusColor) = EmployeeUIUtils.getStatusInfo(status);
        return PopupMenuItem<EmployeeStatus>(
          value: status,
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Text(statusText),
              if (emp.status == status) ...[
                const Spacer(),
                Icon(
                  CupertinoIcons.check_mark,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
              ],
            ],
          ),
        );
      }).toList(),
    ).then((newStatus) {
      setState(
        () => _activeMenuEmployeeId = null,
      ); // Выключаем подсветку строки
      if (newStatus != null && newStatus != emp.status) {
        _updateEmployee(emp.copyWith(status: newStatus));
      }
    });
  }

  void _showObjectMenu(
    BuildContext context,
    ThemeData theme,
    Employee emp,
    List<ObjectEntity> objects,
  ) {
    setState(() => _activeMenuEmployeeId = emp.id); // Включаем подсветку строки

    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final Offset offset = renderBox.localToGlobal(Offset.zero);

    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx,
        offset.dy + renderBox.size.height,
        offset.dx + renderBox.size.width,
        offset.dy,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      constraints: const BoxConstraints(minWidth: 200, maxWidth: 300),
      items: objects.map((obj) {
        final isSelected = emp.objectIds.contains(obj.id);
        return PopupMenuItem<String>(
          value: obj.id,
          child: Row(
            children: [
              Expanded(child: Text(obj.name, overflow: TextOverflow.ellipsis)),
              if (isSelected)
                Icon(
                  CupertinoIcons.check_mark,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
            ],
          ),
        );
      }).toList(),
    ).then((objectId) {
      setState(
        () => _activeMenuEmployeeId = null,
      ); // Выключаем подсветку строки
      if (objectId != null) {
        final newObjectIds = List<String>.from(emp.objectIds);
        if (newObjectIds.contains(objectId)) {
          newObjectIds.remove(objectId);
        } else {
          newObjectIds.add(objectId);
        }
        _updateEmployee(emp.copyWith(objectIds: newObjectIds));
      }
    });
  }

  Future<void> _updateEmployee(Employee updatedEmployee) async {
    try {
      await ref
          .read(state.employeeProvider.notifier)
          .updateEmployee(updatedEmployee);
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(
          context: context,
          message: 'Ошибка при обновлении: $e',
          kind: AppSnackBarKind.error,
        );
      }
    }
  }

  Widget _buildTextCell(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Text(text, overflow: TextOverflow.ellipsis),
    );
  }
}

/// Универсальный виджет для интерактивных ячеек (статус, объект) с эффектом при наведении.
class _InteractiveCellWrapper extends StatefulWidget {
  final ThemeData theme;
  final String text;
  final Color? color;
  final Function(BuildContext)? onTap;

  const _InteractiveCellWrapper({
    required this.theme,
    required this.text,
    this.color,
    this.onTap,
  });

  @override
  State<_InteractiveCellWrapper> createState() =>
      _InteractiveCellWrapperState();
}

class _InteractiveCellWrapperState extends State<_InteractiveCellWrapper> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: widget.onTap != null
          ? (_) => setState(() => _isHovered = true)
          : null,
      onExit: widget.onTap != null
          ? (_) => setState(() => _isHovered = false)
          : null,
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: widget.onTap != null ? () => widget.onTap!(context) : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 4),
          transform: Matrix4.translationValues(0, _isHovered ? -2 : 0, 0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.color != null) ...[
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: widget.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  widget.text,
                  style: TextStyle(
                    fontWeight: _isHovered
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: _isHovered ? widget.theme.colorScheme.primary : null,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BusinessTripCell extends ConsumerStatefulWidget {
  final Employee employee;
  final List<ObjectEntity> objects;

  const _BusinessTripCell({required this.employee, required this.objects});

  @override
  ConsumerState<_BusinessTripCell> createState() => _BusinessTripCellState();
}

class _BusinessTripCellState extends ConsumerState<_BusinessTripCell> {
  bool _isHovered = false;

  void _showRatesMenu(BuildContext context, List<BusinessTripRate> rates, ThemeData theme) {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final Offset offset = renderBox.localToGlobal(Offset.zero);

    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx,
        offset.dy + renderBox.size.height,
        offset.dx + renderBox.size.width,
        offset.dy,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      constraints: const BoxConstraints(minWidth: 200, maxWidth: 350),
      items: rates.map((rate) {
        final objName = widget.objects.firstWhere(
          (o) => o.id == rate.objectId,
          orElse: () => const ObjectEntity(id: '', companyId: '', name: 'Неизвестно', address: ''),
        ).name;
        
        return PopupMenuItem<String>(
          value: rate.id,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  objName,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                '${rate.rate.toStringAsFixed(0)} ₽',
                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ratesAsync = ref.watch(employeeBusinessTripRatesProvider(widget.employee.id));
    
    return ratesAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 12),
        child: Text('...', overflow: TextOverflow.ellipsis),
      ),
      error: (_, __) => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 12),
        child: Text('—', overflow: TextOverflow.ellipsis),
      ),
      data: (allRates) {
        final assignedObjectIds = widget.employee.objectIds;
        
        // Берем только активные ставки для объектов, к которым привязан сотрудник
        final relevantRates = allRates
            .where((r) => assignedObjectIds.contains(r.objectId) && r.isActive)
            .toList();
        
        String text = '—';
        bool isClickable = false;

        if (assignedObjectIds.isEmpty || relevantRates.isEmpty) {
          text = '—';
        } else if (relevantRates.length == 1) {
          text = '${relevantRates.first.rate.toStringAsFixed(0)} ₽';
        } else {
          text = 'Несколько';
          isClickable = true;
        }

        final theme = Theme.of(context);

        Widget cellContent = Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Text(
            text, 
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: _isHovered && isClickable ? FontWeight.bold : FontWeight.normal,
              color: _isHovered && isClickable ? theme.colorScheme.primary : null,
            ),
          ),
        );

        if (isClickable) {
          return MouseRegion(
            onEnter: (_) => setState(() => _isHovered = true),
            onExit: (_) => setState(() => _isHovered = false),
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => _showRatesMenu(context, relevantRates, theme),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                transform: Matrix4.translationValues(0, _isHovered ? -2 : 0, 0),
                child: cellContent,
              ),
            ),
          );
        }

        return cellContent;
      },
    );
  }
}

class _ObjectCell extends ConsumerStatefulWidget {
  final Employee employee;
  final List<ObjectEntity> objects;
  final PermissionService permissions;
  final ThemeData theme;
  final Function(BuildContext, ThemeData, Employee, List<ObjectEntity>) onShowMenu;

  const _ObjectCell({
    required this.employee,
    required this.objects,
    required this.permissions,
    required this.theme,
    required this.onShowMenu,
  });

  @override
  ConsumerState<_ObjectCell> createState() => _ObjectCellState();
}

class _ObjectCellState extends ConsumerState<_ObjectCell> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final ratesAsync = ref.watch(employeeBusinessTripRatesProvider(widget.employee.id));
    
    final assignedObjectIds = widget.employee.objectIds;
    final allRates = ratesAsync.valueOrNull ?? [];
    
    final relevantRates = allRates
        .where((r) => assignedObjectIds.contains(r.objectId) && r.isActive)
        .toList();
    
    final rateObjectIds = relevantRates.map((r) => r.objectId).toSet();

    List<InlineSpan> spans = [];
    for (int i = 0; i < assignedObjectIds.length; i++) {
      final objId = assignedObjectIds[i];
      final objName = widget.objects.firstWhere(
        (o) => o.id == objId,
        orElse: () => const ObjectEntity(id: '', companyId: '', name: '—', address: ''),
      ).name;

      if (objName == '—') continue;

      // Если у объекта есть активная ставка, выделяем его зеленым цветом и жирным шрифтом
      final hasRate = rateObjectIds.contains(objId);

      spans.add(TextSpan(
        text: objName + (i < assignedObjectIds.length - 1 ? ', ' : ''),
        style: TextStyle(
          fontWeight: hasRate ? FontWeight.bold : (_isHovered ? FontWeight.bold : FontWeight.normal),
          color: hasRate 
              ? Colors.green 
              : (_isHovered ? widget.theme.colorScheme.primary : widget.theme.colorScheme.onSurface),
        ),
      ));
    }

    if (spans.isEmpty) {
      spans.add(const TextSpan(text: '—'));
    }

    final onTap = widget.permissions.can('employees', 'update')
        ? () => widget.onShowMenu(context, widget.theme, widget.employee, widget.objects)
        : null;

    return MouseRegion(
      onEnter: onTap != null ? (_) => setState(() => _isHovered = true) : null,
      onExit: onTap != null ? (_) => setState(() => _isHovered = false) : null,
      cursor: onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
          transform: Matrix4.translationValues(0, _isHovered ? -2 : 0, 0),
          child: RichText(
            overflow: TextOverflow.ellipsis,
            text: TextSpan(
              style: widget.theme.textTheme.bodyMedium,
              children: spans,
            ),
          ),
        ),
      ),
    );
  }
}
