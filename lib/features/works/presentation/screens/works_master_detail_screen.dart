import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/month_groups_provider.dart';
import 'work_details_panel.dart';
import 'package:projectgt/presentation/widgets/app_bar_widget.dart';
import 'package:projectgt/presentation/widgets/app_drawer.dart';
import 'package:go_router/go_router.dart';
import 'package:projectgt/features/works/domain/entities/work.dart';
import 'package:projectgt/presentation/state/profile_state.dart';
import 'package:projectgt/features/company/presentation/providers/company_providers.dart';
import 'package:projectgt/core/utils/responsive_utils.dart';
import 'package:projectgt/core/utils/modal_utils.dart';
import '../widgets/month_group_header.dart';
import '../widgets/month_details_panel.dart';
import '../widgets/sliver_month_works_list.dart';
import '../widgets/mobile_month_works_list.dart';
import '../../data/models/month_group.dart';
import 'package:projectgt/features/roles/presentation/widgets/permission_guard.dart';
import 'package:projectgt/features/work_plans/presentation/screens/work_plan_form_modal.dart';
import 'package:projectgt/core/widgets/gt_buttons.dart';
import 'package:projectgt/core/di/providers.dart';

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
    extends ConsumerState<WorksMasterDetailScreen> {
  final _scrollController = ScrollController();
  Work? selectedWork;
  MonthGroup?
  selectedMonth; // Выбранная группа месяца для отображения в детальной панели

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Обрабатывает pull-to-refresh.
  Future<void> _handleRefresh() async {
    await ref.read(monthGroupsProvider.notifier).refresh();
  }

  /// Показывает модальную форму для открытия смены.
  void _showOpenShiftModal(BuildContext context) {
    ModalUtils.showWorkFormModal(context);
  }

  /// Показывает модальное окно создания плана работ.
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

  @override
  Widget build(BuildContext context) {
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

    final monthGroupsState = ref.watch(monthGroupsProvider);
    final profile = ref.watch(currentUserProfileProvider).profile;
    final isDesktop = ResponsiveUtils.isDesktop(context);
    final groups = monthGroupsState.groups;
    final isLoading = monthGroupsState.isLoading;

    // Актуализируем selectedMonth из groups, чтобы данные в панели обновлялись
    if (selectedMonth != null) {
      try {
        selectedMonth = groups.firstWhere(
          (g) => g.month == selectedMonth!.month,
        );
      } catch (e) {
        // Если группа исчезла, сбрасываем выбор
        selectedMonth = null;
      }
    }

    // Проверяем есть ли у пользователя открытая смена
    bool hasOpenByUser = false;
    for (final group in groups) {
      if (group.works != null) {
        hasOpenByUser = group.works!.any(
          (w) =>
              w.status.toLowerCase() == 'open' &&
              w.openedBy == (profile?.id ?? ''),
        );
        if (hasOpenByUser) break;
      }
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      // На десктопе показываем AppBar в Scaffold, на мобильных - он будет в списке
      appBar: isDesktop ? const AppBarWidget(title: 'Смены') : null,
      drawer: const AppDrawer(activeRoute: AppRoute.works),
      floatingActionButton: null,
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (isDesktop) {
            return _buildDesktopLayout(
              isLoading: isLoading,
              groups: groups,
              theme: theme,
              hasOpenByUser: hasOpenByUser,
            );
          } else {
            // Для мобильных добавляем SafeArea, чтобы контент не залезал под статус-бар
            // при прозрачном (отсутствующем) AppBar
            return SafeArea(
              child: _buildMobileLayout(
                isLoading: isLoading,
                groups: groups,
                theme: theme,
              ),
            );
          }
        },
      ),
    );
  }

  /// Строит десктопную версию интерфейса (Card-in-Card layout).
  Widget _buildDesktopLayout({
    required bool isLoading,
    required List<MonthGroup> groups,
    required ThemeData theme,
    required bool hasOpenByUser,
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
              // Левая панель - список смен (узкая)
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
                    if (!hasOpenByUser)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: SizedBox(
                          width: double.infinity,
                          child: PermissionGuard(
                            module: 'works',
                            permission: 'create',
                            child: GTPrimaryButton(
                              onPressed: () => _showOpenShiftModal(context),
                              icon: CupertinoIcons.add,
                              text: 'Открыть смену',
                              backgroundColor: Colors.green,
                            ),
                          ),
                        ),
                      ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: _buildWorksList(
                          isLoading: isLoading,
                          groups: groups,
                          theme: theme,
                          isDesktop: true,
                          // Цвет фона для прилипающего заголовка на десктопе
                          stickyHeaderColor: isDark
                              ? Colors.grey[900]
                              : Colors.white,
                        ),
                      ),
                    ),
                    if (!hasOpenByUser)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: SizedBox(
                          width: double.infinity,
                          child: PermissionGuard(
                            module: 'work_plans',
                            permission: 'create',
                            child: GTPrimaryButton(
                              onPressed: () =>
                                  _showCreateWorkPlanModal(context),
                              icon: CupertinoIcons.add,
                              text: 'Составить план',
                              backgroundColor: Colors.blue,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Правая панель - детали
              Expanded(child: _buildDetailPanel(theme, isDesktop: true)),
            ],
          ),
        ),
      ),
    );
  }

  /// Строит панель деталей (смена или месяц).
  Widget _buildDetailPanel(ThemeData theme, {bool isDesktop = false}) {
    // Если десктоп, не нужны отступы под AppBar, так как мы внутри контейнера
    final topPadding = isDesktop
        ? 0.0
        : MediaQuery.of(context).viewPadding.top + kToolbarHeight + 24;

    // Приоритет: месяц > смена > placeholder
    if (selectedMonth != null) {
      return Column(
        children: [
          if (!isDesktop) SizedBox(height: topPadding),
          Expanded(child: MonthDetailsPanel(group: selectedMonth!)),
        ],
      );
    } else if (selectedWork != null) {
      return selectedWork!.id != null
          ? Column(
              children: [
                if (!isDesktop) SizedBox(height: topPadding),
                Expanded(
                  child: WorkDetailsPanel(
                    workId: selectedWork!.id!,
                    parentContext: context,
                  ),
                ),
              ],
            )
          : const Center(child: Text('Ошибка: ID смены не задан'));
    } else {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.doc_text_search,
              size: 64,
              color: theme.colorScheme.outline.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Выберите смену или месяц из списка',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      );
    }
  }

  /// Строит мобильную версию интерфейса.
  Widget _buildMobileLayout({
    required bool isLoading,
    required List<MonthGroup> groups,
    required ThemeData theme,
  }) {
    return _buildWorksList(
      isLoading: isLoading,
      groups: groups,
      theme: theme,
      isDesktop: false,
      stickyHeaderColor: theme.colorScheme.surface,
    );
  }

  /// Строит список смен с группировкой по месяцам.
  ///
  /// Использует [CustomScrollView] и [SliverMonthWorksList] для эффективного
  /// рендеринга и infinite scroll.
  Widget _buildWorksList({
    required bool isLoading,
    required List<MonthGroup> groups,
    required ThemeData theme,
    required bool isDesktop,
    Color? stickyHeaderColor,
  }) {
    if (isLoading) {
      return const Center(child: CupertinoActivityIndicator());
    }

    if (groups.isEmpty) {
      return const Center(child: Text('Смены не найдены'));
    }

    // Проверка на наличие открытой смены пользователем (для кнопки)
    final profile = ref.watch(currentUserProfileProvider).profile;
    bool hasOpenByUser = false;
    for (final group in groups) {
      if (group.works != null) {
        hasOpenByUser = group.works!.any(
          (w) =>
              w.status.toLowerCase() == 'open' &&
              w.openedBy == (profile?.id ?? ''),
        );
        if (hasOpenByUser) break;
      }
    }

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // AppBar для мобильных (внутри списка, чтобы уезжал)
          if (!isDesktop)
            SliverToBoxAdapter(
              child: AppBarWidget(
                title: 'Смены',
                showThemeSwitch: true,
                // Используем context для открытия Drawer, так как Scaffold выше
                leading: Builder(
                  builder: (context) => CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: const Icon(Icons.menu, color: Colors.green),
                    onPressed: () {
                      Scaffold.of(context).openDrawer();
                    },
                  ),
                ),
              ),
            ),

          // Кнопка открытия смены для мобильных (над списком)
          if (!isDesktop && !hasOpenByUser)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: SizedBox(
                  width: double.infinity,
                  child: PermissionGuard(
                    module: 'works',
                    permission: 'create',
                    child: GTPrimaryButton(
                      onPressed: () => _showOpenShiftModal(context),
                      icon: CupertinoIcons.add,
                      text: 'Открыть смену',
                      backgroundColor: Colors.green,
                    ),
                  ),
                ),
              ),
            ),

          // Генерируем slivers для каждой группы
          for (final group in groups) ...[
            // Заголовок группы с прилипанием
            SliverPersistentHeader(
              key: ValueKey('header_${group.month}'),
              // Прилипаем ТОЛЬКО если группа развернута
              pinned: group.isExpanded,
              delegate: _MonthGroupHeaderDelegate(
                group: group,
                backgroundColor: stickyHeaderColor,
                onTap: () {
                  // Раскрываем/сворачиваем месяц
                  ref
                      .read(monthGroupsProvider.notifier)
                      .toggleMonth(group.month);

                  if (isDesktop) {
                    setState(() {
                      // Всегда выбираем месяц при клике, даже если сворачиваем
                      // Это позволяет видеть сводку
                      selectedMonth = group;
                      selectedWork = null;
                    });
                  }
                },
                onMobileLongPress: () {
                  if (!ResponsiveUtils.isMobile(context)) {
                    return;
                  }

                  final notifier = ref.read(monthGroupsProvider.notifier);
                  notifier.expandMonth(group.month);

                  context.pushNamed('month_details_mobile', extra: group);
                },
              ),
            ),

            // Список смен (только если развернут)
            if (isDesktop)
              if (group.isExpanded)
                SliverMonthWorksList(
                  key: ValueKey('list_${group.month}'),
                  group: group,
                  isCompact: isDesktop,
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
                const SliverToBoxAdapter(child: SizedBox.shrink())
            else
              // Mobile: Анимация раскрытия
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

          // Для мобильных: заполняем пространство и прижимаем кнопку вниз
          if (!isDesktop && !hasOpenByUser)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    child: SizedBox(
                      width: double.infinity,
                      child: PermissionGuard(
                        module: 'work_plans',
                        permission: 'create',
                        child: GTPrimaryButton(
                          onPressed: () => _showCreateWorkPlanModal(context),
                          icon: CupertinoIcons.add,
                          text: 'Составить план',
                          backgroundColor: Colors.blue,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Небольшой отступ внизу списка (только для десктопа)
          if (isDesktop)
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}

/// Делегат для прилипающего заголовка месяца
class _MonthGroupHeaderDelegate extends SliverPersistentHeaderDelegate {
  final MonthGroup group;
  final VoidCallback onTap;
  final VoidCallback? onMobileLongPress;
  final Color? backgroundColor;

  _MonthGroupHeaderDelegate({
    required this.group,
    required this.onTap,
    this.onMobileLongPress,
    this.backgroundColor,
  });

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final theme = Theme.of(context);

    // Если группа свернута, мы не применяем эффект прилипания (не меняем цвет/размер),
    // но заголовок все равно участвует в потоке как pinned.
    // Чтобы убрать эффект, просто передаем stuckAmount = 0.0.
    final bool isExpanded = group.isExpanded;

    // Вычисляем степень "прилипания" (0.0 -> 1.0)
    // shrinkOffset идет от 0 до (maxExtent - minExtent)
    final double rawStuckAmount = (shrinkOffset / (maxExtent - minExtent))
        .clamp(0.0, 1.0);

    // Применяем эффект ТОЛЬКО если группа развернута
    final double stuckAmount = isExpanded ? rawStuckAmount : 0.0;

    // Используем переданный цвет или дефолтный
    // Добавляем разделитель/тень, если заголовок прилип И развернут
    final isStuck = stuckAmount > 0.1;

    return Container(
      color: backgroundColor ?? theme.colorScheme.surface,
      child: Stack(
        children: [
          // Центрируем заголовок, так как высота делегата меняется
          Align(
            alignment: Alignment.center,
            child: MonthGroupHeader(
              group: group,
              onTap: onTap,
              onMobileLongPress: onMobileLongPress,
              stuckAmount: stuckAmount,
            ),
          ),
          // Опционально: добавить тонкую линию внизу, когда прилипло и развернуто
          if (isStuck)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Divider(
                height: 1,
                thickness: 1,
                color: theme.colorScheme.outline.withValues(
                  alpha: 0.1 * stuckAmount,
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  // Высота заголовка:
  // В развернутом состоянии даем больше воздуха (100.0)
  // В свернутом (прилипшем) состоянии - компактнее (80.0)
  double get maxExtent => 100.0;

  @override
  double get minExtent => 80.0;

  @override
  bool shouldRebuild(covariant _MonthGroupHeaderDelegate oldDelegate) {
    return oldDelegate.group != group ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}
