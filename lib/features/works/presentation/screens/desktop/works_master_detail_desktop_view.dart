import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/refresh/app_focus_refresh_coordinator.dart';
import 'package:projectgt/core/theme/theme_settings_provider.dart';
import 'package:projectgt/core/widgets/gt_buttons.dart';
import 'package:projectgt/core/widgets/mobile_atmosphere_backdrop.dart';
import 'package:projectgt/core/widgets/mobile_atmosphere_screen_header.dart';
import 'package:projectgt/domain/entities/work_plan.dart';
import 'package:projectgt/features/roles/application/permission_service.dart';
import 'package:projectgt/features/roles/presentation/widgets/permission_guard.dart';
import 'package:projectgt/features/work_plans/data/models/work_plan_month_group.dart';
import 'package:projectgt/features/work_plans/presentation/providers/work_plan_month_groups_provider.dart';
import 'package:projectgt/features/works/data/models/month_group.dart';
import 'package:projectgt/features/works/domain/entities/work.dart';
import 'package:projectgt/features/works/presentation/providers/month_groups_provider.dart';
import 'package:projectgt/features/works/presentation/screens/works_list_mobile_plans_view.dart';
import 'package:projectgt/features/works/presentation/widgets/desktop_month_work_plans_list.dart';
import 'package:projectgt/features/works/presentation/widgets/sliver_month_works_list.dart';
import 'package:projectgt/features/works/presentation/widgets/work_month_group_sliver_header.dart';
import 'package:projectgt/features/works/presentation/widgets/work_plan_month_group_sliver_header.dart';
import 'package:projectgt/features/works/presentation/widgets/works_list_scope_chips_bar.dart';
import 'package:projectgt/presentation/state/profile_state.dart';

/// Поля и шаг сетки десктопа экрана работ — те же числа, что
/// [ContractListScreenDesktopChrome] у списка договоров.
abstract final class _WorksDesktopScreenChrome {
  static const double _gridGutter = 16;

  /// Как [ContractListScreenDesktopChrome.desktopHeaderOuterPadding].
  static const EdgeInsets headerOuterPadding = EdgeInsets.fromLTRB(
    _gridGutter,
    20,
    _gridGutter,
    8,
  );

  /// Как [ContractListScreenDesktopChrome.desktopBodyOuterPadding].
  static const EdgeInsets bodyOuterPadding = EdgeInsets.fromLTRB(
    _gridGutter,
    0,
    _gridGutter,
    10,
  );

  /// Как [ContractListScreenDesktopChrome.listToSidebarRowGap].
  static const double columnGap = _gridGutter;
}

/// Режим основной колонки на десктопе: смены или планы работ.
enum WorksMasterDetailDisplayMode {
  /// Список смен по месяцам.
  works,

  /// Планы работ по месяцам.
  workPlans,
}

/// Десктопная версия экрана «Смены / планы»: отступы и круглый хром как у списка договоров
/// ([_WorksDesktopScreenChrome], [MobileAtmosphereChromeCircleButton]).
class WorksMasterDetailDesktopView extends ConsumerWidget {
  /// Контроллер прокрутки списка смен.
  final ScrollController scrollController;

  /// Индикатор загрузки текущего режима.
  final bool isLoading;

  /// Группы смен по месяцам.
  final List<MonthGroup> monthGroups;

  /// Группы планов по месяцам.
  final List<WorkPlanMonthGroup> workPlanMonthGroups;

  /// Текущий режим списка.
  final WorksMasterDetailDisplayMode displayMode;

  /// Смена режима «Смены» / «Планы» (родитель обязан сбросить выбор смены, плана и месяца).
  final ValueChanged<WorksMasterDetailDisplayMode> onDisplayModeChanged;

  /// Выбранная смена (режим смен).
  final Work? selectedWork;

  /// Выбранный план (режим планов).
  final WorkPlan? selectedWorkPlan;

  /// Выбор смены из списка.
  final ValueChanged<Work> onWorkSelected;

  /// Выбор плана из списка.
  final ValueChanged<WorkPlan> onWorkPlanSelected;

  /// Тап по заголовку месяца в списке смен (сводка месяца).
  final ValueChanged<MonthGroup> onMonthHeaderTapWorks;

  /// Открытие новой смены.
  final VoidCallback onOpenShift;

  /// Создание плана работ.
  final VoidCallback onCreateWorkPlan;

  /// Правая колонка: детали смены, плана, месяца или плейсхолдер.
  final Widget detailPanel;

  /// Заголовок верхней панели (контекст выбранной смены или плана).
  final String toolbarTitle;

  /// Удаление текущей выбранной смены (если null — кнопка скрыта).
  final VoidCallback? onDeleteSelectedWork;

  /// Редактирование выбранного плана (если null — кнопка скрыта).
  final VoidCallback? onEditSelectedWorkPlan;

  /// Удаление выбранного плана (если null — кнопка скрыта).
  final VoidCallback? onDeleteSelectedWorkPlan;

  /// Создаёт десктопную раскладку экрана работ.
  const WorksMasterDetailDesktopView({
    super.key,
    required this.scrollController,
    required this.isLoading,
    required this.monthGroups,
    required this.workPlanMonthGroups,
    required this.displayMode,
    required this.onDisplayModeChanged,
    required this.selectedWork,
    required this.selectedWorkPlan,
    required this.onWorkSelected,
    required this.onWorkPlanSelected,
    required this.onMonthHeaderTapWorks,
    required this.onOpenShift,
    required this.onCreateWorkPlan,
    required this.detailPanel,
    required this.toolbarTitle,
    this.onDeleteSelectedWork,
    this.onEditSelectedWorkPlan,
    this.onDeleteSelectedWorkPlan,
  });

  BoxDecoration _atmosphereCardDecoration(MobileAtmosphereAppearance a) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [a.cardTop, a.cardBottom],
      ),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: a.cardBorder),
      boxShadow: a.cardShadows,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appearance = MobileAtmosphereAppearance.of(context);
    final isDark = appearance.isDark;
    ref.watch(monthGroupsProvider);
    final onlyMineListScope = ref
        .read(monthGroupsProvider.notifier)
        .isMineListScope;
    final canOpenPlans = ref
        .watch(permissionServiceProvider)
        .can('work_plans', 'create');
    final profileId = ref.watch(currentUserProfileProvider).profile?.id;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: appearance.atmosphereBase,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness: isDark
            ? Brightness.light
            : Brightness.dark,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const MobileAtmosphereBackdrop(),
          SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: _WorksDesktopScreenChrome.headerOuterPadding,
                  child: _WorksDesktopToolbar(
                    appearance: appearance,
                    title: toolbarTitle,
                    onDeleteWork: onDeleteSelectedWork,
                    onEditWorkPlan: onEditSelectedWorkPlan,
                    onDeleteWorkPlan: onDeleteSelectedWorkPlan,
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: _WorksDesktopScreenChrome.bodyOuterPadding,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          width: 350,
                          child: DecoratedBox(
                            decoration: _atmosphereCardDecoration(appearance),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      12,
                                      12,
                                      12,
                                      0,
                                    ),
                                    child:
                                        displayMode ==
                                            WorksMasterDetailDisplayMode.works
                                        ? WorksListScopeChipsBar(
                                            scheme: appearance.scheme,
                                            profileId: profileId,
                                            onlyMineActive: onlyMineListScope,
                                            canOpenPlans: canOpenPlans,
                                            onAllTap: () => ref
                                                .read(
                                                  monthGroupsProvider.notifier,
                                                )
                                                .setOpenedByListFilter(null),
                                            onMineTap: () async {
                                              final id = ref
                                                  .read(
                                                    currentUserProfileProvider,
                                                  )
                                                  .profile
                                                  ?.id;
                                              if (id == null) return;
                                              await ref
                                                  .read(
                                                    monthGroupsProvider
                                                        .notifier,
                                                  )
                                                  .setOpenedByListFilter(id);
                                            },
                                            onPlansTap: () =>
                                                onDisplayModeChanged(
                                                  WorksMasterDetailDisplayMode
                                                      .workPlans,
                                                ),
                                          )
                                        : WorksListMobilePlansChipsBar(
                                            scheme: appearance.scheme,
                                            onShiftsTap: () =>
                                                onDisplayModeChanged(
                                                  WorksMasterDetailDisplayMode
                                                      .works,
                                                ),
                                          ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: SizedBox(
                                      width: double.infinity,
                                      child:
                                          displayMode ==
                                              WorksMasterDetailDisplayMode.works
                                          ? PermissionGuard(
                                              module: 'works',
                                              permission: 'create',
                                              child: GTPrimaryButton(
                                                onPressed: onOpenShift,
                                                icon: CupertinoIcons.add,
                                                text: 'Открыть смену',
                                                backgroundColor: Colors.green,
                                              ),
                                            )
                                          : PermissionGuard(
                                              module: 'work_plans',
                                              permission: 'create',
                                              child: GTPrimaryButton(
                                                onPressed: onCreateWorkPlan,
                                                icon: CupertinoIcons.add,
                                                text: 'Составить план',
                                                backgroundColor: Colors.blue,
                                              ),
                                            ),
                                    ),
                                  ),
                                  Expanded(
                                    child:
                                        displayMode ==
                                            WorksMasterDetailDisplayMode.works
                                        ? _WorksMonthList(
                                            scrollController: scrollController,
                                            isLoading: isLoading,
                                            groups: monthGroups,
                                            appearance: appearance,
                                            selectedWork: selectedWork,
                                            onWorkSelected: onWorkSelected,
                                            onMonthHeaderTapWorks:
                                                onMonthHeaderTapWorks,
                                          )
                                        : _WorkPlansMonthList(
                                            isLoading: isLoading,
                                            groups: workPlanMonthGroups,
                                            appearance: appearance,
                                            selectedWorkPlan: selectedWorkPlan,
                                            onPlanSelected: onWorkPlanSelected,
                                          ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(
                          width: _WorksDesktopScreenChrome.columnGap,
                        ),
                        Expanded(
                          child: DecoratedBox(
                            decoration: _atmosphereCardDecoration(appearance),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: detailPanel,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Верхняя панель без системного AppBar: меню, заголовок, действия, тема.
class _WorksDesktopToolbar extends ConsumerWidget {
  const _WorksDesktopToolbar({
    required this.appearance,
    required this.title,
    this.onDeleteWork,
    this.onEditWorkPlan,
    this.onDeleteWorkPlan,
  });

  final MobileAtmosphereAppearance appearance;
  final String title;
  final VoidCallback? onDeleteWork;
  final VoidCallback? onEditWorkPlan;
  final VoidCallback? onDeleteWorkPlan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDarkMode = appearance.isDark;
    final isRefreshing = ref.watch(
      appFocusRefreshProvider.select((s) => s.isRefreshing),
    );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Builder(
              builder: (ctx) => MobileAtmosphereChromeCircleButton(
                appearance: appearance,
                tooltip: 'Меню',
                icon: Icons.menu_rounded,
                onTap: () => Scaffold.of(ctx).openDrawer(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: appearance.scheme.onSurface,
                ),
              ),
            ),
            if (onDeleteWork != null) ...[
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: MobileAtmosphereChromeCircleButton(
                  appearance: appearance,
                  tooltip: 'Удалить смену',
                  icon: Icons.delete_outline_rounded,
                  iconColor: theme.colorScheme.error,
                  onTap: onDeleteWork!,
                ),
              ),
            ],
            if (onEditWorkPlan != null) ...[
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: MobileAtmosphereChromeCircleButton(
                  appearance: appearance,
                  tooltip: 'Изменить план',
                  icon: Icons.edit_outlined,
                  iconColor: Colors.amber,
                  onTap: onEditWorkPlan!,
                ),
              ),
            ],
            if (onDeleteWorkPlan != null) ...[
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: MobileAtmosphereChromeCircleButton(
                  appearance: appearance,
                  tooltip: 'Удалить план',
                  icon: Icons.delete_outline_rounded,
                  iconColor: theme.colorScheme.error,
                  onTap: onDeleteWorkPlan!,
                ),
              ),
            ],
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: MobileAtmosphereChromeCircleButton(
                appearance: appearance,
                tooltip: isDarkMode ? 'Светлая тема' : 'Тёмная тема',
                icon: isDarkMode
                    ? Icons.light_mode_outlined
                    : Icons.dark_mode_outlined,
                onTap: () {
                  final newMode = isDarkMode ? ThemeMode.light : ThemeMode.dark;
                  ref
                      .read(themeSettingsProvider.notifier)
                      .setThemeMode(newMode);
                },
              ),
            ),
          ],
        ),
        if (isRefreshing)
          Positioned(
            left: 0,
            right: 0,
            bottom: -6,
            child: SizedBox(
              height: 2,
              child: LinearProgressIndicator(
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(
                  appearance.scheme.primary.withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _WorksMonthList extends ConsumerWidget {
  const _WorksMonthList({
    required this.scrollController,
    required this.isLoading,
    required this.groups,
    required this.appearance,
    required this.selectedWork,
    required this.onWorkSelected,
    required this.onMonthHeaderTapWorks,
  });

  final ScrollController scrollController;
  final bool isLoading;
  final List<MonthGroup> groups;
  final MobileAtmosphereAppearance appearance;
  final Work? selectedWork;
  final ValueChanged<Work> onWorkSelected;
  final ValueChanged<MonthGroup> onMonthHeaderTapWorks;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isLoading) {
      return const Center(child: CupertinoActivityIndicator());
    }
    if (groups.isEmpty) {
      return Center(
        child: Text(
          'Смены не найдены',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: appearance.scheme.onSurfaceVariant,
          ),
        ),
      );
    }

    final headerBg = appearance.cardTop;

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(monthGroupsProvider.notifier).refresh();
      },
      child: CustomScrollView(
        controller: scrollController,
        slivers: [
          for (final group in groups) ...[
            SliverPersistentHeader(
              key: ValueKey('header_${group.month}'),
              pinned: group.isExpanded,
              delegate: WorkMonthGroupSliverHeader(
                group: group,
                backgroundColor: headerBg,
                onTap: () {
                  ref
                      .read(monthGroupsProvider.notifier)
                      .toggleMonth(group.month);
                  onMonthHeaderTapWorks(group);
                },
              ),
            ),
            if (group.isExpanded)
              SliverMonthWorksList(
                key: ValueKey('list_${group.month}'),
                group: group,
                isCompact: true,
                selectedWork: selectedWork,
                onWorkSelected: onWorkSelected,
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

class _WorkPlansMonthList extends ConsumerWidget {
  const _WorkPlansMonthList({
    required this.isLoading,
    required this.groups,
    required this.appearance,
    required this.selectedWorkPlan,
    required this.onPlanSelected,
  });

  final bool isLoading;
  final List<WorkPlanMonthGroup> groups;
  final MobileAtmosphereAppearance appearance;
  final WorkPlan? selectedWorkPlan;
  final ValueChanged<WorkPlan> onPlanSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isLoading) {
      return const Center(child: CupertinoActivityIndicator());
    }
    if (groups.isEmpty) {
      return Center(
        child: Text(
          'Планы не найдены',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: appearance.scheme.onSurfaceVariant,
          ),
        ),
      );
    }

    final headerBg = appearance.cardTop;

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
                backgroundColor: headerBg,
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
                onPlanSelected: onPlanSelected,
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
