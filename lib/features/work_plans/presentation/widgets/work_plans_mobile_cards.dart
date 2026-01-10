import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/core/widgets/gt_confirmation_dialog.dart';
import 'package:projectgt/features/roles/application/permission_service.dart';

import 'package:projectgt/features/objects/domain/entities/object.dart';
import '../../../../domain/entities/work_plan.dart';
import '../../../../core/di/providers.dart';

/// Мобильный список карточек планов работ.
///
/// Отображает планы работ в виде карточек, аналогично десктопному виду,
/// но адаптированно для мобильных устройств.
/// Мобильный список карточек планов работ.
///
/// Отображает планы работ в виде списочных карточек с базовой статистикой
/// и быстрыми действиями (свайпы для редактирования/удаления).
class WorkPlansMobileCards extends ConsumerWidget {
  /// Список планов работ для отображения.
  final List<WorkPlan> workPlans;

  /// Список объектов для резолва названий.
  final List<ObjectEntity> objects;

  /// Callback при нажатии на карточку плана работ.
  final Function(WorkPlan) onWorkPlanTap;

  /// Callback при запросе редактирования плана работ.
  final Function(WorkPlan) onEditWorkPlan;

  /// Контроллер прокрутки.
  final ScrollController? scrollController;

  /// Создаёт списочный вид карточек планов работ.
  const WorkPlansMobileCards({
    super.key,
    required this.workPlans,
    required this.objects,
    required this.onWorkPlanTap,
    required this.onEditWorkPlan,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    // Создаем кэш объектов для быстрого доступа
    final Map<String, ObjectEntity> objectById = {
      for (final o in objects) o.id: o,
    };

    return ListView.builder(
      controller: scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: workPlans.length,
      itemBuilder: (context, index) {
        final workPlan = workPlans[index];
        return _buildWorkPlanMobileCard(
          workPlan,
          objectById,
          theme,
          ref,
          context,
        );
      },
    );
  }

  /// Строит мобильную карточку плана работ (аналогично десктопной).
  Widget _buildWorkPlanMobileCard(
    WorkPlan workPlan,
    Map<String, ObjectEntity> objectById,
    ThemeData theme,
    WidgetRef ref,
    BuildContext context,
  ) {
    final dateFormat = DateFormat('dd.MM.yyyy');

    // Проверяем права
    final permissionService = ref.watch(permissionServiceProvider);
    final canUpdate = permissionService.can('work_plans', 'update');
    final canDelete = permissionService.can('work_plans', 'delete');

    DismissDirection direction = DismissDirection.none;
    if (canUpdate && canDelete) {
      direction = DismissDirection.horizontal;
    } else if (canUpdate) {
      direction = DismissDirection.startToEnd;
    } else if (canDelete) {
      direction = DismissDirection.endToStart;
    }

    // Подсчитываем статистику
    final totalWorkers =
        workPlan.workBlocks.expand((block) => block.workerIds).toSet().length;
    final totalWorks =
        workPlan.workBlocks.expand((block) => block.selectedWorks).length;
    final totalCost = workPlan.workBlocks
        .expand((block) => block.selectedWorks)
        .fold(0.0, (sum, work) => sum + work.totalPlannedCost);

    return Dismissible(
      key: ValueKey(workPlan.id ??
          '${workPlan.objectId}_${workPlan.date.millisecondsSinceEpoch}'),
      direction: direction,
      // Свайп вправо — редактировать
      background: canUpdate
          ? Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const Icon(Icons.edit_outlined, color: Colors.amber),
                  const SizedBox(width: 8),
                  Text(
                    'Редактировать',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.amber,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )
          : Container(color: Colors.transparent), // Пустой фон если нельзя
      secondaryBackground: canDelete
          ? Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Icon(Icons.delete_outline, color: Colors.red),
                  const SizedBox(width: 8),
                  Text(
                    'Удалить',
                    style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.red, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            )
          : Container(color: Colors.transparent),
      confirmDismiss: (direction) async {
        // Свайп вправо: открыть модал редактирования и не удалять
        if (direction == DismissDirection.startToEnd) {
          if (canUpdate) {
            onEditWorkPlan(workPlan);
          }
          return false;
        }

        if (direction == DismissDirection.endToStart && canDelete) {
          final result = await GTConfirmationDialog.show(
            context: context,
            title: 'Удалить план?',
            message: 'Действие нельзя отменить.',
            confirmText: 'Удалить',
            type: GTConfirmationType.danger,
          );

          if (result == true && workPlan.id != null) {
            await ref
                .read(workPlanNotifierProvider.notifier)
                .deleteWorkPlan(workPlan.id!);
            return true;
          }
        }
        return false;
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Card(
          elevation: 2,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => onWorkPlanTap(workPlan),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Объект и план на дату в одной строке
                  Row(
                    children: [
                      // Объект
                      Icon(
                        Icons.business_outlined,
                        size: 16,
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _resolveObjectName(workPlan, objectById),
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: theme.colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // План на дату
                      Text(
                        'план на ${dateFormat.format(workPlan.date)}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Статистика с четким распределением по местам
                  Row(
                    children: [
                      // Блоки - левый край
                      Expanded(
                        flex: 1,
                        child: Row(
                          children: [
                            Icon(
                              Icons.view_module_outlined,
                              size: 16,
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.6),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${workPlan.workBlocks.length}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Сотрудники - левоцентр
                      Expanded(
                        flex: 1,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              CupertinoIcons.group,
                              size: 16,
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.6),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$totalWorkers',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Работы - правоцентр
                      Expanded(
                        flex: 1,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.assignment_outlined,
                              size: 16,
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.6),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$totalWorks',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Стоимость - правый край
                      Expanded(
                        flex: 1,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            _formatCurrency(totalCost),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Возвращает название объекта из кэша или из workPlan.
  String _resolveObjectName(
      WorkPlan workPlan, Map<String, ObjectEntity> objectById) {
    final objectId = workPlan.objectId;
    if (objectById.containsKey(objectId)) {
      return objectById[objectId]!.name;
    }
    return workPlan.objectName ?? 'Неизвестный объект';
  }

  /// Форматирует валютное значение.
  String _formatCurrency(double amount) => formatCurrency(amount);
}
