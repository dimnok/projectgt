import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/core/utils/modal_utils.dart';
import 'package:projectgt/core/utils/responsive_utils.dart';
import 'package:projectgt/core/widgets/app_snackbar.dart';
import 'package:projectgt/domain/entities/work_plan.dart';
import 'package:projectgt/features/work_plans/presentation/providers/work_plan_month_groups_provider.dart';
import 'package:projectgt/features/work_plans/presentation/screens/work_plan_form_modal.dart';
import 'package:projectgt/features/works/domain/entities/work.dart';
import 'package:projectgt/features/works/presentation/providers/month_groups_provider.dart';
import 'package:projectgt/features/works/presentation/providers/work_provider.dart';
import 'package:projectgt/presentation/widgets/cupertino_dialog_widget.dart';

/// Общая бизнес-логика экрана работ (мобильного и десктопного):
/// открытие/удаление смен, создание/редактирование/удаление планов.
///
/// Миксин подмешивается к [ConsumerState] любого экрана модуля работ и
/// обращается к [ref] и [context] напрямую. Специализированные колбэки
/// (например, сброс локально выбранных значений) выносятся в реализующие
/// классы через хуки [onWorkDeleted]/[onWorkPlanDeleted].
mixin WorksScreenActionsMixin<T extends ConsumerStatefulWidget>
    on ConsumerState<T> {
  /// Вызывается после удаления смены. Позволяет экрану сбросить выбранное значение.
  void onWorkDeleted() {}

  /// Вызывается после удаления плана работ.
  void onWorkPlanDeleted() {}

  /// Показывает модальную форму для открытия смены.
  ///
  /// Предварительно проверяет наличие уже открытой смены у пользователя,
  /// чтобы не допустить одновременного открытия двух смен.
  Future<void> showOpenShiftModal(BuildContext context) async {
    final hasOpen = await ref.read(hasOpenWorkProvider.future);
    if (!context.mounted) return;

    if (hasOpen) {
      showCupertinoDialog(
        context: context,
        builder: (dialogContext) => CupertinoAlertDialog(
          title: const Text('Внимание'),
          content: const Text(
            'У вас уже есть открытая смена. Пожалуйста, закройте её перед открытием новой.',
          ),
          actions: [
            CupertinoDialogAction(
              child: const Text('ОК'),
              onPressed: () => Navigator.pop(dialogContext),
            ),
          ],
        ),
      );
      return;
    }

    ModalUtils.showWorkFormModal(context);
  }

  /// Показывает модальное окно создания плана работ (адаптивно).
  void showCreateWorkPlanModal(BuildContext context) {
    if (ResponsiveUtils.isDesktop(context)) {
      showDialog(
        context: context,
        builder: (dialogContext) => Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: WorkPlanFormModal(
            onSuccess: (_) {
              ref.read(workPlanNotifierProvider.notifier).loadWorkPlans();
            },
          ),
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (sheetContext) => WorkPlanFormModal(
          onSuccess: (_) {
            ref.read(workPlanNotifierProvider.notifier).loadWorkPlans();
          },
        ),
      );
    }
  }

  /// Показывает модальное окно редактирования плана работ (только на десктопе).
  void showEditWorkPlanModal(BuildContext context, WorkPlan plan) {
    if (!ResponsiveUtils.isDesktop(context)) return;

    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: WorkPlanFormModal(
          workPlan: plan,
          onSuccess: (_) {
            ref.read(workPlanNotifierProvider.notifier).loadWorkPlans();
            ref.read(workPlanMonthGroupsProvider.notifier).refresh();
          },
        ),
      ),
    );
  }

  /// Показывает диалог подтверждения удаления смены.
  void confirmDeleteWork(BuildContext context, Work work) {
    CupertinoDialogs.showDeleteConfirmDialog(
      context: context,
      title: 'Подтверждение удаления',
      message:
          'Вы действительно хотите удалить смену от ${formatRuDate(work.date)}?\n\nЭто действие удалит все связанные работы и часы сотрудников. Операция необратима.',
      confirmButtonText: 'Удалить',
      onConfirm: () async {
        if (work.id == null) return;

        await ref.read(worksProvider.notifier).deleteWork(work.id!);
        await ref.read(monthGroupsProvider.notifier).refresh();

        if (!mounted) return;
        onWorkDeleted();

        if (context.mounted) {
          AppSnackBar.show(
            context: context,
            message: 'Смена успешно удалена',
            kind: AppSnackBarKind.success,
          );
        }
      },
    );
  }

  /// Показывает диалог подтверждения удаления плана работ.
  void confirmDeleteWorkPlan(BuildContext context, WorkPlan plan) {
    CupertinoDialogs.showDeleteConfirmDialog(
      context: context,
      title: 'Подтверждение удаления',
      message:
          'Вы действительно хотите удалить план от ${formatRuDate(plan.date)}?\n\nЭто действие удалит все блоки работ в плане. Операция необратима.',
      confirmButtonText: 'Удалить',
      onConfirm: () async {
        if (plan.id == null) return;

        await ref
            .read(workPlanNotifierProvider.notifier)
            .deleteWorkPlan(plan.id!);
        await ref.read(workPlanMonthGroupsProvider.notifier).refresh();

        if (!mounted) return;
        onWorkPlanDeleted();

        if (context.mounted) {
          AppSnackBar.show(
            context: context,
            message: 'План работ успешно удален',
            kind: AppSnackBarKind.success,
          );
        }
      },
    );
  }
}
