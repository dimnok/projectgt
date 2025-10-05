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
import 'package:projectgt/domain/entities/profile.dart';
import 'package:projectgt/domain/entities/estimate.dart';
import 'package:collection/collection.dart';
import 'dart:async';
import 'dart:math' as math;

import 'package:projectgt/core/utils/responsive_utils.dart';
import 'package:projectgt/core/utils/snackbar_utils.dart';

import 'package:projectgt/presentation/state/profile_state.dart';
import 'package:projectgt/presentation/state/auth_state.dart';

import 'tabs/work_data_tab.dart';
import 'tabs/work_hours_tab.dart';

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

  ///守望даёт панель деталей смены для [workId].
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
  double _workHeaderOffset = 0.0;
  final double _mobileHeaderBaseHeight = 140.0;
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
    _workItemsScrollController.addListener(_handleWorkItemsScroll);

    // Загружаем данные при инициализации
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(employee_state.employeeProvider.notifier).getEmployees();

      // Загружаем сметы для отображения номеров
      if (ref.read(estimateNotifierProvider).estimates.isEmpty) {
        ref.read(estimateNotifierProvider.notifier).loadEstimates();
      }
    });
  }

  void _handleWorkItemsScroll() {
    if (!ResponsiveUtils.isMobile(context)) return;
    if (_tabController.index != 1) return;
    final offset = _workItemsScrollController.positions.isNotEmpty
        ? _workItemsScrollController.offset
        : 0.0;
    final clamped = offset.clamp(0.0, _mobileHeaderBaseHeight);
    if (clamped != _workHeaderOffset) {
      setState(() {
        _workHeaderOffset = clamped;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _workItemsScrollController.removeListener(_handleWorkItemsScroll);
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
    final workAsync = ref.watch(workProvider(widget.workId));

    if (workAsync == null) {
      return const Center(child: Text('Смена не найдена'));
    }

    // Получаем информацию об объекте
    final objects = ref.watch(objectProvider).objects;
    final object = objects.where((o) => o.id == workAsync.objectId).isNotEmpty
        ? objects.firstWhere((o) => o.id == workAsync.objectId)
        : null;
    final objectDisplay = object != null ? object.name : workAsync.objectId;

    // Статусный баннер удалён, вычисление статуса не требуется в хедере

    // В мобильном и десктопном режиме используется одинаковая структура единого блока
    return Column(
      children: [
        // Отступ сверху как в списке смен
        SizedBox(
          height: ResponsiveUtils.isMobile(context) ? 8 : 6,
        ),
        // Единый блок с информацией и табами
        Container(
          margin: EdgeInsets.symmetric(
            horizontal: ResponsiveUtils.isMobile(context) ? 16 : 0,
          ),
          constraints: ResponsiveUtils.isMobile(context)
              ? BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width - 32,
                )
              : null,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
              width: 0.5,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Transform.translate(
            offset: Offset(
                0, ResponsiveUtils.isMobile(context) ? -_workHeaderOffset : 0),
            child: ClipRect(
              child: Align(
                alignment: Alignment.topCenter,
                heightFactor: ResponsiveUtils.isMobile(context)
                    ? math.max(
                        0.0, 1 - (_workHeaderOffset / _mobileHeaderBaseHeight))
                    : 1.0,
                child: Column(
                  children: [
                    // Шапка с иконкой и основной информацией (коллапс для мобильного)
                    ClipRect(
                      child: Align(
                        alignment: Alignment.topCenter,
                        heightFactor: ResponsiveUtils.isMobile(context)
                            ? math.max(
                                0.0,
                                1 -
                                    (_workHeaderOffset /
                                        _mobileHeaderBaseHeight))
                            : 1.0,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Stack(
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Иконка замка как в карточках списка смен
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.surface,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      workAsync.status.toLowerCase() == 'closed'
                                          ? Icons.lock
                                          : Icons.lock_open,
                                      color: workAsync.status.toLowerCase() ==
                                              'closed'
                                          ? Colors.red
                                          : Colors.green,
                                      size: 32,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  // Информация о смене
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Смена от ${_formatDate(workAsync.date)}',
                                          style: theme.textTheme.titleLarge
                                              ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Объект: $objectDisplay',
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        FutureBuilder<Profile?>(
                                          future: ref
                                              .read(profileRepositoryProvider)
                                              .getProfile(workAsync.openedBy),
                                          builder: (context, snapshot) {
                                            final String openedBy = snapshot
                                                        .hasData &&
                                                    snapshot.data?.shortName !=
                                                        null
                                                ? snapshot.data!.shortName!
                                                : 'ID: ${workAsync.openedBy.length > 4 ? "${workAsync.openedBy.substring(0, 4)}..." : workAsync.openedBy}';
                                            return Text(
                                              'Открыл: $openedBy',
                                              style: theme.textTheme.bodyMedium,
                                            );
                                          },
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
                    ),

                    // Разделитель
                    Container(
                      height: 0.5,
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      color: theme.colorScheme.outline.withValues(alpha: 0.2),
                    ),

                    // Табы для разделов информации
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: CupertinoSlidingSegmentedControl<int>(
                        groupValue: _tabController.index,
                        backgroundColor:
                            theme.colorScheme.surface.withValues(alpha: 0.5),
                        thumbColor:
                            theme.colorScheme.primary.withValues(alpha: 0.8),
                        padding: const EdgeInsets.all(4),
                        onValueChanged: (int? value) {
                          if (value != null) {
                            setState(() {
                              _tabController.animateTo(value);
                            });
                          }
                        },
                        children: {
                          0: SizedBox(
                            width: 110,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    size: 18,
                                    color: _tabController.index == 0
                                        ? theme.colorScheme.onPrimary
                                        : theme.colorScheme.onSurface
                                            .withValues(alpha: 0.7),
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      'Данные',
                                      style: TextStyle(
                                        color: _tabController.index == 0
                                            ? theme.colorScheme.onPrimary
                                            : theme.colorScheme.onSurface
                                                .withValues(alpha: 0.7),
                                        fontWeight: _tabController.index == 0
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          1: SizedBox(
                            width: 110,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.work_outline,
                                    size: 18,
                                    color: _tabController.index == 1
                                        ? theme.colorScheme.onPrimary
                                        : theme.colorScheme.onSurface
                                            .withValues(alpha: 0.7),
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      'Работы',
                                      style: TextStyle(
                                        color: _tabController.index == 1
                                            ? theme.colorScheme.onPrimary
                                            : theme.colorScheme.onSurface
                                                .withValues(alpha: 0.7),
                                        fontWeight: _tabController.index == 1
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          2: SizedBox(
                            width: 110,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.people_outline,
                                    size: 18,
                                    color: _tabController.index == 2
                                        ? theme.colorScheme.onPrimary
                                        : theme.colorScheme.onSurface
                                            .withValues(alpha: 0.7),
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      'Сотрудники',
                                      style: TextStyle(
                                        color: _tabController.index == 2
                                            ? theme.colorScheme.onPrimary
                                            : theme.colorScheme.onSurface
                                                .withValues(alpha: 0.7),
                                        fontWeight: _tabController.index == 2
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Контент табов
        Expanded(
          child: _getTabContent(_tabController.index, workAsync, objectDisplay),
        ),
      ],
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
    final currentProfile = ref.watch(profileProvider).profile;
    final isAdmin = ref.watch(authProvider).user?.role == 'admin';
    final bool isOwner = currentProfile != null &&
        workAsync != null &&
        workAsync.openedBy == currentProfile.id;
    final bool canModify = !isWorkClosed && (isOwner || isAdmin);

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
                  // Это обеспечит валидность выбранных значений фильтров
                  _updateFiltersAfterDataChange(items);

                  final uniqueModules = _getUniqueModules(items);
                  final uniqueFloors = _getUniqueFloors(items);
                  final uniqueSystems = _getUniqueSystems(items);
                  final uniqueSubsystems = _selectedSystem != null
                      ? _getUniqueSubsystems(items, system: _selectedSystem)
                      : _getUniqueSubsystems(items);

                  final filteredItems = _filterItems(items);

                  return Column(
                    children: [
                      // Строка фильтров
                      Container(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          border: Border(
                            bottom: BorderSide(
                              color: Theme.of(context)
                                  .colorScheme
                                  .outline
                                  .withValues(alpha: 0.1),
                              width: 1,
                            ),
                          ),
                        ),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              // Поиск
                              SizedBox(
                                width: 200,
                                height: 36,
                                child: TextField(
                                  controller: _searchController,
                                  decoration: InputDecoration(
                                    hintText: 'Поиск',
                                    filled: true,
                                    fillColor: Theme.of(context)
                                        .colorScheme
                                        .surfaceContainerLowest,
                                    prefixIcon:
                                        const Icon(Icons.search, size: 18),
                                    contentPadding: EdgeInsets.zero,
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
                              const SizedBox(width: 12),
                              // Фильтр по модулю
                              DropdownButtonHideUnderline(
                                child: Container(
                                  constraints:
                                      const BoxConstraints(minWidth: 100),
                                  decoration: BoxDecoration(
                                    color: _selectedModule != null
                                        ? Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withValues(alpha: 0.1)
                                        : Theme.of(context)
                                            .colorScheme
                                            .surfaceContainerLowest,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10),
                                  child: DropdownButton<String>(
                                    hint: const Text('Модуль'),
                                    value: _selectedModule,
                                    icon: Icon(
                                      Icons.expand_more,
                                      color: _selectedModule != null
                                          ? Theme.of(context)
                                              .colorScheme
                                              .primary
                                          : Theme.of(context)
                                              .colorScheme
                                              .onSurface,
                                      size: 18,
                                    ),
                                    isDense: true,
                                    onChanged: (String? newValue) {
                                      setState(() {
                                        _selectedModule = newValue;
                                      });
                                    },
                                    items: [
                                      const DropdownMenuItem<String>(
                                        value: null,
                                        child: Text('Все модули'),
                                      ),
                                      ...uniqueModules
                                          .toSet()
                                          .map((String value) {
                                        return DropdownMenuItem<String>(
                                          value: value,
                                          child: Text(value),
                                        );
                                      }),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Фильтр по этажу
                              DropdownButtonHideUnderline(
                                child: Container(
                                  constraints:
                                      const BoxConstraints(minWidth: 100),
                                  decoration: BoxDecoration(
                                    color: _selectedFloor != null
                                        ? Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withValues(alpha: 0.1)
                                        : Theme.of(context)
                                            .colorScheme
                                            .surfaceContainerLowest,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10),
                                  child: DropdownButton<String>(
                                    hint: const Text('Этаж'),
                                    value: _selectedFloor,
                                    icon: Icon(
                                      Icons.expand_more,
                                      color: _selectedFloor != null
                                          ? Theme.of(context)
                                              .colorScheme
                                              .primary
                                          : Theme.of(context)
                                              .colorScheme
                                              .onSurface,
                                      size: 18,
                                    ),
                                    isDense: true,
                                    onChanged: (String? newValue) {
                                      setState(() {
                                        _selectedFloor = newValue;
                                      });
                                    },
                                    items: [
                                      const DropdownMenuItem<String>(
                                        value: null,
                                        child: Text('Все этажи'),
                                      ),
                                      ...uniqueFloors
                                          .toSet()
                                          .map((String value) {
                                        return DropdownMenuItem<String>(
                                          value: value,
                                          child: Text(value),
                                        );
                                      }),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Фильтр по системе
                              DropdownButtonHideUnderline(
                                child: Container(
                                  constraints:
                                      const BoxConstraints(minWidth: 100),
                                  decoration: BoxDecoration(
                                    color: _selectedSystem != null
                                        ? Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withValues(alpha: 0.1)
                                        : Theme.of(context)
                                            .colorScheme
                                            .surfaceContainerLowest,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10),
                                  child: DropdownButton<String>(
                                    hint: const Text('Система'),
                                    value: _selectedSystem,
                                    icon: Icon(
                                      Icons.expand_more,
                                      color: _selectedSystem != null
                                          ? Theme.of(context)
                                              .colorScheme
                                              .primary
                                          : Theme.of(context)
                                              .colorScheme
                                              .onSurface,
                                      size: 18,
                                    ),
                                    isDense: true,
                                    onChanged: (String? newValue) {
                                      setState(() {
                                        _selectedSystem = newValue;
                                        // Сбрасываем подсистему при изменении системы
                                        _selectedSubsystem = null;
                                      });
                                    },
                                    items: [
                                      const DropdownMenuItem<String>(
                                        value: null,
                                        child: Text('Все системы'),
                                      ),
                                      ...uniqueSystems
                                          .toSet()
                                          .map((String value) {
                                        return DropdownMenuItem<String>(
                                          value: value,
                                          child: Text(value),
                                        );
                                      }),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Фильтр по подсистеме
                              DropdownButtonHideUnderline(
                                child: Container(
                                  constraints:
                                      const BoxConstraints(minWidth: 100),
                                  decoration: BoxDecoration(
                                    color: _selectedSubsystem != null
                                        ? Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withValues(alpha: 0.1)
                                        : Theme.of(context)
                                            .colorScheme
                                            .surfaceContainerLowest,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10),
                                  child: DropdownButton<String>(
                                    hint: const Text('Подсистема'),
                                    value: _selectedSubsystem,
                                    icon: Icon(
                                      Icons.expand_more,
                                      color: _selectedSubsystem != null
                                          ? Theme.of(context)
                                              .colorScheme
                                              .primary
                                          : Theme.of(context)
                                              .colorScheme
                                              .onSurface,
                                      size: 18,
                                    ),
                                    isDense: true,
                                    onChanged: (String? newValue) {
                                      setState(() {
                                        _selectedSubsystem = newValue;
                                      });
                                    },
                                    items: [
                                      const DropdownMenuItem<String>(
                                        value: null,
                                        child: Text('Все подсистемы'),
                                      ),
                                      ...uniqueSubsystems
                                          .toSet()
                                          .map((String value) {
                                        return DropdownMenuItem<String>(
                                          value: value,
                                          child: Text(value),
                                        );
                                      }),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Кнопка сброса фильтров
                              if (_searchQuery.isNotEmpty ||
                                  _selectedModule != null ||
                                  _selectedFloor != null ||
                                  _selectedSystem != null ||
                                  _selectedSubsystem != null)
                                TextButton.icon(
                                  onPressed: _resetFilters,
                                  icon: const Icon(Icons.filter_alt_off,
                                      size: 16),
                                  label: const Text('Сбросить'),
                                  style: TextButton.styleFrom(
                                    minimumSize: const Size(50, 36),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10),
                                    backgroundColor: Theme.of(context)
                                        .colorScheme
                                        .errorContainer
                                        .withValues(alpha: 0.2),
                                    foregroundColor:
                                        Theme.of(context).colorScheme.error,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      // Информация о результатах фильтрации
                      if (filteredItems.isEmpty &&
                          (_searchQuery.isNotEmpty ||
                              _selectedModule != null ||
                              _selectedFloor != null ||
                              _selectedSystem != null ||
                              _selectedSubsystem != null))
                        Expanded(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.search_off,
                                    size: 48,
                                    color:
                                        Theme.of(context).colorScheme.outline),
                                const SizedBox(height: 16),
                                const Text(
                                    'Нет работ, соответствующих фильтрам'),
                                const SizedBox(height: 8),
                                TextButton.icon(
                                  onPressed: _resetFilters,
                                  icon: const Icon(Icons.filter_alt_off),
                                  label: const Text('Сбросить фильтры'),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        // Список отфильтрованных работ
                        Expanded(
                          child: ListView.separated(
                            controller: _workItemsScrollController,
                            keyboardDismissBehavior:
                                ScrollViewKeyboardDismissBehavior.onDrag,
                            padding: const EdgeInsets.all(16),
                            itemCount: filteredItems.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, i) {
                              final item = filteredItems[i];

                              // Отображаем номер позиции из сметы, если сметы загружены
                              Widget numberWidget;
                              if (_areEstimatesLoading) {
                                // Если сметы загружаются или еще не загружены, показываем индикатор
                                numberWidget = Container(
                                  width: 30,
                                  alignment: Alignment.center,
                                  child: SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withValues(alpha: 0.5),
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
                                  width: 30,
                                  alignment: Alignment.center,
                                  child: Text(
                                    number,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context)
                                                        .brightness ==
                                                    Brightness.light
                                                ? Colors.lightBlue.shade700
                                                : Colors.lightBlue.shade300),
                                  ),
                                );
                              }

                              // Контроллер и фокус для поля ввода количества
                              final controller = _getQuantityController(
                                  item.id, item.quantity);
                              final focusNode = _getFocusNode(item.id);

                              final isEditing = _editingItemIndex == i;

                              // Проверяем, находимся ли мы в мобильном режиме
                              final isMobile =
                                  !ResponsiveUtils.isDesktop(context);

                              // Обертываем карточку в Dismissible для мобильного свайпа
                              Widget cardWidget = Card(
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                                                    Brightness
                                                                        .light
                                                                ? Colors
                                                                    .lightBlue
                                                                    .shade700
                                                                : Colors
                                                                    .lightBlue
                                                                    .shade300),
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
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
                                                                isEditing
                                                                    ? null
                                                                    : i;

                                                            if (_editingItemIndex ==
                                                                i) {
                                                              // Фокусируемся на поле ввода с небольшой задержкой
                                                              Timer(
                                                                  const Duration(
                                                                      milliseconds:
                                                                          50),
                                                                  () {
                                                                focusNode
                                                                    .requestFocus();
                                                                WidgetsBinding
                                                                    .instance
                                                                    .addPostFrameCallback(
                                                                        (_) {
                                                                  final ctx =
                                                                      focusNode
                                                                          .context;
                                                                  if (ctx !=
                                                                      null) {
                                                                    Scrollable
                                                                        .ensureVisible(
                                                                      ctx,
                                                                      alignment:
                                                                          0.3,
                                                                      duration: const Duration(
                                                                          milliseconds:
                                                                              200),
                                                                    );
                                                                  }
                                                                });
                                                              });
                                                            } else {
                                                              // Сохраняем изменения при выходе из режима редактирования
                                                              final raw =
                                                                  controller
                                                                      .text
                                                                      .replaceAll(
                                                                          ',',
                                                                          '.');
                                                              final newValue =
                                                                  num.tryParse(
                                                                      raw);
                                                              _updateWorkItemQuantity(
                                                                  item,
                                                                  newValue);
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
                                                                    controller
                                                                        .text
                                                                        .replaceAll(
                                                                            ',',
                                                                            '.');
                                                                final newValue =
                                                                    num.tryParse(
                                                                        normalized);
                                                                setState(() {
                                                                  _editingItemIndex =
                                                                      null;
                                                                });
                                                                _updateWorkItemQuantity(
                                                                    item,
                                                                    newValue);
                                                              }
                                                            },
                                                            child: TextField(
                                                              controller:
                                                                  controller,
                                                              focusNode:
                                                                  focusNode,
                                                              keyboardType:
                                                                  const TextInputType
                                                                      .numberWithOptions(
                                                                      decimal:
                                                                          true),
                                                              inputFormatters: [
                                                                FilteringTextInputFormatter
                                                                    .allow(RegExp(
                                                                        r'[0-9.,]')),
                                                              ],
                                                              textAlign:
                                                                  TextAlign
                                                                      .center,
                                                              style: Theme.of(
                                                                      context)
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
                                                                        horizontal:
                                                                            4,
                                                                        vertical:
                                                                            8),
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
                                                              onSubmitted:
                                                                  (value) {
                                                                setState(() {
                                                                  _editingItemIndex =
                                                                      null;
                                                                  final normalized =
                                                                      value.replaceAll(
                                                                          ',',
                                                                          '.');
                                                                  final newValue =
                                                                      num.tryParse(
                                                                          normalized);
                                                                  _updateWorkItemQuantity(
                                                                      item,
                                                                      newValue);
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
                                                              style: Theme.of(
                                                                      context)
                                                                  .textTheme
                                                                  .bodyMedium
                                                                  ?.copyWith(
                                                                    color: Theme.of(context).brightness ==
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
                                                            const SizedBox(
                                                                width: 2),
                                                            Text(
                                                              item.unit,
                                                              style: Theme.of(
                                                                      context)
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
                                                if (!isWorkClosed &&
                                                    !isMobile) ...[
                                                  const SizedBox(width: 8),
                                                  Material(
                                                    color: Colors.transparent,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            20),
                                                    child: InkWell(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              20),
                                                      onTap: () =>
                                                          _confirmDeleteItem(
                                                              context,
                                                              ref,
                                                              item),
                                                      child: MouseRegion(
                                                        cursor:
                                                            SystemMouseCursors
                                                                .click,
                                                        child: Container(
                                                          padding:
                                                              const EdgeInsets
                                                                  .all(6),
                                                          decoration:
                                                              BoxDecoration(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        20),
                                                          ),
                                                          child: Icon(
                                                            Icons
                                                                .delete_outline,
                                                            size: 20,
                                                            color: Theme.of(
                                                                    context)
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
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .onSurface,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                Expanded(
                                                  child: Text(
                                                    '${item.system.isNotEmpty ? item.system : '-'}/${item.subsystem.isNotEmpty ? item.subsystem : '-'}',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .onSurface,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    textAlign: TextAlign.end,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            // Цена и сумма
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Flexible(
                                                  child: Text.rich(
                                                    TextSpan(
                                                      children: [
                                                        const TextSpan(
                                                            text: 'Цена: ',
                                                            style: TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500)),
                                                        TextSpan(
                                                          text:
                                                              '${_formatAmount(item.price ?? 0)} ₽',
                                                          style: TextStyle(
                                                              color: Theme.of(
                                                                      context)
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
                                                                    FontWeight
                                                                        .w500)),
                                                        TextSpan(
                                                          text:
                                                              '${_formatAmount(item.total ?? 0)} ₽',
                                                          style: TextStyle(
                                                              color: Theme.of(
                                                                      context)
                                                                  .colorScheme
                                                                  .primary,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold),
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
                                            _miniInfo(
                                                'Подсистема', item.subsystem),
                                            Expanded(
                                              child: Align(
                                                alignment:
                                                    Alignment.centerRight,
                                                child: Text.rich(
                                                  TextSpan(
                                                    children: [
                                                      const TextSpan(
                                                          text: 'Цена: ',
                                                          style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500)),
                                                      TextSpan(
                                                          text: _formatAmount(
                                                              item.price ?? 0),
                                                          style: TextStyle(
                                                              color: Theme.of(
                                                                      context)
                                                                  .colorScheme
                                                                  .primary)),
                                                      const TextSpan(
                                                          text: ' ₽  |  '),
                                                      const TextSpan(
                                                          text: 'Сумма: ',
                                                          style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500)),
                                                      TextSpan(
                                                          text: _formatAmount(
                                                              item.total ?? 0),
                                                          style: TextStyle(
                                                              color: Theme.of(
                                                                      context)
                                                                  .colorScheme
                                                                  .primary)),
                                                      const TextSpan(
                                                          text: ' ₽'),
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
                                      color:
                                          Theme.of(context).colorScheme.error,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Icon(
                                          Icons.delete_outline,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onError,
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
                          ),
                        ),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => Center(child: Text('Ошибка: $e')),
              );
            },
          ),
          // Кнопка добавления работы - только владелец открытой смены и нет активного поля ввода
          if (canModify && _editingItemIndex == null)
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
                child: const Icon(Icons.add),
              ),
            ),
        ],
      ),
    );
  }

  // Удалено: реализация вкладки "Сотрудники" перенесена в WorkHoursTab

  // Удалено: кэш и метод получения имени сотрудника перенесены в WorkHoursTab

  /// Форматирует дату в формате ДД.ММ.ГГГГ.
  String _formatDate(DateTime date) {
    final formatter = DateFormat('dd.MM.yyyy');
    return formatter.format(date);
  }

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
