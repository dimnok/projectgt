import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import '../../domain/entities/work_item.dart';
import '../../domain/entities/work.dart';
import '../providers/work_items_provider.dart';
import '../providers/work_provider.dart';
import 'work_item_form_improved.dart';
// import 'package:projectgt/core/utils/modal_utils.dart';

import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/presentation/state/employee_state.dart'
    as employee_state;
import 'package:intl/intl.dart';
import 'package:projectgt/domain/entities/estimate.dart';
import 'package:collection/collection.dart';
import 'dart:async';

import 'package:projectgt/core/utils/responsive_utils.dart';
import 'package:projectgt/core/utils/snackbar_utils.dart';

import 'package:projectgt/features/roles/application/permission_service.dart';
import 'package:projectgt/features/roles/presentation/providers/roles_provider.dart';
import 'package:projectgt/presentation/state/profile_state.dart';

import 'package:projectgt/presentation/widgets/custom_sliding_segmented_control.dart';
import 'tabs/work_data_tab.dart';
import 'tabs/work_hours_tab.dart';
import 'work_item_context_menu.dart';

/// Панель деталей смены с табами: работы, материалы, часы.
///
/// Используется как часть мастер-детейл интерфейса на десктопе и как отдельный экран на мобильных.
/// Позволяет просматривать и редактировать списки работ, материалов и часов в смене.
class WorkDetailsPanel extends ConsumerStatefulWidget {
  /// Идентификатор смены.
  final String workId;

  /// Контекст родительского экрана (для корректного отображения модальных окон).
  final BuildContext parentContext;

  /// Callback для уведомления об изменении активного таба.
  final Function(int tabIndex)? onTabChanged;

  /// Создаёт панель деталей смены для [workId].
  const WorkDetailsPanel({
    super.key,
    required this.workId,
    required this.parentContext,
    this.onTabChanged,
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
    _tabController = TabController(length: 3, vsync: this);

    // Добавляем слушатель изменения таба
    _tabController.addListener(() {
      if (widget.onTabChanged != null) {
        widget.onTabChanged!(_tabController.index);
      }
    });

    _workItemsScrollController = ScrollController();

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
    // Освобождаем ресурсы контроллеров и фокусов
    for (final controller in _quantityControllers.values) {
      controller.dispose();
    }
    for (final focus in _focusNodes.values) {
      focus.dispose();
    }
    super.dispose();
  }

  // Получение или создание контроллера для поля ввода количества
  TextEditingController _getQuantityController(
      String itemId, num initialValue) {
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
    final workAsync = ref.read(workProvider(widget.workId));
    final isWorkClosed = workAsync?.status.toLowerCase() == 'closed';

    // Если смена закрыта, не разрешаем обновление
    if (isWorkClosed) {
      if (mounted) {
        SnackBarUtils.showError(
            context, 'Изменение количества невозможно, так как смена закрыта');
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
          .updateOptimistic(updatedItem);
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Используем watch только если данные еще не загружены
    // Это предотвращает мерцание при переходе, если данные уже есть в кэше провайдера
    final workAsync = ref.watch(workProvider(widget.workId));

    if (workAsync == null) {
      // Если данных нет совсем, показываем лоадер
      // Но это редкий кейс, так как мы передаем ID, который должен быть валидным
      return const Center(child: CupertinoActivityIndicator());
    }

    // Получаем информацию об объекте
    final objects = ref.watch(objectProvider).objects;
    final object = objects.where((o) => o.id == workAsync.objectId).isNotEmpty
        ? objects.firstWhere((o) => o.id == workAsync.objectId)
        : null;
    final objectDisplay = object != null ? object.name : workAsync.objectId;

    return Column(
      children: [
        // Отступ сверху как в списке смен
        SizedBox(
          height: ResponsiveUtils.isMobile(context) ? 8 : 6,
        ),
        // Блок с табами
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: CustomSlidingSegmentedControl<int>(
            groupValue: _tabController.index,
            onValueChanged: (int value) {
              setState(() {
                _tabController.animateTo(value);
              });
            },
            backgroundColor: theme.brightness == Brightness.dark
                ? const Color(0xFF3A3A3C)
                : theme.colorScheme.surfaceContainerHighest,
            thumbColor: theme.colorScheme.surface,
            borderRadius: 20,
            border: Border.all(
              color: theme.brightness == Brightness.dark
                  ? Colors.white.withValues(alpha: 0.1)
                  : theme.colorScheme.outline.withValues(alpha: 0.15),
              width: 1,
            ),
            padding: const EdgeInsets.all(4),
            children: {
              0: _buildTabItem(theme, 0, CupertinoIcons.info, 'Данные', 0),
              1: _buildTabItem(theme, 1, CupertinoIcons.wrench, 'Работы', 0),
              2: _buildTabItem(theme, 2, CupertinoIcons.group, 'Сотрудники', 0),
            },
          ),
        ),

        // Фильтры (только для таба Работы)
        if (_tabController.index == 1)
          Consumer(builder: (context, ref, _) {
            final itemsAsync = ref.watch(workItemsProvider(widget.workId));
            return itemsAsync.when(
              data: (items) {
                if (items.isEmpty) return const SizedBox.shrink();
                return Column(
                  children: [
                    const SizedBox(height: 8),
                    _buildFiltersBlock(context, theme, items),
                  ],
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            );
          }),

        // Контент табов
        Expanded(
          child: _getTabContent(_tabController.index, workAsync, objectDisplay),
        ),
      ],
    );
  }

  Widget _buildTabItem(
      ThemeData theme, int index, IconData icon, String label, double width) {
    final isSelected = _tabController.index == index;
    // Используем ConstrainedBox вместо фиксированного SizedBox, чтобы избежать переполнения
    return ConstrainedBox(
      constraints: BoxConstraints(minWidth: width),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13, // Немного уменьшаем шрифт для мобилок
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
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
            workId: widget.workId, parentContext: widget.parentContext);
      default:
        return WorkDataTab(work: workAsync, objectDisplay: objectDisplay);
    }
  }

  Widget _buildWorkItemsTab() {
    // Получаем смену для проверки статуса
    final workAsync = ref.watch(workProvider(widget.workId));
    final isWorkClosed = workAsync?.status.toLowerCase() == 'closed';

    // Проверка прав
    final permissionService = ref.watch(permissionServiceProvider);
    final canUpdate = permissionService.can('works', 'update');
    final canDelete = permissionService.can('works', 'delete');

    // Проверка на супер-админа
    final currentProfile = ref.watch(currentUserProfileProvider).profile;
    final rolesState = ref.watch(rolesNotifierProvider);
    final isSuperAdmin = rolesState.valueOrNull?.any((r) =>
            r.id == currentProfile?.roleId &&
            r.isSystem &&
            r.name == 'Супер-админ') ??
        false;

    // Разрешаем редактировать, если (смена открыта ИЛИ супер-админ) И есть право update
    final bool canModify = (!isWorkClosed || isSuperAdmin) && canUpdate;

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
                            'Нет работ. Добавьте новую работу, нажав на "+"'));
                  }

                  // Обновляем состояние фильтров при каждом изменении данных
                  _updateFiltersAfterDataChange(items);

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
                          Icon(CupertinoIcons.search,
                              size: 48,
                              color: Theme.of(context).colorScheme.outline),
                          const SizedBox(height: 16),
                          const Text('Нет работ, соответствующих фильтрам'),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: _resetFilters,
                            icon:
                                const Icon(CupertinoIcons.slider_horizontal_3),
                            label: const Text('Сбросить фильтры'),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    controller: _workItemsScrollController,
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredItems.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final item = filteredItems[i];

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
                            child: CupertinoActivityIndicator(
                              radius: 9,
                            ),
                          ),
                        );
                      } else {
                        // Если сметы загружены, ищем номер позиции
                        final Estimate? estimate = ref
                            .watch(estimateNotifierProvider)
                            .estimates
                            .firstWhereOrNull(
                              (e) => e.id == item.estimateId,
                            );
                        final number = estimate?.number ?? '-';

                        numberWidget = Container(
                          width: 45,
                          alignment: Alignment.center,
                          child: Text(
                            number,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            softWrap: false,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).brightness ==
                                            Brightness.light
                                        ? Colors.lightBlue.shade700
                                        : Colors.lightBlue.shade300),
                          ),
                        );
                      }

                      // Контроллер и фокус для поля ввода количества
                      final controller =
                          _getQuantityController(item.id, item.quantity);
                      final focusNode = _getFocusNode(item.id);

                      final isEditing = _editingItemIndex == i;

                      // Проверяем, находимся ли мы в мобильном режиме
                      final isMobile = !ResponsiveUtils.isDesktop(context);

                      // Обертываем карточку в Dismissible для мобильного свайпа
                      Widget cardWidget = InkWell(
                        onLongPress: canDelete
                            ? () {
                                WorkItemContextMenu.show(
                                  context: context,
                                  item: item,
                                  workId: widget.workId,
                                  parentContext: widget.parentContext,
                                  ref: ref,
                                  onDeleteComplete: () {
                                    if (mounted) {
                                      final updatedItems = ref
                                              .read(workItemsProvider(
                                                  widget.workId))
                                              .valueOrNull ??
                                          [];
                                      setState(() {
                                        _updateFiltersAfterDataChange(
                                            updatedItems);
                                      });
                                    }
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
                              color: Theme.of(context)
                                  .colorScheme
                                  .outline
                                  .withValues(alpha: 30),
                              width: 1,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 16),
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
                                            child: Text(
                                              item.name,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium
                                                  ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: Theme.of(context)
                                                                  .brightness ==
                                                              Brightness.light
                                                          ? Colors.lightBlue
                                                              .shade700
                                                          : Colors.lightBlue
                                                              .shade300),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
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
                                                                milliseconds:
                                                                    50), () {
                                                          focusNode
                                                              .requestFocus();
                                                          WidgetsBinding
                                                              .instance
                                                              .addPostFrameCallback(
                                                                  (_) {
                                                            final ctx =
                                                                focusNode
                                                                    .context;
                                                            if (ctx != null) {
                                                              Scrollable
                                                                  .ensureVisible(
                                                                ctx,
                                                                alignment: 0.3,
                                                                duration:
                                                                    const Duration(
                                                                        milliseconds:
                                                                            200),
                                                              );
                                                            }
                                                          });
                                                        });
                                                      } else {
                                                        // Сохраняем изменения при выходе из режима редактирования
                                                        final raw = controller
                                                            .text
                                                            .replaceAll(
                                                                ',', '.');
                                                        final newValue =
                                                            num.tryParse(raw);
                                                        _updateWorkItemQuantity(
                                                            item, newValue);
                                                      }
                                                    });
                                                  }
                                                : null,
                                            child: isEditing
                                                ? SizedBox(
                                                    width: 60,
                                                    height: 30,
                                                    child: Focus(
                                                      onFocusChange:
                                                          (hasFocus) {
                                                        if (!hasFocus) {
                                                          final normalized =
                                                              controller.text
                                                                  .replaceAll(
                                                                      ',', '.');
                                                          final newValue =
                                                              num.tryParse(
                                                                  normalized);
                                                          setState(() {
                                                            _editingItemIndex =
                                                                null;
                                                          });
                                                          _updateWorkItemQuantity(
                                                              item, newValue);
                                                        }
                                                      },
                                                      child: TextField(
                                                        controller: controller,
                                                        focusNode: focusNode,
                                                        keyboardType:
                                                            const TextInputType
                                                                .numberWithOptions(
                                                                decimal: true),
                                                        inputFormatters: [
                                                          FilteringTextInputFormatter
                                                              .allow(RegExp(
                                                                  r'[0-9.,]')),
                                                        ],
                                                        textAlign:
                                                            TextAlign.center,
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .bodyMedium
                                                            ?.copyWith(
                                                              color: Theme.of(
                                                                      context)
                                                                  .colorScheme
                                                                  .primary,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                            ),
                                                        decoration:
                                                            InputDecoration(
                                                          isDense: true,
                                                          contentPadding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                                  horizontal: 4,
                                                                  vertical: 8),
                                                          enabledBorder:
                                                              OutlineInputBorder(
                                                            borderSide:
                                                                BorderSide(
                                                              color: Theme.of(
                                                                      context)
                                                                  .colorScheme
                                                                  .primary
                                                                  .withValues(
                                                                      alpha:
                                                                          0.5),
                                                              width: 1,
                                                            ),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        4),
                                                          ),
                                                          focusedBorder:
                                                              OutlineInputBorder(
                                                            borderSide:
                                                                BorderSide(
                                                              color: Theme.of(
                                                                      context)
                                                                  .colorScheme
                                                                  .primary,
                                                              width: 1.5,
                                                            ),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        4),
                                                          ),
                                                        ),
                                                        onSubmitted: (value) {
                                                          setState(() {
                                                            _editingItemIndex =
                                                                null;
                                                            final normalized =
                                                                value
                                                                    .replaceAll(
                                                                        ',',
                                                                        '.');
                                                            final newValue =
                                                                num.tryParse(
                                                                    normalized);
                                                            _updateWorkItemQuantity(
                                                                item, newValue);
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
                                                              color: Theme.of(context)
                                                                          .brightness ==
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
                                                              color: Theme.of(
                                                                      context)
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
                                                    context, ref, item),
                                                child: MouseRegion(
                                                  cursor:
                                                      SystemMouseCursors.click,
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.all(6),
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              20),
                                                    ),
                                                    child: Icon(
                                                      CupertinoIcons.delete,
                                                      size: 20,
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .error,
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
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurface,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Expanded(
                                            child: Text(
                                              '${item.system.isNotEmpty ? item.system : '-'}/${item.subsystem.isNotEmpty ? item.subsystem : '-'}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurface,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                              textAlign: TextAlign.end,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      // Цена и сумма
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Flexible(
                                            child: Text.rich(
                                              TextSpan(
                                                children: [
                                                  const TextSpan(
                                                      text: 'Цена: ',
                                                      style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.w500)),
                                                  TextSpan(
                                                    text:
                                                        '${_formatAmount(item.price ?? 0)} ₽',
                                                    style: TextStyle(
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .primary),
                                                  ),
                                                ],
                                              ),
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall,
                                            ),
                                          ),
                                          Flexible(
                                            child: Text.rich(
                                              TextSpan(
                                                children: [
                                                  const TextSpan(
                                                      text: 'Сумма: ',
                                                      style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.w500)),
                                                  TextSpan(
                                                    text:
                                                        '${_formatAmount(item.total ?? 0)} ₽',
                                                    style: TextStyle(
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .primary,
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  ),
                                                ],
                                              ),
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall,
                                              textAlign: TextAlign.end,
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
                                        child: Align(
                                          alignment: Alignment.centerRight,
                                          child: Text.rich(
                                            TextSpan(
                                              children: [
                                                const TextSpan(
                                                    text: 'Цена: ',
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w500)),
                                                TextSpan(
                                                    text: _formatAmount(
                                                        item.price ?? 0),
                                                    style: TextStyle(
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .primary)),
                                                const TextSpan(text: ' ₽  |  '),
                                                const TextSpan(
                                                    text: 'Сумма: ',
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w500)),
                                                TextSpan(
                                                    text: _formatAmount(
                                                        item.total ?? 0),
                                                    style: TextStyle(
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .primary)),
                                                const TextSpan(text: ' ₽'),
                                              ],
                                            ),
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall,
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
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onError,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          confirmDismiss: (direction) async {
                            return await _showDeleteConfirmationDialog(
                                context, item);
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
                heroTag: 'addWorkItem',
                mini: true,
                onPressed: () {
                  showModalBottomSheet(
                    context: widget.parentContext,
                    isScrollControlled: true,
                    useSafeArea: true,
                    useRootNavigator: true,
                    backgroundColor: Colors.transparent,
                    constraints: BoxConstraints(
                      maxHeight:
                          MediaQuery.of(widget.parentContext).size.height -
                              MediaQuery.of(widget.parentContext).padding.top,
                    ),
                    builder: (ctx) => _buildStylizedModalSheet(
                      widget.parentContext,
                      WorkItemFormImproved(workId: widget.workId),
                    ),
                  );
                },
                child: const Icon(CupertinoIcons.add),
              ),
            ),
        ],
      ),
    );
  }

  // Удалено: реализация вкладки "Сотрудники" перенесена в WorkHoursTab

  // Удалено: кэш и метод получения имени сотрудника перенесены в WorkHoursTab

  /// Форматирует числовое значение для отображения денежной суммы.
  String _formatAmount(num amount) {
    final formatter = NumberFormat('#,##0.00', 'ru_RU');
    return formatter.format(amount);
  }

  // Статусный баннер и вычисление статуса в хедере удалены по требованию

  /// Показывает диалог подтверждения удаления для свайпа (работы)
  Future<bool?> _showDeleteConfirmationDialog(
      BuildContext context, WorkItem item) async {
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

  // Удалено: диалог подтверждения удаления для вкладки сотрудников перенесен в WorkHoursTab

  /// Выполняет удаление работы после подтверждения свайпа
  void _deleteWorkItem(WidgetRef ref, WorkItem item) async {
    await ref
        .read(workItemsProvider(widget.workId).notifier)
        .deleteOptimistic(item.id);

    // После удаления обновляем фильтры по текущему локальному списку, без fetch
    if (mounted) {
      final updatedItems =
          ref.read(workItemsProvider(widget.workId)).valueOrNull ?? [];
      setState(() {
        _updateFiltersAfterDataChange(updatedItems);
      });
    }
  }

  void _confirmDeleteItem(BuildContext context, WidgetRef ref, WorkItem item) {
    // Получаем смену для проверки статуса
    final workAsync = ref.read(workProvider(widget.workId));
    final isWorkClosed = workAsync?.status.toLowerCase() == 'closed';

    // Если смена закрыта, не разрешаем удаление
    if (isWorkClosed) {
      SnackBarUtils.showError(
          context, 'Удаление работ невозможно, так как смена закрыта');
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
              await ref
                  .read(workItemsProvider(widget.workId).notifier)
                  .deleteOptimistic(item.id);

              // После удаления получаем обновленный список элементов и обновляем фильтры
              if (mounted) {
                final updatedItems =
                    ref.read(workItemsProvider(widget.workId)).valueOrNull ??
                        [];
                setState(() {
                  _updateFiltersAfterDataChange(updatedItems);
                });
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
    ValueChanged<String?> onChanged,
  ) {
    final theme = Theme.of(context);
    final isSelected = value != null;

    return SizedBox(
      width: 150,
      height: 36,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.1)
              : theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.4),
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

  // Функция, возвращающая шаблон модального окна
  Widget _buildStylizedModalSheet(BuildContext context, Widget content) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(widget.parentContext).size.width;
    final isDesktop = ResponsiveUtils.isDesktop(widget.parentContext);

    final modalContent = Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: content is WorkItemFormImproved
              ? WorkItemFormImproved(
                  workId: content.workId,
                  initial: content.initial,
                  scrollController: scrollController,
                )
              : content,
        ),
      ),
    );

    if (isDesktop) {
      // Для десктопа - ограничиваем ширину и привязываем к низу (как у сотрудников)
      return Align(
        alignment: Alignment.bottomCenter,
        child: SizedBox(
          width: screenWidth * 0.5, // 50% от ширины экрана
          child: modalContent,
        ),
      );
    } else {
      // Для мобильных - без дополнительных изменений, так как constraints
      // определяются в вызове showModalBottomSheet
      return modalContent;
    }
  }

  Widget _buildFiltersBlock(
      BuildContext context, ThemeData theme, List<WorkItem> items) {
    final uniqueModules = _getUniqueModules(items);
    final uniqueFloors = _getUniqueFloors(items);
    final uniqueSystems = _getUniqueSystems(items);
    final uniqueSubsystems = _selectedSystem != null
        ? _getUniqueSubsystems(items, system: _selectedSystem)
        : _getUniqueSubsystems(items);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? const Color(0xFF3A3A3C)
            : theme.colorScheme.surfaceContainerHighest,
        border: Border.all(
          color: theme.brightness == Brightness.dark
              ? Colors.white.withValues(alpha: 0.1)
              : theme.colorScheme.outline.withValues(alpha: 0.15),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Row(
            children: [
              // Поиск
              SizedBox(
                width: 450,
                height: 36,
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.brightness == Brightness.dark
                        ? Colors.black.withValues(alpha: 0.2)
                        : Colors.black.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: theme.textTheme.bodyMedium,
                    decoration: InputDecoration(
                      hintText: 'Поиск',
                      hintStyle: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      filled: false,
                      prefixIcon: Icon(
                        CupertinoIcons.search,
                        size: 18,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      disabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      isDense: true,
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Фильтры
              _buildFilterDropdown(
                  context,
                  'Модуль',
                  _selectedModule,
                  uniqueModules,
                  (val) => setState(() => _selectedModule = val)),
              const SizedBox(width: 8),
              _buildFilterDropdown(context, 'Этаж', _selectedFloor,
                  uniqueFloors, (val) => setState(() => _selectedFloor = val)),
              const SizedBox(width: 8),
              _buildFilterDropdown(
                  context,
                  'Система',
                  _selectedSystem,
                  uniqueSystems,
                  (val) => setState(() {
                        _selectedSystem = val;
                        _selectedSubsystem = null;
                      })),
              const SizedBox(width: 8),
              _buildFilterDropdown(
                  context,
                  'Подсистема',
                  _selectedSubsystem,
                  uniqueSubsystems,
                  (val) => setState(() => _selectedSubsystem = val)),

              const SizedBox(width: 8),
              // Кнопка сброса
              if (_searchQuery.isNotEmpty ||
                  _selectedModule != null ||
                  _selectedFloor != null ||
                  _selectedSystem != null ||
                  _selectedSubsystem != null)
                IconButton.filledTonal(
                  onPressed: _resetFilters,
                  icon:
                      const Icon(CupertinoIcons.slider_horizontal_3, size: 18),
                  style: IconButton.styleFrom(
                    backgroundColor:
                        theme.colorScheme.errorContainer.withValues(alpha: 0.5),
                    foregroundColor: theme.colorScheme.error,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  tooltip: 'Сбросить',
                ),
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
          Text('$label: ',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Theme.of(context).colorScheme.outline)),
          Text(value,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
