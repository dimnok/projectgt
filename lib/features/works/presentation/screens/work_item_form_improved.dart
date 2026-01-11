import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:projectgt/core/widgets/app_snackbar.dart';
import 'package:projectgt/core/utils/responsive_utils.dart';
import 'package:projectgt/core/widgets/desktop_dialog_content.dart';
import 'package:projectgt/core/widgets/gt_buttons.dart';
import 'package:projectgt/core/widgets/gt_text_field.dart';
import 'package:projectgt/core/widgets/mobile_bottom_sheet_content.dart';
import '../../domain/entities/work_item.dart';
import '../providers/work_items_provider.dart';
import '../../../../core/di/providers.dart';
import '../../../../domain/entities/estimate.dart';
import '../../../../core/widgets/gt_dropdown.dart';
import '../providers/work_provider.dart';
import '../../../../features/company/presentation/providers/company_providers.dart';
import 'package:projectgt/core/utils/modal_utils.dart';
import 'package:projectgt/core/utils/formatters.dart';

/// Улучшенная версия модального окна для создания или редактирования работы (WorkItem).
class WorkItemFormImproved extends ConsumerStatefulWidget {
  /// Идентификатор смены, к которой относится работа.
  final String workId;

  /// Исходная работа для редактирования (null — создание новой).
  final WorkItem? initial;

  /// Контроллер прокрутки для DraggableScrollableSheet (используется только на мобильных в bottom sheet).
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
class _WorkItemFormImprovedState extends ConsumerState<WorkItemFormImproved> {
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

  /// Поиск
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  /// Флаг загрузки для отображения индикатора.
  final bool _isLoading = false;

  /// Флаг сохранения для отображения состояния кнопок.
  bool _isSaving = false;

  /// Списки данных для dropdown'ов
  List<String> _availableSections = [];
  List<String> _availableFloors = [];
  List<String> _availableSystems = [];
  List<String> _availableSubsystems = [];

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
      final workItemsNotifier = ref.read(
        workItemsProvider(widget.workId).notifier,
      );
      final activeCompanyId = ref.read(activeCompanyIdProvider);

      if (activeCompanyId == null) {
        throw Exception('Компания не выбрана');
      }

      // Создаём список WorkItem и сохраняем пакетно одним вызовом
      final itemsToAdd = <WorkItem>[];
      for (final entry in _selectedEstimateItems.entries) {
        final estimate = entry.key;
        final quantity = entry.value ?? 0;
        itemsToAdd.add(
          WorkItem(
            id: isModifying ? widget.initial!.id : const Uuid().v4(),
            companyId: activeCompanyId,
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
            createdAt: isModifying ? widget.initial!.createdAt : DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
      }

      // Если редактируем, обновляем; если добавляем, сохраняем
      if (isModifying) {
        // Редактируем первую (и единственную) работу
        await workItemsNotifier.updateOptimistic(itemsToAdd.first);
      } else {
        // Добавляем новые работы
        await workItemsNotifier.addMany(itemsToAdd);
      }

      // Закрываем модальное окно после успешного сохранения
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      // В случае ошибки показываем сообщение
      if (mounted) {
        AppSnackBar.show(
          context: context,
          message: 'Ошибка сохранения: $e',
          kind: AppSnackBarKind.error,
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

    // Инициализируем выбранные элементы для редактирования
    // (это может быть пусто, если сметы не загружены, но будет обновлено после _loadDropdownData)
    if (isModifying &&
        ref.read(estimateNotifierProvider).estimates.isNotEmpty) {
      final estimate = ref
          .read(estimateNotifierProvider)
          .estimates
          .where((e) => e.id == widget.initial!.estimateId)
          .firstOrNull;
      if (estimate != null) {
        _selectedEstimateItems[estimate] = widget.initial!.quantity is int
            ? (widget.initial!.quantity as int).toDouble()
            : widget.initial!.quantity as double?;
        _quantityControllers[estimate] = TextEditingController(
          text: widget.initial!.quantity.toString(),
        );
      }
    }

    // Загружаем сметы и данные для dropdown'ов
    Future.microtask(() {
      if (ref.read(estimateNotifierProvider).estimates.isEmpty) {
        ref.read(estimateNotifierProvider.notifier).loadEstimates();
      }
      _loadDropdownData();
      // Обновляем отфильтрованный список (важно! это должно быть ДО инициализации выбранных работ)
      _updateFilteredEstimates();

      // Если редактируем, загружаем выбранные работы
      if (isModifying) {
        final estimate = ref
            .read(estimateNotifierProvider)
            .estimates
            .where((e) => e.id == widget.initial!.estimateId)
            .firstOrNull;
        if (estimate != null) {
          _selectedEstimateItems[estimate] = widget.initial!.quantity is int
              ? (widget.initial!.quantity as int).toDouble()
              : widget.initial!.quantity as double?;
          _quantityControllers[estimate] = TextEditingController(
            text: widget.initial!.quantity.toString(),
          );
          // Обновляем UI после инициализации
          if (mounted) {
            setState(() {});
          }
        }
      }
    });
  }

  @override
  void dispose() {
    for (final controller in _quantityControllers.values) {
      controller.dispose();
    }
    _searchController.dispose();
    super.dispose();
  }

  /// Загружает данные для dropdown'ов
  Future<void> _loadDropdownData() async {
    // Загружаем участки и этажи параллельно
    final results = await Future.wait([
      _getAvailableSections(),
      _getAvailableFloors(),
    ]);

    _availableSections = results[0];
    _availableFloors = results[1];

    // Загружаем системы из смет
    final estimates = ref.read(estimateNotifierProvider).estimates;
    _availableSystems = estimates
        .where((e) => e.objectId == objectId)
        .map((e) => e.system)
        .toSet()
        .toList();

    if (mounted) {
      setState(() {});
    }
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
      final existingItems = workItemsAsync.hasValue
          ? (workItemsAsync.value ?? [])
          : <WorkItem>[];

      // Собираем множество estimateId уже добавленных материалов для выбранной комбинации
      final existingEstimateIdsForCombo = existingItems
          .where(
            (item) =>
                item.section == _selectedSection &&
                item.floor == _selectedFloor &&
                item.system == _selectedSystem &&
                item.subsystem == _selectedSubsystem,
          )
          .map((e) => e.estimateId)
          .toSet();

      // Убираем из отображаемого списка только те материалы, которые уже есть в этой комбинации
      // НО при редактировании не исключаем выбранную работу
      filteredList = filteredList.where((estimate) {
        // Если редактируем и это выбранная работа - не исключаем её
        if (isModifying && estimate.id == widget.initial!.estimateId) {
          return true;
        }
        // Иначе исключаем уже добавленные работы
        return !existingEstimateIdsForCombo.contains(estimate.id);
      }).toList();
    }

    setState(() {
      _filteredEstimates = filteredList;
    });
  }

  /// Получает список доступных участков (модулей) для текущего объекта.
  Future<List<String>> _getAvailableSections() async {
    try {
      final activeCompanyId = ref.read(activeCompanyIdProvider);
      final response = await Supabase.instance.client.rpc(
        'get_object_sections',
        params: {'target_object_id': objectId, 'p_company_id': activeCompanyId},
      );

      final List<dynamic> data = response as List<dynamic>;
      return data.map((e) => e['section'] as String).toList();
    } catch (e) {
      debugPrint('Ошибка загрузки участков: $e');
      return [];
    }
  }

  /// Получает список всех доступных этажей для текущего объекта.
  Future<List<String>> _getAvailableFloors() async {
    try {
      final activeCompanyId = ref.read(activeCompanyIdProvider);
      final response = await Supabase.instance.client.rpc(
        'get_object_floors',
        params: {'target_object_id': objectId, 'p_company_id': activeCompanyId},
      );

      final List<dynamic> data = response as List<dynamic>;
      return data.map((e) => e['floor'] as String).toList();
    } catch (e) {
      debugPrint('Ошибка загрузки этажей: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveUtils.isMobile(context);
    final title = widget.initial == null
        ? 'Добавить работы'
        : 'Редактировать работу';

    final footer = Row(
      children: [
        Expanded(
          child: GTSecondaryButton(
            text: 'Отмена',
            onPressed: () => Navigator.pop(context),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: GTPrimaryButton(
            text: widget.initial == null ? 'Добавить' : 'Сохранить',
            isLoading: _isSaving,
            onPressed: (hasSelection && !_isSaving) ? _saveWorkItems : null,
          ),
        ),
      ],
    );

    final content = _isLoading
        ? const Center(child: CupertinoActivityIndicator())
        : Form(key: _formKey, child: _buildFormContent(Theme.of(context)));

    if (isMobile) {
      return MobileBottomSheetContent(
        title: title,
        footer: footer,
        scrollController: widget.scrollController,
        scrollable: false,
        child: content,
      );
    } else {
      return DesktopDialogContent(
        title: title,
        footer: footer,
        scrollable: false,
        child: content,
      );
    }
  }

  /// Строит содержимое формы
  Widget _buildFormContent(ThemeData theme) {
    return CustomScrollView(
      controller: widget.scrollController,
      shrinkWrap: true,
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            children: [_buildSelectionFields(), const SizedBox(height: 12)],
          ),
        ),
        if (allSelected) ..._buildMaterialsSlivers(theme),
      ],
    );
  }

  List<Widget> _buildMaterialsSlivers(ThemeData theme) {
    final query = _searchQuery;
    final filteredBySearch = query.isEmpty
        ? _filteredEstimates
        : _filteredEstimates
              .where((e) => e.name.toLowerCase().contains(query.toLowerCase()))
              .toList();

    return [
      SliverAppBar(
        primary: false,
        pinned: true,
        backgroundColor: theme.colorScheme.surface,
        automaticallyImplyLeading: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shape: const Border(
          bottom: BorderSide(color: Colors.transparent, width: 0),
        ),
        toolbarHeight: 52,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0),
          child: CupertinoSearchTextField(
            controller: _searchController,
            placeholder: 'Поиск работ...',
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            style: TextStyle(color: theme.colorScheme.onSurface),
          ),
        ),
      ),
      if (filteredBySearch.isEmpty)
        const SliverToBoxAdapter(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('Нет работ по вашему запросу'),
            ),
          ),
        )
      else
        SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final estimate = filteredBySearch[index];
            final isSelected = _selectedEstimateItems.containsKey(estimate);
            final isDark = theme.brightness == Brightness.dark;

            // Цвета для выделенного состояния
            final selectedBgColor = isDark
                ? Colors.green.withValues(alpha: 0.2)
                : Colors.green.shade50;
            final selectedTextColor = isDark
                ? Colors.greenAccent.shade100
                : Colors.green.shade700;
            final selectedSubColor = isDark
                ? Colors.greenAccent.shade100.withValues(alpha: 0.7)
                : Colors.green.shade600;

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
                });
              },
              child: Card(
                color: isSelected ? selectedBgColor : theme.colorScheme.surface,
                elevation: isSelected ? 2 : 0,
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  leading: Text(
                    estimate.number,
                    style: TextStyle(
                      color: isSelected
                          ? selectedTextColor
                          : theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  title: Text(
                    estimate.name,
                    style: TextStyle(
                      color: isSelected
                          ? selectedTextColor
                          : theme.colorScheme.onSurface,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                  subtitle: Text(
                    '${formatCurrency(estimate.price)} / ${estimate.unit}',
                    style: TextStyle(
                      color: isSelected
                          ? selectedSubColor
                          : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  trailing: isSelected
                      ? SizedBox(
                          width: 80,
                          child: GTTextField(
                            controller: _quantityControllers[estimate],
                            hintText: 'Кол-во',
                            borderRadius: 8,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 8,
                            ),
                            textAlign: TextAlign.center,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                // ignore: deprecated_member_use
                                RegExp(r'[0-9.,]'),
                              ),
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
          }, childCount: filteredBySearch.length),
        ),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: GTTextButton(
              icon: CupertinoIcons.add,
              text: 'Новый материал',
              onPressed: () async {
                if (_selectedSection == null ||
                    _selectedFloor == null ||
                    _selectedSystem == null ||
                    _selectedSubsystem == null) {
                  AppSnackBar.show(
                    context: context,
                    message: 'Сначала заполните участок, этаж, систему и подсистему',
                    kind: AppSnackBarKind.error,
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

                  final estimates = ref
                      .read(estimateNotifierProvider)
                      .estimates;
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
        ),
      ),
    ];
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

              // Не очищаем выбранные элементы при редактировании
              if (!isModifying) {
                _selectedEstimateItems.clear();
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

                // Не очищаем выбранные элементы при редактировании
                if (!isModifying) {
                  _selectedEstimateItems.clear();
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

                // Не очищаем выбранные элементы при редактировании
                if (!isModifying) {
                  _selectedEstimateItems.clear();
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

                // Не очищаем выбранные элементы при редактировании
                if (!isModifying) {
                  _selectedEstimateItems.clear();
                }
              });
              _updateFilteredEstimates();
            },
          ),
        ],
      ],
    );
  }
}
