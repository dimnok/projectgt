import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:projectgt/domain/entities/employee.dart';
import 'package:projectgt/features/objects/domain/entities/object.dart';
import 'package:projectgt/presentation/state/auth_state.dart';
import 'package:projectgt/presentation/state/employee_state.dart' as state;
import 'package:projectgt/presentation/widgets/app_bar_widget.dart';
import 'package:projectgt/presentation/widgets/app_drawer.dart';
import 'package:projectgt/features/employees/presentation/screens/employee_details_screen.dart';
import 'package:projectgt/core/utils/modal_utils.dart';
import 'package:projectgt/core/utils/responsive_utils.dart';
import 'package:projectgt/features/employees/presentation/widgets/employee_card.dart';
import 'package:projectgt/features/employees/presentation/widgets/employee_statistics_modal.dart';

import 'package:projectgt/features/employees/presentation/widgets/master_detail_layout.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/features/objects/presentation/state/object_state.dart';
import 'package:projectgt/presentation/widgets/cupertino_dialog_widget.dart';
import 'package:projectgt/core/utils/snackbar_utils.dart';
import 'package:projectgt/features/roles/presentation/widgets/permission_guard.dart';

/// Экран со списком сотрудников.
///
/// Позволяет просматривать, искать, фильтровать, добавлять, редактировать и удалять сотрудников.
/// Поддерживает мастер-детейл режим для desktop, адаптивен для мобильных устройств.
class EmployeesListScreen extends ConsumerStatefulWidget {
  /// Создаёт экран списка сотрудников.
  const EmployeesListScreen({super.key});

  @override
  ConsumerState<EmployeesListScreen> createState() =>
      _EmployeesListScreenState();
}

/// Состояние для [EmployeesListScreen].
///
/// Управляет поиском, прокруткой, выбором сотрудника и обработкой событий UI.
class _EmployeesListScreenState extends ConsumerState<EmployeesListScreen> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  bool _showSearchField = false;
  bool _showFab = true;
  Timer? _fabTimer;

  Employee? selectedEmployee;

  Color _toggleColor(WidgetRef ref, String employeeId) {
    final map = ref.read(state.employeeProvider).canBeResponsibleMap;
    final isOn = map[employeeId] == true;
    return isOn ? Colors.green : Colors.red;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(state.employeeProvider.notifier).getEmployees();
      ref.read(objectProvider.notifier).loadObjects();
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    _fabTimer?.cancel();
    super.dispose();
  }

  /// Обработчик прокрутки для показа/скрытия поля поиска и FAB.
  void _onScroll() {
    final scrollPosition = _scrollController.position;

    // Показываем поиск при pull-down (отрицательные значения)
    if (scrollPosition.pixels < -100 && !_showSearchField) {
      setState(() {
        _showSearchField = true;
      });
    }
    // Скрываем поиск при прокрутке вниз
    else if (scrollPosition.pixels > 50 && _showSearchField) {
      setState(() {
        _showSearchField = false;
      });
    }

    // Скрываем FAB во время прокрутки
    if (_showFab) {
      setState(() {
        _showFab = false;
      });
    }

    // Отменяем предыдущий таймер
    _fabTimer?.cancel();

    // Устанавливаем новый таймер на 2 секунды после остановки прокрутки
    _fabTimer = Timer(const Duration(seconds: 2), () {
      if (mounted && !_scrollController.position.isScrollingNotifier.value) {
        setState(() {
          _showFab = true;
        });
      }
    });
  }

  /// Обработчик изменения поискового запроса.
  void _onSearchChanged(String query) {
    ref.read(state.employeeProvider.notifier).setSearchQuery(query);
  }

  Future<void> _handleRefresh() async {
    await ref.read(state.employeeProvider.notifier).refreshEmployees();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final employeeState = ref.watch(state.employeeProvider);
    final authState = ref.watch(authProvider);
    final objectState = ref.watch(objectProvider);
    final isMobile = ResponsiveUtils.isMobile(context);
    final isDesktop = ResponsiveUtils.isDesktop(context);

    final employees = List<Employee>.from(employeeState.filteredEmployees)
      ..sort((a, b) {
        final cmp =
            a.lastName.toLowerCase().compareTo(b.lastName.toLowerCase());
        if (cmp != 0) return cmp;
        return a.firstName.toLowerCase().compareTo(b.firstName.toLowerCase());
      });

    final isLoading = authState.status == AuthStatus.loading ||
        employeeState.status == state.EmployeeStatus.loading ||
        objectState.status == ObjectStatus.loading;

    final objects = objectState.objects;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      extendBodyBehindAppBar: true,
      appBar: AppBarWidget(
        title: 'Сотрудники',
        showSearchField: _showSearchField,
        searchController: _searchController,
        onSearchChanged: _onSearchChanged,
        searchHint: 'Поиск сотрудников...',
        actions: [
          // Иконка статистики сотрудников
          CupertinoButton(
            padding: EdgeInsets.zero,
            child: const Icon(Icons.info_outline),
            onPressed: () => EmployeeStatisticsModal.show(context, employees),
          ),
          if (isDesktop) ...[
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: Icon(
                _showSearchField ? Icons.search_off : Icons.search,
                color: _showSearchField ? Colors.green : null,
              ),
              onPressed: () {
                setState(() {
                  _showSearchField = !_showSearchField;
                  if (!_showSearchField) {
                    _searchController.clear();
                    _onSearchChanged('');
                  }
                });
              },
            ),
          ],
          if (isDesktop && selectedEmployee != null) ...[
            // Тоггл can_be_responsible для выделенного сотрудника (desktop)
            PermissionGuard(
              module: 'employees',
              permission: 'update',
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                child: Icon(
                  Icons.verified_user,
                  color: _toggleColor(ref, selectedEmployee!.id),
                ),
                onPressed: () async {
                  final current = selectedEmployee;
                  if (current == null) return;
                  final messenger = ScaffoldMessenger.of(context);
                  try {
                    await ref
                        .read(state.employeeProvider.notifier)
                        .toggleCanBeResponsible(current.id, null);
                    if (!mounted) return;
                    final isOn = ref
                            .read(state.employeeProvider)
                            .canBeResponsibleMap[current.id] ==
                        true;
                    SnackBarUtils.showSuccessByMessenger(
                      messenger,
                      isOn
                          ? 'Назначен статус ответственного'
                          : 'Снят статус ответственного',
                    );
                  } catch (e) {
                    if (!mounted) return;
                    SnackBarUtils.showErrorByMessenger(
                      messenger,
                      'Ошибка: ${e.toString()}',
                    );
                  }
                },
              ),
            ),
            PermissionGuard(
              module: 'employees',
              permission: 'update',
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                child: const Icon(Icons.edit, color: Colors.amber),
                onPressed: () {
                  ModalUtils.showEmployeeFormModal(context,
                      employeeId: selectedEmployee!.id);
                },
              ),
            ),
            PermissionGuard(
              module: 'employees',
              permission: 'delete',
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                child: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _showDeleteDialog(selectedEmployee!),
              ),
            ),
          ],
        ],
      ),
      drawer: const AppDrawer(activeRoute: AppRoute.employees),
      floatingActionButton: PermissionGuard(
        module: 'employees',
        permission: 'create',
        child: AnimatedScale(
          scale: _showFab ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          child: FloatingActionButton(
            onPressed: () {
              ModalUtils.showEmployeeFormModal(context);
            },
            backgroundColor: Colors.green,
            mini: ResponsiveUtils.isMobile(context),
            shape: const CircleBorder(),
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Определяем, какой контент отображать в зависимости от размера экрана
          if (isDesktop) {
            return _buildDesktopLayout(
              isLoading: isLoading,
              employees: employees,
              employeeState: employeeState,
              objects: objects,
            );
          } else {
            return _buildMobileLayout(
              isLoading: isLoading,
              employees: employees,
              employeeState: employeeState,
              isMobile: isMobile,
              isDesktop: isDesktop,
              objects: objects,
            );
          }
        },
      ),
    );
  }

  /// Строит десктопную версию интерфейса (мастер-детейл).
  Widget _buildDesktopLayout({
    required bool isLoading,
    required List<Employee> employees,
    required state.EmployeeState employeeState,
    required List<ObjectEntity> objects,
  }) {
    final theme = Theme.of(context);

    return MasterDetailLayout(
      masterPanel: Column(
        children: [
          // Список сотрудников
          Expanded(
            child: _buildEmployeesList(
              isLoading: isLoading,
              employees: employees,
              employeeState: employeeState,
              isDesktop: true,
              objects: objects,
            ),
          ),
        ],
      ),
      detailPanel: selectedEmployee == null
          ? Center(
              child: Text(
                'Выберите сотрудника из списка',
                style: theme.textTheme.bodyLarge,
              ),
            )
          : EmployeeDetailsScreen(
              employeeId: selectedEmployee!.id, showAppBar: false),
    );
  }

  /// Строит мобильную версию интерфейса.
  Widget _buildMobileLayout({
    required bool isLoading,
    required List<Employee> employees,
    required state.EmployeeState employeeState,
    required bool isMobile,
    required bool isDesktop,
    required List<ObjectEntity> objects,
  }) {
    return Column(
      children: [
        // Список сотрудников
        Expanded(
          child: _buildEmployeesList(
            isLoading: isLoading,
            employees: employees,
            employeeState: employeeState,
            isDesktop: isDesktop,
            objects: objects,
          ),
        ),
      ],
    );
  }

  /// Строит список сотрудников.
  Widget _buildEmployeesList({
    required bool isLoading,
    required List<Employee> employees,
    required state.EmployeeState employeeState,
    required bool isDesktop,
    required List<ObjectEntity> objects,
  }) {
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: _buildEmployeesListContent(
        isLoading: isLoading,
        employees: employees,
        employeeState: employeeState,
        isDesktop: isDesktop,
        theme: theme,
        objects: objects,
      ),
    );
  }

  /// Создает содержимое списка сотрудников в зависимости от состояния.
  Widget _buildEmployeesListContent({
    required bool isLoading,
    required List<Employee> employees,
    required state.EmployeeState employeeState,
    required bool isDesktop,
    required ThemeData theme,
    required List<ObjectEntity> objects,
  }) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (employees.isEmpty) {
      return _buildEmptyState(employeeState.searchQuery.isEmpty, theme);
    }

    return _buildEmployeesListView(employees, isDesktop, objects);
  }

  /// Строит состояние пустого списка сотрудников.
  Widget _buildEmptyState(bool isEmptyList, ThemeData theme) {
    final message =
        isEmptyList ? 'Список сотрудников пуст' : 'Сотрудники не найдены';

    return Center(
      child: Text(
        message,
        style: theme.textTheme.bodyLarge,
      ),
    );
  }

  /// Строит ListView с сотрудниками.
  Widget _buildEmployeesListView(
      List<Employee> employees, bool isDesktop, List<ObjectEntity> objects) {
    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: employees.length,
      itemBuilder: (context, index) {
        final employee = employees[index];
        final isSelected = selectedEmployee?.id == employee.id;

        return EmployeeCard(
          employee: employee,
          isSelected: isSelected,
          isCompact: isDesktop,
          objects: objects,
          onTap: () => _handleEmployeeTap(employee, isDesktop),
        );
      },
    );
  }

  /// Обрабатывает нажатие на карточку сотрудника.
  void _handleEmployeeTap(Employee employee, bool isDesktop) {
    if (isDesktop) {
      setState(() {
        selectedEmployee = employee;
      });
      ref.read(state.employeeProvider.notifier).getEmployee(employee.id);
    } else {
      context.pushNamed(
        'employee_details',
        pathParameters: {'employeeId': employee.id},
      );
    }
  }

  /// Показывает диалог подтверждения удаления.
  Future<void> _showDeleteDialog(Employee employee) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await CupertinoDialogs.showDeleteConfirmDialog<bool>(
      context: context,
      title: 'Удалить сотрудника?',
      message: 'Вы уверены, что хотите удалить этого сотрудника?',
      onConfirm: () {},
    );

    if (confirmed == true) {
      try {
        await ref
            .read(state.employeeProvider.notifier)
            .deleteEmployee(employee.id);
        if (!mounted) return;
        setState(() {
          selectedEmployee = null;
        });
        messenger.showSnackBar(
          const SnackBar(content: Text('Сотрудник удалён')),
        );
      } catch (e) {
        if (!mounted) return;
        messenger.showSnackBar(
          SnackBar(
            content: Text('Ошибка удаления: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
