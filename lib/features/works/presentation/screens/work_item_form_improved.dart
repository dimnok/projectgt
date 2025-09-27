import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/work_item.dart';
import '../providers/work_items_provider.dart';
import '../../../../core/di/providers.dart';
import '../../../../domain/entities/estimate.dart';
import '../../../../core/widgets/gt_dropdown.dart';
import '../providers/work_provider.dart';
import 'package:intl/intl.dart';
import 'package:projectgt/core/utils/modal_utils.dart';

/// Улучшенная версия модального окна для создания или редактирования работы (WorkItem).
///
/// Оптимизирована для лучшего использования пространства:
/// - Поля выбора можно прокрутить вверх и скрыть
/// - Поле поиска остается видимым
/// - Список материалов занимает максимально доступное место
class WorkItemFormImproved extends ConsumerStatefulWidget {
  /// Идентификатор смены, к которой относится работа.
  final String workId;

  /// Исходная работа для редактирования (null — создание новой).
  final WorkItem? initial;

  /// Контроллер прокрутки для DraggableScrollableSheet.
  final ScrollController? scrollController;

  /// Создаёт улучшенное модальное окно для добавления или редактирования работы.
  const WorkItemFormImproved({
    super.key,
    required this.workId,
    this.initial,
    this.scrollController,
  });

  @override
  ConsumerState<WorkItemFormImproved> createState() =>
      _WorkItemFormImprovedState();
}

/// Состояние для [WorkItemFormImproved].
class _WorkItemFormImprovedState extends ConsumerState<WorkItemFormImproved>
    with TickerProviderStateMixin {
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

  /// Отфильтрованные сметные работы по выбранным параметрам.
  List<Estimate> _filteredEstimates = [];

  /// Карта выбранных работ из сметы и их количества.
  final Map<Estimate, double?> _selectedEstimateItems = {};

  /// Контроллеры для ввода количества по каждой работе.
  final Map<Estimate, TextEditingController> _quantityControllers = {};

  /// Идентификатор объекта (строительного).
  late String objectId;

  /// Поиск в шапке
  bool _headerSearchVisible = false;
  final TextEditingController _headerSearchController = TextEditingController();
  final FocusNode _headerSearchFocusNode = FocusNode();
  String _headerSearchQuery = '';

  /// Флаг загрузки для отображения индикатора.
  final bool _isLoading = false;

  /// Флаг сохранения для отображения состояния кнопок.
  bool _isSaving = false;

  /// Списки данных для dropdown'ов
  List<String> _availableSections = [];
  List<String> _availableFloors = [];
  List<String> _availableSystems = [];
  List<String> _availableSubsystems = [];

  /// Переменные для анимаций
  late AnimationController _buttonsAnimController;
  late Animation<Offset> _leftOffset;
  late Animation<Offset> _rightOffset;

  // Управление видимостью кнопок по прокрутке
  bool _scrolling = false;
  Timer? _scrollEndTimer;

  /// Признак режима редактирования (true — редактирование, false — создание).
  bool get isModifying => widget.initial != null;

  /// Проверяет, выбраны ли все поля для показа списка материалов.
  bool get allSelected =>
      _selectedSection != null &&
      _selectedFloor != null &&
      _selectedSystem != null &&
      _selectedSubsystem != null;

  /// Проверяет, есть ли выбранные работы.
  bool get hasSelection => _selectedEstimateItems.isNotEmpty;

  /// Сохраняет выбранные работы из сметы как WorkItems.
  Future<void> _saveWorkItems() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_selectedSection == null ||
        _selectedFloor == null ||
        _selectedSystem == null ||
        _selectedSubsystem == null) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final workItemsNotifier =
          ref.read(workItemsProvider(widget.workId).notifier);

      // Создаём список WorkItem и сохраняем пакетно одним вызовом
      final itemsToAdd = <WorkItem>[];
      for (final entry in _selectedEstimateItems.entries) {
        final estimate = entry.key;
        final quantity = entry.value ?? 0;
        itemsToAdd.add(
          WorkItem(
            id: const Uuid().v4(),
            workId: widget.workId,
            section: _selectedSection!,
            floor: _selectedFloor!,
            estimateId: estimate.id,
            name: estimate.name,
            system: _selectedSystem!,
            subsystem: _selectedSubsystem!,
            unit: estimate.unit,
            quantity: quantity,
            price: estimate.price,
            total: quantity > 0 ? estimate.price * quantity : 0,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
      }

      await workItemsNotifier.addMany(itemsToAdd);

      // Закрываем модальное окно после успешного сохранения
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      // В случае ошибки показываем сообщение
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка сохранения: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

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
    }

    // Инициализация анимаций
    _buttonsAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _leftOffset = Tween<Offset>(
      begin: const Offset(-2, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _buttonsAnimController,
      curve: Curves.easeOut,
    ));

    _rightOffset = Tween<Offset>(
      begin: const Offset(2, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _buttonsAnimController,
      curve: Curves.easeOut,
    ));

    // Добавляем listener к scroll controller
    if (widget.scrollController != null) {
      widget.scrollController!
          .addListener(() => _scrollListener(widget.scrollController!));
    }

    // Загружаем сметы и данные для dropdown'ов
    Future.microtask(() {
      if (ref.read(estimateNotifierProvider).estimates.isEmpty) {
        ref.read(estimateNotifierProvider.notifier).loadEstimates();
      }
      _loadDropdownData();
    });
  }

  @override
  void dispose() {
    for (final controller in _quantityControllers.values) {
      controller.dispose();
    }
    _headerSearchController.dispose();
    _headerSearchFocusNode.dispose();
    if (widget.scrollController != null) {
      widget.scrollController!
          .removeListener(() => _scrollListener(widget.scrollController!));
    }
    _buttonsAnimController.dispose();
    _scrollEndTimer?.cancel();
    super.dispose();
  }

  /// Загружает данные для dropdown'ов
  Future<void> _loadDropdownData() async {
    // Загружаем участки
    _availableSections = await _getAvailableSections();

    // Загружаем все этажи сразу
    _availableFloors = await _getAvailableFloors();

    // Загружаем системы из смет
    final estimates = ref.read(estimateNotifierProvider).estimates;
    _availableSystems = estimates
        .where((e) => e.objectId == objectId)
        .map((e) => e.system)
        .toSet()
        .toList();

    setState(() {});
  }

  /// Обновляет список подсистем на основе выбранной системы
  void _updateSubsystems() {
    if (_selectedSystem?.isEmpty ?? true) {
      _availableSubsystems = [];
    } else {
      final estimates = ref.read(estimateNotifierProvider).estimates;
      _availableSubsystems = estimates
          .where((e) => e.objectId == objectId && e.system == _selectedSystem)
          .map((e) => e.subsystem)
          .toSet()
          .toList();
    }
    setState(() {});
  }

  /// Обновляет список сметных работ по выбранным фильтрам (система, подсистема, объект).
  void _updateFilteredEstimates() {
    final allEstimates = ref.read(estimateNotifierProvider).estimates;
    var filteredList = allEstimates.where((estimate) {
      if (estimate.objectId != objectId) return false;
      if (_selectedSystem != null &&
          _selectedSystem!.isNotEmpty &&
          estimate.system != _selectedSystem) {
        return false;
      }
      if (_selectedSubsystem != null &&
          _selectedSubsystem!.isNotEmpty &&
          estimate.subsystem != _selectedSubsystem) {
        return false;
      }
      return true;
    }).toList();

    // Исключаем из списка только те материалы (элементы сметы),
    // которые уже добавлены в текущую смену с выбранной комбинацией
    // (участок/этаж/система/подсистема)
    if (_selectedSection != null &&
        _selectedFloor != null &&
        _selectedSystem != null &&
        _selectedSubsystem != null) {
      final workItemsAsync = ref.read(workItemsProvider(widget.workId));
      final existingItems =
          workItemsAsync.hasValue ? (workItemsAsync.value ?? []) : <WorkItem>[];

      // Собираем множество estimateId уже добавленных материалов для выбранной комбинации
      final existingEstimateIdsForCombo = existingItems
          .where((item) =>
              item.section == _selectedSection &&
              item.floor == _selectedFloor &&
              item.system == _selectedSystem &&
              item.subsystem == _selectedSubsystem)
          .map((e) => e.estimateId)
          .toSet();

      // Убираем из отображаемого списка только те материалы, которые уже есть в этой комбинации
      filteredList = filteredList
          .where(
              (estimate) => !existingEstimateIdsForCombo.contains(estimate.id))
          .toList();
    }

    setState(() {
      _filteredEstimates = filteredList;
    });
  }

  /// Получает список доступных участков (модулей) из всех работ.
  Future<List<String>> _getAvailableSections() async {
    final workItemsNotifier = ref.read(workItemsNotifierProvider);
    final items = await workItemsNotifier.getAllWorkItems();
    return items
        .map((e) => e.section)
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();
  }

  /// Получает список всех доступных этажей без привязки к участку.
  Future<List<String>> _getAvailableFloors() async {
    final workItemsNotifier = ref.read(workItemsNotifierProvider);
    final items = await workItemsNotifier.getAllWorkItems();

    return items
        .map((e) => e.floor)
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();
  }

  /// Обработчик прокрутки для показа/скрытия поиска и кнопок.
  void _scrollListener(ScrollController controller) {
    if (!_scrolling) {
      _scrolling = true;
      _buttonsAnimController.reverse();
    }

    _scrollEndTimer?.cancel();
    _scrollEndTimer = Timer(const Duration(milliseconds: 500), () {
      _scrolling = false;
      if (hasSelection) {
        _buttonsAnimController.forward();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Material(
      color: theme.colorScheme.surface,
      child: _isLoading
          ? const Center(child: CupertinoActivityIndicator())
          : GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () {
                final scope = FocusScope.of(context);
                if (!scope.hasPrimaryFocus) {
                  scope.unfocus();
                }
              },
              child: Stack(
                children: [
                  // Основное содержимое
                  Column(
                    children: [
                      // Заголовок с кнопкой поиска
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          border: Border(
                            bottom: BorderSide(
                              color: theme.colorScheme.outline
                                  .withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12.0),
                          child: Row(
                            children: [
                              // Кнопка лупы
                              CupertinoButton(
                                padding: EdgeInsets.zero,
                                onPressed: () {
                                  if (_headerSearchVisible &&
                                      _headerSearchQuery.isNotEmpty) {
                                    setState(() {
                                      _headerSearchController.clear();
                                      _headerSearchQuery = '';
                                    });
                                    return;
                                  }

                                  setState(() {
                                    _headerSearchVisible =
                                        !_headerSearchVisible;
                                  });
                                  if (_headerSearchVisible) {
                                    WidgetsBinding.instance
                                        .addPostFrameCallback((_) {
                                      if (mounted)
                                        _headerSearchFocusNode.requestFocus();
                                    });
                                  }
                                },
                                minSize: 40,
                                child: Icon(
                                  (_headerSearchVisible &&
                                          _headerSearchQuery.isNotEmpty)
                                      ? CupertinoIcons.xmark
                                      : CupertinoIcons.search,
                                  size: 24,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Заголовок и строка поиска: поиск выезжает и сдвигает заголовок
                              Expanded(
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    final maxWidth = constraints.maxWidth;
                                    final targetWidth =
                                        _headerSearchVisible ? maxWidth : 0.0;
                                    return Stack(
                                      alignment: Alignment.centerLeft,
                                      children: [
                                        // Поле поиска, расширяется слева направо
                                        Align(
                                          alignment: Alignment.centerLeft,
                                          child: AnimatedContainer(
                                            duration: const Duration(
                                                milliseconds: 300),
                                            curve: Curves.easeOutCubic,
                                            width: targetWidth,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(24),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: theme
                                                      .colorScheme.shadow
                                                      .withValues(alpha: 0.15),
                                                  blurRadius: 12,
                                                  offset: const Offset(0, 4),
                                                ),
                                              ],
                                            ),
                                            child: targetWidth > 0
                                                ? ClipRect(
                                                    child: TextField(
                                                      focusNode:
                                                          _headerSearchFocusNode,
                                                      controller:
                                                          _headerSearchController,
                                                      decoration:
                                                          InputDecoration(
                                                        hintText: 'Поиск...',
                                                        isDense: true,
                                                        filled: true,
                                                        fillColor: theme
                                                            .colorScheme
                                                            .surface,
                                                        border:
                                                            OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(24),
                                                        ),
                                                        enabledBorder:
                                                            OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(24),
                                                          borderSide:
                                                              BorderSide(
                                                            color: theme
                                                                .colorScheme
                                                                .outline
                                                                .withValues(
                                                                    alpha:
                                                                        0.25),
                                                          ),
                                                        ),
                                                        focusedBorder:
                                                            OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(24),
                                                          borderSide:
                                                              BorderSide(
                                                            color: theme
                                                                .colorScheme
                                                                .primary
                                                                .withValues(
                                                                    alpha: 0.6),
                                                          ),
                                                        ),
                                                        contentPadding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                          vertical: 10,
                                                          horizontal: 14,
                                                        ),
                                                      ),
                                                      onChanged: (v) =>
                                                          setState(() {
                                                        _headerSearchQuery = v;
                                                      }),
                                                    ),
                                                  )
                                                : const SizedBox.shrink(),
                                          ),
                                        ),
                                        // Заголовок, уезжает вправо и исчезает
                                        AnimatedSlide(
                                          duration:
                                              const Duration(milliseconds: 300),
                                          curve: Curves.easeOutCubic,
                                          offset: _headerSearchVisible
                                              ? const Offset(0.5, 0)
                                              : Offset.zero,
                                          child: AnimatedOpacity(
                                            duration: const Duration(
                                                milliseconds: 200),
                                            curve: Curves.easeOutCubic,
                                            opacity: _headerSearchVisible
                                                ? 0.0
                                                : 1.0,
                                            child: Center(
                                              child: Text(
                                                widget.initial == null
                                                    ? 'Добавить работы'
                                                    : 'Редактировать работу',
                                                style: theme
                                                    .textTheme.titleLarge
                                                    ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                              // Кнопка закрытия
                              CupertinoButton(
                                padding: EdgeInsets.zero,
                                onPressed: () => Navigator.pop(context),
                                minimumSize: const Size(40, 40),
                                child: const Icon(
                                  CupertinoIcons.xmark_circle_fill,
                                  size: 28,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Прокручиваемое содержимое
                      Expanded(
                        child: Form(
                          key: _formKey,
                          child: _buildAnimatedContent(theme),
                        ),
                      ),
                    ],
                  ),

                  // Поиск отображается в заголовке по нажатию на кнопку

                  // Анимированные кнопки (скрываем при открытой клавиатуре)
                  if (hasSelection && !isKeyboardOpen)
                    Positioned(
                      bottom: 24 + MediaQuery.viewPaddingOf(context).bottom,
                      left: 20,
                      right: 20,
                      child: Row(
                        children: [
                          Expanded(
                            child: SlideTransition(
                              position: _leftOffset,
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  padding: EdgeInsets.symmetric(
                                    vertical: !kIsWeb &&
                                            (defaultTargetPlatform ==
                                                    TargetPlatform.android ||
                                                defaultTargetPlatform ==
                                                    TargetPlatform.iOS)
                                        ? 12
                                        : 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                ),
                                onPressed: _isSaving
                                    ? null
                                    : () => Navigator.pop(context),
                                child: const Text('Отмена'),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: SlideTransition(
                              position: _rightOffset,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  padding: EdgeInsets.symmetric(
                                    vertical: !kIsWeb &&
                                            (defaultTargetPlatform ==
                                                    TargetPlatform.android ||
                                                defaultTargetPlatform ==
                                                    TargetPlatform.iOS)
                                        ? 12
                                        : 16,
                                  ),
                                  backgroundColor: theme.colorScheme.primary,
                                  foregroundColor: theme.colorScheme.onPrimary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                ),
                                onPressed:
                                    _isSaving ? null : () => _saveWorkItems(),
                                child: _isSaving
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Colors.white),
                                        ),
                                      )
                                    : Text(widget.initial == null
                                        ? 'Добавить'
                                        : 'Сохранить'),
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

  /// Строит анимированное содержимое с логикой из filterable modal.
  Widget _buildAnimatedContent(ThemeData theme) {
    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.fromLTRB(
          20, 24, 20, 200), // Увеличил верхний отступ с 0 до 24
      children: [
        // Поля выбора
        _buildSelectionFields(),

        const SizedBox(height: 20),

        // Список материалов (если все поля выбраны)
        if (allSelected) _buildMaterialsList(),
      ],
    );
  }

  /// Строит поля выбора участка, этажа, системы и подсистемы.
  Widget _buildSelectionFields() {
    final isSectionFilled =
        _selectedSection != null && _selectedSection!.isNotEmpty;
    final isFloorFilled = _selectedFloor != null && _selectedFloor!.isNotEmpty;
    final isSystemFilled =
        _selectedSystem != null && _selectedSystem!.isNotEmpty;

    return Column(
      children: [
        // Поле "Участок"
        GTStringDropdown(
          items: _availableSections,
          selectedItem: _selectedSection,
          labelText: 'Участок',
          hintText: 'Выберите или добавьте участок',
          allowCustomInput: true,
          showAddNewOption: true,
          allowClear: true,
          validator: (value) =>
              value == null || value.isEmpty ? 'Укажите участок' : null,
          onSelectionChanged: (value) {
            setState(() {
              _selectedSection = value;
              _selectedFloor = null;
              _selectedSystem = null;
              _selectedSubsystem = null;
              _selectedEstimateItems.clear();

              // Управление анимацией кнопок
              if (_selectedEstimateItems.isEmpty) {
                _buttonsAnimController.reverse();
              }
            });
            if (value != null && !_availableSections.contains(value)) {
              _availableSections.add(value);
            }
          },
        ),

        // Поле "Этаж" - появляется только после выбора участка
        if (isSectionFilled) ...[
          const SizedBox(height: 16),
          GTStringDropdown(
            items: _availableFloors,
            selectedItem: _selectedFloor,
            labelText: 'Этаж',
            hintText: 'Выберите или добавьте этаж',
            allowCustomInput: true,
            showAddNewOption: true,
            allowClear: true,
            validator: (value) =>
                value == null || value.isEmpty ? 'Укажите этаж' : null,
            onSelectionChanged: (value) {
              setState(() {
                _selectedFloor = value;
                _selectedSystem = null;
                _selectedSubsystem = null;
                _selectedEstimateItems.clear();

                // Управление анимацией кнопок
                if (_selectedEstimateItems.isEmpty) {
                  _buttonsAnimController.reverse();
                }
              });
              if (value != null && !_availableFloors.contains(value)) {
                _availableFloors.add(value);
              }
            },
          ),
        ],

        // Поле "Система" - появляется только после выбора этажа
        if (isFloorFilled) ...[
          const SizedBox(height: 16),
          GTStringDropdown(
            items: _availableSystems,
            selectedItem: _selectedSystem,
            labelText: 'Система',
            hintText: 'Выберите систему',
            allowCustomInput: false,
            allowClear: true,
            validator: (value) =>
                value == null || value.isEmpty ? 'Выберите систему' : null,
            onSelectionChanged: (value) {
              setState(() {
                _selectedSystem = value;
                _selectedSubsystem = null;
                _selectedEstimateItems.clear();

                // Управление анимацией кнопок
                if (_selectedEstimateItems.isEmpty) {
                  _buttonsAnimController.reverse();
                }
              });
              _updateSubsystems();
              _updateFilteredEstimates();
            },
          ),
        ],

        // Поле "Подсистема" - появляется только после выбора системы
        if (isSystemFilled) ...[
          const SizedBox(height: 16),
          GTStringDropdown(
            items: _availableSubsystems,
            selectedItem: _selectedSubsystem,
            labelText: 'Подсистема',
            hintText: 'Выберите подсистему',
            allowCustomInput: false,
            allowClear: true,
            validator: (value) =>
                value == null || value.isEmpty ? 'Выберите подсистему' : null,
            onSelectionChanged: (value) {
              setState(() {
                _selectedSubsystem = value;
                _selectedEstimateItems.clear();

                // Управление анимацией кнопок
                if (_selectedEstimateItems.isEmpty) {
                  _buttonsAnimController.reverse();
                }
              });
              _updateFilteredEstimates();
            },
          ),
        ],
      ],
    );
  }

  /// Строит список материалов в стиле filterable modal.
  Widget _buildMaterialsList() {
    final query = _headerSearchQuery;
    final filteredBySearch = query.isEmpty
        ? _filteredEstimates
        : _filteredEstimates
            .where((e) => e.name.toLowerCase().contains(query.toLowerCase()))
            .toList();

    if (filteredBySearch.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('Нет работ по вашему запросу'),
        ),
      );
    }

    return Column(
      children: [
        ...filteredBySearch.map((estimate) {
          final isSelected = _selectedEstimateItems.containsKey(estimate);
          final theme = Theme.of(context);

          return GestureDetector(
            onTap: () {
              setState(() {
                if (isSelected) {
                  _selectedEstimateItems.remove(estimate);
                  _quantityControllers[estimate]?.dispose();
                  _quantityControllers.remove(estimate);
                } else {
                  _selectedEstimateItems[estimate] = null;
                  _quantityControllers.putIfAbsent(
                    estimate,
                    () => TextEditingController(text: ''),
                  );
                }

                // Управление анимацией кнопок
                if (hasSelection) {
                  _buttonsAnimController.forward();
                } else {
                  _buttonsAnimController.reverse();
                }
              });
            },
            child: Card(
              color:
                  isSelected ? Colors.green.shade50 : theme.colorScheme.surface,
              elevation: isSelected ? 2 : 0,
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                leading: Text(
                  estimate.number,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.green.shade700
                        : theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                title: Text(
                  estimate.name,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.green.shade700
                        : theme.colorScheme.onSurface,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                subtitle: Text(
                  '${NumberFormat('#,##0.00', 'ru').format(estimate.price)} ₽ / ${estimate.unit}',
                  style: TextStyle(
                    color: isSelected
                        ? Colors.green.shade600
                        : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                trailing: isSelected
                    ? SizedBox(
                        width: 80,
                        child: TextField(
                          controller: _quantityControllers[estimate],
                          decoration: const InputDecoration(
                            hintText: 'Кол-во',
                            border: OutlineInputBorder(),
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 8, vertical: 8),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          textAlign: TextAlign.center,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9.,]')),
                          ],
                          onChanged: (value) {
                            final normalized = value.replaceAll(',', '.');
                            final qty = double.tryParse(normalized) ?? 0.0;
                            setState(() {
                              if (qty > 0) {
                                _selectedEstimateItems[estimate] = qty;
                              } else {
                                _selectedEstimateItems[estimate] = null;
                              }
                            });
                          },
                        ),
                      )
                    : null,
              ),
            ),
          );
        }),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Новый материал'),
            onPressed: () async {
              if (_selectedSection == null ||
                  _selectedFloor == null ||
                  _selectedSystem == null ||
                  _selectedSubsystem == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text(
                        'Сначала заполните участок, этаж, систему и подсистему'),
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
                );
                return;
              }

              final result = await ModalUtils.showNewMaterialModal(
                context,
                objectId: objectId,
                system: _selectedSystem!,
                subsystem: _selectedSubsystem!,
              );

              if (result is Map) {
                // Обновляем список смет и пересобираем фильтр сразу после добавления
                await ref
                    .read(estimateNotifierProvider.notifier)
                    .loadEstimates();
                _updateFilteredEstimates();

                final estimates = ref.read(estimateNotifierProvider).estimates;
                final created = estimates.firstWhere(
                  (e) =>
                      e.objectId == objectId &&
                      e.system == _selectedSystem &&
                      e.subsystem == _selectedSubsystem &&
                      e.name == result['name'],
                  orElse: () => estimates.first,
                );
                setState(() {
                  _selectedEstimateItems[created] = null;
                  _quantityControllers.putIfAbsent(
                    created,
                    () => TextEditingController(text: ''),
                  );
                });
              }
            },
          ),
        ),
      ],
    );
  }
}
