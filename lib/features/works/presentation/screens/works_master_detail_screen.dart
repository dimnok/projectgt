import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/month_groups_provider.dart';
import '../providers/work_provider.dart';
import 'work_details_panel.dart';
import 'works_list_mobile_screen.dart';
import 'works_screen_actions_mixin.dart';
import 'package:projectgt/presentation/widgets/app_bar_widget.dart';
import 'package:projectgt/presentation/widgets/app_drawer.dart';
import 'package:projectgt/features/works/domain/entities/work.dart';
import 'package:projectgt/features/company/presentation/providers/company_providers.dart';
import 'package:projectgt/core/utils/responsive_utils.dart';
import '../widgets/month_details_panel.dart';
import '../widgets/sliver_month_works_list.dart';
import '../widgets/work_month_group_sliver_header.dart';
import '../widgets/work_plan_month_group_sliver_header.dart';
import '../../data/models/month_group.dart';
import 'package:projectgt/features/work_plans/data/models/work_plan_month_group.dart';
import 'package:projectgt/features/roles/presentation/widgets/permission_guard.dart';
import 'package:projectgt/features/work_plans/presentation/screens/work_plan_details_screen.dart';
import 'package:projectgt/domain/entities/work_plan.dart';
import '../widgets/desktop_month_work_plans_list.dart';
import 'package:projectgt/core/widgets/gt_buttons.dart';
import 'package:projectgt/features/work_plans/presentation/providers/work_plan_month_groups_provider.dart';
import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/presentation/state/profile_state.dart';
import 'package:projectgt/features/roles/application/permission_service.dart';
import 'package:projectgt/core/widgets/app_snackbar.dart';
import 'package:projectgt/core/error/failure.dart';

/// Режим отображения: смены или планы.
enum _DisplayMode { works, workPlans }

/// Экран списка смен с адаптивным отображением и группировкой по месяцам.
///
/// - На десктопе реализован мастер-детейл паттерн (список + детали).
/// - На мобильных поддерживается pull-to-refresh.
/// - Использует Riverpod для управления состоянием и загрузкой данных.
/// - Смены группируются по месяцам с ленивой загрузкой.
class WorksMasterDetailScreen extends ConsumerStatefulWidget {
  /// Создаёт экран списка смен.
  const WorksMasterDetailScreen({super.key});

  @override
  ConsumerState<WorksMasterDetailScreen> createState() =>
      _WorksMasterDetailScreenState();
}

class _WorksMasterDetailScreenState
    extends ConsumerState<WorksMasterDetailScreen>
    with WorksScreenActionsMixin<WorksMasterDetailScreen> {
  final _scrollController = ScrollController();
  Work? selectedWork;
  WorkPlan? selectedWorkPlan;
  MonthGroup?
  selectedMonth; // Выбранная группа месяца для отображения в детальной панели
  _DisplayMode _displayMode = _DisplayMode.works; // Начальный режим - смены

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!ResponsiveUtils.isDesktop(context)) return;
      ref.read(monthGroupsProvider.notifier).setOpenedByListFilter(null);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void onWorkDeleted() {
    if (!mounted) return;
    setState(() {
      selectedWork = null;
    });
  }

  @override
  void onWorkPlanDeleted() {
    if (!mounted) return;
    setState(() {
      selectedWorkPlan = null;
    });
  }

  /// Обрабатывает pull-to-refresh для десктопного списка смен.
  Future<void> _handleRefresh() async {
    await ref.read(monthGroupsProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveUtils.isDesktop(context);
    if (!isDesktop) {
      return const WorksListMobileScreen();
    }

    final theme = Theme.of(context);

    // [RBAC] Сбрасываем выбор при смене компании
    ref.listen(activeCompanyIdProvider, (previous, next) {
      if (previous != next) {
        setState(() {
          selectedWork = null;
          selectedMonth = null;
        });
      }
    });

    // Слушаем ошибки провайдера смен
    ref.listen<AsyncValue<List<MonthGroup>>>(monthGroupsProvider, (prev, next) {
      next.whenOrNull(
        error: (e, s) {
          final failure = e is Failure ? e : Failure.fromException(e);
          AppSnackBar.show(
            context: context,
            message: failure.message ?? 'Ошибка загрузки смен',
            kind: AppSnackBarKind.error,
          );
        },
      );
    });

    final monthGroupsAsync = ref.watch(monthGroupsProvider);
    final groups = monthGroupsAsync.valueOrNull ?? [];
    final workPlanMonthGroupsState = ref.watch(workPlanMonthGroupsProvider);
    final workPlanGroups = workPlanMonthGroupsState.groups;

    final isLoading = _displayMode == _DisplayMode.works
        ? monthGroupsAsync.isLoading
        : workPlanMonthGroupsState.isLoading;

    // Права на удаление для десктопного AppBar
    bool canDeleteSelected = false;
    bool canEditSelectedPlan = false;
    Work? currentWork;
    if (isDesktop &&
        _displayMode == _DisplayMode.works &&
        selectedWork?.id != null) {
      currentWork = ref.watch(workProvider(selectedWork!.id!)) ?? selectedWork;
      if (currentWork != null) {
        final permissionService = ref.watch(permissionServiceProvider);
        final hasDeletePermission = permissionService.can('works', 'delete');
        final currentProfile = ref.watch(currentUserProfileProvider).profile;
        final isCompanyOwner = currentProfile?.systemRole == 'owner';
        final isOwner =
            currentProfile != null && currentWork.openedBy == currentProfile.id;
        final isWorkClosed = currentWork.status.toLowerCase() == 'closed';

        canDeleteSelected =
            hasDeletePermission &&
            ((isOwner && !isWorkClosed) || isCompanyOwner);
      }
    } else if (isDesktop &&
        _displayMode == _DisplayMode.workPlans &&
        selectedWorkPlan != null) {
      final permissionService = ref.watch(permissionServiceProvider);
      final currentProfile = ref.watch(currentUserProfileProvider).profile;
      final isCompanyOwner = currentProfile?.systemRole == 'owner';

      canEditSelectedPlan =
          permissionService.can('work_plans', 'update') || isCompanyOwner;
      canDeleteSelected =
          permissionService.can('work_plans', 'delete') || isCompanyOwner;
    }

    // Актуализируем selectedMonth из groups, чтобы данные в панели обновлялись
    if (selectedMonth != null) {
      try {
        if (_displayMode == _DisplayMode.works) {
          selectedMonth = groups.firstWhere(
            (g) => g.month == selectedMonth!.month,
          );
        }
      } catch (e) {
        // Если группа исчезла, сбрасываем выбор
        selectedMonth = null;
      }
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBarWidget(
        title: _displayMode == _DisplayMode.works
            ? (currentWork != null
                  ? 'Смена: ${formatRuDate(currentWork.date)}'
                  : 'Смены')
            : (selectedWorkPlan != null
                  ? 'План: ${formatRuDate(selectedWorkPlan!.date)}'
                  : 'Планы работ'),
        actions: [
          if (canDeleteSelected &&
              _displayMode == _DisplayMode.works &&
              currentWork != null)
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => confirmDeleteWork(context, currentWork!),
              child: const Icon(
                CupertinoIcons.delete,
                color: Colors.red,
                size: 22,
              ),
            ),
          if (_displayMode == _DisplayMode.workPlans &&
              selectedWorkPlan != null) ...[
            if (canEditSelectedPlan)
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () =>
                    showEditWorkPlanModal(context, selectedWorkPlan!),
                child: const Icon(
                  CupertinoIcons.pencil,
                  color: Colors.amber,
                  size: 22,
                ),
              ),
            if (canDeleteSelected)
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () =>
                    confirmDeleteWorkPlan(context, selectedWorkPlan!),
                child: const Icon(
                  CupertinoIcons.delete,
                  color: Colors.red,
                  size: 22,
                ),
              ),
          ],
        ],
      ),
      drawer: const AppDrawer(activeRoute: AppRoute.works),
      body: _buildDesktopLayout(
        isLoading: isLoading,
        groups: groups,
        workPlanGroups: workPlanGroups,
        theme: theme,
      ),
    );
  }

  /// Строит десктопную версию интерфейса (Card-in-Card layout).
  Widget _buildDesktopLayout({
    required bool isLoading,
    required List<MonthGroup> groups,
    required List<WorkPlanMonthGroup> workPlanGroups,
    required ThemeData theme,
  }) {
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: isDark
              ? const Color.fromRGBO(38, 40, 42, 1)
              : const Color.fromRGBO(248, 249, 250, 1),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Левая панель - список (узкая)
              Container(
                width: 350,
                margin: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[900] : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Переключатель режимов на десктопе
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[850] : Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildModeTab(
                                title: 'Смены',
                                mode: _DisplayMode.works,
                                activeColor: Colors.green,
                                isDark: isDark,
                              ),
                            ),
                            Expanded(
                              child: _buildModeTab(
                                title: 'Планы',
                                mode: _DisplayMode.workPlans,
                                activeColor: Colors.blue,
                                isDark: isDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: SizedBox(
                        width: double.infinity,
                        child: _displayMode == _DisplayMode.works
                            ? PermissionGuard(
                                module: 'works',
                                permission: 'create',
                                child: GTPrimaryButton(
                                  onPressed: () => showOpenShiftModal(context),
                                  icon: CupertinoIcons.add,
                                  text: 'Открыть смену',
                                  backgroundColor: Colors.green,
                                ),
                              )
                            : PermissionGuard(
                                module: 'work_plans',
                                permission: 'create',
                                child: GTPrimaryButton(
                                  onPressed: () =>
                                      showCreateWorkPlanModal(context),
                                  icon: CupertinoIcons.add,
                                  text: 'Составить план',
                                  backgroundColor: Colors.blue,
                                ),
                              ),
                      ),
                    ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: _displayMode == _DisplayMode.works
                            ? _buildWorksList(
                                isLoading: isLoading,
                                groups: groups,
                                theme: theme,
                                stickyHeaderColor: isDark
                                    ? Colors.grey[900]
                                    : Colors.white,
                              )
                            : _buildDesktopWorkPlansList(
                                isLoading: isLoading,
                                groups: workPlanGroups,
                                theme: theme,
                                stickyHeaderColor: isDark
                                    ? Colors.grey[900]
                                    : Colors.white,
                              ),
                      ),
                    ),
                  ],
                ),
              ),

              // Правая панель - детали
              Expanded(child: _buildDetailPanel(theme)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeTab({
    required String title,
    required _DisplayMode mode,
    required Color activeColor,
    required bool isDark,
  }) {
    final isActive = _displayMode == mode;
    return GestureDetector(
      onTap: () {
        setState(() {
          _displayMode = mode;
          // Сбрасываем выбор при смене режима
          selectedWork = null;
          selectedWorkPlan = null;
          selectedMonth = null;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? (isDark ? Colors.grey[800] : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              color: isActive
                  ? activeColor
                  : (isDark ? Colors.grey[400] : Colors.grey[600]),
            ),
          ),
        ),
      ),
    );
  }

  /// Строит список планов работ для десктопа.
  Widget _buildDesktopWorkPlansList({
    required bool isLoading,
    required List<WorkPlanMonthGroup> groups,
    required ThemeData theme,
    required Color? stickyHeaderColor,
  }) {
    if (isLoading) {
      return const Center(child: CupertinoActivityIndicator());
    }

    if (groups.isEmpty) {
      return const Center(child: Text('Планы не найдены'));
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(workPlanMonthGroupsProvider.notifier).refresh();
      },
      child: CustomScrollView(
        slivers: [
          for (final group in groups) ...[
            SliverPersistentHeader(
              key: ValueKey('plan_header_${group.month}'),
              pinned: group.isExpanded,
              delegate: WorkPlanMonthGroupSliverHeader(
                group: group,
                backgroundColor: stickyHeaderColor,
                onTap: () {
                  ref
                      .read(workPlanMonthGroupsProvider.notifier)
                      .toggleMonth(group.month);
                },
              ),
            ),
            if (group.isExpanded)
              DesktopMonthWorkPlansList(
                key: ValueKey('plan_list_${group.month}'),
                group: group,
                selectedPlan: selectedWorkPlan,
                onPlanSelected: (plan) {
                  setState(() {
                    selectedWorkPlan = plan;
                    selectedWork = null;
                    selectedMonth = null;
                  });
                },
              )
            else
              const SliverToBoxAdapter(child: SizedBox.shrink()),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  /// Строит панель деталей (смена, план или сводка месяца) в правой колонке мастер-детейла.
  Widget _buildDetailPanel(ThemeData theme) {
    // Приоритет: месяц > смена/план > placeholder
    if (selectedMonth != null) {
      return MonthDetailsPanel(group: selectedMonth!);
    } else if (selectedWork != null && _displayMode == _DisplayMode.works) {
      return selectedWork!.id != null
          ? WorkDetailsPanel(
              workId: selectedWork!.id!,
              parentContext: context,
            )
          : const Center(child: Text('Ошибка: ID смены не задан'));
    } else if (selectedWorkPlan != null &&
        _displayMode == _DisplayMode.workPlans) {
      return selectedWorkPlan!.id != null
          ? WorkPlanDetailsScreen(
              workPlanId: selectedWorkPlan!.id!,
              showAppBar: false,
            )
          : const Center(child: Text('Ошибка: ID плана не задан'));
    } else {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _displayMode == _DisplayMode.works
                  ? CupertinoIcons.doc_text_search
                  : CupertinoIcons.doc_plaintext,
              size: 64,
              color: theme.colorScheme.outline.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              _displayMode == _DisplayMode.works
                  ? 'Выберите смену или месяц из списка'
                  : 'Выберите план работ из списка',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      );
    }
  }

  /// Строит десктопный список смен с группировкой по месяцам.
  ///
  /// Использует [CustomScrollView] и [SliverMonthWorksList] для эффективного
  /// рендеринга и infinite scroll.
  Widget _buildWorksList({
    required bool isLoading,
    required List<MonthGroup> groups,
    required ThemeData theme,
    Color? stickyHeaderColor,
  }) {
    if (isLoading) {
      return const Center(child: CupertinoActivityIndicator());
    }

    if (groups.isEmpty) {
      return const Center(child: Text('Смены не найдены'));
    }

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          for (final group in groups) ...[
            SliverPersistentHeader(
              key: ValueKey('header_${group.month}'),
              pinned: group.isExpanded,
              delegate: WorkMonthGroupSliverHeader(
                group: group,
                backgroundColor: stickyHeaderColor,
                onTap: () {
                  ref
                      .read(monthGroupsProvider.notifier)
                      .toggleMonth(group.month);
                  setState(() {
                    selectedMonth = group;
                    selectedWork = null;
                  });
                },
              ),
            ),
            if (group.isExpanded)
              SliverMonthWorksList(
                key: ValueKey('list_${group.month}'),
                group: group,
                isCompact: true,
                selectedWork: selectedWork,
                onWorkSelected: (work) {
                  setState(() {
                    selectedWork = work;
                    selectedMonth = null;
                  });
                },
                onLoadMore: () {
                  ref
                      .read(monthGroupsProvider.notifier)
                      .loadMoreMonthWorks(group.month);
                },
              )
            else
              const SliverToBoxAdapter(child: SizedBox.shrink()),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}
