import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/month_groups_provider.dart';
import 'work_details_panel.dart';
import 'package:projectgt/presentation/widgets/app_bar_widget.dart';
import 'package:projectgt/presentation/widgets/app_drawer.dart';
import 'package:go_router/go_router.dart';
import 'package:projectgt/features/works/domain/entities/work.dart';
import 'package:projectgt/presentation/state/profile_state.dart';
import 'package:projectgt/core/utils/responsive_utils.dart';
import 'package:projectgt/core/utils/modal_utils.dart';
import 'package:projectgt/features/employees/presentation/widgets/master_detail_layout.dart';
import '../widgets/month_group_header.dart';
import '../widgets/month_works_list.dart';
import '../widgets/month_details_panel.dart';
import '../../data/models/month_group.dart';

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
  bool _showFab = true;
  int _activeTabIndex =
      0; // Индекс активного таба (0 - Данные, 1 - Работы, 2 - Сотрудники)
  Timer? _fabTimer;
  Work? selectedWork;
  MonthGroup?
      selectedMonth; // Выбранная группа месяца для отображения в детальной панели

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(monthGroupsProvider.notifier).loadMonths();
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

  /// Обрабатывает pull-to-refresh.
  Future<void> _handleRefresh() async {
    await ref.read(monthGroupsProvider.notifier).refresh();
  }

  /// Показывает модальную форму для открытия смены.
  void _showOpenShiftModal(BuildContext context) {
    ModalUtils.showWorkFormModal(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final monthGroupsState = ref.watch(monthGroupsProvider);
    final profile = ref.watch(currentUserProfileProvider).profile;
    final isDesktop = ResponsiveUtils.isDesktop(context);
    final groups = monthGroupsState.groups;
    final isLoading = monthGroupsState.isLoading;

    // Проверяем есть ли у пользователя открытая смена
    bool hasOpenByUser = false;
    for (final group in groups) {
      if (group.works != null) {
        hasOpenByUser = group.works!.any((w) =>
            w.status.toLowerCase() == 'open' &&
            w.openedBy == (profile?.id ?? ''));
        if (hasOpenByUser) break;
      }
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      extendBodyBehindAppBar: true,
      appBar: const AppBarWidget(
        title: 'Смены',
      ),
      drawer: const AppDrawer(activeRoute: AppRoute.works),
      floatingActionButton: AnimatedScale(
        scale: _showFab &&
                (ResponsiveUtils.isMobile(context) || _activeTabIndex == 0) &&
                !hasOpenByUser
            ? 1.0
            : 0.0,
        duration: const Duration(milliseconds: 300),
        child: SafeArea(
          child: FloatingActionButton(
            onPressed: () {
              _showOpenShiftModal(context);
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
          if (isDesktop) {
            return _buildDesktopLayout(
              isLoading: isLoading,
              groups: groups,
              theme: theme,
            );
          } else {
            return _buildMobileLayout(
              isLoading: isLoading,
              groups: groups,
              theme: theme,
            );
          }
        },
      ),
    );
  }

  /// Строит десктопную версию интерфейса (мастер-детейл).
  Widget _buildDesktopLayout({
    required bool isLoading,
    required List groups,
    required ThemeData theme,
  }) {
    return MasterDetailLayout(
      masterPanel: _buildWorksList(
        isLoading: isLoading,
        groups: groups,
        theme: theme,
        isDesktop: true,
      ),
      detailPanel: _buildDetailPanel(theme),
    );
  }

  /// Строит панель деталей (смена или месяц).
  Widget _buildDetailPanel(ThemeData theme) {
    // Приоритет: месяц > смена > placeholder
    if (selectedMonth != null) {
      return Column(
        children: [
          // Отступ сверху для мастер-детейл режима
          SizedBox(
            height:
                MediaQuery.of(context).viewPadding.top + kToolbarHeight + 24,
          ),
          Expanded(
            child: MonthDetailsPanel(group: selectedMonth!),
          ),
        ],
      );
    } else if (selectedWork != null) {
      return selectedWork!.id != null
          ? Column(
              children: [
                // Отступ сверху для мастер-детейл режима
                SizedBox(
                  height: MediaQuery.of(context).viewPadding.top +
                      kToolbarHeight +
                      24,
                ),
                Expanded(
                  child: WorkDetailsPanel(
                    workId: selectedWork!.id!,
                    parentContext: context,
                    onTabChanged: (tabIndex) {
                      setState(() {
                        _activeTabIndex = tabIndex;
                      });
                    },
                  ),
                ),
              ],
            )
          : const Center(child: Text('Ошибка: ID смены не задан'));
    } else {
      return Center(
        child: Text(
          'Выберите смену или месяц из списка',
          style: theme.textTheme.bodyLarge,
        ),
      );
    }
  }

  /// Строит мобильную версию интерфейса.
  Widget _buildMobileLayout({
    required bool isLoading,
    required List groups,
    required ThemeData theme,
  }) {
    return _buildWorksList(
      isLoading: isLoading,
      groups: groups,
      theme: theme,
      isDesktop: false,
    );
  }

  /// Строит список смен с группировкой по месяцам.
  Widget _buildWorksList({
    required bool isLoading,
    required List groups,
    required ThemeData theme,
    required bool isDesktop,
  }) {
    if (isLoading) {
      return const Center(child: CupertinoActivityIndicator());
    }

    if (groups.isEmpty) {
      return const Center(child: Text('Смены не найдены'));
    }

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: ListView.builder(
        controller: _scrollController,
        itemCount: groups.length,
        itemBuilder: (context, index) {
          final group = groups[index];

          return Column(
            key: ValueKey(group.month),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Заголовок группы месяца
              MonthGroupHeader(
                group: group,
                onTap: () {
                  // Раскрываем/сворачиваем месяц
                  ref
                      .read(monthGroupsProvider.notifier)
                      .toggleMonth(group.month);

                  // На десктопе показываем информацию о месяце в детальной панели
                  if (isDesktop) {
                    setState(() {
                      selectedMonth = group;
                      selectedWork = null; // Сбрасываем выбранную смену
                    });
                  }
                },
                onMobileLongPress: () {
                  if (!ResponsiveUtils.isMobile(context)) {
                    return;
                  }

                  final notifier = ref.read(monthGroupsProvider.notifier);
                  notifier.expandMonth(group.month);

                  context.pushNamed(
                    'month_details_mobile',
                    extra: group,
                  );
                },
              ),

              // Список смен (если группа развёрнута)
              if (group.isExpanded)
                MonthWorksList(
                  group: group,
                  onWorkSelected: (work) {
                    if (isDesktop) {
                      setState(() {
                        selectedWork = work;
                        selectedMonth = null; // Сбрасываем выбранный месяц
                      });
                    } else {
                      if (work.id != null) {
                        context.goNamed(
                          'work_details',
                          pathParameters: {'workId': work.id!},
                        );
                      }
                    }
                  },
                  onLoadMore: () {
                    // Подгрузка дополнительных смен при infinite scroll
                    ref
                        .read(monthGroupsProvider.notifier)
                        .loadMoreMonthWorks(group.month);
                  },
                  selectedWork: selectedWork,
                ),
            ],
          );
        },
      ),
    );
  }
}
