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
import 'package:projectgt/features/roles/presentation/providers/roles_provider.dart';
import 'package:projectgt/presentation/state/profile_state.dart';

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
    final hasDeletePermission = permissionService.can('works', 'delete');

    if (work == null) {
      return Scaffold(
        appBar: AppBarWidget(
          title: 'Смена',
          leading: isMobile ? const BackButton() : null,
        ),
        body: const Center(child: Text('Смена не найдена')),
      );
    }

    // Проверка прав на удаление (аналогично другим экранам)
    final rolesState = ref.watch(rolesNotifierProvider);
    final currentProfile = ref.watch(currentUserProfileProvider).profile;
    final isSuperAdmin = rolesState.valueOrNull?.any((r) =>
            r.id == currentProfile?.roleId &&
            r.isSystem &&
            r.name == 'Супер-админ') ??
        false;

    final isOwner =
        currentProfile != null && work.openedBy == currentProfile.id;
    final isWorkClosed = work.status.toLowerCase() == 'closed';

    // Удалять можно, если есть право delete И ((автор и открыто) ИЛИ супер-админ)
    final canDelete =
        hasDeletePermission && ((isOwner && !isWorkClosed) || isSuperAdmin);

    // Удаляем Hero, так как он вызывает конфликты с вложенными Hero виджетами (например, в табе сотрудников)
    // и проблемы с layout (overflow) при анимации Scaffold
    return Scaffold(
      appBar: AppBarWidget(
        title: isMobile ? 'Смена' : 'Смена: ${_formatDate(work.date)}',
        leading: isMobile ? const BackButton() : null,
        actions: [
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
