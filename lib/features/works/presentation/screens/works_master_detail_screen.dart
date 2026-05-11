import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/month_groups_provider.dart';
import '../providers/work_provider.dart';
import 'desktop/works_master_detail_desktop_view.dart';
import 'work_details_panel.dart';
import 'works_list_mobile_screen.dart';
import 'works_screen_actions_mixin.dart';
import 'package:projectgt/presentation/widgets/app_drawer.dart';
import 'package:projectgt/features/works/domain/entities/work.dart';
import 'package:projectgt/features/company/presentation/providers/company_providers.dart';
import 'package:projectgt/core/utils/responsive_utils.dart';
import 'package:projectgt/core/widgets/mobile_atmosphere_backdrop.dart';
import '../widgets/month_details_panel.dart';
import '../../data/models/month_group.dart';
import 'package:projectgt/features/work_plans/presentation/screens/work_plan_details_screen.dart';
import 'package:projectgt/domain/entities/work_plan.dart';
import 'package:projectgt/features/work_plans/presentation/providers/work_plan_month_groups_provider.dart';
import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/presentation/state/profile_state.dart';
import 'package:projectgt/features/roles/application/permission_service.dart';
import 'package:projectgt/core/widgets/app_snackbar.dart';
import 'package:projectgt/core/error/failure.dart';

/// Экран списка смен с адаптивным отображением и группировкой по месяцам.
///
/// - На десктопе — мастер-детейл: отступы и хром как у списка договоров
///   ([WorksMasterDetailDesktopView]), без [AppBarWidget].
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
  WorksMasterDetailDisplayMode _displayMode =
      WorksMasterDetailDisplayMode.works;

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

    final isLoading = _displayMode == WorksMasterDetailDisplayMode.works
        ? monthGroupsAsync.isLoading
        : workPlanMonthGroupsState.isLoading;

    // Права на кнопки верхней панели десктопа
    bool canDeleteSelected = false;
    bool canEditSelectedPlan = false;
    Work? currentWork;
    if (isDesktop &&
        _displayMode == WorksMasterDetailDisplayMode.works &&
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
        _displayMode == WorksMasterDetailDisplayMode.workPlans &&
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
        if (_displayMode == WorksMasterDetailDisplayMode.works) {
          selectedMonth = groups.firstWhere(
            (g) => g.month == selectedMonth!.month,
          );
        }
      } catch (e) {
        // Если группа исчезла, сбрасываем выбор
        selectedMonth = null;
      }
    }

    final appearance = MobileAtmosphereAppearance.of(context);

    return Scaffold(
      backgroundColor: appearance.isDark
          ? appearance.atmosphereBase
          : Colors.transparent,
      drawer: const AppDrawer(activeRoute: AppRoute.works),
      body: WorksMasterDetailDesktopView(
        scrollController: _scrollController,
        isLoading: isLoading,
        monthGroups: groups,
        workPlanMonthGroups: workPlanGroups,
        displayMode: _displayMode,
        onDisplayModeChanged: (mode) {
          setState(() {
            _displayMode = mode;
            selectedWork = null;
            selectedWorkPlan = null;
            selectedMonth = null;
          });
        },
        selectedWork: selectedWork,
        selectedWorkPlan: selectedWorkPlan,
        onWorkSelected: (work) {
          setState(() {
            selectedWork = work;
            selectedMonth = null;
          });
        },
        onWorkPlanSelected: (plan) {
          setState(() {
            selectedWorkPlan = plan;
            selectedWork = null;
            selectedMonth = null;
          });
        },
        onMonthHeaderTapWorks: (group) {
          setState(() {
            selectedMonth = group;
            selectedWork = null;
          });
        },
        onOpenShift: () => showOpenShiftModal(context),
        onCreateWorkPlan: () => showCreateWorkPlanModal(context),
        detailPanel: _buildDetailPanel(theme),
        toolbarTitle: _desktopToolbarTitle(currentWork, selectedWorkPlan),
        onDeleteSelectedWork:
            canDeleteSelected &&
                _displayMode == WorksMasterDetailDisplayMode.works &&
                currentWork != null
            ? () => confirmDeleteWork(context, currentWork!)
            : null,
        onEditSelectedWorkPlan:
            _displayMode == WorksMasterDetailDisplayMode.workPlans &&
                selectedWorkPlan != null &&
                canEditSelectedPlan
            ? () => showEditWorkPlanModal(context, selectedWorkPlan!)
            : null,
        onDeleteSelectedWorkPlan:
            _displayMode == WorksMasterDetailDisplayMode.workPlans &&
                selectedWorkPlan != null &&
                canDeleteSelected
            ? () => confirmDeleteWorkPlan(context, selectedWorkPlan!)
            : null,
      ),
    );
  }

  String _desktopToolbarTitle(Work? currentWork, WorkPlan? plan) {
    if (_displayMode == WorksMasterDetailDisplayMode.works) {
      return currentWork != null
          ? 'Смена: ${formatRuDate(currentWork.date)}'
          : 'Смены';
    }
    return plan != null ? 'План: ${formatRuDate(plan.date)}' : 'Планы работ';
  }

  /// Строит панель деталей (смена, план или сводка месяца) в правой колонке мастер-детейла.
  Widget _buildDetailPanel(ThemeData theme) {
    // Приоритет: месяц > смена/план > placeholder
    if (selectedMonth != null) {
      return MonthDetailsPanel(group: selectedMonth!);
    } else if (selectedWork != null &&
        _displayMode == WorksMasterDetailDisplayMode.works) {
      return selectedWork!.id != null
          ? WorkDetailsPanel(workId: selectedWork!.id!, parentContext: context)
          : const Center(child: Text('Ошибка: ID смены не задан'));
    } else if (selectedWorkPlan != null &&
        _displayMode == WorksMasterDetailDisplayMode.workPlans) {
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
              _displayMode == WorksMasterDetailDisplayMode.works
                  ? CupertinoIcons.doc_text_search
                  : CupertinoIcons.doc_plaintext,
              size: 64,
              color: theme.colorScheme.outline.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              _displayMode == WorksMasterDetailDisplayMode.works
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
}
