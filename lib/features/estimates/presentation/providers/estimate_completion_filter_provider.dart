import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/domain/entities/contract.dart';

/// Состояние фильтрации отчёта о выполнении смет.
class EstimateCompletionFilterState {
  /// Список выбранных идентификаторов объектов для фильтрации.
  final List<String> objectIds;

  /// Список выбранных идентификаторов договоров для фильтрации.
  final List<String> contractIds;

  /// Список выбранных систем для фильтрации.
  final List<String> systems;

  /// Список ПРИМЕНЁННЫХ идентификаторов объектов (после нажатия "Применить").
  final List<String> appliedObjectIds;

  /// Список ПРИМЕНЁННЫХ идентификаторов договоров (после нажатия "Применить").
  final List<String> appliedContractIds;

  /// Список ПРИМЕНЁННЫХ систем (после нажатия "Применить").
  final List<String> appliedSystems;

  /// Список всех объектов (для выпадающих списков и фильтрации).
  final List<dynamic> objects;

  /// Список всех договоров (для выпадающих списков и фильтрации).
  final List<dynamic> contracts;

  /// Список всех доступных систем.
  final List<String> availableSystems;

  /// Конструктор состояния фильтрации.
  EstimateCompletionFilterState({
    this.objectIds = const [],
    this.contractIds = const [],
    this.systems = const [],
    this.appliedObjectIds = const [],
    this.appliedContractIds = const [],
    this.appliedSystems = const [],
    this.objects = const [],
    this.contracts = const [],
    this.availableSystems = const [],
  });

  /// Создаёт копию состояния с изменёнными полями.
  EstimateCompletionFilterState copyWith({
    List<String>? objectIds,
    List<String>? contractIds,
    List<String>? systems,
    List<String>? appliedObjectIds,
    List<String>? appliedContractIds,
    List<String>? appliedSystems,
    List<dynamic>? objects,
    List<dynamic>? contracts,
    List<String>? availableSystems,
  }) =>
      EstimateCompletionFilterState(
        objectIds: objectIds ?? this.objectIds,
        contractIds: contractIds ?? this.contractIds,
        systems: systems ?? this.systems,
        appliedObjectIds: appliedObjectIds ?? this.appliedObjectIds,
        appliedContractIds: appliedContractIds ?? this.appliedContractIds,
        appliedSystems: appliedSystems ?? this.appliedSystems,
        objects: objects ?? this.objects,
        contracts: contracts ?? this.contracts,
        availableSystems: availableSystems ?? this.availableSystems,
      );
}

/// StateNotifier для управления состоянием фильтрации отчёта о выполнении.
class EstimateCompletionFilterNotifier
    extends StateNotifier<EstimateCompletionFilterState> {
  final Ref _ref;
  bool _isInitializing = false;

  /// Конструктор.
  EstimateCompletionFilterNotifier(this._ref)
      : super(EstimateCompletionFilterState()) {
    Future.microtask(() {
      _initializeData();
    });
  }

  /// Инициализация данных объектов, договоров и смет из провайдеров.
  Future<void> _initializeData() async {
    if (_isInitializing) return;
    _isInitializing = true;

    try {
      updateDataFromProviders();

      final objectState = _ref.read(objectProvider);
      final contractState = _ref.read(contractProvider);
      final estimateState = _ref.read(estimateNotifierProvider);

      bool needsToWait = false;

      if (objectState.objects.isEmpty) {
        needsToWait = true;
        _ref.read(objectProvider.notifier).loadObjects();
      }

      if (contractState.contracts.isEmpty) {
        needsToWait = true;
        _ref.read(contractProvider.notifier).loadContracts();
      }

      if (estimateState.estimates.isEmpty) {
        needsToWait = true;
        _ref.read(estimateNotifierProvider.notifier).loadEstimates();
      }

      if (needsToWait) {
        await Future.delayed(const Duration(milliseconds: 300));
        updateDataFromProviders();
      }
    } finally {
      _isInitializing = false;
    }
  }

  /// Обновляет данные из соответствующих провайдеров.
  void updateDataFromProviders() {
    final objectState = _ref.read(objectProvider);
    final contractState = _ref.read(contractProvider);
    final estimateState = _ref.read(estimateNotifierProvider);

    // Извлекаем уникальные системы из смет
    final systems = <String>{};

    for (final estimate in estimateState.estimates) {
      if (estimate.system.isNotEmpty) {
        systems.add(estimate.system);
      }
    }

    final systemsList = systems.toList()..sort();

    state = state.copyWith(
      objects: objectState.objects,
      contracts: contractState.contracts,
      availableSystems: systemsList,
    );
  }

  /// Установить фильтр по объектам.
  void setObjectFilter(List<String> ids) =>
      state = state.copyWith(objectIds: ids);

  /// Установить фильтр по договорам.
  void setContractFilter(List<String> ids) =>
      state = state.copyWith(contractIds: ids);

  /// Установить фильтр по системам.
  void setSystemFilter(List<String> systems) =>
      state = state.copyWith(systems: systems);

  /// Применить выбранные фильтры (вызывается при нажатии кнопки "Применить").
  void applyFilters() {
    state = state.copyWith(
      appliedObjectIds: state.objectIds,
      appliedContractIds: state.contractIds,
      appliedSystems: state.systems,
    );
  }

  /// Сбросить все фильтры к значениям по умолчанию.
  void resetFilters() {
    state = EstimateCompletionFilterState(
      objects: state.objects,
      contracts: state.contracts,
      availableSystems: state.availableSystems,
    );
  }
}

/// Провайдер состояния фильтрации отчёта о выполнении.
final estimateCompletionFilterProvider = StateNotifierProvider<
    EstimateCompletionFilterNotifier, EstimateCompletionFilterState>((ref) {
  return EstimateCompletionFilterNotifier(ref);
});

/// Провайдер объектов — только с активными договорами
final availableObjectsForCompletionProvider = Provider<List<dynamic>>((ref) {
  final filter = ref.watch(estimateCompletionFilterProvider);
  final contractState = ref.watch(contractProvider);

  // Получаем только активные договоры
  final activeContracts = contractState.contracts
      .where((c) => c.status == ContractStatus.active)
      .toList();

  // Собираем уникальные ID объектов с активными договорами
  final objectIds = activeContracts.map((c) => c.objectId).toSet();

  // Возвращаем только объекты которые есть в активных договорах
  return filter.objects.where((o) => objectIds.contains(o.id)).toList();
});

/// Провайдер договоров — только активные (в работе)
final availableContractsForCompletionProvider = Provider<List<dynamic>>((ref) {
  final filter = ref.watch(estimateCompletionFilterProvider);
  final contractState = ref.watch(contractProvider);

  // Если выбраны объекты или системы — фильтруем по ним
  final selectedObjectIds = filter.objectIds;

  // Фильтруем договоры: только активные со статусом "в работе"
  return contractState.contracts.where((c) {
    // Должен быть активный статус
    if (c.status != ContractStatus.active) return false;

    // Если выбраны объекты, договор должен быть для них
    if (selectedObjectIds.isNotEmpty &&
        !selectedObjectIds.contains(c.objectId)) {
      return false;
    }

    return true;
  }).toList();
});

/// Провайдер систем с учётом каскадных фильтров
final availableSystemsForCompletionProvider = Provider<List<String>>((ref) {
  final filter = ref.watch(estimateCompletionFilterProvider);
  final estimateState = ref.watch(estimateNotifierProvider);

  // Если выбраны объекты или договоры — фильтруем по ним
  final filteredEstimates = estimateState.estimates.where((estimate) {
    final byObject = filter.objectIds.isEmpty ||
        filter.objectIds.contains(estimate.objectId);
    final byContract = filter.contractIds.isEmpty ||
        filter.contractIds.contains(estimate.contractId);
    return byObject && byContract;
  });

  final systems = filteredEstimates
      .map((e) => e.system)
      .where((s) => s.isNotEmpty)
      .toSet()
      .toList();
  systems.sort();
  return systems;
});
