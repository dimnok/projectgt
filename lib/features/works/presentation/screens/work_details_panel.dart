import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import '../../domain/entities/work_item.dart';
import '../../domain/entities/work.dart';
import '../providers/work_items_provider.dart';
import '../providers/work_provider.dart';

import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/presentation/state/employee_state.dart'
    as employee_state;
import 'package:projectgt/domain/entities/estimate.dart';
import 'package:collection/collection.dart';
import 'dart:async';

import 'package:projectgt/core/utils/responsive_utils.dart';
import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/core/widgets/app_snackbar.dart';
import 'package:projectgt/core/widgets/gt_text_field.dart';

import 'package:projectgt/features/roles/application/permission_service.dart';
import 'package:projectgt/presentation/state/profile_state.dart';

import 'package:projectgt/core/widgets/gt_buttons.dart';
import 'package:projectgt/presentation/widgets/custom_sliding_segmented_control.dart';
import 'package:projectgt/features/works/presentation/widgets/work_detail_data_spacing.dart';
import 'package:projectgt/features/works/presentation/widgets/work_details_desktop_header_chrome.dart';
import 'tabs/work_data_tab.dart';
import 'tabs/work_hours_tab.dart';
import 'work_item_context_menu.dart';
import 'package:projectgt/features/contractors/presentation/state/contractor_state.dart';

/// Панель деталей смены с табами: работы, материалы, часы.
///
/// Используется как часть мастер-детейл интерфейса на десктопе и как отдельный экран на мобильных.
/// На десктопе верхняя зона табов и фильтров оформлена единым блоком [WorkDetailsDesktopHeaderChrome]
/// (без вложенной второй рамки у фильтров); скроллится только контент активной вкладки.
/// На планшете и узком экране без десктоп-хрома переключатель и фильтры закреплены над областью вкладки,
/// прокрутка только у содержимого вкладки (без общего скролла «шапка+табы»).
/// Позволяет просматривать и редактировать списки работ, материалов и часов в смене.
class WorkDetailsPanel extends ConsumerStatefulWidget {
  /// Идентификатор смены.
  final String workId;

  /// Контекст родительского экрана (для корректного отображения модальных окон).
  final BuildContext parentContext;

  /// Callback для уведомления об изменении активного таба.
  final Function(int tabIndex)? onTabChanged;

  /// Предварительно загруженная смена (опционально).
  /// Если передана, используется вместо поиска в провайдере.
  final Work? initialWork;

  /// Начальный индекс таба (по умолчанию 0).
  final int initialTabIndex;

  /// Создаёт панель деталей смены для [workId].
  const WorkDetailsPanel({
    super.key,
    required this.workId,
    required this.parentContext,
    this.onTabChanged,
    this.initialWork,
    this.initialTabIndex = 0,
  });

  @override
  ConsumerState<WorkDetailsPanel> createState() => _WorkDetailsPanelState();
}

/// Состояние для [WorkDetailsPanel].
///
/// Управляет табами, фильтрами, загрузкой и редактированием работ, сотрудников и материалов.
class _WorkDetailsPanelState extends ConsumerState<WorkDetailsPanel>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int? _editingItemIndex;
  late ScrollController _workItemsScrollController;
  final Map<String, TextEditingController> _quantityControllers = {};
  final Map<String, FocusNode> _focusNodes = {};
  ProviderSubscription? _workItemsSubscription;

  // Добавляем переменные для фильтрации работ
  String _searchQuery = '';
  String? _selectedModule;
  String? _selectedFloor;
  String? _selectedSystem;
  String? _selectedSubsystem;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );

    // Добавляем слушатель изменения таба
    _tabController.addListener(() {
      if (widget.onTabChanged != null) {
        widget.onTabChanged!(_tabController.index);
      }
    });

    _workItemsScrollController = ScrollController();

    // Слушаем изменения в работах для обновления фильтров (устранение двойной перерисовки)
    // Используем listenManual в initState, так как ref.listen предназначен только для build
    _workItemsSubscription = ref.listenManual<AsyncValue<List<WorkItem>>>(
      workItemsProvider(widget.workId),
      (previous, next) {
        next.whenData((items) {
          if (mounted) {
            setState(() {
              _updateFiltersAfterDataChange(items);
            });
          }
        });
      },
    );

    // Загружаем данные при инициализации
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(employee_state.employeeProvider.notifier).getEmployees();

      // Загружаем сметы для отображения номеров
      if (ref.read(estimateNotifierProvider).estimates.isEmpty) {
        ref.read(estimateNotifierProvider.notifier).loadEstimates();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _workItemsScrollController.dispose();
    _searchController.dispose();
    _workItemsSubscription?.close();
    // Освобождаем ресурсы контроллеров и фокусов
    for (final controller in _quantityControllers.values) {
      controller.dispose();
    }
    for (final focus in _focusNodes.values) {
      focus.dispose();
    }
    super.dispose();
  }

  Work? _getWork() {
    // Сначала используем переданную смену (если есть),
    // затем ищем в кэше провайдера (синхронно через watch)
    return widget.initialWork ?? ref.watch(workProvider(widget.workId));
  }

  // Получение или создание контроллера для поля ввода количества
  TextEditingController _getQuantityController(
    String itemId,
    num initialValue,
  ) {
    if (!_quantityControllers.containsKey(itemId)) {
      final initialText = initialValue % 1 == 0
          ? initialValue.toInt().toString()
          : initialValue.toString();
      _quantityControllers[itemId] = TextEditingController(text: initialText);
    }
    return _quantityControllers[itemId]!;
  }

  // Получение или создание фокус-ноды для поля ввода
  FocusNode _getFocusNode(String itemId) {
    if (!_focusNodes.containsKey(itemId)) {
      _focusNodes[itemId] = FocusNode();
    }
    return _focusNodes[itemId]!;
  }

  // Обновление количества работы
  Future<void> _updateWorkItemQuantity(WorkItem item, num? newQuantity) async {
    // Получаем смену для проверки статуса
    final workAsync =
        widget.initialWork ?? ref.read(workProvider(widget.workId));
    final isWorkClosed = workAsync?.status.toLowerCase() == 'closed';

    // Если смена закрыта, не разрешаем обновление
    if (isWorkClosed) {
      if (mounted) {
        AppSnackBar.show(
          context: context,
          message: 'Изменение количества невозможно, так как смена закрыта',
          kind: AppSnackBarKind.error,
        );
      }
      return;
    }

    if (newQuantity != null &&
        newQuantity > 0 &&
        newQuantity != item.quantity) {
      // Вычисляем total как double
      final double total = (item.price ?? 0) * newQuantity;

      final updatedItem = item.copyWith(
        quantity: newQuantity,
        total: total,
        updatedAt: DateTime.now(),
      );

      await ref
          .read(workItemsProvider(widget.workId).notifier)
          .update(updatedItem);
    }
  }

  // Добавляем вспомогательный метод для проверки состояния загрузки смет
  bool get _areEstimatesLoading =>
      ref.read(estimateNotifierProvider).isLoading ||
      ref.read(estimateNotifierProvider).estimates.isEmpty;

  // Получить уникальные значения для фильтров
  List<String> _getUniqueModules(List<WorkItem> items) {
    return items.map((item) => item.section).toSet().toList()..sort();
  }

  List<String> _getUniqueFloors(List<WorkItem> items) {
    return items.map((item) => item.floor).toSet().toList()..sort();
  }

  List<String> _getUniqueSystems(List<WorkItem> items) {
    return items.map((item) => item.system).toSet().toList()..sort();
  }

  List<String> _getUniqueSubsystems(List<WorkItem> items, {String? system}) {
    if (system == null) {
      return items.map((item) => item.subsystem).toSet().toList()..sort();
    }
    return items
        .where((item) => item.system == system)
        .map((item) => item.subsystem)
        .toSet()
        .toList()
      ..sort();
  }

  // Фильтрация работ
  List<WorkItem> _filterItems(List<WorkItem> items) {
    return items.where((item) {
      if (_searchQuery.isNotEmpty &&
          !item.name.toLowerCase().contains(_searchQuery.toLowerCase())) {
        return false;
      }
      if (_selectedModule != null && item.section != _selectedModule) {
        return false;
      }
      if (_selectedFloor != null && item.floor != _selectedFloor) {
        return false;
      }
      if (_selectedSystem != null && item.system != _selectedSystem) {
        return false;
      }
      if (_selectedSubsystem != null && item.subsystem != _selectedSubsystem) {
        return false;
      }
      return true;
    }).toList();
  }

  // Сброс всех фильтров
  void _resetFilters() {
    setState(() {
      _searchQuery = '';
      _searchController.clear();
      _selectedModule = null;
      _selectedFloor = null;
      _selectedSystem = null;
      _selectedSubsystem = null;
    });
  }

  void _updateFiltersAfterDataChange(List<WorkItem> items) {
    final uniqueModules = _getUniqueModules(items);
    final uniqueFloors = _getUniqueFloors(items);
    final uniqueSystems = _getUniqueSystems(items);
    final uniqueSubsystems = _selectedSystem != null
        ? _getUniqueSubsystems(items, system: _selectedSystem)
        : _getUniqueSubsystems(items);

    // Проверяем, существуют ли еще выбранные значения в новых списках
    // Если нет, сбрасываем их на null
    if (_selectedModule != null && !uniqueModules.contains(_selectedModule)) {
      _selectedModule = null;
    }

    if (_selectedFloor != null && !uniqueFloors.contains(_selectedFloor)) {
      _selectedFloor = null;
    }

    if (_selectedSystem != null && !uniqueSystems.contains(_selectedSystem)) {
      _selectedSystem = null;
      // Если система сброшена, то и подсистему тоже надо сбросить
      _selectedSubsystem = null;
    } else if (_selectedSubsystem != null &&
        !uniqueSubsystems.contains(_selectedSubsystem)) {
      _selectedSubsystem = null;
    }
  }

  /// Переключатель «Данные / Работы / Сотрудники» (без внешних полей).
  ///
  /// [forDesktopChrome] — компактный радиус и поля под единый хром панели (десктоп).
  /// [embeddedInMobileToolbar] — только узкий телефон: трек без внешней рамки, внутри общей карточки с фильтрами.
  Widget _buildSlidingSegmentControl(
    ThemeData theme, {
    bool forDesktopChrome = false,
    bool embeddedInMobileToolbar = false,
  }) {
    final scheme = theme.colorScheme;
    final phone = !forDesktopChrome && ResponsiveUtils.isMobile(context);
    IconData? tabIcon(IconData full) => phone ? null : full;

    final Color backgroundColor;
    final BoxBorder? border;
    final double segmentRadius;
    if (embeddedInMobileToolbar && phone) {
      backgroundColor = theme.brightness == Brightness.dark
          ? scheme.surface.withValues(alpha: 0.22)
          : scheme.surface.withValues(alpha: 0.62);
      border = null;
      segmentRadius = WorkDetailDataSpacing.mobileEmbeddedSegmentRadius;
    } else if (phone) {
      backgroundColor = scheme.surfaceContainerHighest.withValues(alpha: 0.45);
      border = Border.all(
        color: scheme.outline.withValues(alpha: 0.38),
        width: 1,
      );
      segmentRadius = WorkDetailDataSpacing.segmentControlTrackRadius;
    } else {
      backgroundColor = theme.brightness == Brightness.dark
          ? scheme.surfaceContainer
          : scheme.surfaceContainerHighest;
      border = Border.all(
        color: theme.brightness == Brightness.dark
            ? Colors.white.withValues(alpha: 0.1)
            : scheme.outline.withValues(alpha: 0.15),
        width: 1,
      );
      segmentRadius = WorkDetailDataSpacing.segmentControlTrackRadius;
    }

    final control = CustomSlidingSegmentedControl<int>(
      groupValue: _tabController.index,
      onValueChanged: (int value) {
        setState(() {
          _tabController.animateTo(value);
        });
      },
      backgroundColor: backgroundColor,
      thumbColor: scheme.surface,
      borderRadius: segmentRadius,
      border: border,
      padding: WorkDetailDataSpacing.segmentControlTrackPadding,
      children: {
        0: _buildTabItem(
          theme,
          0,
          tabIcon(CupertinoIcons.info),
          'Данные',
          desktopSpacious: forDesktopChrome,
        ),
        1: _buildTabItem(
          theme,
          1,
          tabIcon(CupertinoIcons.wrench),
          'Работы',
          desktopSpacious: forDesktopChrome,
        ),
        2: _buildTabItem(
          theme,
          2,
          tabIcon(CupertinoIcons.group),
          'Сотрудники',
          desktopSpacious: forDesktopChrome,
        ),
      },
    );

    if (phone) {
      return SizedBox(
        width: double.infinity,
        height: WorkDetailDataSpacing.mobileWorkTabSegmentBarHeight,
        child: control,
      );
    }
    return control;
  }

  /// Единая мобильная карточка: сегмент вкладок + фильтры списка работ (таб «Работы»).
  Widget _buildMobileUnifiedToolbar(ThemeData theme) {
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final fill = isDark
        ? scheme.surfaceContainer
        : scheme.surfaceContainerHighest;
    final outline = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : scheme.outline.withValues(alpha: 0.15);
    const r = WorkDetailDataSpacing.mobileUnifiedToolbarRadius;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: WorkDetailDataSpacing.mobileScrollHorizontal,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: fill,
          border: Border.all(color: outline, width: 1),
          borderRadius: BorderRadius.circular(r),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(r),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
                child: _buildSlidingSegmentControl(
                  theme,
                  embeddedInMobileToolbar: true,
                ),
              ),
              Consumer(
                builder: (context, ref, _) {
                  if (_tabController.index != 1) {
                    return const SizedBox(height: 10);
                  }
                  final itemsAsync = ref.watch(
                    workItemsProvider(widget.workId),
                  );
                  return itemsAsync.when(
                    data: (items) {
                      if (items.isEmpty) {
                        return const SizedBox(height: 10);
                      }
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(10, 6, 10, 0),
                            child: Divider(
                              height: 1,
                              thickness: 1,
                              color: scheme.outlineVariant.withValues(
                                alpha: 0.35,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                            child: _buildFiltersBlock(
                              context,
                              theme,
                              items,
                              embedInMobileToolbar: true,
                            ),
                          ),
                        ],
                      );
                    },
                    loading: () => const SizedBox(height: 8),
                    error: (_, __) => const SizedBox(height: 8),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Разделитель и фильтры внутри [WorkDetailsDesktopHeaderChrome] (таб «Работы»).
  Widget _buildDesktopHeaderBelowSegment(ThemeData theme) {
    if (_tabController.index != 1) return const SizedBox.shrink();
    return Consumer(
      builder: (context, ref, _) {
        final itemsAsync = ref.watch(workItemsProvider(widget.workId));
        return itemsAsync.when(
          data: (items) {
            if (items.isEmpty) return const SizedBox.shrink();
            final scheme = theme.colorScheme;
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: WorkDetailDataSpacing.desktopHeaderDividerInset,
                  ),
                  child: Divider(
                    height: 1,
                    thickness: 1,
                    color: scheme.outlineVariant.withValues(alpha: 0.35),
                  ),
                ),
                Padding(
                  padding: WorkDetailDataSpacing.desktopHeaderFiltersInner,
                  child: _buildFiltersBlock(
                    context,
                    theme,
                    items,
                    embedInDesktopChrome: true,
                  ),
                ),
              ],
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        );
      },
    );
  }

  /// Фильтры списка работ под табами (только активный таб «Работы», только планшет / не телефон).
  Widget _buildFiltersBelowTabsIfWorksTab(ThemeData theme) {
    if (_tabController.index != 1) return const SizedBox.shrink();
    return Consumer(
      builder: (context, ref, _) {
        final itemsAsync = ref.watch(workItemsProvider(widget.workId));
        return itemsAsync.when(
          data: (items) {
            if (items.isEmpty) return const SizedBox.shrink();
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                _buildFiltersBlock(context, theme, items),
              ],
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = ResponsiveUtils.isDesktop(context);

    // Используем переданную смену или ищем в провайдере
    final workAsync =
        widget.initialWork ?? ref.watch(workProvider(widget.workId));

    if (workAsync == null) {
      // Если данных нет совсем, показываем лоадер
      // Но это редкий кейс, так как мы передаем ID, который должен быть валидным
      return const Center(child: CupertinoActivityIndicator());
    }

    // Получаем информацию об объекте
    final objects = ref.watch(objectProvider).objects;
    final object = objects.firstWhereOrNull((o) => o.id == workAsync.objectId);
    final objectDisplay = object != null ? object.name : workAsync.objectId;

    final tabContent = _getTabContent(
      _tabController.index,
      workAsync,
      objectDisplay,
    );

    // Десктоп: закреплённый хром «табы + фильтры», скролл только у контента вкладки.
    if (isDesktop) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          WorkDetailsDesktopHeaderChrome(
            segmentBar: _buildSlidingSegmentControl(
              theme,
              forDesktopChrome: true,
            ),
            belowSegment: _buildDesktopHeaderBelowSegment(theme),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 16),
              child: tabContent,
            ),
          ),
        ],
      );
    }

    // Узкий телефон: одна карточка «вкладки + фильтры»; планшет — сегмент и фильтры раздельно.
    final isPhone = ResponsiveUtils.isMobile(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: isPhone ? WorkDetailDataSpacing.mobileSegmentTopGap : 6,
        ),
        if (isPhone)
          _buildMobileUnifiedToolbar(theme)
        else ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildSlidingSegmentControl(theme),
          ),
          _buildFiltersBelowTabsIfWorksTab(theme),
        ],
        const SizedBox(height: 8),
        Expanded(child: tabContent),
      ],
    );
  }

  Widget _buildTabItem(
    ThemeData theme,
    int index,
    IconData? icon,
    String label, {
    bool desktopSpacious = false,
  }) {
    final isSelected = _tabController.index == index;
    final scheme = theme.colorScheme;
    final textOnly = icon == null && !desktopSpacious;

    final EdgeInsets segmentPadding;
    if (desktopSpacious) {
      segmentPadding = WorkDetailDataSpacing.desktopSegmentItemPadding;
    } else if (textOnly) {
      segmentPadding = WorkDetailDataSpacing.mobileWorkTabSegmentTextPadding;
    } else {
      segmentPadding = WorkDetailDataSpacing.segmentItemPaddingOf(context);
    }

    if (textOnly) {
      final base = theme.textTheme.labelLarge ?? theme.textTheme.bodyMedium!;
      return ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 0),
        child: Padding(
          padding: segmentPadding,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: base.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 12.5,
              height: 1.1,
              color: isSelected
                  ? scheme.onSurface
                  : scheme.onSurface.withValues(alpha: 0.52),
            ),
          ),
        ),
      );
    }

    // Используем ConstrainedBox вместо фиксированного SizedBox, чтобы избежать переполнения
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 0),
      child: Padding(
        padding: segmentPadding,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon!,
              size: desktopSpacious ? 19 : 18,
              color: isSelected ? scheme.primary : scheme.onSurfaceVariant,
            ),
            SizedBox(
              width: desktopSpacious
                  ? WorkDetailDataSpacing.segmentIconGap
                  : WorkDetailDataSpacing.segmentIconGapOf(context),
            ),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: desktopSpacious ? 14 : 13,
                  color: isSelected ? scheme.primary : scheme.onSurfaceVariant,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Возвращает контент выбранного таба без свайпов
  Widget _getTabContent(int tabIndex, Work workAsync, String objectDisplay) {
    switch (tabIndex) {
      case 0:
        return WorkDataTab(work: workAsync, objectDisplay: objectDisplay);
      case 1:
        return _buildWorkItemsTab();
      case 2:
        return WorkHoursTab(
          workId: widget.workId,
          parentContext: widget.parentContext,
          initialWork: workAsync,
        );
      default:
        return WorkDataTab(work: workAsync, objectDisplay: objectDisplay);
    }
  }

  Widget _buildWorkItemsTab() {
    // Получаем смену для проверки статуса
    final workAsync = _getWork();
    final isWorkClosed = workAsync?.status.toLowerCase() == 'closed';

    // Проверка прав
    final permissionService = ref.watch(permissionServiceProvider);
    final canUpdate = permissionService.can('works', 'update');

    // Проверка на владельца компании
    final currentProfile = ref.watch(currentUserProfileProvider).profile;
    final isCompanyOwner = currentProfile?.systemRole == 'owner';

    // Проверка на владельца смены
    final isOwner =
        currentProfile != null && workAsync?.openedBy == currentProfile.id;

    // Разрешаем редактировать, если ((Я владелец смены И смена открыта) ИЛИ (Я Владелец компании)) И есть глобальное право update
    final bool canModify =
        ((isOwner && !isWorkClosed) || isCompanyOwner) && canUpdate;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        final scope = FocusScope.of(context);
        if (!scope.hasPrimaryFocus) {
          scope.unfocus();
        }
      },
      child: Stack(
        children: [
          Consumer(
            builder: (context, ref, _) {
              final itemsAsync = ref.watch(workItemsProvider(widget.workId));
              return itemsAsync.when(
                data: (items) {
                  if (items.isEmpty) {
                    return const Center(
                      child: Text(
                        'Нет работ. Добавьте новую работу, нажав на "+"',
                      ),
                    );
                  }

                  final filteredItems = _filterItems(items);

                  // Если нет результатов фильтрации
                  if (filteredItems.isEmpty &&
                      (_searchQuery.isNotEmpty ||
                          _selectedModule != null ||
                          _selectedFloor != null ||
                          _selectedSystem != null ||
                          _selectedSubsystem != null)) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            CupertinoIcons.search,
                            size: 48,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                          const SizedBox(height: 16),
                          const Text('Нет работ, соответствующих фильтрам'),
                          const SizedBox(height: 8),
                          GTTextButton(
                            onPressed: _resetFilters,
                            icon: CupertinoIcons.slider_horizontal_3,
                            text: 'Сбросить фильтры',
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    controller: _workItemsScrollController,
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: ResponsiveUtils.isMobile(context)
                        ? WorkDetailDataSpacing.mobileTabListPadding
                        : const EdgeInsets.all(16),
                    itemCount: filteredItems.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final item = filteredItems[i];
                      final contractors = ref
                          .watch(contractorNotifierProvider)
                          .contractors;
                      final contractorLabel = item.contractorId == null
                          ? null
                          : contractors
                                .firstWhereOrNull(
                                  (c) => c.id == item.contractorId,
                                )
                                ?.shortName;

                      // Отображаем номер позиции из сметы, если сметы загружены
                      Widget numberWidget;
                      if (_areEstimatesLoading) {
                        // Если сметы загружаются или еще не загружены, показываем индикатор
                        numberWidget = Container(
                          width: 45,
                          alignment: Alignment.center,
                          child: const SizedBox(
                            width: 18,
                            height: 18,
                            child: CupertinoActivityIndicator(radius: 9),
                          ),
                        );
                      } else {
                        // Если сметы загружены, ищем номер позиции
                        final Estimate? estimate = ref
                            .watch(estimateNotifierProvider)
                            .estimates
                            .firstWhereOrNull((e) => e.id == item.estimateId);
                        final number = estimate?.number ?? '-';

                        numberWidget = Container(
                          width: 45,
                          alignment: Alignment.center,
                          child: Text(
                            number,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            softWrap: false,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      Theme.of(context).brightness ==
                                          Brightness.light
                                      ? Colors.lightBlue.shade700
                                      : Colors.lightBlue.shade300,
                                ),
                          ),
                        );
                      }

                      // Контроллер и фокус для поля ввода количества
                      final controller = _getQuantityController(
                        item.id,
                        item.quantity,
                      );
                      final focusNode = _getFocusNode(item.id);

                      final isEditing = _editingItemIndex == i;

                      // Проверяем, находимся ли мы в мобильном режиме
                      final isMobile = !ResponsiveUtils.isDesktop(context);

                      // Обертываем карточку в Dismissible для мобильного свайпа
                      Widget cardWidget = InkWell(
                        onLongPress: isCompanyOwner
                            ? () {
                                WorkItemContextMenu.show(
                                  context: context,
                                  item: item,
                                  workId: widget.workId,
                                  parentContext: widget.parentContext,
                                  ref: ref,
                                  initialObjectId: workAsync?.objectId,
                                  onDeleteComplete: () {
                                    // Ресурс (контроллеры) освобождаются в _deleteWorkItem или _confirmDeleteItem.
                                    // Обновление фильтров теперь обрабатывается через ref.listen в build.
                                  },
                                );
                              }
                            : null,
                        child: Card(
                          margin: EdgeInsets.zero,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(
                              color: Theme.of(
                                context,
                              ).colorScheme.outline.withValues(alpha: 30),
                              width: 1,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 16,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    numberWidget,
                                    const SizedBox(width: 4),
                                    Expanded(
                                      flex: 3,
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  item.name,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodyMedium
                                                      ?.copyWith(
                                                        fontSize: isMobile
                                                            ? 12
                                                            : 14,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color:
                                                            Theme.of(
                                                                  context,
                                                                ).brightness ==
                                                                Brightness.light
                                                            ? Colors
                                                                  .lightBlue
                                                                  .shade700
                                                            : Colors
                                                                  .lightBlue
                                                                  .shade300,
                                                      ),
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          // Область количества и единицы измерения
                                          GestureDetector(
                                            onTap: canModify
                                                ? () {
                                                    setState(() {
                                                      // Переключаем режим редактирования
                                                      _editingItemIndex =
                                                          isEditing ? null : i;

                                                      if (_editingItemIndex ==
                                                          i) {
                                                        // Фокусируемся на поле ввода с небольшой задержкой
                                                        Timer(
                                                          const Duration(
                                                            milliseconds: 50,
                                                          ),
                                                          () {
                                                            focusNode
                                                                .requestFocus();
                                                            WidgetsBinding
                                                                .instance
                                                                .addPostFrameCallback((
                                                                  _,
                                                                ) {
                                                                  final ctx =
                                                                      focusNode
                                                                          .context;
                                                                  if (ctx !=
                                                                      null) {
                                                                    Scrollable.ensureVisible(
                                                                      ctx,
                                                                      alignment:
                                                                          0.3,
                                                                      duration: const Duration(
                                                                        milliseconds:
                                                                            200,
                                                                      ),
                                                                    );
                                                                  }
                                                                });
                                                          },
                                                        );
                                                      } else {
                                                        // Сохраняем изменения при выходе из режима редактирования
                                                        final raw = controller
                                                            .text
                                                            .replaceAll(
                                                              ',',
                                                              '.',
                                                            );
                                                        final newValue =
                                                            num.tryParse(raw);
                                                        _updateWorkItemQuantity(
                                                          item,
                                                          newValue,
                                                        );
                                                      }
                                                    });
                                                  }
                                                : null,
                                            child: isEditing
                                                ? SizedBox(
                                                    width: 60,
                                                    height: 30,
                                                    child: Focus(
                                                      onFocusChange: (hasFocus) {
                                                        if (!hasFocus) {
                                                          final normalized =
                                                              controller.text
                                                                  .replaceAll(
                                                                    ',',
                                                                    '.',
                                                                  );
                                                          final newValue =
                                                              num.tryParse(
                                                                normalized,
                                                              );
                                                          setState(() {
                                                            _editingItemIndex =
                                                                null;
                                                          });
                                                          _updateWorkItemQuantity(
                                                            item,
                                                            newValue,
                                                          );
                                                        }
                                                      },
                                                      child: GTTextField(
                                                        controller: controller,
                                                        keyboardType:
                                                            const TextInputType.numberWithOptions(
                                                              decimal: true,
                                                            ),
                                                        inputFormatters: [
                                                          FilteringTextInputFormatter.allow(
                                                            // ignore: deprecated_member_use
                                                            RegExp(r'[0-9.,]'),
                                                          ),
                                                        ],
                                                        textAlign:
                                                            TextAlign.center,
                                                        contentPadding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 4,
                                                              vertical: 8,
                                                            ),
                                                        borderRadius: 4,
                                                        onSubmitted: (value) {
                                                          setState(() {
                                                            _editingItemIndex =
                                                                null;
                                                            final normalized =
                                                                value
                                                                    .replaceAll(
                                                                      ',',
                                                                      '.',
                                                                    );
                                                            final newValue =
                                                                num.tryParse(
                                                                  normalized,
                                                                );
                                                            _updateWorkItemQuantity(
                                                              item,
                                                              newValue,
                                                            );
                                                          });
                                                        },
                                                      ),
                                                    ),
                                                  )
                                                : Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Text(
                                                        '× ${item.quantity % 1 == 0 ? item.quantity.toInt().toString() : item.quantity.toString()}',
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .bodyMedium
                                                            ?.copyWith(
                                                              fontSize: isMobile
                                                                  ? 12
                                                                  : 14,
                                                              color:
                                                                  Theme.of(
                                                                        context,
                                                                      ).brightness ==
                                                                      Brightness
                                                                          .light
                                                                  ? Colors
                                                                        .lightBlue
                                                                        .shade700
                                                                  : Colors
                                                                        .lightBlue
                                                                        .shade300,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                            ),
                                                      ),
                                                      const SizedBox(width: 2),
                                                      Text(
                                                        item.unit,
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .bodySmall
                                                            ?.copyWith(
                                                              color:
                                                                  Theme.of(
                                                                        context,
                                                                      )
                                                                      .colorScheme
                                                                      .outline,
                                                            ),
                                                      ),
                                                    ],
                                                  ),
                                          ),
                                          // Кнопка удаления работы - показываем только на десктопе
                                          if (!isWorkClosed && !isMobile) ...[
                                            const SizedBox(width: 8),
                                            Material(
                                              color: Colors.transparent,
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              child: InkWell(
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                                onTap: () => _confirmDeleteItem(
                                                  context,
                                                  ref,
                                                  item,
                                                ),
                                                child: MouseRegion(
                                                  cursor:
                                                      SystemMouseCursors.click,
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.all(6),
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            20,
                                                          ),
                                                    ),
                                                    child: Icon(
                                                      CupertinoIcons.delete,
                                                      size: 20,
                                                      color: Theme.of(
                                                        context,
                                                      ).colorScheme.error,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                // Разные отображения для мобильной и десктопной версии
                                if (isMobile)
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Компактное отображение: модуль/этаж и система/подсистема
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              '${item.section.isNotEmpty ? item.section : '-'}/${item.floor.isNotEmpty ? item.floor : '-'}',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.onSurface,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Expanded(
                                            child: Text(
                                              '${item.system.isNotEmpty ? item.system : '-'}/${item.subsystem.isNotEmpty ? item.subsystem : '-'}',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.onSurface,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                              textAlign: TextAlign.end,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      // Цена, подрядчик (по центру), сумма
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Expanded(
                                            child: Align(
                                              alignment: Alignment.centerLeft,
                                              child: Text.rich(
                                                TextSpan(
                                                  children: [
                                                    const TextSpan(
                                                      text: 'Цена: ',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                    TextSpan(
                                                      text: formatCurrency(
                                                        item.price ?? 0,
                                                      ),
                                                      style: TextStyle(
                                                        color: Theme.of(
                                                          context,
                                                        ).colorScheme.primary,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall
                                                    ?.copyWith(fontSize: 10),
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            child:
                                                (contractorLabel != null &&
                                                    contractorLabel.isNotEmpty)
                                                ? Text(
                                                    contractorLabel,
                                                    textAlign: TextAlign.center,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      fontSize: 8,
                                                      color: Theme.of(
                                                        context,
                                                      ).colorScheme.error,
                                                    ),
                                                  )
                                                : const SizedBox.shrink(),
                                          ),
                                          Expanded(
                                            child: Align(
                                              alignment: Alignment.centerRight,
                                              child: Text.rich(
                                                TextSpan(
                                                  children: [
                                                    const TextSpan(
                                                      text: 'Сумма: ',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                    TextSpan(
                                                      text: formatCurrency(
                                                        item.total ?? 0,
                                                      ),
                                                      style: TextStyle(
                                                        color: Theme.of(
                                                          context,
                                                        ).colorScheme.primary,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall
                                                    ?.copyWith(fontSize: 10),
                                                textAlign: TextAlign.end,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  )
                                else
                                  Row(
                                    children: [
                                      _miniInfo('Модуль', item.section),
                                      _miniInfo('Этаж', item.floor),
                                      _miniInfo('Система', item.system),
                                      _miniInfo('Подсистема', item.subsystem),
                                      Expanded(
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Expanded(
                                              child: Align(
                                                alignment: Alignment.centerLeft,
                                                child: Text.rich(
                                                  TextSpan(
                                                    children: [
                                                      const TextSpan(
                                                        text: 'Цена: ',
                                                        style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                      ),
                                                      TextSpan(
                                                        text: formatCurrency(
                                                          item.price ?? 0,
                                                        ),
                                                        style: TextStyle(
                                                          color: Theme.of(
                                                            context,
                                                          ).colorScheme.primary,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall
                                                      ?.copyWith(fontSize: 12),
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child:
                                                  (contractorLabel != null &&
                                                      contractorLabel
                                                          .isNotEmpty)
                                                  ? Text(
                                                      contractorLabel,
                                                      textAlign:
                                                          TextAlign.center,
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        color: Theme.of(
                                                          context,
                                                        ).colorScheme.error,
                                                      ),
                                                    )
                                                  : const SizedBox.shrink(),
                                            ),
                                            Expanded(
                                              child: Align(
                                                alignment:
                                                    Alignment.centerRight,
                                                child: Text.rich(
                                                  TextSpan(
                                                    children: [
                                                      const TextSpan(
                                                        text: 'Сумма: ',
                                                        style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                      ),
                                                      TextSpan(
                                                        text: formatCurrency(
                                                          item.total ?? 0,
                                                        ),
                                                        style: TextStyle(
                                                          color: Theme.of(
                                                            context,
                                                          ).colorScheme.primary,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall
                                                      ?.copyWith(fontSize: 12),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                      // Возвращаем Dismissible для мобильных или обычную карточку для десктопа
                      if (isMobile && canModify) {
                        return Dismissible(
                          key: Key(item.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.error,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Icon(
                                  CupertinoIcons.delete,
                                  color: Theme.of(context).colorScheme.onError,
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Удалить',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onError,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          confirmDismiss: (direction) async {
                            return await _showDeleteConfirmationDialog(
                              context,
                              item,
                            );
                          },
                          onDismissed: (direction) {
                            _deleteWorkItem(ref, item);
                          },
                          child: cardWidget,
                        );
                      } else {
                        return cardWidget;
                      }
                    },
                  );
                },
                loading: () =>
                    const Center(child: CupertinoActivityIndicator()),
                error: (e, st) => Center(child: Text('Ошибка: $e')),
              );
            },
          ),
          // Кнопка добавления работы - только для открытой смены (для закрытой достаточно таба с долгим табом)
          if (!isWorkClosed && canModify && _editingItemIndex == null)
            Positioned(
              right: 16,
              bottom: 16 + MediaQuery.viewPaddingOf(context).bottom,
              child: FloatingActionButton(
                heroTag: null,
                mini: true,
                onPressed: () {
                  WorkItemContextMenu.openNewWorkItemForm(
                    context: widget.parentContext,
                    workId: widget.workId,
                    initialObjectId: workAsync?.objectId,
                  );
                },
                child: const Icon(CupertinoIcons.add),
              ),
            ),
        ],
      ),
    );
  }

  /// Показывает диалог подтверждения удаления для свайпа (работы)
  Future<bool?> _showDeleteConfirmationDialog(
    BuildContext context,
    WorkItem item,
  ) async {
    return await showCupertinoModalPopup<bool>(
      context: context,
      builder: (BuildContext context) => CupertinoAlertDialog(
        title: const Text('Подтверждение'),
        content: Text('Удалить работу "${item.name}"?'),
        actions: <CupertinoDialogAction>[
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  /// Выполняет удаление работы после подтверждения свайпа
  void _deleteWorkItem(WidgetRef ref, WorkItem item) async {
    // Очистка ресурсов при удалении (Critical)
    _quantityControllers[item.id]?.dispose();
    _quantityControllers.remove(item.id);
    _focusNodes[item.id]?.dispose();
    _focusNodes.remove(item.id);

    await ref.read(workItemsProvider(widget.workId).notifier).delete(item.id);
  }

  void _confirmDeleteItem(BuildContext context, WidgetRef ref, WorkItem item) {
    // Получаем смену для проверки статуса
    final workAsync =
        widget.initialWork ?? ref.read(workProvider(widget.workId));
    final isWorkClosed = workAsync?.status.toLowerCase() == 'closed';

    // Если смена закрыта, не разрешаем удаление
    if (isWorkClosed) {
      AppSnackBar.show(
        context: context,
        message: 'Удаление работ невозможно, так как смена закрыта',
        kind: AppSnackBarKind.error,
      );
      return;
    }

    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => CupertinoAlertDialog(
        title: const Text('Подтверждение'),
        content: Text('Вы действительно хотите удалить работу "${item.name}"?'),
        actions: <CupertinoDialogAction>[
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Отмена'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              final navigator = Navigator.of(context);

              // Очистка ресурсов при удалении (Critical)
              _quantityControllers[item.id]?.dispose();
              _quantityControllers.remove(item.id);
              _focusNodes[item.id]?.dispose();
              _focusNodes.remove(item.id);

              await ref
                  .read(workItemsProvider(widget.workId).notifier)
                  .delete(item.id);

              if (mounted) {
                navigator.pop();
              }
            },
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown(
    BuildContext context,
    String label,
    String? value,
    List<String> items,
    ValueChanged<String?> onChanged, {
    double width = 150,
    double height = 36,
  }) {
    final theme = Theme.of(context);
    final isSelected = value != null;

    return SizedBox(
      width: width,
      height: height,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.1)
              : theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.4,
                ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary.withValues(alpha: 0.2)
                : Colors.transparent,
            width: 1,
          ),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            isDense: true,
            hint: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            icon: Icon(
              CupertinoIcons.chevron_down,
              size: 14,
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
            borderRadius: BorderRadius.circular(20),
            onChanged: onChanged,
            items: [
              DropdownMenuItem<String>(
                value: null,
                child: Text(
                  'Все ${label.toLowerCase()}',
                  style: theme.textTheme.bodySmall?.copyWith(fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              ...items.toSet().map((String val) {
                return DropdownMenuItem<String>(
                  value: val,
                  child: Text(
                    val,
                    style: theme.textTheme.bodySmall?.copyWith(fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFiltersBlock(
    BuildContext context,
    ThemeData theme,
    List<WorkItem> items, {
    bool embedInDesktopChrome = false,
    bool embedInMobileToolbar = false,
  }) {
    assert(
      !(embedInDesktopChrome && embedInMobileToolbar),
      'Взаимоисключающие режимы встраивания фильтров',
    );

    final uniqueModules = _getUniqueModules(items);
    final uniqueFloors = _getUniqueFloors(items);
    final uniqueSystems = _getUniqueSystems(items);
    final uniqueSubsystems = _selectedSystem != null
        ? _getUniqueSubsystems(items, system: _selectedSystem)
        : _getUniqueSubsystems(items);

    final isMobile = ResponsiveUtils.isMobile(context);

    final filterChipHeight = embedInDesktopChrome ? 40.0 : 36.0;
    final filterChipWidth = embedInDesktopChrome ? 172.0 : 150.0;
    final gap = embedInDesktopChrome ? 10.0 : 8.0;
    final searchWidth = embedInDesktopChrome
        ? 480.0
        : (isMobile ? double.infinity : 450.0);

    final searchField = SizedBox(
      width: searchWidth,
      height: filterChipHeight,
      child: GTTextField(
        controller: _searchController,
        hintText: 'Поиск',
        prefixIcon: CupertinoIcons.search,
        borderRadius: 20,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: embedInDesktopChrome ? 10 : 8,
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
      ),
    );

    final filters = [
      _buildFilterDropdown(
        context,
        'Модуль',
        _selectedModule,
        uniqueModules,
        (val) => setState(() => _selectedModule = val),
        width: filterChipWidth,
        height: filterChipHeight,
      ),
      SizedBox(width: gap),
      _buildFilterDropdown(
        context,
        'Этаж',
        _selectedFloor,
        uniqueFloors,
        (val) => setState(() => _selectedFloor = val),
        width: filterChipWidth,
        height: filterChipHeight,
      ),
      SizedBox(width: gap),
      _buildFilterDropdown(
        context,
        'Система',
        _selectedSystem,
        uniqueSystems,
        (val) => setState(() {
          _selectedSystem = val;
          _selectedSubsystem = null;
        }),
        width: filterChipWidth,
        height: filterChipHeight,
      ),
      SizedBox(width: gap),
      _buildFilterDropdown(
        context,
        'Подсистема',
        _selectedSubsystem,
        uniqueSubsystems,
        (val) => setState(() => _selectedSubsystem = val),
        width: filterChipWidth,
        height: filterChipHeight,
      ),
      SizedBox(width: gap),
      if (_searchQuery.isNotEmpty ||
          _selectedModule != null ||
          _selectedFloor != null ||
          _selectedSystem != null ||
          _selectedSubsystem != null)
        SizedBox(
          height: filterChipHeight,
          width: filterChipHeight,
          child: IconButton.filledTonal(
            padding: EdgeInsets.zero,
            onPressed: _resetFilters,
            icon: const Icon(CupertinoIcons.slider_horizontal_3, size: 18),
            style: IconButton.styleFrom(
              backgroundColor: theme.colorScheme.errorContainer.withValues(
                alpha: 0.5,
              ),
              foregroundColor: theme.colorScheme.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            tooltip: 'Сбросить',
          ),
        ),
    ];

    if (embedInMobileToolbar) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          searchField,
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: filters),
          ),
        ],
      );
    }

    if (embedInDesktopChrome) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [searchField, const SizedBox(width: 16), ...filters],
        ),
      );
    }

    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.isMobile(context)
            ? WorkDetailDataSpacing.mobileScrollHorizontal
            : 16,
      ),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? theme.colorScheme.surfaceContainer
            : theme.colorScheme.surfaceContainerHighest,
        border: Border.all(
          color: theme.brightness == Brightness.dark
              ? Colors.white.withValues(alpha: 0.1)
              : theme.colorScheme.outline.withValues(alpha: 0.15),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: isMobile
          ? Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  searchField,
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(children: filters),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    searchField,
                    const SizedBox(width: 16),
                    ...filters,
                  ],
                ),
              ),
            ),
    );
  }

  Widget _miniInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.outline,
              fontSize: 12,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
