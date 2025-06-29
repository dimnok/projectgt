import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/work_item.dart';
import '../../domain/entities/work_hour.dart';
import '../../domain/entities/work.dart';
import '../providers/work_items_provider.dart';
import '../providers/work_hours_provider.dart';
import '../providers/work_provider.dart';
import 'work_item_form_modal.dart';
import 'work_hour_form_modal.dart';
import 'package:projectgt/presentation/widgets/app_badge.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/presentation/state/employee_state.dart'
    as employee_state;
import 'package:intl/intl.dart';
import 'package:projectgt/domain/entities/profile.dart';
import 'package:projectgt/domain/entities/estimate.dart';
import 'package:collection/collection.dart';
import 'dart:async';
import 'dart:math' as math;
import '../widgets/work_photo_view.dart';
import 'package:image_picker/image_picker.dart';
import 'package:projectgt/core/utils/responsive_utils.dart';
import 'package:projectgt/core/utils/snackbar_utils.dart';
import 'package:projectgt/presentation/widgets/cupertino_dialog_widget.dart';

/// Панель деталей смены с табами: работы, материалы, часы.
///
/// Используется как часть мастер-детейл интерфейса на десктопе и как отдельный экран на мобильных.
/// Позволяет просматривать и редактировать списки работ, материалов и часов в смене.
class WorkDetailsPanel extends ConsumerStatefulWidget {
  /// Идентификатор смены.
  final String workId;
  /// Контекст родительского экрана (для корректного отображения модальных окон).
  final BuildContext parentContext;

  /// Создаёт панель деталей смены для [workId].
  const WorkDetailsPanel({super.key, required this.workId, required this.parentContext});

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
  TextEditingController _getQuantityController(String itemId, num initialValue) {
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
        SnackBarUtils.showError(context, 'Изменение количества невозможно, так как смена закрыта');
      }
      return;
    }
    
    if (newQuantity != null && newQuantity > 0 && newQuantity != item.quantity) {
      // Вычисляем total как double
      final double total = (item.price ?? 0) * newQuantity;
      
      final updatedItem = item.copyWith(
        quantity: newQuantity,
        total: total,
        updatedAt: DateTime.now(),
      );
      
      await ref.read(workItemsProvider(widget.workId).notifier).update(updatedItem);
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
    return items.where((item) => item.system == system).map((item) => item.subsystem).toSet().toList()..sort();
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
    } else if (_selectedSubsystem != null && !uniqueSubsystems.contains(_selectedSubsystem)) {
      _selectedSubsystem = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final workAsync = ref.watch(workProvider(widget.workId));
    final isMobile = !ResponsiveUtils.isDesktop(context);

    if (workAsync == null) {
      return const Center(child: Text('Смена не найдена'));
    }

    // Получаем информацию об объекте
    final objects = ref.watch(objectProvider).objects;
    final object = objects.where((o) => o.id == workAsync.objectId).isNotEmpty
        ? objects.firstWhere((o) => o.id == workAsync.objectId)
        : null;
    final objectDisplay = object != null ? object.name : workAsync.objectId;

    // Получаем информацию о статусе
    final (statusText, statusColor) = _getWorkStatusInfo(workAsync.status);

    // Контент с табами
    final tabsContent = Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Данные'),
            Tab(text: 'Работы'),
            Tab(text: 'Сотрудники'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // Данные о смене
              _buildDataTab(workAsync, objectDisplay),
              // Работы
              _buildWorkItemsTab(),
              // Сотрудники (бывшие часы)
              _buildWorkHoursTab(),
            ],
          ),
        ),
      ],
    );

    // В мобильном режиме возвращаем только табы (шапку отображает основной экран)
    if (isMobile) {
      return tabsContent;
    }

    // В десктопном режиме добавляем шапку
    return Column(
      children: [
        // Шапка
        Stack(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.shadow.withValues(alpha: 20),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: theme.colorScheme.primary.withValues(alpha: 20),
                    child: Icon(Icons.work_rounded,
                        size: 40, color: theme.colorScheme.primary),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Смена от ${_formatDate(workAsync.date)}',
                            style: theme.textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text('Объект: $objectDisplay',
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        FutureBuilder<Profile?>(
                          future: ref
                              .read(profileRepositoryProvider)
                              .getProfile(workAsync.openedBy),
                          builder: (context, snapshot) {
                            final String openedBy = snapshot.hasData &&
                                    snapshot.data?.shortName != null
                                ? snapshot.data!.shortName!
                                : 'ID: ${workAsync.openedBy.length > 4 ? "${workAsync.openedBy.substring(0, 4)}..." : workAsync.openedBy}';
                            return Text('Открыл: $openedBy',
                                style: theme.textTheme.bodyMedium);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 16,
              right: 24,
              child: AppBadge(
                text: statusText,
                color: statusColor,
              ),
            ),
          ],
        ),
        // Табы и контент
        Expanded(child: tabsContent),
      ],
    );
  }

  Widget _buildWorkItemsTab() {
    // Получаем смену для проверки статуса
    final workAsync = ref.watch(workProvider(widget.workId));
    final isWorkClosed = workAsync?.status.toLowerCase() == 'closed';
    
    return Stack(
      children: [
        Consumer(
          builder: (context, ref, _) {
            final itemsAsync = ref.watch(workItemsProvider(widget.workId));
            return itemsAsync.when(
              data: (items) {
                if (items.isEmpty) {
                  return const Center(
                    child: Text('Нет работ. Добавьте новую работу, нажав на "+"')
                  );
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
                            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
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
                                  fillColor: Theme.of(context).colorScheme.surfaceContainerLowest,
                                  prefixIcon: const Icon(Icons.search, size: 18),
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
                                constraints: const BoxConstraints(minWidth: 100),
                                decoration: BoxDecoration(
                                  color: _selectedModule != null
                                      ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                                      : Theme.of(context).colorScheme.surfaceContainerLowest,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                child: DropdownButton<String>(
                                  hint: const Text('Модуль'),
                                  value: _selectedModule,
                                  icon: Icon(
                                    Icons.expand_more,
                                    color: _selectedModule != null
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(context).colorScheme.onSurface,
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
                                    ...uniqueModules.toSet().map((String value) {
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
                                constraints: const BoxConstraints(minWidth: 100),
                                decoration: BoxDecoration(
                                  color: _selectedFloor != null
                                      ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                                      : Theme.of(context).colorScheme.surfaceContainerLowest,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                child: DropdownButton<String>(
                                  hint: const Text('Этаж'),
                                  value: _selectedFloor,
                                  icon: Icon(
                                    Icons.expand_more,
                                    color: _selectedFloor != null
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(context).colorScheme.onSurface,
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
                                    ...uniqueFloors.toSet().map((String value) {
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
                                constraints: const BoxConstraints(minWidth: 100),
                                decoration: BoxDecoration(
                                  color: _selectedSystem != null
                                      ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                                      : Theme.of(context).colorScheme.surfaceContainerLowest,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                child: DropdownButton<String>(
                                  hint: const Text('Система'),
                                  value: _selectedSystem,
                                  icon: Icon(
                                    Icons.expand_more,
                                    color: _selectedSystem != null
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(context).colorScheme.onSurface,
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
                                    ...uniqueSystems.toSet().map((String value) {
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
                                constraints: const BoxConstraints(minWidth: 100),
                                decoration: BoxDecoration(
                                  color: _selectedSubsystem != null
                                      ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                                      : Theme.of(context).colorScheme.surfaceContainerLowest,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                child: DropdownButton<String>(
                                  hint: const Text('Подсистема'),
                                  value: _selectedSubsystem,
                                  icon: Icon(
                                    Icons.expand_more,
                                    color: _selectedSubsystem != null
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(context).colorScheme.onSurface,
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
                                    ...uniqueSubsystems.toSet().map((String value) {
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
                            if (_searchQuery.isNotEmpty || _selectedModule != null || _selectedFloor != null || 
                                _selectedSystem != null || _selectedSubsystem != null)
                              TextButton.icon(
                                onPressed: _resetFilters,
                                icon: const Icon(Icons.filter_alt_off, size: 16),
                                label: const Text('Сбросить'),
                                style: TextButton.styleFrom(
                                  minimumSize: const Size(50, 36),
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                  backgroundColor: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.2),
                                  foregroundColor: Theme.of(context).colorScheme.error,
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
                    if (filteredItems.isEmpty && (_searchQuery.isNotEmpty || _selectedModule != null || 
                        _selectedFloor != null || _selectedSystem != null || _selectedSubsystem != null))
                      Expanded(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search_off, size: 48, color: Theme.of(context).colorScheme.outline),
                              const SizedBox(height: 16),
                              const Text('Нет работ, соответствующих фильтрам'),
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
                                width: 48,
                                alignment: Alignment.center,
                                child: SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                                  ),
                                ),
                              );
                            } else {
                              // Если сметы загружены, ищем номер позиции
                              final Estimate? estimate = ref.watch(estimateNotifierProvider).estimates.firstWhereOrNull(
                                (e) => e.id == item.estimateId,
                              );
                              final number = estimate?.number ?? '-';
                              
                              numberWidget = Container(
                                width: 48,
                                alignment: Alignment.center,
                                child: Text(
                                  number,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              );
                            }
                            
                            // Контроллер и фокус для поля ввода количества
                            final controller = _getQuantityController(item.id, item.quantity);
                            final focusNode = _getFocusNode(item.id);
                            
                            final isEditing = _editingItemIndex == i;
                            
                            // Проверяем, находимся ли мы в мобильном режиме
                            final isMobile = !ResponsiveUtils.isDesktop(context);
                            
                        return Card(
                              margin: EdgeInsets.zero,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                            side: BorderSide(
                                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 30),
                              width: 1,
                            ),
                          ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        numberWidget,
                                        const SizedBox(width: 8),
                                        Expanded(
                                          flex: 3,
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                              item.name,
                                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              // Область количества и единицы измерения
                                              GestureDetector(
                                                onTap: !isWorkClosed ? () {
                                                  setState(() {
                                                    // Переключаем режим редактирования
                                                    _editingItemIndex = isEditing ? null : i;
                                                    
                                                    if (_editingItemIndex == i) {
                                                      // Фокусируемся на поле ввода с небольшой задержкой
                                                      Timer(const Duration(milliseconds: 50), () {
                                                        focusNode.requestFocus();
                                                      });
                                                    } else {
                                                      // Сохраняем изменения при выходе из режима редактирования
                                                      final newValue = num.tryParse(controller.text);
                                                      _updateWorkItemQuantity(item, newValue);
                                                    }
                                                  });
                                                } : null,
                                                child: isEditing
                                                    ? SizedBox(
                                                        width: 60,
                                                        height: 30,
                                                        child: TextField(
                                                          controller: controller,
                                                          focusNode: focusNode,
                                                          keyboardType: TextInputType.text,
                                                          textAlign: TextAlign.center,
                                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                            color: Theme.of(context).colorScheme.primary,
                                                            fontWeight: FontWeight.w600,
                                                          ),
                                                          decoration: InputDecoration(
                                                            isDense: true,
                                                            contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                                                            enabledBorder: OutlineInputBorder(
                                                              borderSide: BorderSide(
                                                                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                                                                width: 1,
                                                              ),
                                                              borderRadius: BorderRadius.circular(4),
                                                            ),
                                                            focusedBorder: OutlineInputBorder(
                                                              borderSide: BorderSide(
                                                                color: Theme.of(context).colorScheme.primary,
                                                                width: 1.5,
                                                              ),
                                                              borderRadius: BorderRadius.circular(4),
                                                            ),
                                                          ),
                                                          onSubmitted: (value) {
                                                            setState(() {
                                                              _editingItemIndex = null;
                                                              final newValue = num.tryParse(value);
                                                              _updateWorkItemQuantity(item, newValue);
                                                            });
                                                          },
                                                        ),
                                                      )
                                                    : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                                          Text(
                                                            '× ${item.quantity % 1 == 0 ? item.quantity.toInt().toString() : item.quantity.toString()}',
                                                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                              color: Theme.of(context).colorScheme.primary,
                                                              fontWeight: FontWeight.w600,
                                                            ),
                                                          ),
                                                          const SizedBox(width: 2),
                                                          Text(
                                                            item.unit,
                                                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                              color: Theme.of(context).colorScheme.outline,
                                                            ),
                                ),
                              ],
                            ),
                                              ),
                                              // Кнопка удаления работы - показываем только если смена не закрыта
                                              if (!isWorkClosed) ...[
                                                const SizedBox(width: 8),
                                                Material(
                                                  color: Colors.transparent,
                                                  borderRadius: BorderRadius.circular(20),
                                                  child: InkWell(
                                                    borderRadius: BorderRadius.circular(20),
                                                    onTap: () => _confirmDeleteItem(context, ref, item),
                                                    child: MouseRegion(
                                                      cursor: SystemMouseCursors.click,
                                                      child: Container(
                                                        padding: const EdgeInsets.all(6),
                                                        decoration: BoxDecoration(
                                                          borderRadius: BorderRadius.circular(20),
                                                        ),
                                                        child: Icon(
                                                          Icons.delete_outline,
                                                          size: 20,
                                                          color: Theme.of(context).colorScheme.error,
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
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Первая строка: модуль и этаж
                                          Row(
                                            children: [
                                              Expanded(child: _compactMiniInfo('Модуль', item.section)),
                                              Expanded(child: _compactMiniInfo('Этаж', item.floor)),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          // Вторая строка: система и подсистема
                                          Row(
                                            children: [
                                              Expanded(child: _compactMiniInfo('Система', item.system)),
                                              Expanded(child: _compactMiniInfo('Подсистема', item.subsystem)),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          // Цена и сумма
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Flexible(
                                                child: Text.rich(
                                                  TextSpan(
                                                    children: [
                                                      const TextSpan(text: 'Цена: ', style: TextStyle(fontWeight: FontWeight.w500)),
                                                      TextSpan(
                                                        text: '${_formatAmount(item.price ?? 0)} ₽', 
                                                        style: TextStyle(color: Theme.of(context).colorScheme.primary),
                                                      ),
                                                    ],
                                                  ),
                                                  style: Theme.of(context).textTheme.bodySmall,
                                                ),
                                              ),
                                              Flexible(
                                                child: Text.rich(
                                                  TextSpan(
                                                    children: [
                                                      const TextSpan(text: 'Сумма: ', style: TextStyle(fontWeight: FontWeight.w500)),
                                                      TextSpan(
                                                        text: '${_formatAmount(item.total ?? 0)} ₽', 
                                                        style: TextStyle(
                                                          color: Theme.of(context).colorScheme.primary,
                                                          fontWeight: FontWeight.bold
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  style: Theme.of(context).textTheme.bodySmall,
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
                                                    const TextSpan(text: 'Цена: ', style: TextStyle(fontWeight: FontWeight.w500)),
                                                    TextSpan(text: _formatAmount(item.price ?? 0), style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                                                    const TextSpan(text: ' ₽  |  '),
                                                    const TextSpan(text: 'Сумма: ', style: TextStyle(fontWeight: FontWeight.w500)),
                                                    TextSpan(text: _formatAmount(item.total ?? 0), style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                                                    const TextSpan(text: ' ₽'),
                                                  ],
                                                ),
                                                style: Theme.of(context).textTheme.bodySmall,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                  ],
                                  ),
                                ),
                              );
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
        // Кнопка добавления работы - показываем только если смена не закрыта
        if (!isWorkClosed)
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton(
              heroTag: 'addWorkItem',
              mini: true,
              onPressed: () {
                showModalBottomSheet(
                  context: widget.parentContext,
                  isScrollControlled: true,
                  useSafeArea: true,
                  backgroundColor: Colors.transparent,
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(widget.parentContext).size.height -
                        MediaQuery.of(widget.parentContext).padding.top -
                        kToolbarHeight,
                  ),
                  builder: (ctx) => _buildStylizedModalSheet(
                    widget.parentContext,
                    WorkItemFormModal(workId: widget.workId),
                  ),
                );
              },
              child: const Icon(Icons.add),
            ),
          ),
        // Сообщение о закрытой смене, если смена закрыта
        if (isWorkClosed)
          Positioned(
            right: 16,
            bottom: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.lock,
                    size: 16,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Смена закрыта',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildWorkHoursTab() {
    // Получаем смену для проверки статуса
    final workAsync = ref.watch(workProvider(widget.workId));
    final isWorkClosed = workAsync?.status.toLowerCase() == 'closed';
    
    return Stack(
      children: [
        Consumer(
          builder: (context, ref, _) {
            final hoursAsync = ref.watch(workHoursProvider(widget.workId));
            return hoursAsync.when(
              data: (hours) => hours.isEmpty
                  ? const Center(
                      child: Text(
                          'Нет сотрудников в смене. Добавьте сотрудника, нажав на "+"'))
                  : ListView.builder(
                      itemCount: hours.length,
                      padding: const EdgeInsets.all(16),
                      itemBuilder: (context, i) {
                        final hour = hours[i];

                        return FutureBuilder<String>(
                            future: _getEmployeeName(hour.employeeId, ref),
                            builder: (context, snapshot) {
                              final employeeName = snapshot.data ??
                                  'Сотрудник ID: ${hour.employeeId}';

                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .outline
                                        .withValues(alpha: 0.2),
                                    width: 1,
                                  ),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  leading: Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${i + 1}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                      ),
                                    ),
                                  ),
                                  title: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          employeeName,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary
                                              .withValues(alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          '${hour.hours} ч',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  subtitle: hour.comment != null &&
                                          hour.comment!.isNotEmpty
                                      ? Padding(
                                          padding:
                                              const EdgeInsets.only(top: 4),
                                          child: Text(
                                              'Комментарий: ${hour.comment}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                              ),
                                            ),
                                        )
                                      : null,
                                  // Кнопку удаления показываем только если смена не закрыта
                                  trailing: !isWorkClosed 
                                    ? IconButton(
                                        icon: Icon(
                                          Icons.delete_outline,
                                          color: Theme.of(context).colorScheme.error,
                                        ),
                                        onPressed: () => _confirmDeleteHour(context, ref, hour),
                                        tooltip: 'Удалить',
                                      )
                                    : null,
                                  // Редактирование доступно только если смена не закрыта
                                  onTap: !isWorkClosed
                                    ? () {
                                        showModalBottomSheet(
                                          context: widget.parentContext,
                                          isScrollControlled: true,
                                          useSafeArea: true,
                                          backgroundColor: Colors.transparent,
                                          constraints: BoxConstraints(
                                            maxHeight: MediaQuery.of(widget.parentContext).size.height -
                                                MediaQuery.of(widget.parentContext).padding.top -
                                                kToolbarHeight,
                                          ),
                                          builder: (ctx) => _buildStylizedModalSheet(
                                            widget.parentContext,
                                            WorkHourFormModal(
                                              workId: widget.workId,
                                              initial: hour,
                                            ),
                                          ),
                                        );
                                      }
                                    : null,
                                ),
                              );
                            });
                      },
                    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('Ошибка: $e')),
            );
          },
        ),
        // Кнопка добавления часов - показываем только если смена не закрыта
        if (!isWorkClosed)
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton(
              heroTag: 'addWorkHour',
              mini: true,
              onPressed: () {
                showModalBottomSheet(
                  context: widget.parentContext,
                  isScrollControlled: true,
                  useSafeArea: true,
                  backgroundColor: Colors.transparent,
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(widget.parentContext).size.height -
                        MediaQuery.of(widget.parentContext).padding.top -
                        kToolbarHeight,
                  ),
                  builder: (ctx) => _buildStylizedModalSheet(
                    widget.parentContext,
                    WorkHourFormModal(workId: widget.workId),
                  ),
                );
              },
              child: const Icon(Icons.add),
            ),
          ),
        // Сообщение о закрытой смене, если смена закрыта
        if (isWorkClosed)
          Positioned(
            right: 16,
            bottom: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.lock,
                    size: 16,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Смена закрыта',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // Кэш имен сотрудников
  final Map<String, String> _employeeNameCache = {};

  // Получает имя сотрудника из кэша или из репозитория
  Future<String> _getEmployeeName(String employeeId, WidgetRef ref) async {
    // Проверяем кэш
    if (_employeeNameCache.containsKey(employeeId)) {
      return _employeeNameCache[employeeId]!;
    }

    // Ищем в текущем списке
    final employees = ref.read(employee_state.employeeProvider).employees;
    final employee = employees.where((e) => e.id == employeeId).toList().isEmpty
        ? null
        : employees.firstWhere((e) => e.id == employeeId);

    if (employee != null) {
      // Форматируем ФИО с поддержкой отчества
      final name =
          '${employee.lastName} ${employee.firstName}${employee.middleName != null && employee.middleName!.isNotEmpty ? ' ${employee.middleName}' : ''}';
      _employeeNameCache[employeeId] = name;
      return name;
    }

    // Если сотрудник не найден в списке, делаем запрос к репозиторию
    try {
      await ref
          .read(employee_state.employeeProvider.notifier)
          .getEmployee(employeeId);
      final updatedEmployees =
          ref.read(employee_state.employeeProvider).employees;
      final updatedEmployee =
          updatedEmployees.where((e) => e.id == employeeId).toList().isEmpty
              ? null
              : updatedEmployees.firstWhere((e) => e.id == employeeId);

      if (updatedEmployee != null) {
        // Форматируем ФИО с поддержкой отчества
        final name =
            '${updatedEmployee.lastName} ${updatedEmployee.firstName}${updatedEmployee.middleName != null && updatedEmployee.middleName!.isNotEmpty ? ' ${updatedEmployee.middleName}' : ''}';
        _employeeNameCache[employeeId] = name;
        return name;
      }
    } catch (e) {
      debugPrint('Error fetching employee $employeeId: $e');
    }

    return 'Сотрудник ID: $employeeId';
  }

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

  /// Возвращает текст и цвет статуса смены.
  (String, Color) _getWorkStatusInfo(String status) {
    final theme = Theme.of(context);
    switch (status.toLowerCase()) {
      case 'open':
        return ('Открыта', theme.colorScheme.primary);
      case 'closed':
        return ('Закрыта', theme.colorScheme.outline);
      default:
        return (status, theme.colorScheme.secondary);
    }
  }

  void _confirmDeleteItem(BuildContext context, WidgetRef ref, WorkItem item) {
    // Получаем смену для проверки статуса
    final workAsync = ref.read(workProvider(widget.workId));
    final isWorkClosed = workAsync?.status.toLowerCase() == 'closed';
    
    // Если смена закрыта, не разрешаем удаление
    if (isWorkClosed) {
      SnackBarUtils.showError(context, 'Удаление работ невозможно, так как смена закрыта');
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
              await ref.read(workItemsProvider(widget.workId).notifier).delete(item.id);
              
              // После удаления получаем обновленный список элементов и обновляем фильтры
              if (mounted) {
                final updatedItems = ref.read(workItemsProvider(widget.workId)).valueOrNull ?? [];
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

  void _confirmDeleteHour(BuildContext context, WidgetRef ref, WorkHour hour) {
    // Получаем смену для проверки статуса
    final workAsync = ref.read(workProvider(widget.workId));
    final isWorkClosed = workAsync?.status.toLowerCase() == 'closed';
    
    // Если смена закрыта, не разрешаем удаление
    if (isWorkClosed) {
      SnackBarUtils.showError(context, 'Удаление сотрудников невозможно, так как смена закрыта');
      return;
    }
    
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => CupertinoAlertDialog(
        title: const Text('Подтверждение'),
        content: const Text('Вы действительно хотите удалить сотрудника из смены?'),
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
            onPressed: () {
              ref.read(workHoursProvider(widget.workId).notifier).delete(hour.id);
              Navigator.of(context).pop();
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
      margin: isDesktop
        ? const EdgeInsets.only(top: 48)
        : EdgeInsets.only(top: kToolbarHeight + MediaQuery.of(context).padding.top),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, -8),
          ),
        ],
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.12),
          width: 1.5,
        ),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 1.0,
        minChildSize: 0.5,
        maxChildSize: 1.0,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(widget.parentContext).viewInsets.bottom,
            ),
            child: content,
          ),
        ),
      ),
    );

    if (isDesktop) {
      // Для десктопа - ограничиваем ширину и центрируем с анимацией
      return Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: screenWidth * 0.5, // 50% от ширины экрана
                ),
                child: modalContent,
              ),
      );
    } else {
      // Для мобильных - без дополнительных изменений, так как constraints
      // определяются в вызове showModalBottomSheet
      return modalContent;
    }
  }

  Widget _buildDataTab(Work work, String objectDisplay) {
    final theme = Theme.of(context);
    final isMobile = !ResponsiveUtils.isDesktop(context);
    
    return Consumer(
      builder: (context, ref, _) {
        // Получаем работы в смене
        final itemsAsync = ref.watch(workItemsProvider(widget.workId));
        // Получаем сотрудников в смене
        final hoursAsync = ref.watch(workHoursProvider(widget.workId));
        
        // Проверяем, закрыта ли смена
        final isWorkClosed = work.status.toLowerCase() == 'closed';
        
        return itemsAsync.when(
          data: (items) {
            return hoursAsync.when(
              data: (hours) {
                // Проверяем условия для закрытия смены
                final canCloseWorkFuture = _canCloseWork(work, items, hours);
                
                // Количество работ
                final worksCount = items.length;
                
                // Количество сотрудников (уникальных)
                final uniqueEmployees = hours.map((h) => h.employeeId).toSet().length;
                
                // Общая сумма смены
                final totalAmount = items.fold<double>(
                  0, 
                  (sum, item) => sum + (item.total ?? 0)
                );
                
                // Выработка на сотрудника
                final productivityPerEmployee = uniqueEmployees > 0 
                  ? totalAmount / uniqueEmployees 
                  : 0.0;
                
                // Форматирование чисел
                final formatter = NumberFormat('#,##0.00', 'ru_RU');
                
                // В десктопном режиме показываем информацию в две колонки
                if (!isMobile) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Сводная информация',
                          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Блок с кнопкой закрытия смены или информацией о том, что смена закрыта
                        FutureBuilder<(bool, String?)>(
                          future: canCloseWorkFuture,
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const Center(child: CircularProgressIndicator());
                            }
                            
                            final (canClose, message) = snapshot.data!;
                            
                            if (isWorkClosed) {
                              // Если смена уже закрыта, показываем информационное сообщение
                              return Container(
                                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: theme.colorScheme.error.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.lock,
                                      color: theme.colorScheme.error,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Text(
                                        'Смена закрыта и доступна только для просмотра',
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.w500,
                                          color: theme.colorScheme.error,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            } else if (canClose) {
                              // Если все условия для закрытия выполнены, показываем кнопку закрытия
                              return ElevatedButton.icon(
                                onPressed: () {
                                  _showCloseWorkConfirmation(work);
                                },
                                icon: const Icon(Icons.lock_outline),
                                label: const Text('Закрыть смену'),
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(44),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  backgroundColor: theme.colorScheme.error,
                                  foregroundColor: theme.colorScheme.onError,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              );
                            } else {
                              // Если условия не выполнены, показываем предупреждение
                              return Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: theme.colorScheme.error.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.warning_amber_rounded,
                                          color: theme.colorScheme.error,
                                          size: 24,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            'Невозможно закрыть смену',
                                            style: theme.textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.w600,
                                              color: theme.colorScheme.error,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Для закрытия смены требуется выполнить следующие условия:',
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    _buildCheckItem('Наличие хотя бы одной работы', items.isNotEmpty),
                                    _buildCheckItem('Наличие хотя бы одного сотрудника', hours.isNotEmpty),
                                    _buildCheckItem(
                                      'У всех работ указано количество', 
                                      items.isNotEmpty && !items.any((item) => item.quantity <= 0)
                                    ),
                                    _buildCheckItem(
                                      'У всех сотрудников проставлены часы', 
                                      hours.isNotEmpty && !hours.any((hour) => hour.hours <= 0)
                                    ),
                                    _buildCheckItem(
                                      'Добавлено вечернее фото', 
                                      work.eveningPhotoUrl != null && work.eveningPhotoUrl!.isNotEmpty
                                    ),
                                    if (work.eveningPhotoUrl == null || work.eveningPhotoUrl!.isEmpty) ...[
                                      const SizedBox(height: 16),
                                      ElevatedButton.icon(
                                        onPressed: () => _showEveningPhotoOptions(work),
                                        icon: const Icon(Icons.photo_camera),
                                        label: const Text('Добавить вечернее фото'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: theme.colorScheme.primary,
                                          foregroundColor: theme.colorScheme.onPrimary,
                                        ),
                                      ),
                                    ],
                                    if (message != null) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        message,
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: theme.colorScheme.error,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            }
                          },
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Основная информация - в две колонки
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Левая колонка - основная информация
                            Expanded(
                              child: Card(
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(
                                    color: theme.colorScheme.outline.withValues(alpha: 0.2),
                                    width: 1,
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Общая информация',
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: theme.colorScheme.primary,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      _buildDataRow(
                                        icon: Icons.calendar_today,
                                        label: 'Дата:',
                                        value: _formatDate(work.date),
                                      ),
                                      const Divider(height: 32),
                                      _buildDataRow(
                                        icon: Icons.business,
                                        label: 'Объект:',
                                        value: objectDisplay,
                                      ),
                                      const Divider(height: 32),
                                      _buildDataRow(
                                        icon: Icons.person,
                                        label: 'Открыл:',
                                        value: FutureBuilder<Profile?>(
                                          future: ref.read(profileRepositoryProvider).getProfile(work.openedBy),
                                          builder: (context, snapshot) {
                                            final String openedBy = snapshot.hasData && snapshot.data?.shortName != null
                                              ? snapshot.data!.shortName!
                                              : 'ID: ${work.openedBy.length > 4 ? "${work.openedBy.substring(0, 4)}..." : work.openedBy}';
                                            return Text(
                                              openedBy,
                                              style: theme.textTheme.titleMedium,
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            
                            const SizedBox(width: 16),
                            
                            // Правая колонка - статистика
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Карточка статистики
                                  Card(
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      side: BorderSide(
                                        color: theme.colorScheme.outline.withValues(alpha: 0.2),
                                        width: 1,
                                      ),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(24),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Производственные показатели',
                                            style: theme.textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: theme.colorScheme.primary,
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          
                                          // Количество работ - с визуалом
                                          _buildMetricCard(
                                            icon: Icons.work,
                                            label: 'Работ',
                                            value: worksCount.toString(),
                                            iconColor: theme.colorScheme.tertiary,
                                          ),
                                          
                                          const SizedBox(height: 16),
                                          
                                          // Количество сотрудников - с визуалом
                                          _buildMetricCard(
                                            icon: Icons.groups,
                                            label: 'Сотрудников',
                                            value: uniqueEmployees.toString(),
                                            iconColor: theme.colorScheme.secondary,
                                          ),
                                          
                                          const SizedBox(height: 16),
                                          
                                          // Общая сумма - с визуальным выделением
                                          _buildMetricCard(
                                            icon: Icons.paid,
                                            label: 'Общая сумма',
                                            value: '${formatter.format(totalAmount)} ₽',
                                            iconColor: theme.colorScheme.primary,
                                            isLarge: true,
                                          ),
                                          
                                          const SizedBox(height: 16),
                                          
                                          // Выработка на сотрудника - с визуалом
                                          _buildMetricCard(
                                            icon: Icons.trending_up,
                                            label: 'Выработка на сотрудника',
                                            value: '${formatter.format(productivityPerEmployee)} ₽/чел.',
                                            iconColor: theme.colorScheme.tertiary,
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
                        
                        const SizedBox(height: 24),
                        
                        // График распределения работ
                        if (items.isNotEmpty) 
                          _buildWorkDistributionCard(items),
                        
                        const SizedBox(height: 24),
                        
                        // Фотографии смены (перемещены после графика распределения работ)
                        WorkPhotoView(work: work),
                        
                        const SizedBox(height: 24),
                      ],
                    ),
                  );
                }
                
                // Мобильный режим - оставляем однолонный вид для удобства
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Сводная информация',
                            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),

                          const SizedBox(height: 24),
                          
                          // Блок с кнопкой закрытия смены или информацией о том, что смена закрыта
                          FutureBuilder<(bool, String?)>(
                            future: canCloseWorkFuture,
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return const Center(child: CircularProgressIndicator());
                              }
                              
                              final (canClose, message) = snapshot.data!;
                              
                              if (isWorkClosed) {
                                // Если смена уже закрыта, показываем информационное сообщение
                                return Container(
                                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: theme.colorScheme.error.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.lock,
                                        color: theme.colorScheme.error,
                                        size: 24,
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Text(
                                          'Смена закрыта и доступна только для просмотра',
                                          style: theme.textTheme.titleSmall?.copyWith(
                                            fontWeight: FontWeight.w500,
                                            color: theme.colorScheme.error,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              } else if (canClose) {
                                // Если все условия для закрытия выполнены, показываем кнопку закрытия
                                return ElevatedButton.icon(
                                  onPressed: () {
                                    _showCloseWorkConfirmation(work);
                                  },
                                  icon: const Icon(Icons.lock_outline),
                                  label: const Text('Закрыть смену'),
                                  style: ElevatedButton.styleFrom(
                                    minimumSize: const Size.fromHeight(44),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    backgroundColor: theme.colorScheme.primary,
                                    foregroundColor: theme.colorScheme.onPrimary,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                );
                              } else {
                                // Если условия не выполнены, показываем предупреждение
                                return Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: theme.colorScheme.error.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.warning_amber_rounded,
                                            color: theme.colorScheme.error,
                                            size: 24,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              'Невозможно закрыть смену',
                                              style: theme.textTheme.titleMedium?.copyWith(
                                                fontWeight: FontWeight.w600,
                                                color: theme.colorScheme.error,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Для закрытия смены требуется выполнить следующие условия:',
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      _buildCheckItem('Наличие хотя бы одной работы', items.isNotEmpty),
                                      _buildCheckItem('Наличие хотя бы одного сотрудника', hours.isNotEmpty),
                                      _buildCheckItem(
                                        'У всех работ указано количество', 
                                        items.isNotEmpty && !items.any((item) => item.quantity <= 0)
                                      ),
                                      _buildCheckItem(
                                        'У всех сотрудников проставлены часы', 
                                        hours.isNotEmpty && !hours.any((hour) => hour.hours <= 0)
                                      ),
                                      _buildCheckItem(
                                        'Добавлено вечернее фото', 
                                        work.eveningPhotoUrl != null && work.eveningPhotoUrl!.isNotEmpty
                                      ),
                                      if (work.eveningPhotoUrl == null || work.eveningPhotoUrl!.isEmpty) ...[
                                        const SizedBox(height: 16),
                                        ElevatedButton.icon(
                                          onPressed: () => _showEveningPhotoOptions(work),
                                          icon: const Icon(Icons.photo_camera),
                                          label: const Text('Добавить вечернее фото'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: theme.colorScheme.primary,
                                            foregroundColor: theme.colorScheme.onPrimary,
                                          ),
                                        ),
                                      ],
                                      if (message != null) ...[
                                        const SizedBox(height: 8),
                                        Text(
                                          message,
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: theme.colorScheme.error,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                );
                              }
                            },
                          ),
                          
                          const SizedBox(height: 32),
                          
                          // Карточка с данными
                          Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                color: theme.colorScheme.outline.withValues(alpha: 0.2),
                                width: 1,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildDataRow(
                                    icon: Icons.calendar_today,
                                    label: 'Дата:',
                                    value: _formatDate(work.date),
                                  ),
                                  const Divider(height: 32),
                                  _buildDataRow(
                                    icon: Icons.business,
                                    label: 'Объект:',
                                    value: objectDisplay,
                                  ),
                                  const Divider(height: 32),
                                  _buildDataRow(
                                    icon: Icons.person,
                                    label: 'Открыл:',
                                    value: FutureBuilder<Profile?>(
                                      future: ref.read(profileRepositoryProvider).getProfile(work.openedBy),
                                      builder: (context, snapshot) {
                                        final String openedBy = snapshot.hasData && snapshot.data?.shortName != null
                                          ? snapshot.data!.shortName!
                                          : 'ID: ${work.openedBy.length > 4 ? "${work.openedBy.substring(0, 4)}..." : work.openedBy}';
                                        return Text(
                                          openedBy,
                                          style: theme.textTheme.titleMedium,
                                        );
                                      },
                                    ),
                                  ),
                                  const Divider(height: 32),
                                  _buildDataRow(
                                    icon: Icons.groups,
                                    label: 'Сотрудников:',
                                    value: '$uniqueEmployees чел.',
                                    iconColor: theme.colorScheme.primary,
                                  ),
                                  const Divider(height: 32),
                                  _buildDataRow(
                                    icon: Icons.work,
                                    label: 'Работ:',
                                    value: '$worksCount шт.',
                                    iconColor: theme.colorScheme.primary,
                                  ),
                                  const Divider(height: 32),
                                  _buildDataRow(
                                    icon: Icons.paid,
                                    label: 'Общая сумма:',
                                    value: '${formatter.format(totalAmount)} ₽',
                                    textColor: theme.colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                  ),
                                  const Divider(height: 32),
                                  _buildDataRow(
                                    icon: Icons.trending_up,
                                    label: 'Выработка на сотрудника:',
                                    value: '${formatter.format(productivityPerEmployee)} ₽/чел.',
                                    iconColor: theme.colorScheme.tertiary,
                                    textColor: theme.colorScheme.tertiary,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          
                          
                          // Распределение работ по системам
                          if (items.isNotEmpty) ...[
                            const SizedBox(height: 32),
                            _buildWorkDistributionCard(items),
                          ],
                          
                          // Фотографии смены (перемещены после распределения работ)
                          const SizedBox(height: 32),
                          WorkPhotoView(work: work),
                        ],
                      ),
                    ),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('Ошибка загрузки сотрудников: $e')),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => Center(child: Text('Ошибка загрузки работ: $e')),
        );
      },
    );
  }
  
  // Вспомогательный метод для отображения элемента проверки условия
  Widget _buildCheckItem(String text, bool isCompleted) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            isCompleted ? Icons.check_circle : Icons.cancel,
            color: isCompleted ? Colors.green : theme.colorScheme.error,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isCompleted ? null : theme.colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDataRow({
    required IconData icon,
    required String label,
    required dynamic value,
    Color? iconColor,
    Color? textColor,
    FontWeight fontWeight = FontWeight.w500,
    double fontSize = 16,
  }) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          icon,
          color: iconColor ?? theme.colorScheme.onSurfaceVariant,
          size: 24,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              if (value is Widget)
                value
              else
                Text(
                  value.toString(),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: fontWeight,
                    fontSize: fontSize,
                    color: textColor,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
  


  // Создает визуальную метрику для статистики в красивой карточке
  Widget _buildMetricCard({
    required IconData icon,
    required String label,
    required String value,
    Color? iconColor,
    bool isLarge = false,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (iconColor ?? theme.colorScheme.primary).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: iconColor ?? theme.colorScheme.primary,
              size: isLarge ? 28 : 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: isLarge ? 22 : 18,
                    color: isLarge ? theme.colorScheme.primary : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkDistributionCard(List<WorkItem> items) {
    final theme = Theme.of(context);
    final numberFormat = NumberFormat('#,##0.00', 'ru_RU');
    
    // Группировка работ по системам
    final systemGroups = <String, int>{};
    
    // Группировка сумм по системам
    final systemSums = <String, double>{};
    
    for (final item in items) {
      // Подсчет количества работ
      systemGroups[item.system] = (systemGroups[item.system] ?? 0) + 1;
      
      // Подсчет сумм работ
      systemSums[item.system] = (systemSums[item.system] ?? 0) + (item.total ?? 0);
    }
    
    // Сортировка систем по количеству работ
    final sortedSystems = systemGroups.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    // Максимальное значение для нормализации
    final maxValue = sortedSystems.isNotEmpty ? sortedSystems.first.value.toDouble() : 1.0;
    
    // Общее количество работ для расчёта процентов
    final totalItems = items.length.toDouble();
    
    // Общая сумма для расчета процентов
    final totalSum = systemSums.values.fold<double>(0, (sum, value) => sum + value);
    
    // Кастомная цветовая палитра для диаграммы - яркие контрастные цвета
    final List<Color> colors = [
      const Color(0xFF2196F3), // Синий
      const Color(0xFF4CAF50), // Зеленый
      const Color(0xFFFF9800), // Оранжевый
      const Color(0xFF9C27B0), // Фиолетовый
      const Color(0xFFF44336), // Красный
    ];
    
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Распределение работ по системам',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            ...sortedSystems.take(5).toList().asMap().entries.map((entry) {
              final index = entry.key;
              final systemEntry = entry.value;
              final progress = systemEntry.value / maxValue;
              final systemName = systemEntry.key;
              final itemCount = systemEntry.value;
              final systemSum = systemSums[systemName] ?? 0;
              
              // Процент от общего количества и от общей суммы
              final countPercent = totalItems > 0 ? itemCount / totalItems : 0.0;
              final sumPercent = totalSum > 0 ? systemSum / totalSum : 0.0;
              
              // Цвет для этой системы
              final color = colors[index % colors.length];
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Процентный кружок
                        _buildPercentageCircle(countPercent, color, '${(countPercent * 100).round()}%'),
                        
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      systemName,
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '$itemCount шт. (${(countPercent * 100).round()}%)',
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        '${numberFormat.format(systemSum)} ₽ (${(sumPercent * 100).round()}%)',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: color,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  minHeight: 8,
                                  backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                                  valueColor: AlwaysStoppedAnimation<Color>(color),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
            
            // Общая сумма всех работ
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      margin: const EdgeInsets.only(right: 12),
                      child: Icon(
                        Icons.data_usage_rounded,
                        color: theme.colorScheme.primary,
                        size: 24,
                      ),
                    ),
                    Text(
                      'Общая сумма:',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${numberFormat.format(totalSum)} ₽',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  

  
  // Виджет для отображения процентного круга
  Widget _buildPercentageCircle(double percentage, Color color, String label) {
    return Container(
      width: 40,
      height: 40,
      margin: const EdgeInsets.only(right: 12),
      child: Stack(
        children: [
          // Круг с процентным заполнением
          CustomPaint(
            size: const Size(40, 40),
            painter: CirclePercentPainter(
              percentage: percentage,
              color: color,
              backgroundColor: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
              fillColor: Theme.of(context).colorScheme.surface,
              strokeWidth: 4,
            ),
          ),
          // Текст с процентами
          Center(
            child: Text(
              '${(percentage * 100).round()}%',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Проверяет, возможно ли закрыть смену и возвращает пару (bool, String?) с флагом и сообщением.
  /// Проверяет, возможно ли закрыть смену
  Future<(bool, String?)> _canCloseWork(Work work, List<WorkItem> workItems, List<WorkHour> workHours) async {
    // Если смена уже закрыта, возвращаем false
    if (work.status.toLowerCase() == 'closed') {
      return (false, 'Смена уже закрыта');
    }
    
    // Проверяем, что есть хотя бы одна работа
    if (workItems.isEmpty) {
      return (false, 'Невозможно закрыть смену без работ');
    }
    
    // Проверяем, что есть хотя бы один сотрудник
    if (workHours.isEmpty) {
      return (false, 'Невозможно закрыть смену без сотрудников');
    }
    
    // Проверяем, что у всех работ указано количество
    final invalidWorkItems = workItems.where((item) => item.quantity <= 0).toList();
    if (invalidWorkItems.isNotEmpty) {
      return (false, 'У некоторых работ не указано количество. Необходимо заполнить все поля количества перед закрытием смены.');
    }
    
    // Проверяем, что у всех сотрудников проставлены часы
    final invalidWorkHours = workHours.where((hour) => hour.hours <= 0).toList();
    if (invalidWorkHours.isNotEmpty) {
      return (false, 'У некоторых сотрудников не указаны часы. Необходимо заполнить все поля часов перед закрытием смены.');
    }
    
    // Проверяем наличие вечернего фото
    if (work.eveningPhotoUrl == null || work.eveningPhotoUrl!.isEmpty) {
      return (false, 'Необходимо добавить вечернее фото перед закрытием смены.');
    }
    
    return (true, null);
  }
  
  /// Обрабатывает закрытие смены
  Future<void> _closeWork(Work work) async {
    final workNotifier = ref.read(worksProvider.notifier);
    
    // Создаем обновленную смену со статусом "closed"
    final updatedWork = work.copyWith(
      status: 'closed',
      updatedAt: DateTime.now(),
    );
    
    try {
      // Обновляем смену в БД
      await workNotifier.updateWork(updatedWork);
      
      // Выводим сообщение об успешном закрытии
      if (mounted) {
        SnackBarUtils.showSuccess(context, 'Смена успешно закрыта');
      }
    } catch (e) {
      // В случае ошибки выводим сообщение
      if (mounted) {
        SnackBarUtils.showError(context, 'Ошибка при закрытии смены: $e');
      }
    }
  }
  
  /// Показывает диалог подтверждения закрытия смены
  void _showCloseWorkConfirmation(Work work) {
    CupertinoDialogs.showConfirmDialog<bool>(
      context: context,
      title: 'Подтверждение закрытия смены',
      message: '''После закрытия смены будет невозможно:
• Добавлять/удалять работы и сотрудников
• Изменять количество работ и часы
• Редактировать фотографии

Вы уверены, что хотите закрыть смену?''',
      confirmButtonText: 'Закрыть смену',
      isDestructiveAction: true,
      onConfirm: () async => await _closeWork(work),
    );
  }

  Widget _miniInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Row(
        children: [
          Text('$label: ', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.outline)),
          Text(value, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // Добавляем новый вспомогательный виджет для компактного отображения информации на мобильных устройствах
  Widget _compactMiniInfo(String label, String? value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          Flexible(
            child: Text(
              value?.isNotEmpty == true ? value! : '-',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// Показывает диалог выбора источника вечернего фото
  void _showEveningPhotoOptions(Work work) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Вечернее фото смены',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _PhotoOptionButton(
                  icon: Icons.photo_camera,
                  label: 'Камера',
                  onTap: () {
                    Navigator.pop(context);
                    _pickEveningPhoto(ImageSource.camera, work);
                  },
                ),
                _PhotoOptionButton(
                  icon: Icons.photo_library,
                  label: 'Галерея',
                  onTap: () {
                    Navigator.pop(context);
                    _pickEveningPhoto(ImageSource.gallery, work);
                  },
                ),
                if (work.eveningPhotoUrl != null && work.eveningPhotoUrl!.isNotEmpty)
                  _PhotoOptionButton(
                    icon: Icons.delete_outline,
                    label: 'Удалить',
                    onTap: () async {
                      Navigator.pop(context);
                      // Удаляем фото
                      final updatedWork = work.copyWith(
                        eveningPhotoUrl: null,
                        updatedAt: DateTime.now(),
                      );
                      await ref.read(worksProvider.notifier).updateWork(updatedWork);
                    },
                  ),
              ],
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
          ],
        ),
      ),
    );
  }

  /// Выбирает и загружает вечернее фото
  Future<void> _pickEveningPhoto(ImageSource source, Work work) async {
    final photoService = ref.read(photoServiceProvider);
    final file = await photoService.pickImage(source);
    if (file == null) return;
    if (!mounted) return;
    
    // Показываем диалог подтверждения выбранного фото
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        contentPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(file, fit: BoxFit.contain, height: 240),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Отмена'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Сохранить'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    
    if (confirmed != true) return;
    
    // Загружаем фото и получаем URL
    final url = await photoService.uploadPhoto(
      entity: 'work',
      id: work.id ?? '',
      file: file,
      displayName: 'evening',
    );
    
    if (url != null) {
      // Обновляем работу с новым URL вечернего фото
      final updatedWork = work.copyWith(
        eveningPhotoUrl: url,
        updatedAt: DateTime.now(),
      );
      await ref.read(worksProvider.notifier).updateWork(updatedWork);
      if (!mounted) return;
    }
  }
}

// Кастомный painter для рисования процентного круга (progress circle).
///
/// Используется для визуализации процента выполнения в виде дуги.
class CirclePercentPainter extends CustomPainter {
  /// Процент заполнения (0.0 - 1.0).
  final double percentage;
  /// Цвет дуги.
  final Color color;
  /// Толщина линии.
  final double strokeWidth;
  /// Цвет фона круга.
  final Color backgroundColor;
  /// Цвет заливки внутреннего круга.
  final Color fillColor;

  /// Создаёт painter для процентного круга.
  CirclePercentPainter({
    required this.percentage,
    required this.color,
    required this.backgroundColor,
    required this.fillColor,
    this.strokeWidth = 4.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - strokeWidth / 2;
    
    // Рисуем фоновый круг
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    
    canvas.drawCircle(center, radius, backgroundPaint);
    
    // Рисуем дугу с процентами
    final foregroundPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    
    final sweepAngle = 2 * math.pi * percentage;
    
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, // Начинаем с верхней точки
      sweepAngle,
      false,
      foregroundPaint,
    );
    
    // Добавляем заливку внутреннего круга для лучшего контраста
    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(center, radius - strokeWidth, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CirclePercentPainter oldDelegate) {
    return oldDelegate.percentage != percentage || 
           oldDelegate.color != color || 
           oldDelegate.strokeWidth != strokeWidth ||
           oldDelegate.backgroundColor != backgroundColor ||
           oldDelegate.fillColor != fillColor;
  }
}

/// Виджет-кнопка для выбора действий с фото
class _PhotoOptionButton extends StatelessWidget {
  /// Иконка действия.
  final IconData icon;
  /// Подпись действия.
  final String label;
  /// Коллбэк нажатия.
  final VoidCallback onTap;
  
  /// Создаёт кнопку выбора действия с фото.
  const _PhotoOptionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: CircleAvatar(
            radius: 24,
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: Icon(icon, color: Theme.of(context).colorScheme.onPrimary, size: 24),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
