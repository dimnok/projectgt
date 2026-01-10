import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/core/widgets/edge_to_edge_scaffold.dart';
import 'package:projectgt/features/work_plans/presentation/screens/work_plan_form_modal.dart';

/// Полноэкранный экран редактирования плана работ.
/// Полноэкранный экран редактирования существующего плана работ.
class WorkPlanEditScreen extends ConsumerWidget {
  /// Идентификатор плана работ для редактирования
  final String workPlanId;

  /// Создаёт экран редактирования для плана с идентификатором [workPlanId].
  const WorkPlanEditScreen({super.key, required this.workPlanId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workPlanState = ref.watch(workPlanNotifierProvider);
    final workPlan =
        workPlanState.workPlans.where((wp) => wp.id == workPlanId).firstOrNull;

    if (workPlanState.isLoading && workPlan == null) {
      return const EdgeToEdgeScaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (workPlan == null) {
      // Если план ещё не в кэше — подгружаем список и показываем заглушку
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(workPlanNotifierProvider.notifier).loadWorkPlans();
      });
      return const EdgeToEdgeScaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return EdgeToEdgeScaffold(
      appBar: AppBar(
        title: const Text('Редактирование плана'),
        leading: const BackButton(),
      ),
      body: SafeArea(
        child: WorkPlanFormModal(
          workPlan: workPlan,
          asDialog: false,
          onSuccess: (_) {
            // Обновляем список и выходим на предыдущий экран
            ref.read(workPlanNotifierProvider.notifier).loadWorkPlans();
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }
}
