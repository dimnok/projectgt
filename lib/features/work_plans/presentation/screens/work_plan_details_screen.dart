import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/domain/entities/work_plan.dart';
import 'package:projectgt/presentation/widgets/app_bar_widget.dart';
import 'package:projectgt/presentation/widgets/app_drawer.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/presentation/state/object_state.dart';
import 'package:projectgt/presentation/state/employee_state.dart' as state;
import 'package:projectgt/core/utils/responsive_utils.dart';
import 'package:projectgt/features/work_plans/presentation/widgets/work_plan_mobile_details.dart';
import 'package:intl/intl.dart';
import 'package:projectgt/core/utils/formatters.dart';

/// Экран с подробной информацией о плане работ.
///
/// Отображает детальную информацию о плане работ, включая блоки работ,
/// назначенных сотрудников, объемы и стоимость.
class WorkPlanDetailsScreen extends ConsumerStatefulWidget {
  /// ID плана работ для отображения.
  final String workPlanId;

  /// Показывать ли AppBar и Drawer.
  final bool showAppBar;

  /// Создаёт экран деталей плана работ.
  const WorkPlanDetailsScreen({
    super.key,
    required this.workPlanId,
    this.showAppBar = true,
  });

  @override
  ConsumerState<WorkPlanDetailsScreen> createState() =>
      _WorkPlanDetailsScreenState();
}

class _WorkPlanDetailsScreenState extends ConsumerState<WorkPlanDetailsScreen> {
  // Константные значения для повторяющихся отступов
  static const double _contentPadding = 16.0;

  @override
  void initState() {
    super.initState();

    // Загружаем данные
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(workPlanNotifierProvider.notifier).loadWorkPlans();
      ref.read(objectProvider.notifier).loadObjects();
      ref.read(state.employeeProvider.notifier).getEmployees();
    });
  }

  /// Форматирует дату
  String _formatDate(DateTime date) {
    return DateFormat('dd.MM.yyyy').format(date);
  }

  /// Форматирует сумму с разделителями тысяч
  String _formatCurrency(double amount) => formatCurrency(amount);

  @override
  Widget build(BuildContext context) {
    // Для мобильных устройств используем отдельный виджет
    if (ResponsiveUtils.isMobile(context)) {
      return WorkPlanMobileDetails(
        workPlanId: widget.workPlanId,
        showAppBar: widget.showAppBar,
      );
    }

    // Для десктопа используем текущую реализацию
    final theme = Theme.of(context);
    final workPlanState = ref.watch(workPlanNotifierProvider);
    final objectState = ref.watch(objectProvider);
    final employeeState = ref.watch(state.employeeProvider);

    // Ищем план работ по ID
    final workPlan = workPlanState.workPlans
        .where((wp) => wp.id == widget.workPlanId)
        .firstOrNull;

    final isLoading = workPlan == null && workPlanState.isLoading;

    if (isLoading) {
      return Scaffold(
        appBar:
            widget.showAppBar ? const AppBarWidget(title: 'План работ') : null,
        drawer: widget.showAppBar
            ? const AppDrawer(activeRoute: AppRoute.workPlans)
            : null,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (workPlan == null) {
      return Scaffold(
        appBar:
            widget.showAppBar ? const AppBarWidget(title: 'План работ') : null,
        drawer: widget.showAppBar
            ? const AppDrawer(activeRoute: AppRoute.workPlans)
            : null,
        body: Center(
          child: Text(
            'План работ не найден',
            style: theme.textTheme.bodyLarge,
          ),
        ),
      );
    }

    // Получаем объект по ID
    final objectEntity = objectState.objects
        .where((obj) => obj.id == workPlan.objectId)
        .firstOrNull;

    // Общий стиль для заголовков секций
    final sectionTitleStyle = theme.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.bold,
    );

    // Общий стиль для меток
    final labelStyle = TextStyle(
      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
      fontSize: ResponsiveUtils.adaptiveValue(
          context: context, mobile: 14.0, desktop: 15.0),
    );

    // Общий стиль для значений
    final valueStyle = TextStyle(
      fontWeight: FontWeight.w500,
      fontSize: ResponsiveUtils.adaptiveValue(
          context: context, mobile: 15.0, desktop: 16.0),
    );

    return Scaffold(
      appBar: widget.showAppBar
          ? AppBarWidget(
              title: 'План работ на ${_formatDate(workPlan.date)}',
              leading: const BackButton(),
              showThemeSwitch: false,
            )
          : null,
      drawer: null,
      body: Column(
        children: [
          // Отступ сверху для мастер-детейл режима (когда AppBar скрыт)
          if (!widget.showAppBar)
            SizedBox(
              height:
                  MediaQuery.of(context).viewPadding.top + kToolbarHeight + 24,
            ),
          // Отступ сверху как в списке планов работ
          SizedBox(
            height: ResponsiveUtils.isMobile(context) ? 8 : 6,
          ),
          // Единый блок с информацией и табами
          Container(
            margin: EdgeInsets.symmetric(
              horizontal: ResponsiveUtils.isMobile(context) ? 16 : 0,
            ),
            constraints: ResponsiveUtils.isMobile(context)
                ? BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width - 32,
                  )
                : null,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.2),
                width: 0.5,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.shadow.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Шапка с основной информацией
                Padding(
                  padding: EdgeInsets.all(ResponsiveUtils.adaptiveValue(
                    context: context,
                    mobile: _contentPadding,
                    desktop: _contentPadding * 1.5,
                  )),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Дата и объект
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Иконка плана работ
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: theme.colorScheme.outline
                                    .withValues(alpha: 0.3),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: theme.colorScheme.shadow
                                      .withValues(alpha: 0.1),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: ResponsiveUtils.adaptiveValue(
                                context: context,
                                mobile: 40.0,
                                desktop: 50.0,
                              ),
                              backgroundColor: theme.colorScheme.primary
                                  .withValues(alpha: 0.1),
                              child: Icon(
                                Icons.assignment_outlined,
                                size: ResponsiveUtils.adaptiveValue(
                                  context: context,
                                  mobile: 32.0,
                                  desktop: 40.0,
                                ),
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),

                          const SizedBox(width: 16),

                          // Основная информация о плане работ
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Дата
                                Text(
                                  'План работ на ${_formatDate(workPlan.date)}',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: ResponsiveUtils.adaptiveValue(
                                      context: context,
                                      mobile: theme
                                              .textTheme.titleLarge?.fontSize ??
                                          22.0,
                                      desktop: (theme.textTheme.titleLarge
                                                  ?.fontSize ??
                                              22.0) *
                                          1.2,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                    height: ResponsiveUtils.adaptiveValue(
                                  context: context,
                                  mobile: 8.0,
                                  desktop: 12.0,
                                )),
                                // Объект
                                Text(
                                  objectEntity?.name ??
                                      workPlan.objectName ??
                                      'Неизвестный объект',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontSize: ResponsiveUtils.adaptiveValue(
                                      context: context,
                                      mobile: theme.textTheme.titleMedium
                                              ?.fontSize ??
                                          16.0,
                                      desktop: (theme.textTheme.titleMedium
                                                  ?.fontSize ??
                                              16.0) *
                                          1.1,
                                    ),
                                  ),
                                ),
                                if (objectEntity?.address != null) ...[
                                  SizedBox(
                                      height: ResponsiveUtils.adaptiveValue(
                                    context: context,
                                    mobile: 4.0,
                                    desktop: 6.0,
                                  )),
                                  Text(
                                    objectEntity!.address,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.6),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Содержимое с блоками работ
          Expanded(
            child: _buildWorkBlocksTab(workPlan, objectState, employeeState,
                theme, labelStyle, valueStyle, sectionTitleStyle),
          ),
        ],
      ),
    );
  }

  /// Строит вкладку с блоками работ
  Widget _buildWorkBlocksTab(
      WorkPlan workPlan,
      ObjectState objectState,
      state.EmployeeState employeeState,
      ThemeData theme,
      TextStyle labelStyle,
      TextStyle valueStyle,
      TextStyle? sectionTitleStyle) {
    return ListView(
      padding: EdgeInsets.all(ResponsiveUtils.getAdaptivePadding(context)),
      children: [
        // Удалено: повтор заголовка "План работ на ..."
        ...workPlan.workBlocks.asMap().entries.map((entry) {
          final index = entry.key;
          final block = entry.value;
          return _buildWorkBlockCard(block, index, theme, employeeState);
        }).toList(),
      ],
    );
  }

  /// Строит карточку блока работ
  Widget _buildWorkBlockCard(WorkBlock block, int index, ThemeData theme,
      state.EmployeeState employeeState) {
    final responsible = block.responsibleId != null
        ? employeeState.employees
            .where((emp) => emp.id == block.responsibleId)
            .firstOrNull
        : null;

    final workers = employeeState.employees
        .where((emp) => block.workerIds.contains(emp.id))
        .toList();

    final totalCost = block.selectedWorks
        .fold(0.0, (sum, work) => sum + work.totalPlannedCost);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shadowColor: theme.colorScheme.shadow.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: ResponsiveUtils.getAdaptiveBorderRadius(context),
      ),
      child: Padding(
        padding: ResponsiveUtils.getAdaptiveInsets(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок блока
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${index + 1}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _buildBlockTitle(block),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (block.selectedWorks.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          '${block.selectedWorks.length} работ • ${_formatCurrency(totalCost)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),

            const Divider(height: 32),

            // Ответственный (выделен красным)
            if (responsible != null) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.person_outline,
                    size: 16,
                    color: Colors.red,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Ответственный:',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${responsible.lastName} ${responsible.firstName}${responsible.middleName != null ? ' ${responsible.middleName}' : ''}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],

            // Работники
            if (workers.isNotEmpty) ...[
              _buildInfoRow(
                theme,
                'Работники:',
                workers
                    .map((w) =>
                        '${w.lastName} ${w.firstName}${w.middleName != null ? ' ${w.middleName}' : ''}')
                    .join(', '),
                Icons.people_outline,
              ),
              const SizedBox(height: 12),
            ],

            // Работы
            if (block.selectedWorks.isNotEmpty) ...[
              Row(
                children: [
                  Icon(
                    Icons.construction,
                    size: 16,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Работы:',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...block.selectedWorks.asMap().entries.map((entry) {
                final int index = entry.key;
                final work = entry.value;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    border: Border.all(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      // Номер работы
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                work.name,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${work.plannedQuantity} ${work.unit}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.6),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _formatCurrency(work.totalPlannedCost),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ],
        ),
      ),
    );
  }

  /// Строит строку информации с иконкой
  Widget _buildInfoRow(
      ThemeData theme, String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }

  /// Строит заголовок блока
  String _buildBlockTitle(WorkBlock block) {
    final parts = <String>[];

    if (block.section != null && block.section!.isNotEmpty) {
      parts.add(block.section!);
    }

    if (block.floor != null && block.floor!.isNotEmpty) {
      parts.add(block.floor!);
    }

    if (block.system.isNotEmpty) {
      parts.add(block.system);
    }

    if (parts.isEmpty) {
      return 'Блок работ';
    }

    return parts.join(' • ');
  }
}
