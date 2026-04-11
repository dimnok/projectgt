import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/presentation/state/employee_state.dart' as state;
import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/presentation/widgets/app_bar_widget.dart';
import 'package:projectgt/features/employees/presentation/widgets/employee_details_modal.dart';

/// Экран-обертка для отображения деталей сотрудника по прямой ссылке.
///
/// Загружает данные по [employeeId] и переиспользует UI из [EmployeeDetailsModal].
class EmployeeDetailsScreen extends ConsumerStatefulWidget {
  /// ID сотрудника, данные которого нужно загрузить и отобразить.
  final String employeeId;

  /// Создает экран-обертку для деталей сотрудника.
  const EmployeeDetailsScreen({super.key, required this.employeeId});

  @override
  ConsumerState<EmployeeDetailsScreen> createState() => _EmployeeDetailsScreenState();
}

class _EmployeeDetailsScreenState extends ConsumerState<EmployeeDetailsScreen> {
  /// Кэш контейнера Riverpod: [ProviderScope.containerOf] в [dispose] недопустим;
  /// также нужен для отложенного сброса поиска вне фазы построения дерева.
  ProviderContainer? _providerContainer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _providerContainer ??= ProviderScope.containerOf(context);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Future(() {
        if (!mounted) return;
        ref.read(state.employeeProvider.notifier).getEmployee(widget.employeeId);
        ref.read(objectProvider.notifier).loadObjects();
      });
    });
  }

  @override
  void dispose() {
    final container = _providerContainer;
    super.dispose();
    if (container != null) {
      Future(() {
        container.read(state.employeeProvider.notifier).setSearchQuery('');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final employeeState = ref.watch(state.employeeProvider);
    final objectState = ref.watch(objectProvider);

    // Ищем сотрудника в списке или берем загруженного
    final employee = employeeState.employees.where((e) => e.id == widget.employeeId).firstOrNull ?? 
                     (employeeState.employee?.id == widget.employeeId ? employeeState.employee : null);

    final isLoading = employee == null && employeeState.status == state.EmployeeStatus.loading;

    if (isLoading || objectState.objects.isEmpty) {
      return const Scaffold(
        appBar: AppBarWidget(title: 'Загрузка...', leading: BackButton(), showThemeSwitch: false),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (employee == null) {
      return Scaffold(
        appBar: const AppBarWidget(title: 'Ошибка', leading: BackButton(), showThemeSwitch: false),
        body: Center(child: Text('Сотрудник не найден', style: theme.textTheme.bodyLarge)),
      );
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      appBar: AppBarWidget(
        title: '${employee.lastName} ${employee.firstName}',
        leading: const BackButton(),
        showThemeSwitch: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1000),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.shadow.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(24.0),
            // Переиспользуем UI модального окна, но показываем его как часть экрана
            child: EmployeeDetailsModal(
              employee: employee,
              objects: objectState.objects,
            ),
          ),
        ),
      ),
    );
  }
}
