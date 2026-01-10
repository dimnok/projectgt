import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:projectgt/core/widgets/gt_confirmation_dialog.dart';
import 'package:projectgt/features/objects/domain/entities/object.dart';
import 'package:projectgt/domain/entities/work_plan.dart';
import 'package:projectgt/presentation/state/employee_state.dart' as state;
import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/presentation/widgets/app_bar_widget.dart';
import 'package:projectgt/features/work_plans/presentation/screens/work_plan_form_modal.dart';
import 'package:projectgt/core/utils/formatters.dart';

/// Мобильный детальный экран плана работ.
///
/// Информативный, но не перегруженный экран для просмотра деталей плана работ
/// на мобильных устройствах. Оптимизирован для удобного чтения и восприятия.
/// Мобильный детальный экран плана работ с ключевой информацией и списком блоков.
class WorkPlanMobileDetails extends ConsumerStatefulWidget {
  /// ID плана работ для отображения.
  final String workPlanId;

  /// Показывать ли AppBar (по умолчанию true).
  final bool showAppBar;

  /// Создаёт экран с деталями плана работ для мобильных устройств.
  const WorkPlanMobileDetails({
    super.key,
    required this.workPlanId,
    this.showAppBar = true,
  });

  @override
  ConsumerState<WorkPlanMobileDetails> createState() =>
      _WorkPlanMobileDetailsState();
}

class _WorkPlanMobileDetailsState extends ConsumerState<WorkPlanMobileDetails> {
  // Константные значения для повторяющихся отступов
  static const double _contentPadding = 16.0;
  static const double _sectionSpacing = 16.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(workPlanNotifierProvider.notifier).loadWorkPlans();
      ref.read(objectProvider.notifier).loadObjects();
    });
  }

  /// Открывает модальное окно редактирования плана работ (мобильное).
  void _showEditWorkPlanModal(WorkPlan workPlan) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => WorkPlanFormModal(
        workPlan: workPlan,
        onSuccess: (_) {
          ref.read(workPlanNotifierProvider.notifier).loadWorkPlans();
        },
      ),
    );
  }

  /// Подтверждает и удаляет план работ. После удаления закрывает экран.
  Future<void> _confirmAndDeleteWorkPlan(WorkPlan workPlan) async {
    if (workPlan.id == null) return;

    final confirmed = await GTConfirmationDialog.show(
      context: context,
      title: 'Удалить план?',
      message: 'Действие нельзя отменить.',
      confirmText: 'Удалить',
      type: GTConfirmationType.danger,
    );

    if (confirmed == true) {
      await ref
          .read(workPlanNotifierProvider.notifier)
          .deleteWorkPlan(workPlan.id!);
      if (!mounted) return;
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final workPlanState = ref.watch(workPlanNotifierProvider);

    // Ищем план работ по ID
    final workPlan = workPlanState.workPlans
        .where((wp) => wp.id == widget.workPlanId)
        .firstOrNull;

    final isLoading = workPlan == null && workPlanState.isLoading;
    final objectState = ref.watch(objectProvider);
    final employeeState = ref.watch(state.employeeProvider);

    if (isLoading) {
      return Scaffold(
        appBar:
            widget.showAppBar ? const AppBarWidget(title: 'План работ') : null,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (workPlan == null) {
      return Scaffold(
        appBar:
            widget.showAppBar ? const AppBarWidget(title: 'План работ') : null,
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

    return Scaffold(
      appBar: widget.showAppBar
          ? AppBarWidget(
              title: GtFormatters.formatRuDate(workPlan.date),
              leading: const BackButton(),
              showThemeSwitch: false,
              centerTitle: false,
              actions: [
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    _showEditWorkPlanModal(workPlan);
                  },
                  child: const Icon(
                    CupertinoIcons.pencil,
                    size: 22,
                    color: Colors.amber,
                  ),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    _confirmAndDeleteWorkPlan(workPlan);
                  },
                  child: Icon(
                    CupertinoIcons.trash,
                    size: 22,
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
            )
          : null,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Основная информация о плане
            _buildMainInfoCard(workPlan, objectEntity, theme),

            const SizedBox(height: _sectionSpacing),

            // Блоки работ
            _buildWorkBlocksList(workPlan, employeeState, theme),
          ],
        ),
      ),
    );
  }

  /// Строит карточку с основной информацией о плане работ (компактная версия для мобильных).
  Widget _buildMainInfoCard(
      WorkPlan workPlan, ObjectEntity? objectEntity, ThemeData theme) {
    final dateFormat = DateFormat('dd.MM.yyyy');

    // Подсчитываем количество специалистов и общую стоимость
    final totalSpecialists =
        workPlan.workBlocks.expand((block) => block.workerIds).toSet().length;
    final totalCost = workPlan.workBlocks
        .expand((block) => block.selectedWorks)
        .fold(0.0, (sum, work) => sum + work.totalPlannedCost);

    return Container(
      margin: const EdgeInsets.all(_contentPadding),
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
      child: Padding(
        padding: const EdgeInsets.all(_contentPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Объект и дата
            Row(
              children: [
                Expanded(
                  child: Text(
                    objectEntity?.name ??
                        workPlan.objectName ??
                        'Неизвестный объект',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  dateFormat.format(workPlan.date),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Количество специалистов и сумма
            Row(
              children: [
                Icon(
                  CupertinoIcons.group,
                  size: 18,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 6),
                Text(
                  '$totalSpecialists',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Text(
                  _formatCurrency(totalCost),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Строит список блоков работ.
  Widget _buildWorkBlocksList(
      WorkPlan workPlan, state.EmployeeState employeeState, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Заголовок секции
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: _contentPadding),
          child: Text(
            'Блоки работ (${workPlan.workBlocks.length})',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Список блоков
        ...workPlan.workBlocks.asMap().entries.map((entry) {
          final index = entry.key;
          final block = entry.value;
          return _buildWorkBlockCard(block, index, theme, employeeState);
        }),
      ],
    );
  }

  /// Строит карточку блока работ для мобильной версии.
  Widget _buildWorkBlockCard(WorkBlock block, int index, ThemeData theme,
      state.EmployeeState employeeState) {
    // Получаем ответственного
    final responsible = block.responsibleId != null
        ? employeeState.employees
            .where((emp) => emp.id == block.responsibleId)
            .firstOrNull
        : null;

    // Подсчитываем стоимость блока
    final totalCost = block.selectedWorks
        .fold(0.0, (sum, work) => sum + work.totalPlannedCost);

    return Container(
      margin: const EdgeInsets.only(
        left: _contentPadding,
        right: _contentPadding,
        bottom: 12,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
          width: 0.5,
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.03),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок блока
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
            ),
            child: Row(
              children: [
                // Номер блока
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
                  child: Text(
                    _buildBlockTitle(block),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  _formatCurrency(totalCost),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),

          // Содержимое блока
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ответственный (выделен красным)
                if (responsible != null) ...[
                  Row(
                    children: [
                      const Icon(
                        Icons.person_outline,
                        size: 16,
                        color: Colors.red,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Ответственный:',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${responsible.lastName} ${responsible.firstName.isNotEmpty ? '${responsible.firstName[0]}.' : ''}${responsible.middleName != null && responsible.middleName!.isNotEmpty ? '${responsible.middleName![0]}.' : ''}',
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

                // Список сотрудников
                if (block.workerIds.isNotEmpty) ...[
                  Row(
                    children: [
                      Icon(
                        Icons.group_outlined,
                        size: 16,
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Сотрудники:',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: block.workerIds.map((workerId) {
                      final worker = employeeState.employees
                          .where((emp) => emp.id == workerId)
                          .firstOrNull;

                      if (worker == null) return const SizedBox.shrink();

                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color:
                              theme.colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: theme.colorScheme.primary
                                .withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          '${worker.lastName} ${worker.firstName.isNotEmpty ? '${worker.firstName[0]}.' : ''}${worker.middleName != null && worker.middleName!.isNotEmpty ? '${worker.middleName![0]}.' : ''}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                ],

                // Список работ с нумерацией
                if (block.selectedWorks.isNotEmpty) ...[
                  Text(
                    'Работы (${block.selectedWorks.length}):',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...block.selectedWorks.asMap().entries.map((entry) {
                    final int workIndex = entry.key;
                    final work = entry.value;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        border: Border.all(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.1),
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          // Номер работы
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                '${workIndex + 1}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  work.name,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Text(
                                      '${work.plannedQuantity} ${work.unit}',
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.onSurface
                                            .withValues(alpha: 0.6),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _formatCurrency(work.totalPlannedCost),
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Строит заголовок блока.
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

    return parts.isEmpty ? 'Блок работ' : parts.join(' • ');
  }

  /// Форматирует валютное значение.
  String _formatCurrency(double value) => formatCurrency(value);
}
