import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/work_item.dart';
import '../providers/work_items_provider.dart';
import '../../../../core/di/providers.dart';
import '../../../../domain/entities/estimate.dart';
import 'package:uuid/uuid.dart';
import '../providers/work_provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'dart:developer' as developer;

/// Модальное окно для создания или редактирования работы (WorkItem).
///
/// Позволяет выбрать участок, этаж, систему, подсистему и добавить работы из сметы с указанием количества.
/// Использует Riverpod для управления состоянием, поддерживает редактирование и создание новых работ.
class WorkItemFormModal extends ConsumerStatefulWidget {
  /// Идентификатор смены, к которой относится работа.
  final String workId;
  /// Исходная работа для редактирования (null — создание новой).
  final WorkItem? initial;
  /// Создаёт модальное окно для добавления или редактирования работы.
  const WorkItemFormModal({super.key, required this.workId, this.initial});

  @override
  ConsumerState<WorkItemFormModal> createState() => _WorkItemFormModalState();
}

/// Состояние для [WorkItemFormModal].
///
/// Управляет формой, контроллерами, фильтрацией смет, выбором систем и подсистем, а также сохранением выбранных работ.
class _WorkItemFormModalState extends ConsumerState<WorkItemFormModal> {
  /// Ключ формы для валидации.
  final _formKey = GlobalKey<FormState>();
  
  /// Выбранный участок (модуль).
  String? _selectedSection;
  /// Выбранный этаж.
  String? _selectedFloor;
  /// Выбранная система.
  String? _selectedSystem;
  /// Выбранная подсистема.
  String? _selectedSubsystem;
  
  /// Контроллер для поля "Система".
  final TextEditingController _systemController = TextEditingController();
  /// Контроллер для поля "Подсистема".
  final TextEditingController _subsystemController = TextEditingController();
  /// Контроллер для поля "Участок".
  final TextEditingController _sectionController = TextEditingController();
  /// Контроллер для поля "Этаж".
  final TextEditingController _floorController = TextEditingController();
  
  /// Отфильтрованные сметные работы по выбранным параметрам.
  List<Estimate> _filteredEstimates = [];
  
  /// Карта выбранных работ из сметы и их количества.
  final Map<Estimate, double?> _selectedEstimateItems = {};
  /// Контроллеры для ввода количества по каждой работе.
  final Map<Estimate, TextEditingController> _quantityControllers = {};
  
  /// Идентификатор объекта (строительного).
  late String objectId;
  
  /// Текущий поисковый запрос по работам.
  String _searchQuery = '';
  
  /// Признак режима редактирования (true — редактирование, false — создание).
  bool get isModifying => widget.initial != null;
  
  @override
  void initState() {
    super.initState();
    final work = ref.read(workProvider(widget.workId));
    objectId = work?.objectId ?? '';
    if (objectId.isEmpty) {
      throw Exception('objectId не найден для данной смены');
    }
    if (isModifying) {
      _selectedSection = widget.initial!.section;
      _selectedFloor = widget.initial!.floor;
      _selectedSystem = widget.initial!.system;
      _selectedSubsystem = widget.initial!.subsystem;
      _sectionController.text = _selectedSection ?? '';
      _floorController.text = _selectedFloor ?? '';
      _systemController.text = _selectedSystem ?? '';
      _subsystemController.text = _selectedSubsystem ?? '';
    }
    
    // Загружаем сметы, если ещё не загружены
    Future.microtask(() {
      if (ref.read(estimateNotifierProvider).estimates.isEmpty) {
        ref.read(estimateNotifierProvider.notifier).loadEstimates();
      }
    });
  }
  
  @override
  void dispose() {
    for (final controller in _quantityControllers.values) {
      controller.dispose();
    }
    _systemController.dispose();
    _subsystemController.dispose();
    _sectionController.dispose();
    _floorController.dispose();
    super.dispose();
  }
  
  /// Обновляет список сметных работ по выбранным фильтрам (система, подсистема, объект).
  void _updateFilteredEstimates() {
    final allEstimates = ref.read(estimateNotifierProvider).estimates;
    final filteredList = allEstimates.where((estimate) {
      if (estimate.objectId != objectId) return false;
      if (_selectedSystem != null && _selectedSystem!.isNotEmpty && estimate.system != _selectedSystem) return false;
      if (_selectedSubsystem != null && _selectedSubsystem!.isNotEmpty && estimate.subsystem != _selectedSubsystem) return false;
      return true;
    }).toList();
    
    setState(() {
      _filteredEstimates = filteredList;
    });
  }
  
  /// Получает список доступных участков (модулей) из всех работ.
  Future<List<String>> _getAvailableSections() async {
    final workItemsNotifier = ref.read(workItemsNotifierProvider);
    final items = await workItemsNotifier.getAllWorkItems();
    return items.map((e) => e.section).where((e) => e.isNotEmpty).toSet().toList();
  }
  
  /// Получает список доступных этажей для выбранного участка.
  Future<List<String>> _getAvailableFloors() async {
    final workItemsNotifier = ref.read(workItemsNotifierProvider);
    final items = await workItemsNotifier.getAllWorkItems();
    
    if (_selectedSection != null && _selectedSection!.isNotEmpty) {
      return items
          .where((e) => e.section == _selectedSection)
          .map((e) => e.floor)
          .where((e) => e.isNotEmpty)
          .toSet()
          .toList();
    }
    return items.map((e) => e.floor).where((e) => e.isNotEmpty).toSet().toList();
  }
  
  /// Сохраняет выбранные работы из сметы с указанным количеством.
  /// Если не выбрано ни одной работы — показывает ошибку.
  Future<void> _saveSelectedItems() async {
    if (_selectedEstimateItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите хотя бы одну работу из сметы'))
      );
      return;
    }
    
    final workItemsNotifier = ref.read(workItemsProvider(widget.workId).notifier);
    
    for (final entry in _selectedEstimateItems.entries) {
      final estimate = entry.key;
      final quantity = entry.value ?? 0.0;
      
      final workItem = WorkItem(
        id: const Uuid().v4(),
        workId: widget.workId,
        section: _selectedSection ?? '',
        floor: _selectedFloor ?? '',
        estimateId: estimate.id,
        name: estimate.name,
        system: estimate.system,
        subsystem: estimate.subsystem,
        unit: estimate.unit,
        quantity: quantity,
        price: estimate.price,
        total: estimate.price * quantity,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      developer.log('DEBUG: workItem.toJson() = [38;5;2m${workItem.toJson()}[0m', name: 'work_item_form_modal');
      await workItemsNotifier.add(workItem);
    }
    
    if (mounted) Navigator.pop(context);
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSectionFilled = _selectedSection != null && _selectedSection!.isNotEmpty;
    final isFloorFilled = _selectedFloor != null && _selectedFloor!.isNotEmpty;
    final isSystemFilled = _selectedSystem != null && _selectedSystem!.isNotEmpty;
    final isSubsystemFilled = _selectedSubsystem != null && _selectedSubsystem!.isNotEmpty;
    
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Заголовок с кнопкой закрытия
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.initial == null ? 'Добавить работы' : 'Редактировать работу',
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      style: IconButton.styleFrom(foregroundColor: Colors.red),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(),
              // Карточка с основным содержимым
              Card(
                margin: EdgeInsets.zero,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: theme.colorScheme.outline.withValues(alpha: 51),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Информационный заголовок
                        Text('Информация о работе', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        // Участок (модуль) - TypeAheadField
                        TypeAheadField<String>(
                          controller: _sectionController,
                          suggestionsCallback: (pattern) {
                            return _getAvailableSections()
                                .then((sections) => sections.where((section) => section.toLowerCase().contains(pattern.toLowerCase())).toList());
                          },
                          itemBuilder: (context, suggestion) {
                            return ListTile(
                              title: Text(suggestion),
                            );
                          },
                          onSelected: (suggestion) {
                            setState(() {
                              _selectedSection = suggestion;
                              _sectionController.text = suggestion;
                            });
                          },
                          builder: (context, controller, focusNode) {
                            return TextFormField(
                              controller: controller,
                              focusNode: focusNode,
                              decoration: InputDecoration(
                                labelText: 'Участок',
                                border: const OutlineInputBorder(),
                                prefixIcon: const Icon(Icons.location_on),
                                suffixIcon: controller.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear),
                                        tooltip: 'Очистить',
                                        onPressed: () {
                                          setState(() {
                                            _selectedSection = null;
                                            controller.clear();
                                            _selectedFloor = null;
                                            _floorController.clear();
                                            _selectedSystem = null;
                                            _systemController.clear();
                                            _selectedSubsystem = null;
                                            _subsystemController.clear();
                                            _selectedEstimateItems.clear();
                                          });
                                        },
                                      )
                                    : null,
                              ),
                              readOnly: false,
                              onChanged: (value) {
                                setState(() {
                                  _selectedSection = value;
                                  if (value.isEmpty) {
                                    _selectedFloor = null;
                                    _selectedSystem = null;
                                    _selectedSubsystem = null;
                                    _selectedEstimateItems.clear();
                                  }
                                });
                              },
                              validator: (value) => value == null || value.isEmpty ? 'Укажите участок' : null,
                            );
                          },
                          hideOnEmpty: false,
                          emptyBuilder: (context) => const ListTile(
                            title: Text('Нет совпадений'),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Этаж - TypeAheadField
                        TypeAheadField<String>(
                          controller: _floorController,
                          suggestionsCallback: (pattern) {
                            if (!isSectionFilled) return [];
                            return _getAvailableFloors()
                                .then((floors) => floors.where((floor) => floor.toLowerCase().contains(pattern.toLowerCase())).toList());
                          },
                          itemBuilder: (context, suggestion) {
                            return ListTile(
                              title: Text(suggestion),
                            );
                          },
                          onSelected: (suggestion) {
                            setState(() {
                              _selectedFloor = suggestion;
                              _floorController.text = suggestion;
                            });
                          },
                          builder: (context, controller, focusNode) {
                            return TextFormField(
                              controller: controller,
                              focusNode: focusNode,
                              decoration: InputDecoration(
                                labelText: 'Этаж',
                                border: const OutlineInputBorder(),
                                prefixIcon: const Icon(Icons.stairs),
                                suffixIcon: controller.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear),
                                        tooltip: 'Очистить',
                                        onPressed: () {
                                          setState(() {
                                            _selectedFloor = null;
                                            controller.clear();
                                            _selectedSystem = null;
                                            _systemController.clear();
                                            _selectedSubsystem = null;
                                            _subsystemController.clear();
                                            _selectedEstimateItems.clear();
                                          });
                                        },
                                      )
                                    : null,
                              ),
                              readOnly: false,
                              enabled: isSectionFilled,
                              onChanged: (value) {
                                setState(() {
                                  _selectedFloor = value;
                                  if (value.isEmpty) {
                                    _selectedSystem = null;
                                    _selectedSubsystem = null;
                                    _selectedEstimateItems.clear();
                                  }
                                });
                              },
                              validator: (value) => value == null || value.isEmpty ? 'Укажите этаж' : null,
                            );
                          },
                          hideOnEmpty: false,
                          emptyBuilder: (context) => const ListTile(
                            title: Text('Нет совпадений'),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Система - TypeAheadField
                        TypeAheadField<String>(
                          controller: _systemController,
                          suggestionsCallback: (pattern) {
                            if (!isFloorFilled) return Future.value(<String>[]);
                            final estimates = ref.read(estimateNotifierProvider).estimates;
                            final systems = estimates
                                .where((e) => e.objectId == objectId)
                                .map((e) => e.system)
                                .toSet()
                                .toList()
                                .where((system) => system.toLowerCase().contains(pattern.toLowerCase()))
                                .toList();
                            return Future.value(systems);
                          },
                          itemBuilder: (context, suggestion) {
                            return ListTile(
                              title: Text(suggestion),
                            );
                          },
                          onSelected: (suggestion) {
                            setState(() {
                              _selectedSystem = suggestion;
                              _systemController.text = suggestion;
                              _selectedSubsystem = null;
                              _subsystemController.clear();
                              _selectedEstimateItems.clear();
                            });
                            _updateFilteredEstimates();
                          },
                          builder: (context, controller, focusNode) {
                            return TextFormField(
                              controller: controller,
                              focusNode: focusNode,
                              decoration: InputDecoration(
                                labelText: 'Система',
                                border: const OutlineInputBorder(),
                                prefixIcon: const Icon(Icons.category),
                                suffixIcon: controller.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear),
                                        tooltip: 'Очистить',
                                        onPressed: () {
                                          setState(() {
                                            _selectedSystem = null;
                                            controller.clear();
                                            _selectedSubsystem = null;
                                            _subsystemController.clear();
                                            _selectedEstimateItems.clear();
                                          });
                                        },
                                      )
                                    : null,
                              ),
                              readOnly: false,
                              enabled: isFloorFilled,
                              validator: (value) => value == null || value.isEmpty ? 'Выберите систему' : null,
                            );
                          },
                          hideOnEmpty: false,
                          emptyBuilder: (context) => const ListTile(
                            title: Text('Нет совпадений'),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Подсистема - TypeAheadField
                        TypeAheadField<String>(
                          controller: _subsystemController,
                          suggestionsCallback: (pattern) {
                            if (!isSystemFilled) return Future.value(<String>[]);
                            final estimates = ref.read(estimateNotifierProvider).estimates;
                            final subsystems = estimates
                                .where((e) => e.objectId == objectId && e.system == _selectedSystem)
                                .map((e) => e.subsystem)
                                .toSet()
                                .toList()
                                .where((subsystem) => subsystem.toLowerCase().contains(pattern.toLowerCase()))
                                .toList();
                            return Future.value(subsystems);
                          },
                          itemBuilder: (context, suggestion) {
                            return ListTile(
                              title: Text(suggestion),
                            );
                          },
                          onSelected: (suggestion) {
                            setState(() {
                              _selectedSubsystem = suggestion;
                              _subsystemController.text = suggestion;
                              _selectedEstimateItems.clear();
                            });
                            _updateFilteredEstimates();
                          },
                          builder: (context, controller, focusNode) {
                            return TextFormField(
                              controller: controller,
                              focusNode: focusNode,
                              decoration: InputDecoration(
                                labelText: 'Подсистема',
                                border: const OutlineInputBorder(),
                                prefixIcon: const Icon(Icons.dns),
                                suffixIcon: controller.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear),
                                        tooltip: 'Очистить',
                                        onPressed: () {
                                          setState(() {
                                            _selectedSubsystem = null;
                                            controller.clear();
                                            _selectedEstimateItems.clear();
                                          });
                                        },
                                      )
                                    : null,
                              ),
                              readOnly: false,
                              enabled: isSystemFilled,
                              validator: (value) => value == null || value.isEmpty ? 'Выберите подсистему' : null,
                            );
                          },
                          hideOnEmpty: false,
                          emptyBuilder: (context) => const ListTile(
                            title: Text('Нет совпадений'),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const SizedBox(height: 20),
                        // Список работ из сметы
                        if (isSubsystemFilled) _buildEstimateItemsList(),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Унифицированные кнопки
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(44),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      child: const Text('Отмена'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _selectedEstimateItems.isEmpty ? null : _saveSelectedItems,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(44),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      child: const Text('Добавить выбранные работы'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
  
  /// Строит список работ из сметы с возможностью выбора и ввода количества.
  ///
  /// Возвращает виджет с таблицей работ, полем поиска и итоговой суммой.
  Widget _buildEstimateItemsList() {
    final numberFormat = NumberFormat('#,##0.00', 'ru_RU');
    final filteredBySearch = _searchQuery.isEmpty
      ? _filteredEstimates
      : _filteredEstimates.where((e) => e.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Работы из сметы:',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        // Поле поиска
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 12),
          child: TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Поиск по наименованию',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
        ),
        const SizedBox(height: 8),
        if (filteredBySearch.isEmpty) ...[
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(
              child: Text('Выберите систему и подсистему для отображения работ из сметы'),
            ),
          ),
        ]
        else ...[
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                const SizedBox(width: 32),
                Expanded(
                  flex: 3,
                  child: Text(
                    'Наименование',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                Expanded(
                  child: Text(
                    'Ед.изм.',
                    style: Theme.of(context).textTheme.titleSmall,
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: Text(
                    'Цена',
                    style: Theme.of(context).textTheme.titleSmall,
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: Text(
                    'Кол-во',
                    style: Theme.of(context).textTheme.titleSmall,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2)),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(8),
                bottomRight: Radius.circular(8),
              ),
            ),
            constraints: const BoxConstraints(maxHeight: 300),
            child: filteredBySearch.isEmpty
              ? const Center(child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('Нет работ по вашему запросу'),
                ))
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: filteredBySearch.length,
                  itemBuilder: (context, index) {
                    final estimate = filteredBySearch[index];
                    final isSelected = _selectedEstimateItems.containsKey(estimate);
                    final quantity = _selectedEstimateItems[estimate];
                    final controller = _quantityControllers.putIfAbsent(
                      estimate,
                      () => TextEditingController(
                        text: quantity != null && quantity > 0
                          ? (quantity % 1 == 0 ? quantity.toInt().toString() : quantity.toString())
                          : '',
                      ),
                    );
                    if (isSelected) {
                      final newText = quantity != null && quantity > 0
                        ? (quantity % 1 == 0 ? quantity.toInt().toString() : quantity.toString())
                        : '';
                      if (controller.text != newText) {
                        controller.text = newText;
                        controller.selection = TextSelection.fromPosition(
                          TextPosition(offset: controller.text.length),
                        );
                      }
                    }
                    return Row(
                      children: [
                        Checkbox(
                          value: isSelected,
                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                _selectedEstimateItems[estimate] = null;
                                _quantityControllers.putIfAbsent(
                                  estimate,
                                  () => TextEditingController(),
                                );
                              } else {
                                _selectedEstimateItems.remove(estimate);
                                _quantityControllers[estimate]?.dispose();
                                _quantityControllers.remove(estimate);
                              }
                            });
                          },
                        ),
                        Expanded(
                          flex: 3,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Text(estimate.name),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            estimate.unit,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            numberFormat.format(estimate.price),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                            child: TextField(
                              controller: controller,
                              decoration: const InputDecoration(
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.text,
                              textAlign: TextAlign.center,
                              enabled: isSelected,
                              onChanged: (value) {
                                final qty = double.tryParse(value);
                                setState(() {
                                  if (isSelected) {
                                    if (qty != null && qty > 0) {
                                      _selectedEstimateItems[estimate] = qty;
                                    } else {
                                      _selectedEstimateItems[estimate] = null;
                                    }
                                  }
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
          ),
        ],
        if (_selectedEstimateItems.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'Выбрано работ: ${_selectedEstimateItems.length}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Сумма работ: ${numberFormat.format(
                _selectedEstimateItems.entries
                  .where((e) => e.value != null && e.value! > 0)
                  .fold<double>(0, (sum, e) => sum + e.key.price * e.value!)
              )} ₽',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ],
    );
  }
} 