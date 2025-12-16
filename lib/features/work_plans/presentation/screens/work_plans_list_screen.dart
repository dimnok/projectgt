import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:projectgt/domain/entities/work_plan.dart';
import 'package:projectgt/domain/entities/object.dart';
import 'package:projectgt/presentation/widgets/app_bar_widget.dart';
import 'package:projectgt/presentation/widgets/app_drawer.dart';
import 'package:projectgt/features/work_plans/presentation/screens/work_plan_form_modal.dart';
import 'package:projectgt/features/work_plans/presentation/screens/work_plan_details_screen.dart';
import 'package:projectgt/features/employees/presentation/widgets/master_detail_layout.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/core/utils/responsive_utils.dart';
import 'package:projectgt/presentation/state/object_state.dart';
import 'package:projectgt/features/work_plans/presentation/widgets/work_plans_mobile_cards.dart';
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
      extendBodyBehindAppBar: true,
      appBar: AppBarWidget(
        title: 'Планы работ',
        actions: [
          if (isDesktop && selectedWorkPlan != null) ...[
            PermissionGuard(
              module: 'work_plans',
              permission: 'update',
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                child: const Icon(Icons.edit, color: Colors.amber),
                onPressed: () {
                  _showEditWorkPlanModal(context, selectedWorkPlan!);
                },
              ),
            ),
            const SizedBox(width: 8),
            PermissionGuard(
              module: 'work_plans',
              permission: 'delete',
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                child: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () {
                  _confirmAndDeleteSelectedWorkPlan();
                },
              ),
            ),
          ],
        ],
      ),
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
            return _buildMobileLayout(
              isLoading: isLoading,
              workPlans: workPlans,
              objects: objects,
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
    return Column(
      children: [
        // Список планов работ
        Expanded(
          child: _buildWorkPlansList(
            isLoading: isLoading,
            workPlans: workPlans,
            objects: objects,
            isDesktop: false,
          ),
        ),
      ],
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
  }

  /// Создает содержимое списка планов работ в зависимости от состояния.
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

    if (isDesktop) {
      return _buildWorkPlansDesktopListView(workPlans, objects);
    } else {
      // Используем новые мобильные карточки
      return WorkPlansMobileCards(
        workPlans: workPlans,
        objects: objects,
        onWorkPlanTap: (workPlan) => _handleWorkPlanTap(workPlan, false),
        onEditWorkPlan: (workPlan) => _showEditWorkPlanModal(context, workPlan),
        scrollController: _scrollController,
      );
    }
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
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: 16,
        top: MediaQuery.of(context).viewPadding.top + kToolbarHeight + 24 + 6,
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height -
            MediaQuery.of(context).padding.top -
            kToolbarHeight,
      ),
      builder: (context) {
        final isDesktop = MediaQuery.of(context).size.width >= 900;
        Widget modalContent = Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(28),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: DraggableScrollableSheet(
            initialChildSize: 1.0,
            minChildSize: 0.5,
            maxChildSize: 1.0,
            expand: false,
            builder: (context, scrollController) => SingleChildScrollView(
              controller: scrollController,
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: WorkPlanFormModal(
                  onSuccess: (isNew) {
                    // Обновляем список планов работ после успешного сохранения
                    ref.read(workPlanNotifierProvider.notifier).loadWorkPlans();
                  },
                ),
              ),
            ),
          ),
        );

        if (isDesktop) {
          return Center(
            child: SizedBox(
              width:
                  (MediaQuery.of(context).size.width * 0.5).clamp(400.0, 900.0),
              child: modalContent,
            ),
          );
        } else {
          return modalContent;
        }
      },
    );
  }

  /// Показывает модальное окно редактирования плана работ
  void _showEditWorkPlanModal(BuildContext context, WorkPlan workPlan) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height -
            MediaQuery.of(context).padding.top -
            kToolbarHeight,
      ),
      builder: (context) {
        final isDesktop = MediaQuery.of(context).size.width >= 900;
        Widget modalContent = Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(28),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: DraggableScrollableSheet(
            initialChildSize: 1.0,
            minChildSize: 0.5,
            maxChildSize: 1.0,
            expand: false,
            builder: (context, scrollController) => SingleChildScrollView(
              controller: scrollController,
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: WorkPlanFormModal(
                  workPlan: workPlan, // Передаем план для редактирования
                  onSuccess: (isNew) {
                    // Обновляем список планов работ после успешного сохранения
                    ref.read(workPlanNotifierProvider.notifier).loadWorkPlans();
                    if (!isNew) {
                      // При редактировании сбрасываем выбранный план для перезагрузки
                      setState(() {
                        selectedWorkPlan = null;
                      });
                    }
                  },
                ),
              ),
            ),
          ),
        );

        if (isDesktop) {
          return Center(
            child: SizedBox(
              width:
                  (MediaQuery.of(context).size.width * 0.5).clamp(400.0, 900.0),
              child: modalContent,
            ),
          );
        } else {
          return modalContent;
        }
      },
    );
  }

  /// Подтверждает и удаляет выбранный план работ (для десктопа из AppBar).
  Future<void> _confirmAndDeleteSelectedWorkPlan() async {
    final workPlan = selectedWorkPlan;
    if (workPlan?.id == null) return;

    final theme = Theme.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить план?'),
        content: const Text('Действие нельзя отменить.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style:
                TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref
          .read(workPlanNotifierProvider.notifier)
          .deleteWorkPlan(workPlan!.id!);
      if (!mounted) return;
      setState(() {
        selectedWorkPlan = null;
      });
    }
  }
}
