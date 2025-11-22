import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/work.dart';
import '../providers/work_provider.dart';
import '../providers/month_groups_provider.dart';
import 'package:projectgt/presentation/widgets/app_bar_widget.dart';
import 'package:projectgt/presentation/widgets/app_drawer.dart';

import 'package:projectgt/presentation/widgets/cupertino_dialog_widget.dart';
import 'package:go_router/go_router.dart';
import 'package:projectgt/core/utils/snackbar_utils.dart';
import 'package:projectgt/core/utils/responsive_utils.dart';
import 'work_details_panel.dart';
import 'package:projectgt/features/roles/application/permission_service.dart';

/// Экран деталей смены с вкладками работ, материалов и часов.
///
/// Используется для отображения детальной информации о смене,
/// а также для управления списками работ, материалов и часов.
class WorkDetailsScreen extends ConsumerWidget {
  /// Идентификатор смены для отображения деталей.
  final String workId;

  /// Создаёт экран деталей смены по [workId].
  const WorkDetailsScreen({super.key, required this.workId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final work = ref.watch(workProvider(workId));
    final isMobile = ResponsiveUtils.isDesktop(context) == false;
    final permissionService = ref.watch(permissionServiceProvider);
    final canUpdate = permissionService.can('works', 'update');
    final canDelete = permissionService.can('works', 'delete');

    if (work == null) {
      return Scaffold(
        appBar: AppBarWidget(
          title: 'Смена',
          leading: isMobile ? const BackButton() : null,
        ),
        body: const Center(child: Text('Смена не найдена')),
      );
    }

    return Scaffold(
      appBar: AppBarWidget(
        title: isMobile ? 'Смена' : 'Смена: ${_formatDate(work.date)}',
        leading: isMobile ? const BackButton() : null,
        actions: [
          if (canUpdate)
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.amber),
              onPressed: () => _showEditWorkDialog(context, ref, work),
              tooltip: 'Редактировать',
            ),
          if (canDelete)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _confirmDeleteWork(context, ref, work),
              tooltip: 'Удалить',
            ),
        ],
        showThemeSwitch: !isMobile,
        centerTitle: isMobile,
      ),
      drawer: isMobile ? null : const AppDrawer(activeRoute: AppRoute.works),
      body: Builder(
        builder: (scaffoldContext) =>
            WorkDetailsPanel(workId: workId, parentContext: scaffoldContext),
      ),
    );
  }

  /// Форматирует дату [date] в строку "дд.мм.гггг".
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  /// Показывает диалог редактирования статуса смены.
  void _showEditWorkDialog(BuildContext context, WidgetRef ref, Work? work) {
    if (work == null) return;
    final statusController = TextEditingController(text: work.status);
    showDialog(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Редактировать смену'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: statusController,
              decoration: const InputDecoration(
                labelText: 'Статус',
                hintText: 'Введите статус (open/closed)',
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (statusController.text.trim().isEmpty) {
                SnackBarUtils.showWarning(
                    dialogContext, 'Введите статус смены');
                return;
              }

              final newStatus = statusController.text.trim();
              final updatedWork = Work(
                id: work.id,
                date: work.date,
                objectId: work.objectId,
                openedBy: work.openedBy,
                status: newStatus,
                photoUrl: work.photoUrl,
                eveningPhotoUrl: work.eveningPhotoUrl,
                createdAt: work.createdAt,
                updatedAt: DateTime.now(),
                telegramMessageId: work.telegramMessageId,
              );

              await ref.read(worksProvider.notifier).updateWork(updatedWork);

              if (dialogContext.mounted) {
                // Закрываем диалог
                Navigator.of(dialogContext).pop();
              }

              // Используем основной контекст экрана для Snackbar
              if (context.mounted) {
                SnackBarUtils.showInfo(context, 'Смена обновлена');
              }
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  /// Показывает диалог подтверждения удаления смены.
  void _confirmDeleteWork(BuildContext context, WidgetRef ref, Work work) {
    CupertinoDialogs.showDeleteConfirmDialog(
      context: context,
      title: 'Подтверждение удаления',
      message:
          'Вы действительно хотите удалить смену от ${_formatDate(work.date)}?\n\nЭто действие удалит все связанные работы и часы сотрудников. Операция необратима.',
      confirmButtonText: 'Удалить',
      onConfirm: () async {
        if (work.id == null) return;

        await ref.read(worksProvider.notifier).deleteWork(work.id!);

        // Обновляем список смен для немедленного отображения изменений
        await ref.read(monthGroupsProvider.notifier).refresh();

        if (context.mounted) {
          context.goNamed('works');
          SnackBarUtils.showSuccess(context, 'Смена успешно удалена');
        }
      },
    );
  }
}
