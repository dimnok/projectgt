import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
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
import '../providers/repositories_providers.dart';
import 'package:projectgt/core/utils/formatters.dart';

/// Экран деталей смены с вкладками работ, материалов и часов.
///
/// Используется для отображения детальной информации о смене,
/// а также для управления списками работ, материалов и часов.
class WorkDetailsScreen extends ConsumerStatefulWidget {
  /// Идентификатор смены для отображения деталей.
  final String workId;

  /// Начальный индекс таба (опционально).
  final int initialTabIndex;

  /// Создаёт экран деталей смены по [workId].
  const WorkDetailsScreen({
    super.key,
    required this.workId,
    this.initialTabIndex = 0,
  });

  @override
  ConsumerState<WorkDetailsScreen> createState() => _WorkDetailsScreenState();
}

class _WorkDetailsScreenState extends ConsumerState<WorkDetailsScreen> {
  /// Загруженная локально смена (если нет в глобальном стейте)
  Work? _localWork;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Отложенная проверка наличия смены в стейте
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndLoadWork();
    });
  }

  /// Проверяет наличие смены в глобальном стейте, если нет - загружает.
  Future<void> _checkAndLoadWork() async {
    // Сначала проверяем в глобальном стейте
    final globalWork = ref.read(workProvider(widget.workId));

    if (globalWork != null) {
      return; // Уже есть, ничего не делаем
    }

    // Если нет, загружаем локально
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      debugPrint(
          'WorkDetailsScreen: Loading work ${widget.workId} from repository...');
      final repository = ref.read(workRepositoryProvider);
      final work = await repository.getWork(widget.workId);
      debugPrint('WorkDetailsScreen: Loaded work result: ${work?.id}');

      if (mounted) {
        setState(() {
          _localWork = work;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('WorkDetailsScreen: Error loading work: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Пытаемся получить смену из глобального стейта или локального
    final globalWork = ref.watch(workProvider(widget.workId));
    final work = globalWork ?? _localWork;

    final isMobile = ResponsiveUtils.isDesktop(context) == false;

    // Состояние загрузки
    if (work == null && _isLoading) {
      return Scaffold(
        appBar: AppBarWidget(
          title: 'Загрузка...',
          leading: isMobile ? const BackButton() : null,
        ),
        body: Hero(
          tag: 'work_card_${widget.workId}',
          child: const Center(child: CupertinoActivityIndicator()),
        ),
      );
    }

    // Состояние ошибки
    if (work == null && _error != null) {
      return Scaffold(
        appBar: AppBarWidget(
          title: 'Ошибка',
          leading: isMobile ? const BackButton() : null,
        ),
        body: Hero(
          tag: 'work_card_${widget.workId}',
          child: Center(child: Text('Ошибка загрузки: $_error')),
        ),
      );
    }

    // Состояние "не найдено"
    if (work == null) {
      return Scaffold(
        appBar: AppBarWidget(
          title: 'Смена',
          leading: isMobile ? const BackButton() : null,
        ),
        body: const Center(child: Text('Смена не найдена')),
      );
    }

    // Отрисовка данных
    final permissionService = ref.watch(permissionServiceProvider);
    final hasDeletePermission = permissionService.can('works', 'delete');

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

    final canDelete =
        hasDeletePermission && ((isOwner && !isWorkClosed) || isSuperAdmin);

    return Scaffold(
      appBar: AppBarWidget(
        title: isMobile ? 'Смена' : 'Смена: ${formatRuDate(work.date)}',
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
      body: Hero(
        tag: 'work_card_${widget.workId}',
        child: Material(
          type: MaterialType.transparency,
          child: Builder(
            builder: (scaffoldContext) => WorkDetailsPanel(
              workId: widget.workId,
              parentContext: scaffoldContext,
              initialWork: work,
              initialTabIndex: widget.initialTabIndex,
            ),
          ),
        ),
      ),
    );
  }

  /// Показывает диалог подтверждения удаления смены.
  void _confirmDeleteWork(BuildContext context, WidgetRef ref, Work work) {
    CupertinoDialogs.showDeleteConfirmDialog(
      context: context,
      title: 'Подтверждение удаления',
      message:
          'Вы действительно хотите удалить смену от ${formatRuDate(work.date)}?\n\nЭто действие удалит все связанные работы и часы сотрудников. Операция необратима.',
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
