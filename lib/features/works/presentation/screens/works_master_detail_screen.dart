import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/work_provider.dart';
import 'work_details_panel.dart';
import 'package:projectgt/presentation/widgets/app_bar_widget.dart';
import 'package:projectgt/presentation/widgets/app_drawer.dart';
import 'package:go_router/go_router.dart';
import 'package:projectgt/features/works/domain/entities/work.dart';
import 'package:intl/intl.dart';
import 'package:projectgt/presentation/widgets/app_badge.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/domain/entities/profile.dart';
import 'package:projectgt/presentation/state/profile_state.dart';
import '../providers/work_hours_provider.dart';
import '../providers/work_items_provider.dart';
import 'package:projectgt/core/utils/responsive_utils.dart';

import 'package:projectgt/core/utils/modal_utils.dart';
// developer import removed

import 'package:projectgt/features/employees/presentation/widgets/master_detail_layout.dart';

/// Экран списка смен с поддержкой поиска, фильтрации и адаптивного отображения.
///
/// - На десктопе реализован мастер-детейл паттерн (список + детали).
/// - На мобильных поиск открывается жестом вниз, поддерживается pull-to-refresh.
/// - Использует Riverpod для управления состоянием и загрузкой данных.
class WorksMasterDetailScreen extends ConsumerStatefulWidget {
  /// Создаёт экран списка смен.
  const WorksMasterDetailScreen({super.key});

  @override
  ConsumerState<WorksMasterDetailScreen> createState() =>
      _WorksMasterDetailScreenState();
}

class _WorksMasterDetailScreenState
    extends ConsumerState<WorksMasterDetailScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  bool _showSearchField = false;
  bool _showFab = true;
  int _activeTabIndex =
      0; // Индекс активного таба (0 - Данные, 1 - Работы, 2 - Сотрудники)
  Timer? _fabTimer;
  Work? selectedWork;

  /// Кэш профилей пользователей для оптимизации отображения.
  final Map<String, Profile?> _profileCache = {};

  /// Получает профиль пользователя из кэша или репозитория.
  Future<Profile?> _getUserProfile(String userId) async {
    if (_profileCache.containsKey(userId)) {
      return _profileCache[userId];
    }

    try {
      final profile =
          await ref.read(profileRepositoryProvider).getProfile(userId);
      _profileCache[userId] = profile;
      return profile;
    } catch (e) {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(worksProvider.notifier).loadWorks();
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    _fabTimer?.cancel();
    super.dispose();
  }

  /// Обработчик прокрутки для показа/скрытия поля поиска и FAB.
  void _onScroll() {
    final scrollPosition = _scrollController.position;

    // Показываем поиск при pull-down (отрицательные значения)
    if (scrollPosition.pixels < -100 && !_showSearchField) {
      setState(() {
        _showSearchField = true;
      });
    }
    // Скрываем поиск при прокрутке вниз
    else if (scrollPosition.pixels > 50 && _showSearchField) {
      setState(() {
        _showSearchField = false;
      });
    }

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

  /// Обработчик изменения поискового запроса.
  void _onSearchChanged(String query) {
    // Поиск будет выполняться в build методе через фильтрацию
    setState(() {});
  }

  /// Обрабатывает pull-to-refresh.
  Future<void> _handleRefresh() async {
    await ref.read(worksProvider.notifier).loadWorks();
  }

  /// Показывает модальную форму для открытия смены.
  void _showOpenShiftModal(BuildContext context) {
    ModalUtils.showWorkFormModal(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final worksState = ref.watch(worksProvider);
    final profile = ref.watch(profileProvider).profile;
    final isDesktop = ResponsiveUtils.isDesktop(context);
    final works = worksState.works;
    final isLoading = worksState.isLoading;
    final searchQuery = _searchController.text;

    // У пользователя может быть только одна открытая смена
    final hasOpenByUser = works.any((w) =>
        w.status.toLowerCase() == 'open' && w.openedBy == (profile?.id ?? ''));

    // Фильтруем и сортируем смены
    final filteredWorks = List<Work>.from(searchQuery.isEmpty
        ? works
        : works.where((w) {
            final objectName = ref
                    .watch(objectProvider)
                    .objects
                    .where((o) => o.id == w.objectId)
                    .map((o) => o.name)
                    .firstOrNull ??
                '';

            return w.objectId
                    .toLowerCase()
                    .contains(searchQuery.toLowerCase()) ||
                w.status.toLowerCase().contains(searchQuery.toLowerCase()) ||
                objectName.toLowerCase().contains(searchQuery.toLowerCase());
          }).toList())
      ..sort((a, b) => b.date.compareTo(a.date));

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      extendBodyBehindAppBar: true,
      appBar: AppBarWidget(
        title: 'Смены',
        showSearchField: _showSearchField,
        searchController: _searchController,
        onSearchChanged: _onSearchChanged,
        searchHint: 'Поиск смен...',
        actions: [
          if (isDesktop) ...[
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: Icon(
                _showSearchField ? Icons.search_off : Icons.search,
                color: _showSearchField ? Colors.green : null,
              ),
              onPressed: () {
                setState(() {
                  _showSearchField = !_showSearchField;
                  if (!_showSearchField) {
                    _searchController.clear();
                    _onSearchChanged('');
                  }
                });
              },
            ),
          ],
        ],
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
              filteredWorks: filteredWorks,
              theme: theme,
            );
          } else {
            return _buildMobileLayout(
              isLoading: isLoading,
              filteredWorks: filteredWorks,
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
    required List<Work> filteredWorks,
    required ThemeData theme,
  }) {
    return MasterDetailLayout(
      masterPanel: _buildWorksList(
        isLoading: isLoading,
        filteredWorks: filteredWorks,
        theme: theme,
        isDesktop: true,
      ),
      detailPanel: selectedWork == null
          ? Center(
              child: Text(
                'Выберите смену из списка',
                style: theme.textTheme.bodyLarge,
              ),
            )
          : selectedWork!.id != null
              ? Column(
                  children: [
                    // Отступ сверху для мастер-детейл режима (когда AppBar скрыт в детейл-панели)
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
              : const Center(child: Text('Ошибка: ID смены не задан')),
    );
  }

  /// Строит мобильную версию интерфейса.
  Widget _buildMobileLayout({
    required bool isLoading,
    required List<Work> filteredWorks,
    required ThemeData theme,
  }) {
    return _buildWorksList(
      isLoading: isLoading,
      filteredWorks: filteredWorks,
      theme: theme,
      isDesktop: false,
    );
  }

  /// Строит список смен.
  Widget _buildWorksList({
    required bool isLoading,
    required List<Work> filteredWorks,
    required ThemeData theme,
    required bool isDesktop,
  }) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (filteredWorks.isEmpty) {
      return const Center(child: Text('Смены не найдены'));
    }

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: ListView.builder(
        controller: _scrollController,
        itemCount: filteredWorks.length,
        itemBuilder: (context, i) {
          final work = filteredWorks[i];
          final selected = isDesktop ? work.id == selectedWork?.id : false;

          // Получаем название объекта
          final objectName = ref
                  .watch(objectProvider)
                  .objects
                  .where((o) => o.id == work.objectId)
                  .map((o) => o.name)
                  .firstOrNull ??
              work.objectId;

          // Получаем статус работы с цветом
          final (statusText, statusColor) = _getWorkStatusInfo(work.status);

          return FutureBuilder<Profile?>(
              future: _getUserProfile(work.openedBy),
              builder: (context, snapshot) {
                final String createdBy = snapshot.hasData &&
                        snapshot.data?.shortName != null
                    ? snapshot.data!.shortName!
                    : 'ID: ${work.openedBy.length > 4 ? "${work.openedBy.substring(0, 4)}..." : work.openedBy}';

                return Card(
                  margin: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 0 : 16,
                    vertical: isDesktop ? 6 : 8,
                  ),
                  elevation: isDesktop ? 0 : 8,
                  shadowColor: isDesktop
                      ? null
                      : theme.colorScheme.shadow.withValues(alpha: 0.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                        ResponsiveUtils.borderRadiusMedium),
                    side: BorderSide(
                      color: selected
                          ? Colors.green
                          : theme.colorScheme.outline.withValues(alpha: 0.1),
                      width: selected ? 2 : 1,
                    ),
                  ),
                  child: InkWell(
                    onTap: () {
                      if (isDesktop) {
                        setState(() {
                          selectedWork = work;
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
                    borderRadius: BorderRadius.circular(
                        ResponsiveUtils.borderRadiusMedium),
                    child: Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            children: [
                              // Иконка смены вместо фото
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surface,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: theme.colorScheme.outlineVariant,
                                  ),
                                ),
                                child: Icon(
                                  work.status.toLowerCase() == 'closed'
                                      ? Icons.lock
                                      : Icons.lock_open,
                                  color: work.status.toLowerCase() == 'closed'
                                      ? Colors.red
                                      : Colors.green,
                                  size: 32,
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Информация о смене
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        // Цветовая точка статуса только в мобильном режиме
                                        if (!isDesktop) ...[
                                          Container(
                                            width: 8,
                                            height: 8,
                                            decoration: BoxDecoration(
                                              color: statusColor,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                        ],
                                        Text(
                                          _formatDate(work.date),
                                          style: theme.textTheme.titleSmall
                                              ?.copyWith(
                                                  fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      objectName,
                                      style: theme.textTheme.bodySmall,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Открыл: $createdBy',
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.secondary,
                                        fontSize: 12,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (isDesktop) ...[
                                AppBadge(
                                  text: statusText,
                                  color: statusColor,
                                ),
                                const SizedBox(height: 8),
                              ],
                              // Общая сумма и выработка
                              Consumer(
                                builder: (context, ref, _) {
                                  if (work.id == null) {
                                    return const SizedBox.shrink();
                                  }

                                  final itemsAsync =
                                      ref.watch(workItemsProvider(work.id!));
                                  final hoursAsync =
                                      ref.watch(workHoursProvider(work.id!));

                                  return itemsAsync.when(
                                    data: (items) => hoursAsync.when(
                                      data: (hours) {
                                        // Расчет общей суммы
                                        final totalAmount = items.fold<double>(
                                            0,
                                            (sum, item) =>
                                                sum + (item.total ?? 0));

                                        // Количество уникальных сотрудников
                                        final uniqueEmployees = hours
                                            .map((h) => h.employeeId)
                                            .toSet()
                                            .length;

                                        // Выработка на сотрудника
                                        final productivityPerEmployee =
                                            uniqueEmployees > 0
                                                ? totalAmount / uniqueEmployees
                                                : 0.0;

                                        final formatter =
                                            NumberFormat('#,##0', 'ru_RU');

                                        return Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              '${formatter.format(totalAmount)} ₽',
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                fontWeight: FontWeight.w600,
                                                color:
                                                    theme.colorScheme.primary,
                                              ),
                                            ),
                                            if (uniqueEmployees > 0) ...[
                                              const SizedBox(height: 2),
                                              Text(
                                                '${formatter.format(productivityPerEmployee)} ₽/чел',
                                                style: theme.textTheme.bodySmall
                                                    ?.copyWith(
                                                  fontSize: 10,
                                                  color: theme
                                                      .colorScheme.secondary,
                                                ),
                                              ),
                                            ],
                                          ],
                                        );
                                      },
                                      loading: () => const SizedBox.shrink(),
                                      error: (_, __) => const SizedBox.shrink(),
                                    ),
                                    loading: () => const SizedBox.shrink(),
                                    error: (_, __) => const SizedBox.shrink(),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              });
        },
      ),
    );
  }

  /// Форматирует дату в строку ДД.ММ.ГГГГ.
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  /// Возвращает текст и цвет статуса смены.
  (String, Color) _getWorkStatusInfo(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return ('Открыта', Colors.green);
      case 'closed':
        return ('Закрыта', Colors.red);
      default:
        return (status, Colors.blue);
    }
  }
}
