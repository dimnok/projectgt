import 'dart:async';
import 'dart:math' as math;
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
import '../providers/repositories_providers.dart';
import '../../../../core/di/providers.dart';
import '../../../../domain/entities/estimate.dart';
import '../../../../core/widgets/gt_dropdown.dart';
import '../providers/work_provider.dart';
import '../../../../features/company/presentation/providers/company_providers.dart';
import 'package:projectgt/core/utils/modal_utils.dart';
import 'package:projectgt/core/utils/formatters.dart';
import 'package:collection/collection.dart';
import 'package:projectgt/features/contractors/domain/entities/contractor.dart';
import 'package:projectgt/features/contractors/presentation/state/contractor_state.dart';

/// Улучшенная версия модального окна для создания или редактирования работы (WorkItem).
class WorkItemFormImproved extends ConsumerStatefulWidget {
  /// Идентификатор смены, к которой относится работа.
  final String workId;

  /// Исходная работа для редактирования (null — создание новой).
  final WorkItem? initial;

  /// Идентификатор объекта, если форма открывается вне экрана смены.
  final String? initialObjectId;

  /// ID смет, уже занятых в смене для текущей комбинации фильтров (лёгкая загрузка).
  ///
  /// Если задан, форма не тянет все [work_items] смены для фильтра списка смет.
  final Set<String>? occupiedEstimateIdsForCombo;

  /// Контроллер прокрутки для DraggableScrollableSheet (используется только на мобильных в bottom sheet).
  final ScrollController? scrollController;

  /// Создаёт улучшенное модальное окно для добавления или редактирования работы.
  const WorkItemFormImproved({
    super.key,
    required this.workId,
    this.initial,
    this.initialObjectId,
    this.occupiedEstimateIdsForCombo,
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

  /// Узел фокуса для поля поиска по сметам (не даём потерять фокус при смене viewport / snap скролла).
  final FocusNode _searchFocusNode = FocusNode(
    debugLabel: 'workEstimateSearch',
  );

  String _searchQuery = '';

  /// Локальный [ScrollController] списка, если снаружи не передан [WorkItemFormImproved.scrollController].
  ScrollController? _ownedListScrollController;

  /// Дополнительная высота внизу мобильного скролла: не даёт сбросить offset при сужении списка по поиску.
  double _mobileScrollBottomPad = 0;

  /// Высота первого [SliverToBoxAdapter] (поля над списком смет) на мобилке — начало сливеров материалов в offset скролла.
  final GlobalKey _mobileLeadingBlockKey = GlobalKey();

  /// Поля выбора (участок / этаж / …) свернуты: освобождаем высоту, поиск остаётся в закреплённой шапке.
  ///
  /// Только мобильный layout: на десктопе внешний скролл не связан с [_listScrollController], сворачивание не включается.
  bool _selectionFieldsCollapsed = false;

  /// Порог смещения скролла (px), после которого сворачиваем блок полей выбора.
  static const double _collapseSelectionScrollThreshold = 40;

  /// Контроллер прокрутки списка формы (внешний или внутренний).
  ScrollController get _listScrollController =>
      widget.scrollController ?? _ownedListScrollController!;

  /// Флаг загрузки для отображения индикатора.
  final bool _isLoading = false;

  /// Флаг сохранения для отображения состояния кнопок.
  bool _isSaving = false;

  /// Выбранный подрядчик (null — работа силами компании).
  Contractor? _selectedContractor;

  /// Занятые estimate_id в смене (из [occupiedEstimateIdsForCombo] или провайдера).
  Set<String>? _occupiedEstimateIdsForCombo;

  /// Ввод количества специалистов подрядчика (показывается при выбранном подрядчике).
  late final TextEditingController _specialistsCountController;

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
            ks2Id: isModifying ? widget.initial!.ks2Id : null,
            contractorId: _selectedContractor?.id,
            specialistsCount: _selectedContractor == null
                ? null
                : _parsedSpecialistsCount(),
          ),
        );
      }

      // Если редактируем, обновляем; если добавляем, сохраняем
      if (isModifying) {
        // Редактируем первую (и единственную) работу
        await workItemsNotifier.update(itemsToAdd.first);
      } else {
        // Добавляем новые работы
        await workItemsNotifier.addMany(itemsToAdd);
      }

      // Закрываем модальное окно после успешного сохранения
      if (mounted) {
        Navigator.pop(context, true);
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
    if (widget.scrollController == null) {
      _ownedListScrollController = ScrollController();
    }
    _listScrollController.addListener(_handleScrollForSelectionCollapse);
    _specialistsCountController = TextEditingController(
      text: isModifying && widget.initial?.specialistsCount != null
          ? '${widget.initial!.specialistsCount}'
          : '',
    );
    final work = ref.read(workProvider(widget.workId));
    objectId = widget.initialObjectId ?? work?.objectId ?? '';
    if (objectId.isEmpty) {
      throw Exception('objectId не найден для данной смены');
    }
    if (isModifying) {
      _selectedSection = widget.initial!.section;
      _selectedFloor = widget.initial!.floor;
      _selectedSystem = widget.initial!.system;
      _selectedSubsystem = widget.initial!.subsystem;
    }

    if (widget.occupiedEstimateIdsForCombo != null) {
      _occupiedEstimateIdsForCombo =
          Set<String>.from(widget.occupiedEstimateIdsForCombo!);
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
    Future.microtask(() async {
      if (ref.read(estimateNotifierProvider).estimates.isEmpty) {
        await ref.read(estimateNotifierProvider.notifier).loadEstimates();
      }
      await ref.read(contractorNotifierProvider.notifier).loadContractors();
      if (!mounted) return;
      if (isModifying && widget.initial?.contractorId != null) {
        final list = ref.read(contractorNotifierProvider).contractors;
        final match = list
            .where((c) => c.id == widget.initial!.contractorId)
            .firstOrNull;
        setState(() => _selectedContractor = match);
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
    _listScrollController.removeListener(_handleScrollForSelectionCollapse);
    for (final controller in _quantityControllers.values) {
      controller.dispose();
    }
    _specialistsCountController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _ownedListScrollController?.dispose();
    super.dispose();
  }

  /// Сворачивает блок полей выбора при прокрутке списка вниз (контент уходит вверх).
  ///
  /// Не трогает поиск и [_onSearchQueryChanged]. Раскрытие только через [_expandSelectionFields].
  void _handleScrollForSelectionCollapse() {
    if (!mounted) return;
    if (!allSelected || _selectionFieldsCollapsed) return;
    if (!ResponsiveUtils.isMobile(context)) return;
    final c = _listScrollController;
    if (!c.hasClients) return;
    if (c.offset <= _collapseSelectionScrollThreshold) return;

    final box =
        _mobileLeadingBlockKey.currentContext?.findRenderObject() as RenderBox?;
    final leadingH = (box != null && box.hasSize) ? box.size.height : 0.0;

    setState(() {
      _selectionFieldsCollapsed = true;
    });

    if (leadingH > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !c.hasClients) return;
        final next = (c.offset - leadingH).clamp(
          0.0,
          c.position.maxScrollExtent,
        );
        if ((c.offset - next).abs() > 0.5) {
          c.jumpTo(next);
        }
      });
    }
  }

  /// Раскрывает поля выбора и прокручивает к началу формы, чтобы блок снова был виден.
  void _expandSelectionFields() {
    if (!_selectionFieldsCollapsed) return;
    setState(() {
      _selectionFieldsCollapsed = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_listScrollController.hasClients) return;
      _listScrollController.jumpTo(0);
    });
  }

  /// Разбор поля «специалисты» для сохранения (пусто → null).
  int? _parsedSpecialistsCount() {
    final raw = _specialistsCountController.text.trim();
    if (raw.isEmpty) return null;
    return int.tryParse(raw);
  }

  /// Валидация поля количества специалистов (только при выбранном подрядчике).
  String? _validateSpecialistsCount(String? value) {
    if (_selectedContractor == null) return null;
    final v = value?.trim() ?? '';
    if (v.isEmpty) return null;
    final n = int.tryParse(v);
    if (n == null) return 'Введите целое число';
    if (n < 0) return 'Не меньше 0';
    return null;
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
    final estimates = ref.read(estimateNotifierProvider).estimates.where((e) {
      if (e.objectId != objectId) return false;
      if (e.visibleInEstimatesModule) return true;
      return isModifying &&
          widget.initial != null &&
          e.id == widget.initial!.estimateId;
    });
    _availableSystems = estimates.map((e) => e.system).toSet().toList();

    if (mounted) {
      setState(() {});
    }
  }

  /// Обновляет список подсистем на основе выбранной системы
  void _updateSubsystems() {
    if (_selectedSystem?.isEmpty ?? true) {
      _availableSubsystems = [];
    } else {
      final estimates = ref.read(estimateNotifierProvider).estimates.where((e) {
        if (e.objectId != objectId || e.system != _selectedSystem) return false;
        if (e.visibleInEstimatesModule) return true;
        return isModifying &&
            widget.initial != null &&
            e.id == widget.initial!.estimateId;
      });
      _availableSubsystems = estimates.map((e) => e.subsystem).toSet().toList();
    }
    setState(() {});
  }

  /// Перезагружает занятые estimate_id при смене подрядчика (режим лёгкой загрузки).
  Future<void> _reloadOccupiedEstimateIdsIfNeeded() async {
    if (widget.occupiedEstimateIdsForCombo == null) return;
    if (_selectedSection == null ||
        _selectedFloor == null ||
        _selectedSystem == null ||
        _selectedSubsystem == null) {
      return;
    }
    final ids = await ref.read(workItemRepositoryProvider).fetchEstimateIdsForCombo(
          workId: widget.workId,
          section: _selectedSection!,
          floor: _selectedFloor!,
          system: _selectedSystem!,
          subsystem: _selectedSubsystem!,
          contractorId: _selectedContractor?.id,
        );
    if (!mounted) return;
    setState(() {
      _occupiedEstimateIdsForCombo = ids;
    });
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

    filteredList = filteredList.where((estimate) {
      if (estimate.visibleInEstimatesModule) return true;
      return isModifying &&
          widget.initial != null &&
          estimate.id == widget.initial!.estimateId;
    }).toList();

    // Исключаем из списка только те материалы (элементы сметы),
    // которые уже добавлены в текущую смену с выбранной комбинацией
    // (участок/этаж/система/подсистема)
    if (_selectedSection != null &&
        _selectedFloor != null &&
        _selectedSystem != null &&
        _selectedSubsystem != null) {
      final Set<String> existingEstimateIdsForCombo;
      if (_occupiedEstimateIdsForCombo != null) {
        existingEstimateIdsForCombo = _occupiedEstimateIdsForCombo!;
      } else {
        final workItemsAsync = ref.read(workItemsProvider(widget.workId));
        final existingItems = workItemsAsync.hasValue
            ? (workItemsAsync.value ?? [])
            : <WorkItem>[];
        existingEstimateIdsForCombo = existingItems
            .where(
              (item) =>
                  item.section == _selectedSection &&
                  item.floor == _selectedFloor &&
                  item.system == _selectedSystem &&
                  item.subsystem == _selectedSubsystem &&
                  item.contractorId == _selectedContractor?.id,
            )
            .map((e) => e.estimateId)
            .toSet();
      }

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
      _mobileScrollBottomPad = 0;
    });
  }

  /// Обновляет текст поиска по списку смет; на мобилке сохраняет offset прокрутки.
  void _onSearchQueryChanged(String value) {
    final isMobile = ResponsiveUtils.isMobile(context);
    final c = _listScrollController;
    final preserve = isMobile && c.hasClients ? c.offset : null;
    final beforeMax = c.hasClients ? c.position.maxScrollExtent : -1.0;
    final narrowing =
        _searchQuery.isNotEmpty &&
        value.startsWith(_searchQuery) &&
        value.length > _searchQuery.length;
    final firstSearchChar = _searchQuery.isEmpty && value.isNotEmpty;
    const preemptSlackPx = 64.0;

    /// Верхняя граница нижнего pad от текущего offset — без неё beforeMax раздувается
    /// от самого pad и headroom уходит в бесконечность (логи bottomPad 2813+).
    const maxPadAbovePreserve = 480.0;

    /// Ограничение добавки по «запасу» прокрутки до сужения (не зависит от pad).
    const maxNarrowingExtraPx = 320.0;
    final rawHeadroom = preserve != null
        ? math.max(0.0, beforeMax - preserve)
        : 0.0;
    final narrowingExtra = math.min(rawHeadroom * 1.5, maxNarrowingExtraPx);
    double? preemptTargetPx;
    if (isMobile && preserve != null && value.isNotEmpty) {
      if (firstSearchChar) {
        preemptTargetPx = preserve + preemptSlackPx;
      } else if (narrowing) {
        // Не используем _mobileScrollBottomPad в формуле — иначе beforeMax и pad
        // разгоняются по кругу.
        preemptTargetPx = preserve + preemptSlackPx + narrowingExtra;
      }
    }
    setState(() {
      if (value.isEmpty) {
        _mobileScrollBottomPad = 0;
      } else if (preemptTargetPx != null && preserve != null) {
        // До layout укороченного списка расширяем extent; потолок — от preserve.
        _mobileScrollBottomPad = math.min(
          math.max(_mobileScrollBottomPad, preemptTargetPx),
          preserve + maxPadAbovePreserve,
        );
      }
      _searchQuery = value;
    });
    if (preserve != null) {
      final target = preserve;
      final snapMaterialsToTop =
          isMobile && firstSearchChar && value.isNotEmpty;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        var desired = target;
        if (snapMaterialsToTop) {
          final materialsStart = _mobileMaterialsStartScrollOffset();
          // При свёрнутом leading ключ не в дереве — [materialsStart] == 0; раньше условие
          // materialsStart > 0 блокировало snap, и сохранялся большой [preserve] под pinned-поиском.
          if (desired > materialsStart) {
            desired = materialsStart;
          }
        }
        _ensureMobileScrollCapacityForSearch(desired);
      });
    }
  }

  /// Возвращает offset скролла, с которого начинается блок сливеров материалов (после полей выбора).
  double _mobileMaterialsStartScrollOffset() {
    final box =
        _mobileLeadingBlockKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) {
      return 0;
    }
    return box.size.height;
  }

  /// Увеличивает нижний «запас» скролла, если после сужения списка offset больше [maxScrollExtent].
  void _ensureMobileScrollCapacityForSearch(
    double desiredOffset, [
    int depth = 0,
  ]) {
    if (!mounted || depth > 4) return;
    final c = _listScrollController;
    if (!c.hasClients) return;
    final maxExt = c.position.maxScrollExtent;
    if (desiredOffset <= maxExt + 0.5) {
      final clamped = desiredOffset.clamp(0.0, maxExt);
      if ((c.offset - clamped).abs() > 0.5) {
        c.jumpTo(clamped);
      }
      return;
    }
    final deficit = desiredOffset - maxExt;
    setState(() {
      _mobileScrollBottomPad += deficit;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !c.hasClients) return;
      c.jumpTo(desiredOffset.clamp(0.0, c.position.maxScrollExtent));
      _ensureMobileScrollCapacityForSearch(desiredOffset, depth + 1);
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
    if ((!allSelected || !isMobile) && _selectionFieldsCollapsed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _selectionFieldsCollapsed = false;
        });
      });
    }
    final showSelectionCollapsed =
        _selectionFieldsCollapsed && allSelected && isMobile;
    final theme = Theme.of(context);
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

    if (isMobile) {
      return MobileBottomSheetContent(
        title: title,
        footer: footer,
        fixedFooter: true,
        scrollable: false,
        scrollController: _listScrollController,
        child: _isLoading
            ? const SizedBox(
                height: 120,
                child: Center(child: CupertinoActivityIndicator()),
              )
            : Form(
                key: _formKey,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final maxH = constraints.maxHeight;
                    final hasBoundedHeight =
                        maxH.isFinite && maxH < double.infinity;
                    // Один и тот же тип дерева всегда: иначе при первой букве поиска менялся
                    // shrinkWrap/viewport и терялся фокус. Непустой поиск — minHeight == maxH,
                    // чтобы короткий список не сжимал лист; пустой — minHeight 0, высота по контенту.
                    final searchActive = _searchQuery.isNotEmpty;
                    final scroll = CustomScrollView(
                      controller: _listScrollController,
                      primary: false,
                      shrinkWrap: true,
                      physics: const ClampingScrollPhysics(),
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      slivers: [
                        SliverToBoxAdapter(
                          child: AnimatedSize(
                            duration: const Duration(milliseconds: 240),
                            curve: Curves.easeInOutCubic,
                            alignment: Alignment.topCenter,
                            child: showSelectionCollapsed
                                ? const SizedBox(width: double.infinity)
                                : KeyedSubtree(
                                    key: _mobileLeadingBlockKey,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        _buildSelectionFields(),
                                        const SizedBox(height: 12),
                                      ],
                                    ),
                                  ),
                          ),
                        ),
                        if (allSelected)
                          ..._buildMaterialsSlivers(
                            theme,
                            scrollBottomPad: _mobileScrollBottomPad,
                          ),
                        SliverToBoxAdapter(
                          child: SizedBox(
                            height: MediaQuery.viewInsetsOf(context).bottom,
                          ),
                        ),
                      ],
                    );
                    if (!hasBoundedHeight) {
                      return scroll;
                    }
                    return ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: searchActive ? maxH : 0,
                        maxHeight: maxH,
                      ),
                      child: scroll,
                    );
                  },
                ),
              ),
      );
    }

    final content = _isLoading
        ? const Center(child: CupertinoActivityIndicator())
        : Form(key: _formKey, child: _buildFormContent(theme));

    return DesktopDialogContent(
      title: title,
      footer: footer,
      scrollable: false,
      child: content,
    );
  }

  /// Строит содержимое формы
  Widget _buildFormContent(ThemeData theme) {
    final isDesktop = ResponsiveUtils.isDesktop(context);
    final showSelectionCollapsed =
        _selectionFieldsCollapsed &&
        allSelected &&
        ResponsiveUtils.isMobile(context);
    return CustomScrollView(
      controller: _listScrollController,
      primary: false,
      shrinkWrap: !isDesktop,
      physics: isDesktop
          ? const ClampingScrollPhysics()
          : const NeverScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: AnimatedSize(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeInOutCubic,
            alignment: Alignment.topCenter,
            child: showSelectionCollapsed
                ? const SizedBox(width: double.infinity)
                : KeyedSubtree(
                    key: _mobileLeadingBlockKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildSelectionFields(),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
          ),
        ),
        if (allSelected)
          ..._buildMaterialsSlivers(
            theme,
            scrollBottomPad: ResponsiveUtils.isMobile(context)
                ? _mobileScrollBottomPad
                : 0,
          ),
      ],
    );
  }

  /// Сливеры списка смет, поиска и кнопки «Новый материал».
  ///
  /// [scrollBottomPad] — только мобилка: искусственно увеличивает [maxScrollExtent], чтобы при
  /// сужении результатов поиска не сбрасывалась прокрутка и не всплывали фильтры.
  List<Widget> _buildMaterialsSlivers(
    ThemeData theme, {
    double scrollBottomPad = 0,
  }) {
    final query = _searchQuery;
    final filteredBySearch = query.isEmpty
        ? _filteredEstimates
        : _filteredEstimates
              .where((e) => e.name.toLowerCase().contains(query.toLowerCase()))
              .toList();

    final showSelectionCollapsed =
        _selectionFieldsCollapsed &&
        allSelected &&
        ResponsiveUtils.isMobile(context);

    return [
      SliverPersistentHeader(
        pinned: true,
        delegate: _WorkEstimateSearchHeaderDelegate(
          theme: theme,
          searchController: _searchController,
          searchFocusNode: _searchFocusNode,
          onQueryChanged: _onSearchQueryChanged,
          filtersCollapsed: showSelectionCollapsed,
          onExpandFilters: _expandSelectionFields,
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
            final isDesktop = ResponsiveUtils.isDesktop(context);
            final titleFontSize = isDesktop ? 14.0 : 12.0;
            final subtitleFontSize = isDesktop ? 12.0 : 10.0;

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
                margin: const EdgeInsets.symmetric(vertical: 2),
                child: ListTile(
                  visualDensity: VisualDensity.compact,
                  minVerticalPadding: 0,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 2,
                  ),
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        estimate.name,
                        style: TextStyle(
                          color: isSelected
                              ? selectedTextColor
                              : theme.colorScheme.onSurface,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                          fontSize: titleFontSize,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${formatCurrency(estimate.price)} / ${estimate.unit}',
                        style: TextStyle(
                          color: isSelected
                              ? selectedSubColor
                              : theme.colorScheme.onSurface.withValues(
                                  alpha: 0.6,
                                ),
                          fontSize: subtitleFontSize,
                          height: 1.15,
                        ),
                      ),
                    ],
                  ),
                  trailing: isSelected
                      ? SizedBox(
                          width: 80,
                          child: GTTextField(
                            controller: _quantityControllers[estimate],
                            hintText: 'Кол-во',
                            borderRadius: 8,
                            style:
                                (theme.textTheme.bodyMedium ??
                                        const TextStyle())
                                    .copyWith(
                                      fontSize: isDesktop ? 14.0 : 12.0,
                                    ),
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
                    message:
                        'Сначала заполните участок, этаж, систему и подсистему',
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
      if (scrollBottomPad > 0)
        SliverToBoxAdapter(child: SizedBox(height: scrollBottomPad)),
    ];
  }

  /// Строит поля выбора участка, этажа, системы и подсистемы.
  Widget _buildSelectionFields() {
    final isSectionFilled =
        _selectedSection != null && _selectedSection!.isNotEmpty;
    final isFloorFilled = _selectedFloor != null && _selectedFloor!.isNotEmpty;
    final isSystemFilled =
        _selectedSystem != null && _selectedSystem!.isNotEmpty;
    final contractorState = ref.watch(contractorNotifierProvider);
    final contractorChoices = contractorState.contractors
        .where((c) => c.type == ContractorType.contractor)
        .toList();

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: GTDropdown<Contractor>(
                items: contractorChoices,
                itemDisplayBuilder: (c) => c.shortName,
                labelText: 'Подрядчик',
                hintText: 'Не выбран — наша бригада',
                selectedItem: _selectedContractor,
                allowClear: true,
                isLoading: contractorState.status == ContractorStatus.loading,
                onSelectionChanged: (value) {
                  setState(() {
                    _selectedContractor = value;
                    if (value == null) {
                      _specialistsCountController.clear();
                    }
                    if (!isModifying) {
                      _selectedEstimateItems.clear();
                    }
                  });
                  if (widget.occupiedEstimateIdsForCombo != null) {
                    unawaited(
                      _reloadOccupiedEstimateIdsIfNeeded().then((_) {
                        if (mounted) _updateFilteredEstimates();
                      }),
                    );
                  } else {
                    _updateFilteredEstimates();
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 96,
              child: GTTextField(
                controller: _specialistsCountController,
                labelText: 'Спец.',
                hintText: _selectedContractor == null ? '—' : null,
                enabled: _selectedContractor != null,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                textInputAction: TextInputAction.done,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: _validateSpecialistsCount,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
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

/// Закрепляемая под [SliverPersistentHeader] область поиска по списку сметных работ.
class _WorkEstimateSearchHeaderDelegate extends SliverPersistentHeaderDelegate {
  /// Создаёт делегат шапки поиска.
  _WorkEstimateSearchHeaderDelegate({
    required this.theme,
    required this.searchController,
    required this.searchFocusNode,
    required this.onQueryChanged,
    required this.filtersCollapsed,
    required this.onExpandFilters,
  });

  /// Тема для цветов поля и фона.
  final ThemeData theme;

  /// Контроллер текста поиска.
  final TextEditingController searchController;

  /// Узел фокуса поля поиска (тот же экземпляр на всём жизненном цикле формы).
  final FocusNode searchFocusNode;

  /// Вызывается при изменении запроса.
  final ValueChanged<String> onQueryChanged;

  /// Поля выбора (участок, этаж, …) свернуты — показываем кнопку раскрытия слева от поиска.
  final bool filtersCollapsed;

  /// Раскрывает блок полей выбора (мобильный режим).
  final VoidCallback onExpandFilters;

  static const double _toolbarHeight = 52;

  @override
  double get minExtent => _toolbarHeight;

  @override
  double get maxExtent => _toolbarHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final searchField = CupertinoSearchTextField(
      controller: searchController,
      focusNode: searchFocusNode,
      placeholder: 'Поиск работ...',
      onChanged: onQueryChanged,
      style: TextStyle(color: theme.colorScheme.onSurface),
    );

    return Material(
      color: theme.colorScheme.surface,
      elevation: overlapsContent ? 0.5 : 0,
      shadowColor: theme.colorScheme.shadow.withValues(alpha: 0.12),
      surfaceTintColor: Colors.transparent,
      child: SizedBox(
        height: _toolbarHeight,
        child: filtersCollapsed
            ? Padding(
                padding: const EdgeInsets.only(left: 4, right: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    IconButton(
                      tooltip: 'Показать фильтры',
                      style: IconButton.styleFrom(
                        foregroundColor: theme.colorScheme.onSurface,
                        backgroundColor:
                            theme.colorScheme.surfaceContainerHighest,
                        shape: const CircleBorder(),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        minimumSize: const Size(40, 40),
                        padding: EdgeInsets.zero,
                      ),
                      onPressed: onExpandFilters,
                      icon: const Icon(
                        CupertinoIcons.slider_horizontal_3,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: searchField),
                  ],
                ),
              )
            : Align(alignment: Alignment.centerLeft, child: searchField),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _WorkEstimateSearchHeaderDelegate oldDelegate) {
    return oldDelegate.theme != theme ||
        oldDelegate.searchController != searchController ||
        oldDelegate.searchFocusNode != searchFocusNode ||
        oldDelegate.filtersCollapsed != filtersCollapsed ||
        oldDelegate.onExpandFilters != onExpandFilters;
  }
}
