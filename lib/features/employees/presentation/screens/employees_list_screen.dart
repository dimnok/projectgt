import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:projectgt/domain/entities/employee.dart';
import 'package:projectgt/domain/entities/object.dart';
import 'package:projectgt/presentation/state/auth_state.dart';
import 'package:projectgt/presentation/state/employee_state.dart' as state;
import 'package:projectgt/presentation/state/object_state.dart';
import 'package:projectgt/presentation/widgets/app_bar_widget.dart';
import 'package:projectgt/presentation/widgets/app_drawer.dart';
import 'package:projectgt/features/employees/presentation/screens/employee_details_screen.dart';
import 'package:projectgt/core/utils/snackbar_utils.dart';
import 'package:projectgt/core/utils/modal_utils.dart';
import 'package:projectgt/core/utils/responsive_utils.dart';
import 'package:projectgt/features/employees/presentation/widgets/employee_card.dart';
import 'package:projectgt/features/employees/presentation/widgets/search_field.dart';
import 'package:projectgt/features/employees/presentation/widgets/master_detail_layout.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/presentation/widgets/cupertino_dialog_widget.dart';

/// Экран со списком сотрудников.
///
/// Позволяет просматривать, искать, фильтровать, добавлять, редактировать и удалять сотрудников.
/// Поддерживает мастер-детейл режим для desktop, адаптивен для мобильных устройств.
class EmployeesListScreen extends ConsumerStatefulWidget {
  /// Создаёт экран списка сотрудников.
  const EmployeesListScreen({super.key});

  @override
  ConsumerState<EmployeesListScreen> createState() => _EmployeesListScreenState();
}

/// Состояние для [EmployeesListScreen].
///
/// Управляет поиском, прокруткой, выбором сотрудника и обработкой событий UI.
class _EmployeesListScreenState extends ConsumerState<EmployeesListScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isSearchVisible = false;
  bool _preventRefresh = false;

  Employee? selectedEmployee;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(state.employeeProvider.notifier).getEmployees();
      ref.read(objectProvider.notifier).loadObjects();
    });
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  // Слушатель прокрутки для показа/скрытия поиска
  void _scrollListener() {
    final isMobile = ResponsiveUtils.isMobile(context);
    if (isMobile && _scrollController.position.pixels < -50) {
      if (!_isSearchVisible) {
        setState(() {
          _isSearchVisible = true;
          _preventRefresh = true;
        });
        
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            setState(() {
              _preventRefresh = false;
            });
          }
        });
      }
    } 
    else if (_scrollController.position.pixels > 0 && _isSearchVisible && isMobile) {
      setState(() {
        _isSearchVisible = false;
      });
    }
  }

  void _filterEmployees(String query) {
    ref.read(state.employeeProvider.notifier).setSearchQuery(query);
  }

  Future<void> _handleRefresh() async {
    if (_preventRefresh) {
      return Future.value();
    }
    
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
        final cmp = a.lastName.toLowerCase().compareTo(b.lastName.toLowerCase());
        if (cmp != 0) return cmp;
        return a.firstName.toLowerCase().compareTo(b.firstName.toLowerCase());
      });
      
    final isLoading = authState.status == AuthStatus.loading || 
                      employeeState.status == state.EmployeeStatus.loading ||
                      objectState.status == ObjectStatus.loading;
    
    final objects = objectState.objects;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBarWidget(
        title: 'Сотрудники',
        actions: [
          if (isDesktop && selectedEmployee != null) ...[
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.amber),
              tooltip: 'Редактировать',
              onPressed: () {
                ModalUtils.showEmployeeFormModal(context, employeeId: selectedEmployee!.id);
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              tooltip: 'Удалить',
              onPressed: () => _showDeleteDialog(selectedEmployee!),
            ),
          ],
        ],
      ),
      drawer: const AppDrawer(activeRoute: AppRoute.employees),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ModalUtils.showEmployeeFormModal(context);
        },
        backgroundColor: Colors.green,
        child: const Icon(Icons.add, color: Colors.white),
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
          // Поле поиска (всегда видимо)
          SearchField(
            controller: _searchController,
            labelText: 'Поиск сотрудников',
            onChanged: _filterEmployees,
          ),
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
          : EmployeeDetailsScreen(employeeId: selectedEmployee!.id, showAppBar: false),
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
    final theme = Theme.of(context);
    
    return Column(
      children: [
        // Поле поиска с анимацией появления/исчезновения
        SearchField(
          controller: _searchController,
          labelText: 'Поиск сотрудников',
          onChanged: _filterEmployees,
          isVisible: _isSearchVisible,
        ),
        // Подсказки для поиска
        _buildSearchHint(isMobile, theme),
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

  /// Отображает подсказку для поиска на мобильных устройствах.
  Widget _buildSearchHint(bool isMobile, ThemeData theme) {
    // Если не мобильный - не показываем подсказку
    if (!isMobile) {
      return const SizedBox.shrink();
    }
    
    // Выбираем текст подсказки в зависимости от состояния поиска
    final String hintText = _isSearchVisible
        ? "↓ Потяните ещё раз для обновления списка ↓"
        : "↓ Потяните вниз для поиска ↓";
    
    // Настраиваем отступы
    final double verticalPadding = _isSearchVisible ? 4.0 : 8.0;
    
    return Padding(
      padding: EdgeInsets.symmetric(vertical: verticalPadding),
      child: Center(
        child: Text(
          hintText,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ),
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
    final message = isEmptyList
      ? 'Список сотрудников пуст'
      : 'Сотрудники не найдены';
      
    return Center(
      child: Text(
        message,
        style: theme.textTheme.bodyLarge,
      ),
    );
  }
  
  /// Строит ListView с сотрудниками.
  Widget _buildEmployeesListView(
    List<Employee> employees, 
    bool isDesktop, 
    List<ObjectEntity> objects
  ) {
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
    final confirmed = await CupertinoDialogs.showDeleteConfirmDialog<bool>(
      context: context,
      title: 'Удалить сотрудника?',
      message: 'Вы уверены, что хотите удалить этого сотрудника?',
      onConfirm: () {},
    );
    
    if (confirmed == true) {
      try {
        await ref.read(state.employeeProvider.notifier).deleteEmployee(employee.id);
        if (!mounted) return;
        setState(() {
          selectedEmployee = null;
        });
        SnackBarUtils.showError(context, 'Сотрудник удалён');
      } catch (e) {
        if (!mounted) return;
        SnackBarUtils.showError(context, 'Ошибка удаления: ${e.toString()}');
      }
    }
  }
} 