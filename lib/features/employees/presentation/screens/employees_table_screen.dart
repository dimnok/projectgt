import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/core/utils/employee_ui_utils.dart';
import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/domain/entities/employee.dart';
import 'package:projectgt/features/objects/domain/entities/object.dart';
import 'package:projectgt/features/objects/presentation/state/object_state.dart';
import 'package:projectgt/presentation/state/employee_state.dart' as state;
import 'package:projectgt/features/roles/application/permission_service.dart';
import 'package:projectgt/presentation/widgets/app_bar_widget.dart';
import 'package:projectgt/presentation/widgets/app_drawer.dart';
import 'package:projectgt/core/widgets/gt_buttons.dart';
import 'package:projectgt/core/widgets/gt_text_field.dart';
import 'package:projectgt/core/utils/modal_utils.dart';

/// Экран управления сотрудниками в табличном виде.
///
/// Реализует полноэкранный список сотрудников в виде таблицы с закрепленным заголовком,
/// расширенной фильтрацией и возможностью быстрого изменения статуса и объектов.
class EmployeesTableScreen extends ConsumerStatefulWidget {
  const EmployeesTableScreen({super.key});

  @override
  ConsumerState<EmployeesTableScreen> createState() => _EmployeesTableScreenState();
}

class _EmployeesTableScreenState extends ConsumerState<EmployeesTableScreen> {
  final _searchController = TextEditingController();
  final Set<String> _selectedEmployeeIds = {};
  bool _isAllSelected = false;
  EmployeeStatus? _selectedStatusFilter;
  
  /// ID сотрудника, для которого сейчас открыто меню (для подсветки строки)
  String? _activeMenuEmployeeId;

  // Константы верстки для переиспользования
  static const _headerHeight = 56.0;
  static const _borderRadius = 16.0;
  static const _tableBorderRadius = 12.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(state.employeeProvider.notifier).getEmployees();
      ref.read(objectProvider.notifier).loadObjects();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    ref.read(state.employeeProvider.notifier).setSearchQuery(query);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final employeeState = ref.watch(state.employeeProvider);
    final objectState = ref.watch(objectProvider);
    final permissions = ref.watch(permissionServiceProvider);

    if (!permissions.can('employees_table', 'read')) {
      return const Scaffold(
        body: Center(child: Text('У вас нет прав для просмотра этой страницы')),
      );
    }

    final allFilteredBySearch = employeeState.filteredEmployees;
    
    // Оптимизированная фильтрация и сортировка
    final employees = allFilteredBySearch.where((e) {
      if (_selectedStatusFilter == null) return true;
      return e.status == _selectedStatusFilter;
    }).toList()
      ..sort((a, b) => a.lastName.compareTo(b.lastName));

    // Умный индикатор загрузки: только при пустом списке
    final isLoading = (employeeState.status == state.EmployeeStatus.loading && employees.isEmpty) ||
        (objectState.status == ObjectStatus.loading && objectState.objects.isEmpty);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBarWidget(
        title: 'Управление сотрудниками (${employees.length})',
        actions: [
          if (permissions.can('employees_table', 'create'))
            GTPrimaryButton(
              text: 'Добавить сотрудника',
              onPressed: () => ModalUtils.showEmployeeFormModal(context),
              icon: CupertinoIcons.add,
            ),
          const SizedBox(width: 8),
          if (permissions.can('employees_table', 'export'))
            GTSecondaryButton(
              text: 'Экспорт',
              onPressed: () {
                // TODO: Реализовать экспорт
              },
              icon: CupertinoIcons.cloud_download,
            ),
          const SizedBox(width: 16),
        ],
      ),
      drawer: const AppDrawer(activeRoute: AppRoute.employees),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            _buildFiltersRow(theme, allFilteredBySearch),
            const SizedBox(height: 24),
            Expanded(
              child: _buildTableContainer(theme, employees, objectState.objects, isLoading, permissions),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltersRow(ThemeData theme, List<Employee> allEmployees) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: GTTextField(
            controller: _searchController,
            hintText: 'Поиск сотрудника, должность...',
            prefixIcon: CupertinoIcons.search,
            onChanged: _onSearchChanged,
            borderRadius: _borderRadius,
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          flex: 5,
          child: _buildStatusFilterPanel(theme, allEmployees),
        ),
      ],
    );
  }

  Widget _buildStatusFilterPanel(ThemeData theme, List<Employee> allEmployees) {
    // Оптимизированный подсчет счетчиков за один проход
    final counts = <EmployeeStatus?, int>{
      null: allEmployees.length,
      EmployeeStatus.working: 0,
      EmployeeStatus.vacation: 0,
      EmployeeStatus.sickLeave: 0,
      EmployeeStatus.unpaidLeave: 0,
      EmployeeStatus.fired: 0,
    };

    for (final e in allEmployees) {
      counts[e.status] = (counts[e.status] ?? 0) + 1;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final buttonWidth = (constraints.maxWidth - (5 * 8)) / 6;
        
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _FilterButton(
              theme: theme,
              label: 'Все',
              count: counts[null]!,
              isSelected: _selectedStatusFilter == null,
              width: buttonWidth,
              onTap: () => setState(() => _selectedStatusFilter = null),
            ),
            ...EmployeeStatus.values.map((status) {
              final label = _getStatusLabel(status);
              return _FilterButton(
                theme: theme,
                label: label,
                count: counts[status] ?? 0,
                isSelected: _selectedStatusFilter == status,
                width: buttonWidth,
                onTap: () => setState(() => _selectedStatusFilter = status),
              );
            }),
          ],
        );
      },
    );
  }

  String _getStatusLabel(EmployeeStatus status) {
    switch (status) {
      case EmployeeStatus.working: return 'Работает';
      case EmployeeStatus.vacation: return 'Отпуск';
      case EmployeeStatus.sickLeave: return 'Болеет';
      case EmployeeStatus.unpaidLeave: return 'Б/С';
      case EmployeeStatus.fired: return 'Уволен';
    }
  }

  Widget _buildTableContainer(
    ThemeData theme,
    List<Employee> employees,
    List<ObjectEntity> objects,
    bool isLoading,
    PermissionService permissions,
  ) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    const columnWidths = {
      0: FixedColumnWidth(48),
      1: FlexColumnWidth(3),
      2: FlexColumnWidth(1.5),
      3: FlexColumnWidth(1.5),
      4: FlexColumnWidth(1.2),
      5: FlexColumnWidth(1.5),
      6: FlexColumnWidth(2),
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
              child: _buildScrollableBody(theme, employees, objects, columnWidths, permissions),
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
            .map((emp) => _buildDataRow(emp, objects, theme, employees.length, permissions))
            .toList(),
      ),
    );
  }

  Widget _buildHeaderCell(ThemeData theme, {required Widget child, EdgeInsetsGeometry? padding}) {
    return Padding(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 12),
      child: DefaultTextStyle(
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onSurface,
        ) ?? const TextStyle(fontWeight: FontWeight.bold),
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

    final objectNames = emp.objectIds
        .map((id) => objects.firstWhere(
              (o) => o.id == id, 
              orElse: () => const ObjectEntity(id: '', companyId: '', name: '—', address: '')
            ).name)
        .where((name) => name != '—')
        .join(', ');

    return TableRow(
      key: ValueKey(emp.id),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.1))),
        color: isMenuActive 
            ? theme.colorScheme.primary.withValues(alpha: 0.08) // Подсветка при открытом меню
            : (isSelected ? Colors.green.withValues(alpha: 0.05) : null),
      ),
      children: [
        _buildCheckboxCell(emp.id, isSelected, totalCount),
        _buildEmployeeInfoCell(theme, emp),
        _buildStatusCell(theme, emp, statusText, statusColor, permissions),
        _buildTextCell(emp.employmentDate != null ? formatRuDate(emp.employmentDate!) : '—'),
        _buildTextCell(emp.employmentType == EmploymentType.official ? 'Офиц.' : 'Неофиц.'),
        _buildTextCell(emp.currentHourlyRate != null ? formatCurrency(emp.currentHourlyRate!) : '—'),
        _buildObjectCell(theme, emp, objects, objectNames, permissions),
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

  Widget _buildEmployeeInfoCell(ThemeData theme, Employee emp) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundImage: emp.photoUrl != null ? CachedNetworkImageProvider(emp.photoUrl!) : null,
            child: emp.photoUrl == null ? const Icon(CupertinoIcons.person) : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(emp.fullName, style: const TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                if (emp.position != null)
                  Text(
                    emp.position!,
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCell(ThemeData theme, Employee emp, String text, Color color, PermissionService permissions) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: _InteractiveCellWrapper(
        theme: theme,
        text: text,
        color: color,
        onTap: permissions.can('employees_table', 'update') 
            ? (context) => _showStatusMenu(context, theme, emp)
            : null,
      ),
    );
  }

  Widget _buildObjectCell(ThemeData theme, Employee emp, List<ObjectEntity> objects, String objectNames, PermissionService permissions) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: _InteractiveCellWrapper(
        theme: theme,
        text: objectNames.isEmpty ? '—' : objectNames,
        onTap: permissions.can('employees_table', 'update')
            ? (context) => _showObjectMenu(context, theme, emp, objects)
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
              Container(width: 8, height: 8, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
              const SizedBox(width: 12),
              Text(statusText),
              if (emp.status == status) ...[
                const Spacer(),
                Icon(CupertinoIcons.check_mark, size: 16, color: theme.colorScheme.primary),
              ],
            ],
          ),
        );
      }).toList(),
    ).then((newStatus) {
      setState(() => _activeMenuEmployeeId = null); // Выключаем подсветку строки
      if (newStatus != null && newStatus != emp.status) {
        _updateEmployee(emp.copyWith(status: newStatus));
      }
    });
  }

  void _showObjectMenu(BuildContext context, ThemeData theme, Employee emp, List<ObjectEntity> objects) {
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
                Icon(CupertinoIcons.check_mark, size: 16, color: theme.colorScheme.primary),
            ],
          ),
        );
      }).toList(),
    ).then((objectId) {
      setState(() => _activeMenuEmployeeId = null); // Выключаем подсветку строки
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
      await ref.read(state.employeeProvider.notifier).updateEmployee(updatedEmployee);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка при обновлении: $e')),
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

/// Внутренний виджет кнопки фильтра для оптимизации ребилдов.
class _FilterButton extends StatelessWidget {
  final ThemeData theme;
  final String label;
  final int count;
  final bool isSelected;
  final double width;
  final VoidCallback onTap;

  const _FilterButton({
    required this.theme,
    required this.label,
    required this.count,
    required this.isSelected,
    required this.width,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = theme.brightness == Brightness.dark;
    final accentColor = isSelected ? (isDark ? Colors.white : Colors.black) : theme.colorScheme.onSurface;

    return SizedBox(
      width: width,
      height: 48,
      child: Material(
        color: isSelected 
            ? (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05))
            : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected 
                    ? (isDark ? Colors.white : Colors.black) 
                    : (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black12),
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: accentColor.withValues(alpha: isSelected ? 1.0 : 0.6),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  count.toString(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: accentColor.withValues(alpha: isSelected ? 1.0 : 0.4),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
  State<_InteractiveCellWrapper> createState() => _InteractiveCellWrapperState();
}

class _InteractiveCellWrapperState extends State<_InteractiveCellWrapper> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: widget.onTap != null ? (_) => setState(() => _isHovered = true) : null,
      onExit: widget.onTap != null ? (_) => setState(() => _isHovered = false) : null,
      cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
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
                    fontWeight: _isHovered ? FontWeight.bold : FontWeight.normal,
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
