import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:projectgt/core/error/failure.dart';
import 'package:projectgt/core/widgets/app_snackbar.dart';
import 'package:projectgt/core/widgets/mobile_atmosphere_backdrop.dart';
import 'package:projectgt/core/widgets/mobile_atmosphere_screen_header.dart';
import 'package:projectgt/features/roles/application/permission_service.dart';
import 'package:projectgt/features/work_plans/presentation/providers/work_plan_month_groups_provider.dart';
import 'package:projectgt/features/works/data/models/month_group.dart';
import 'package:projectgt/features/works/presentation/providers/month_groups_provider.dart';
import 'package:projectgt/features/works/presentation/screens/works_list_mobile_plans_view.dart';
import 'package:projectgt/features/works/presentation/screens/works_screen_actions_mixin.dart';
import 'package:projectgt/features/works/presentation/widgets/mobile_month_works_list.dart';
import 'package:projectgt/features/works/presentation/widgets/work_month_group_sliver_header.dart';
import 'package:projectgt/presentation/state/profile_state.dart';
import 'package:projectgt/presentation/widgets/app_drawer.dart';

/// Режим отображения на мобильном экране работ: смены или планы.
enum _MobileDisplayMode { works, workPlans }

/// Мобильный экран модуля «Работы».
///
/// Показывает список смен и/или планов работ, сгруппированных по месяцам,
/// поверх многослойного фона [MobileAtmosphereBackdrop]. Переключение режима
/// (смены/планы) происходит без навигации — через [AnimatedSwitcher].
///
/// Десктопная реализация живёт в `WorksMasterDetailScreen` и использует
/// master-detail layout; этот экран намеренно не содержит state-полей
/// `selectedWork`/`selectedMonth`, поскольку на мобильном переход в детали
/// выполняется через `pushNamed('work_details' | 'month_details_mobile')`.
class WorksListMobileScreen extends ConsumerStatefulWidget {
  /// Создаёт мобильный экран списка смен и планов.
  const WorksListMobileScreen({super.key});

  @override
  ConsumerState<WorksListMobileScreen> createState() =>
      _WorksListMobileScreenState();
}

class _WorksListMobileScreenState extends ConsumerState<WorksListMobileScreen>
    with WorksScreenActionsMixin<WorksListMobileScreen> {
  _MobileDisplayMode _displayMode = _MobileDisplayMode.works;

  Future<void> _handleWorksRefresh() =>
      ref.read(monthGroupsProvider.notifier).refresh();

  Future<void> _handlePlansRefresh() =>
      ref.read(workPlanMonthGroupsProvider.notifier).refresh();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appearance = MobileAtmosphereAppearance.of(context);
    final isDark = appearance.isDark;

    ref.listen<AsyncValue<List<MonthGroup>>>(monthGroupsProvider, (
      previous,
      next,
    ) {
      next.whenOrNull(
        error: (error, _) {
          if (!mounted) return;
          final failure = error is Failure
              ? error
              : Failure.fromException(error);
          AppSnackBar.show(
            context: context,
            message: failure.message ?? 'Ошибка загрузки смен',
            kind: AppSnackBarKind.error,
          );
        },
      );
    });

    final monthGroupsAsync = ref.watch(monthGroupsProvider);
    final monthGroupsNotifier = ref.read(monthGroupsProvider.notifier);
    final onlyMineListScope = monthGroupsNotifier.isMineListScope;

    final worksGroups = monthGroupsAsync.valueOrNull ?? const <MonthGroup>[];
    final worksLoading = monthGroupsAsync.isLoading && worksGroups.isEmpty;

    final permissions = ref.watch(permissionServiceProvider);
    final canCreateShift = permissions.can('works', 'create');
    final canViewWorkPlans = permissions.can('work_plans', 'create');
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
      child: Scaffold(
        backgroundColor: isDark
            ? appearance.atmosphereBase
            : Colors.transparent,
        drawer: const AppDrawer(activeRoute: AppRoute.works),
        body: Stack(
          fit: StackFit.expand,
          children: [
            const MobileAtmosphereBackdrop(),
            SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  MobileAtmosphereScreenHeader(
                    appearance: appearance,
                    title: _displayMode == _MobileDisplayMode.works
                        ? 'Смены'
                        : 'Планы',
                    leading: Builder(
                      builder: (ctx) => MobileAtmosphereChromeCircleButton(
                        appearance: appearance,
                        icon: Icons.menu_rounded,
                        onTap: () => Scaffold.of(ctx).openDrawer(),
                      ),
                    ),
                    trailing: _displayMode == _MobileDisplayMode.works
                        ? (canCreateShift
                              ? MobileAtmosphereChromeCircleButton(
                                  appearance: appearance,
                                  tooltip: 'Открыть смену',
                                  icon: Icons.add_rounded,
                                  iconColor: theme.colorScheme.primary,
                                  iconSize: 26,
                                  onTap: () => showOpenShiftModal(context),
                                )
                              : null)
                        : (canViewWorkPlans
                              ? MobileAtmosphereChromeCircleButton(
                                  appearance: appearance,
                                  tooltip: 'Составить план',
                                  icon: Icons.add_rounded,
                                  iconColor: theme.colorScheme.primary,
                                  iconSize: 26,
                                  onTap: () => showCreateWorkPlanModal(context),
                                )
                              : null),
                  ),
                  if (_displayMode == _MobileDisplayMode.works)
                    _MobileWorksListChipsBar(
                      scheme: theme.colorScheme,
                      profileId: profileId,
                      onlyMineActive: onlyMineListScope,
                      canOpenPlans: canViewWorkPlans,
                      onAllTap: () async {
                        await ref
                            .read(monthGroupsProvider.notifier)
                            .setOpenedByListFilter(null);
                      },
                      onMineTap: () async {
                        final id = ref
                            .read(currentUserProfileProvider)
                            .profile
                            ?.id;
                        if (id == null) return;
                        await ref
                            .read(monthGroupsProvider.notifier)
                            .setOpenedByListFilter(id);
                      },
                      onPlansTap: () => setState(() {
                        _displayMode = _MobileDisplayMode.workPlans;
                      }),
                    )
                  else
                    WorksListMobilePlansChipsBar(
                      scheme: theme.colorScheme,
                      onShiftsTap: () => setState(() {
                        _displayMode = _MobileDisplayMode.works;
                      }),
                    ),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 500),
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.2),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      ),
                      child: _displayMode == _MobileDisplayMode.works
                          ? _buildWorksView(
                              key: const ValueKey('works_view'),
                              theme: theme,
                              isLoading: worksLoading,
                              groups: worksGroups,
                              showMineOnlyEmptyHint:
                                  onlyMineListScope && profileId != null,
                            )
                          : WorksListMobilePlansView(
                              key: const ValueKey('plans_view'),
                              onRefresh: _handlePlansRefresh,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorksView({
    Key? key,
    required ThemeData theme,
    required bool isLoading,
    required List<MonthGroup> groups,
    required bool showMineOnlyEmptyHint,
  }) {
    if (isLoading) {
      return Center(key: key, child: const CupertinoActivityIndicator());
    }

    final emptyMessage = showMineOnlyEmptyHint
        ? 'У вас пока нет смен.\nНажмите «Все», чтобы увидеть смены компании.'
        : 'Смены не найдены';

    return RefreshIndicator(
      key: key,
      onRefresh: _handleWorksRefresh,
      child: CustomScrollView(
        slivers: [
          if (groups.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Text(
                    emptyMessage,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.95,
                      ),
                      height: 1.35,
                    ),
                  ),
                ),
              ),
            )
          else
            for (final group in groups) ...[
              SliverPersistentHeader(
                key: ValueKey('header_${group.month}'),
                pinned: group.isExpanded,
                delegate: WorkMonthGroupSliverHeader(
                  group: group,
                  backgroundColor: Colors.transparent,
                  onTap: () => ref
                      .read(monthGroupsProvider.notifier)
                      .toggleMonth(group.month),
                  onMobileLongPress: () {
                    ref
                        .read(monthGroupsProvider.notifier)
                        .expandMonth(group.month);
                    context.pushNamed('month_details_mobile', extra: group);
                  },
                ),
              ),
              SliverToBoxAdapter(
                key: ValueKey('anim_list_${group.month}'),
                child: AnimatedSize(
                  duration: const Duration(milliseconds: 400),
                  alignment: Alignment.topCenter,
                  curve: Curves.fastOutSlowIn,
                  child: group.isExpanded
                      ? MobileMonthWorksList(
                          group: group,
                          onWorkSelected: (work) {
                            if (work.id != null) {
                              context.goNamed(
                                'work_details',
                                pathParameters: {'workId': work.id!},
                              );
                            }
                          },
                          onLoadMore: () {
                            ref
                                .read(monthGroupsProvider.notifier)
                                .loadMoreMonthWorks(group.month);
                          },
                        )
                      : const SizedBox(width: double.infinity, height: 0),
                ),
              ),
            ],
        ],
      ),
    );
  }
}

/// Горизонтальная полоса чипов списка смен: «Все» / «Мои смены» / «Планы».
///
/// Визуально совпадает с текстовыми чипами статусов на экране сотрудников.
class _MobileWorksListChipsBar extends StatelessWidget {
  /// Создаёт полосу чипов над списком смен.
  const _MobileWorksListChipsBar({
    required this.scheme,
    required this.profileId,
    required this.onlyMineActive,
    required this.canOpenPlans,
    required this.onAllTap,
    required this.onMineTap,
    required this.onPlansTap,
  });

  final ColorScheme scheme;
  final String? profileId;
  final bool onlyMineActive;
  final bool canOpenPlans;
  final Future<void> Function() onAllTap;
  final Future<void> Function() onMineTap;
  final VoidCallback onPlansTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
        child: Row(
          children: [
            _MobileFilterTextChip(
              scheme: scheme,
              label: 'Все',
              selected: !onlyMineActive,
              onTap: onAllTap,
            ),
            if (profileId != null) ...[
              const SizedBox(width: 22),
              _MobileFilterTextChip(
                scheme: scheme,
                label: 'Мои смены',
                selected: onlyMineActive,
                onTap: onMineTap,
              ),
            ],
            if (canOpenPlans) ...[
              const SizedBox(width: 22),
              _MobileFilterTextChip(
                scheme: scheme,
                label: 'Планы',
                selected: false,
                onTap: () async {
                  onPlansTap();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Текстовый чип фильтра: в активном состоянии — цвет primary и подчёркивание.
class _MobileFilterTextChip extends StatelessWidget {
  const _MobileFilterTextChip({
    required this.scheme,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final ColorScheme scheme;
  final String label;
  final bool selected;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? scheme.primary : scheme.onSurfaceVariant;

    return InkWell(
      onTap: () async {
        await onTap();
      },
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            letterSpacing: 0.1,
            height: 1.35,
            decoration: selected
                ? TextDecoration.underline
                : TextDecoration.none,
            decorationColor: scheme.primary,
            decorationThickness: 2,
            decorationStyle: TextDecorationStyle.solid,
          ),
        ),
      ),
    );
  }
}
