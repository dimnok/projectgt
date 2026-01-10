import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:projectgt/core/widgets/app_snackbar.dart';
import 'package:projectgt/core/widgets/gt_confirmation_dialog.dart';
import 'package:projectgt/domain/entities/work_plan.dart';
import 'package:projectgt/features/objects/domain/entities/object.dart';
import 'package:projectgt/presentation/widgets/app_bar_widget.dart';
import 'package:projectgt/presentation/widgets/app_drawer.dart';
import 'package:projectgt/features/work_plans/presentation/screens/work_plan_form_modal.dart';
import 'package:projectgt/features/work_plans/presentation/screens/work_plan_details_screen.dart';
import 'package:projectgt/features/employees/presentation/widgets/master_detail_layout.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/features/objects/presentation/state/object_state.dart';
import 'package:projectgt/core/utils/responsive_utils.dart';
import 'package:intl/intl.dart';
import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/features/roles/presentation/widgets/permission_guard.dart';

/// Экран списка планов работ.
///
/// Отображает список планов работ с возможностью создания, редактирования и просмотра.
/// Поддерживает мастер-детейл режим для desktop, адаптивен для мобильных устройств.
class WorkPlansListScreen extends ConsumerStatefulWidget {
  /// Создает экран списка планов работ.
  const WorkPlansListScreen({super.key});

  @override
  ConsumerState<WorkPlansListScreen> createState() =>
      _WorkPlansListScreenState();
}

/// Состояние для [WorkPlansListScreen].
///
/// Управляет поиском, прокруткой, выбором плана работ и обработкой событий UI.
class _WorkPlansListScreenState extends ConsumerState<WorkPlansListScreen> {
  final _scrollController = ScrollController();
  bool _showFab = true;
  Timer? _fabTimer;

  WorkPlan? selectedWorkPlan;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(workPlanNotifierProvider.notifier).loadWorkPlans();
      ref.read(objectProvider.notifier).loadObjects();
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _fabTimer?.cancel();
    super.dispose();
  }

  /// Обработчик прокрутки для показа/скрытия FAB.
  void _onScroll() {
    // Скрываем FAB во время прокрутки
    if (_showFab) {
      setState(() {
        _showFab = false;
      });
    }

    // Отменяем предыдущий таймер
    _fabTimer?.cancel();

    // Устанавливаем новый таймер на 2 секунды после остановки прокрутки
    _fabTimer = Timer(const Duration(seconds: 2), () {
      if (mounted && !_scrollController.position.isScrollingNotifier.value) {
        setState(() {
          _showFab = true;
        });
      }
    });
  }

  Future<void> _handleRefresh() async {
    await ref.read(workPlanNotifierProvider.notifier).loadWorkPlans();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final workPlanState = ref.watch(workPlanNotifierProvider);
    final objectState = ref.watch(objectProvider);
    final isDesktop = ResponsiveUtils.isDesktop(context);

    final workPlans = List<WorkPlan>.from(workPlanState.workPlans)
      ..sort((a, b) =>
          b.date.compareTo(a.date)); // Сортируем по дате (новые сверху)

    final isLoading =
        workPlanState.isLoading || objectState.status == ObjectStatus.loading;

    final objects = objectState.objects;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: isDesktop
          ? AppBarWidget(
              title: 'Планы работ',
              actions: [
                if (selectedWorkPlan != null) ...[
                  PermissionGuard(
                    module: 'work_plans',
                    permission: 'update',
                    child: CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        _showEditWorkPlanModal(context, selectedWorkPlan!);
                      },
                      child: const Icon(
                        CupertinoIcons.pencil,
                        size: 22,
                        color: Colors.amber,
                      ),
                    ),
                  ),
                  PermissionGuard(
                    module: 'work_plans',
                    permission: 'delete',
                    child: CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        _confirmAndDeleteSelectedWorkPlan();
                      },
                      child: Icon(
                        CupertinoIcons.trash,
                        size: 22,
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ],
            )
          : null,
      drawer: const AppDrawer(activeRoute: AppRoute.workPlans),
      floatingActionButton: PermissionGuard(
        module: 'work_plans',
        permission: 'create',
        child: AnimatedScale(
          scale: _showFab ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          child: FloatingActionButton(
            onPressed: () {
              _showCreateWorkPlanModal(context);
            },
            backgroundColor: Colors.green,
            mini: ResponsiveUtils.isMobile(context),
            shape: const CircleBorder(),
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Определяем, какой контент отображать в зависимости от размера экрана
          if (isDesktop) {
            return _buildDesktopLayout(
              isLoading: isLoading,
              workPlans: workPlans,
              objects: objects,
            );
          } else {
            // Для мобильных добавляем SafeArea, чтобы контент не залезал под статус-бар
            return SafeArea(
              child: _buildMobileLayout(
                isLoading: isLoading,
                workPlans: workPlans,
                objects: objects,
              ),
            );
          }
        },
      ),
    );
  }

  /// Строит десктопную версию интерфейса (мастер-детейл).
  Widget _buildDesktopLayout({
    required bool isLoading,
    required List<WorkPlan> workPlans,
    required List<ObjectEntity> objects,
  }) {
    final theme = Theme.of(context);

    return MasterDetailLayout(
      masterPanel: Column(
        children: [
          // Список планов работ
          Expanded(
            child: _buildWorkPlansList(
              isLoading: isLoading,
              workPlans: workPlans,
              objects: objects,
              isDesktop: true,
            ),
          ),
        ],
      ),
      detailPanel: selectedWorkPlan == null
          ? Center(
              child: Text(
                'Выберите план работ из списка',
                style: theme.textTheme.bodyLarge,
              ),
            )
          : WorkPlanDetailsScreen(
              workPlanId: selectedWorkPlan!.id!, showAppBar: false),
    );
  }

  /// Строит мобильную версию интерфейса.
  Widget _buildMobileLayout({
    required bool isLoading,
    required List<WorkPlan> workPlans,
    required List<ObjectEntity> objects,
  }) {
    return _buildWorkPlansList(
      isLoading: isLoading,
      workPlans: workPlans,
      objects: objects,
      isDesktop: false,
    );
  }

  /// Строит список планов работ.
  Widget _buildWorkPlansList({
    required bool isLoading,
    required List<WorkPlan> workPlans,
    required List<ObjectEntity> objects,
    required bool isDesktop,
  }) {
    final theme = Theme.of(context);

    if (isDesktop) {
      return RefreshIndicator(
        onRefresh: _handleRefresh,
        child: _buildWorkPlansListContent(
          isLoading: isLoading,
          workPlans: workPlans,
          objects: objects,
          isDesktop: isDesktop,
          theme: theme,
        ),
      );
    } else {
      // Мобильная версия с AppBar в слайвере и контентом в CustomScrollView
      return RefreshIndicator(
        onRefresh: _handleRefresh,
        child: _buildMobileWorkPlansContent(
          isLoading: isLoading,
          workPlans: workPlans,
          objects: objects,
          theme: theme,
        ),
      );
    }
  }

  /// Строит мобильный контент со списком в CustomScrollView.
  Widget _buildMobileWorkPlansContent({
    required bool isLoading,
    required List<WorkPlan> workPlans,
    required List<ObjectEntity> objects,
    required ThemeData theme,
  }) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (workPlans.isEmpty) {
      return CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverToBoxAdapter(
            child: AppBarWidget(
              title: 'Планы работ',
              leading: Builder(
                builder: (context) => CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: const Icon(Icons.menu, color: Colors.blue),
                  onPressed: () {
                    Scaffold.of(context).openDrawer();
                  },
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _buildEmptyState(theme),
          ),
        ],
      );
    }

    // Создаем кэш объектов для быстрого доступа
    final Map<String, ObjectEntity> objectById = {
      for (final o in objects) o.id: o,
    };

    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        // AppBar для мобильных
        SliverToBoxAdapter(
          child: AppBarWidget(
            title: 'Планы работ',
            leading: Builder(
              builder: (context) => CupertinoButton(
                padding: EdgeInsets.zero,
                child: const Icon(Icons.menu, color: Colors.blue),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              ),
            ),
          ),
        ),
        // Карточки планов работ
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final workPlan = workPlans[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildWorkPlanMobileCard(
                    workPlan,
                    objectById,
                    theme,
                  ),
                );
              },
              childCount: workPlans.length,
            ),
          ),
        ),
      ],
    );
  }

  /// Строит одну мобильную карточку плана работ.
  Widget _buildWorkPlanMobileCard(
    WorkPlan workPlan,
    Map<String, ObjectEntity> objectById,
    ThemeData theme,
  ) {
    final dateFormat = DateFormat('dd.MM.yyyy');

    // Подсчитываем статистику
    final totalWorkers =
        workPlan.workBlocks.expand((block) => block.workerIds).toSet().length;
    final totalCost = workPlan.workBlocks
        .expand((block) => block.selectedWorks)
        .fold(0.0, (sum, work) => sum + work.totalPlannedCost);

    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _handleWorkPlanTap(workPlan, false),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Заголовок с датой
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'План работ на ${dateFormat.format(workPlan.date)}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // Объект
              Row(
                children: [
                  Icon(
                    Icons.business_outlined,
                    size: 14,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      _resolveObjectName(workPlan, objectById),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.8),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Компактная статистика
              Row(
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 14,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$totalWorkers чел.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.payments_outlined,
                    size: 14,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      _formatCurrency(totalCost),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Создает содержимое списка планов работ для десктопа.
  Widget _buildWorkPlansListContent({
    required bool isLoading,
    required List<WorkPlan> workPlans,
    required List<ObjectEntity> objects,
    required bool isDesktop,
    required ThemeData theme,
  }) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (workPlans.isEmpty) {
      return _buildEmptyState(theme);
    }

    return _buildWorkPlansDesktopListView(workPlans, objects);
  }

  /// Строит состояние пустого списка планов работ.
  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 64,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'Нет планов работ',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Создайте первый план работ',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  /// Строит десктопный ListView с планами работ в виде карточек.
  Widget _buildWorkPlansDesktopListView(
      List<WorkPlan> workPlans, List<ObjectEntity> objects) {
    final Map<String, ObjectEntity> objectById = {
      for (final o in objects) o.id: o,
    };

    return ListView.separated(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: 16,
        top: 24,
      ),
      itemCount: workPlans.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final workPlan = workPlans[index];
        final isSelected = selectedWorkPlan?.id == workPlan.id;
        return _buildWorkPlanDesktopCard(workPlan, objectById, isSelected);
      },
    );
  }

  /// Строит карточку плана работ для десктопа
  Widget _buildWorkPlanDesktopCard(WorkPlan workPlan,
      Map<String, ObjectEntity> objectById, bool isSelected) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd.MM.yyyy');

    // Подсчитываем общую статистику
    final totalWorkers =
        workPlan.workBlocks.expand((block) => block.workerIds).toSet().length;

    final totalCost = workPlan.workBlocks
        .expand((block) => block.selectedWorks)
        .fold(0.0, (sum, work) => sum + work.totalPlannedCost);

    return Card(
      elevation: isSelected ? 4 : 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? BorderSide(
                color: theme.colorScheme.primary.withValues(alpha: 0.5),
                width: 2,
              )
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _handleWorkPlanTap(workPlan, true),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isSelected
                ? theme.colorScheme.primary.withValues(alpha: 0.03)
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Заголовок с датой
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'План работ на ${dateFormat.format(workPlan.date)}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isSelected ? theme.colorScheme.primary : null,
                      ),
                    ),
                  ),
                  if (isSelected)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Выбран',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.w500,
                          fontSize: 10,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 6),

              // Объект
              Row(
                children: [
                  Icon(
                    Icons.business_outlined,
                    size: 14,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      _resolveObjectName(workPlan, objectById),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.8),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Компактная статистика в одну строку
              Row(
                children: [
                  // Количество сотрудников
                  Icon(
                    CupertinoIcons.group,
                    size: 14,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$totalWorkers чел.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Планируемая сумма
                  Icon(
                    Icons.payments_outlined,
                    size: 14,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatCurrency(totalCost),
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Возвращает имя объекта по objectId через кэш объектов, либо из workPlan/objectName
  String _resolveObjectName(
      WorkPlan workPlan, Map<String, ObjectEntity> objectById) {
    final fromMap = objectById[workPlan.objectId]?.name;
    return fromMap ?? workPlan.objectName ?? 'Неизвестный объект';
  }

  /// Форматирует сумму с разделителями тысяч
  String _formatCurrency(double amount) => formatCurrency(amount);

  /// Обрабатывает нажатие на план работ.
  void _handleWorkPlanTap(WorkPlan workPlan, bool isDesktop) {
    if (isDesktop) {
      setState(() {
        selectedWorkPlan = workPlan;
      });
    } else {
      context.pushNamed(
        'work_plan_details',
        pathParameters: {'workPlanId': workPlan.id!},
      );
    }
  }

  /// Показывает модальное окно создания плана работ
  void _showCreateWorkPlanModal(BuildContext context) {
    if (ResponsiveUtils.isDesktop(context)) {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: WorkPlanFormModal(
            onSuccess: (isNew) {
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
        builder: (context) => WorkPlanFormModal(
          onSuccess: (isNew) {
            ref.read(workPlanNotifierProvider.notifier).loadWorkPlans();
          },
        ),
      );
    }
  }

  /// Показывает модальное окно редактирования плана работ
  void _showEditWorkPlanModal(BuildContext context, WorkPlan workPlan) {
    if (ResponsiveUtils.isDesktop(context)) {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: WorkPlanFormModal(
            workPlan: workPlan,
            onSuccess: (isNew) {
              ref.read(workPlanNotifierProvider.notifier).loadWorkPlans();
              if (!isNew) {
                setState(() {
                  selectedWorkPlan = null;
                });
              }
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
        builder: (context) => WorkPlanFormModal(
          workPlan: workPlan,
          onSuccess: (isNew) {
            ref.read(workPlanNotifierProvider.notifier).loadWorkPlans();
            if (!isNew) {
              setState(() {
                selectedWorkPlan = null;
              });
            }
          },
        ),
      );
    }
  }

  /// Подтверждает и удаляет выбранный план работ (для десктопа из AppBar).
  Future<void> _confirmAndDeleteSelectedWorkPlan() async {
    final workPlan = selectedWorkPlan;
    if (workPlan?.id == null) return;

    final confirmed = await GTConfirmationDialog.show(
      context: context,
      title: 'Удалить план?',
      message: 'Действие нельзя отменить.',
      confirmText: 'Удалить',
      type: GTConfirmationType.danger,
    );

    if (confirmed == true) {
      try {
        await ref
            .read(workPlanNotifierProvider.notifier)
            .deleteWorkPlan(workPlan!.id!);
        if (!mounted) return;
        setState(() {
          selectedWorkPlan = null;
        });
        AppSnackBar.show(
          context: context,
          message: 'План работ успешно удален',
          kind: AppSnackBarKind.success,
        );
      } catch (e) {
        if (!mounted) return;
        AppSnackBar.show(
          context: context,
          message: 'Ошибка при удалении плана: $e',
          kind: AppSnackBarKind.error,
        );
      }
    }
  }
}
