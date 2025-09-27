import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/di/providers.dart';

/// Состояние фильтрации выгрузки данных.
///
/// Хранит выбранные значения фильтров: объекты, договоры, системы, подсистемы, период.
/// Используется для динамической фильтрации данных в модуле выгрузки.
class ExportFilterState {
  /// Список выбранных идентификаторов объектов для фильтрации.
  final List<String> objectIds;

  /// Список выбранных идентификаторов договоров для фильтрации.
  final List<String> contractIds;

  /// Список выбранных систем для фильтрации.
  final List<String> systems;

  /// Список выбранных подсистем для фильтрации.
  final List<String> subsystems;

  /// Дата начала периода.
  final DateTime dateFrom;

  /// Дата окончания периода.
  final DateTime dateTo;

  /// Список всех объектов (для выпадающих списков и фильтрации).
  final List<dynamic> objects;

  /// Список всех договоров (для выпадающих списков и фильтрации).
  final List<dynamic> contracts;

  /// Список всех доступных систем.
  final List<String> availableSystems;

  /// Список всех доступных подсистем.
  final List<String> availableSubsystems;

  /// Конструктор состояния фильтрации выгрузки.
  ExportFilterState({
    this.objectIds = const [],
    this.contractIds = const [],
    this.systems = const [],
    this.subsystems = const [],
    DateTime? dateFrom,
    DateTime? dateTo,
    this.objects = const [],
    this.contracts = const [],
    this.availableSystems = const [],
    this.availableSubsystems = const [],
  })  : dateFrom =
            dateFrom ?? DateTime(DateTime.now().year, DateTime.now().month, 1),
        dateTo = dateTo ??
            DateTime(DateTime.now().year, DateTime.now().month + 1, 0);

  /// Создаёт копию состояния с изменёнными полями.
  ExportFilterState copyWith({
    List<String>? objectIds,
    List<String>? contractIds,
    List<String>? systems,
    List<String>? subsystems,
    DateTime? dateFrom,
    DateTime? dateTo,
    List<dynamic>? objects,
    List<dynamic>? contracts,
    List<String>? availableSystems,
    List<String>? availableSubsystems,
  }) =>
      ExportFilterState(
        objectIds: objectIds ?? this.objectIds,
        contractIds: contractIds ?? this.contractIds,
        systems: systems ?? this.systems,
        subsystems: subsystems ?? this.subsystems,
        dateFrom: dateFrom ?? this.dateFrom,
        dateTo: dateTo ?? this.dateTo,
        objects: objects ?? this.objects,
        contracts: contracts ?? this.contracts,
        availableSystems: availableSystems ?? this.availableSystems,
        availableSubsystems: availableSubsystems ?? this.availableSubsystems,
      );
}

/// StateNotifier для управления состоянием фильтрации выгрузки.
///
/// Отвечает за инициализацию, обновление и сброс фильтров, а также за загрузку данных.
class ExportFilterNotifier extends StateNotifier<ExportFilterState> {
  final Ref _ref;
  bool _isInitializing = false;

  /// Конструктор.
  ExportFilterNotifier(this._ref) : super(ExportFilterState()) {
    // Безопасно инициализируем данные при создании провайдера
    Future.microtask(() {
      _initializeData();
    });
  }

  /// Инициализация данных объектов, договоров и смет из провайдеров.
  Future<void> _initializeData() async {
    if (_isInitializing) return;
    _isInitializing = true;

    try {
      // Обновляем данные из уже доступных провайдеров
      updateDataFromProviders();

      // Загружаем данные, если они еще не загружены
      final objectState = _ref.read(objectProvider);
      final contractState = _ref.read(contractProvider);
      final estimateState = _ref.read(estimateNotifierProvider);

      bool needsToWait = false;

      if (objectState.objects.isEmpty) {
        needsToWait = true;
        try {
          _ref.read(objectProvider.notifier).loadObjects();
        } catch (e) {
          // Игнорируем ошибку
        }
      }

      if (contractState.contracts.isEmpty) {
        needsToWait = true;
        try {
          _ref.read(contractProvider.notifier).loadContracts();
        } catch (e) {
          // Игнорируем ошибку
        }
      }

      if (estimateState.estimates.isEmpty) {
        needsToWait = true;
        try {
          _ref.read(estimateNotifierProvider.notifier).loadEstimates();
        } catch (e) {
          // Игнорируем ошибку
        }
      }

      // Если требуется дождаться завершения загрузки данных,
      // ждем небольшой промежуток времени и обновляем состояние
      if (needsToWait) {
        await Future.delayed(const Duration(milliseconds: 500));
        updateDataFromProviders();
      }
    } catch (e) {
      // Игнорируем ошибку
    } finally {
      _isInitializing = false;
    }
  }

  /// Обновляет данные из соответствующих провайдеров.
  void updateDataFromProviders() {
    try {
      final objectState = _ref.read(objectProvider);
      final contractState = _ref.read(contractProvider);
      final estimateState = _ref.read(estimateNotifierProvider);

      // Извлекаем уникальные системы и подсистемы из смет
      final systems = <String>{};
      final subsystems = <String>{};

      for (final estimate in estimateState.estimates) {
        if (estimate.system.isNotEmpty) {
          systems.add(estimate.system);
        }
        if (estimate.subsystem.isNotEmpty) {
          subsystems.add(estimate.subsystem);
        }
      }

      final systemsList = systems.toList()..sort();
      final subsystemsList = subsystems.toList()..sort();

      state = state.copyWith(
        objects: objectState.objects,
        contracts: contractState.contracts,
        availableSystems: systemsList,
        availableSubsystems: subsystemsList,
      );
    } catch (e) {
      // Игнорируем ошибку
    }
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

  /// Установить фильтр по подсистемам.
  void setSubsystemFilter(List<String> subsystems) =>
      state = state.copyWith(subsystems: subsystems);

  /// Установить период фильтрации.
  void setPeriod(DateTime dateFrom, DateTime dateTo) =>
      state = state.copyWith(dateFrom: dateFrom, dateTo: dateTo);

  /// Установить дату начала периода.
  void setDateFrom(DateTime dateFrom) =>
      state = state.copyWith(dateFrom: dateFrom);

  /// Установить дату окончания периода.
  void setDateTo(DateTime dateTo) => state = state.copyWith(dateTo: dateTo);

  /// Сбросить все фильтры к значениям по умолчанию.
  void resetFilters() {
    final now = DateTime.now();
    state = ExportFilterState(
      objectIds: [],
      contractIds: [],
      systems: [],
      subsystems: [],
      dateFrom: DateTime(now.year, now.month, 1),
      dateTo: DateTime(now.year, now.month + 1, 0),
      objects: state.objects,
      contracts: state.contracts,
      availableSystems: state.availableSystems,
      availableSubsystems: state.availableSubsystems,
    );
  }
}

/// Провайдер состояния фильтрации выгрузки.
final exportFilterProvider =
    StateNotifierProvider<ExportFilterNotifier, ExportFilterState>((ref) {
  return ExportFilterNotifier(ref);
});

/// Провайдер объектов с учётом каскадных фильтров
final availableObjectsForExportProvider = Provider<List<dynamic>>((ref) {
  final filter = ref.watch(exportFilterProvider);
  final estimateState = ref.watch(estimateNotifierProvider);

  // Если выбраны договоры, системы или подсистемы — фильтруем по ним
  final filteredEstimates = estimateState.estimates.where((estimate) {
    final byContract = filter.contractIds.isEmpty ||
        filter.contractIds.contains(estimate.contractId);
    final bySystem =
        filter.systems.isEmpty || filter.systems.contains(estimate.system);
    final bySubsystem = filter.subsystems.isEmpty ||
        filter.subsystems.contains(estimate.subsystem);
    return byContract && bySystem && bySubsystem;
  });

  final objectIds = filteredEstimates.map((e) => e.objectId).toSet();
  return filter.objects.where((o) => objectIds.contains(o.id)).toList();
});

/// Провайдер договоров с учётом каскадных фильтров
final availableContractsForExportProvider = Provider<List<dynamic>>((ref) {
  final filter = ref.watch(exportFilterProvider);
  final estimateState = ref.watch(estimateNotifierProvider);

  // Если выбраны объекты, системы или подсистемы — фильтруем по ним
  final filteredEstimates = estimateState.estimates.where((estimate) {
    final byObject = filter.objectIds.isEmpty ||
        filter.objectIds.contains(estimate.objectId);
    final bySystem =
        filter.systems.isEmpty || filter.systems.contains(estimate.system);
    final bySubsystem = filter.subsystems.isEmpty ||
        filter.subsystems.contains(estimate.subsystem);
    return byObject && bySystem && bySubsystem;
  });

  final contractIds = filteredEstimates.map((e) => e.contractId).toSet();
  return filter.contracts.where((c) => contractIds.contains(c.id)).toList();
});

/// Провайдер систем с учётом каскадных фильтров
final availableSystemsForExportProvider = Provider<List<String>>((ref) {
  final filter = ref.watch(exportFilterProvider);
  final estimateState = ref.watch(estimateNotifierProvider);

  // Если выбраны объекты, договоры или подсистемы — фильтруем по ним
  final filteredEstimates = estimateState.estimates.where((estimate) {
    final byObject = filter.objectIds.isEmpty ||
        filter.objectIds.contains(estimate.objectId);
    final byContract = filter.contractIds.isEmpty ||
        filter.contractIds.contains(estimate.contractId);
    final bySubsystem = filter.subsystems.isEmpty ||
        filter.subsystems.contains(estimate.subsystem);
    return byObject && byContract && bySubsystem;
  });

  final systems = filteredEstimates
      .map((e) => e.system)
      .where((s) => s.isNotEmpty)
      .toSet()
      .toList();
  systems.sort();
  return systems;
});

/// Провайдер подсистем с учётом каскадных фильтров
final availableSubsystemsForExportProvider = Provider<List<String>>((ref) {
  final filter = ref.watch(exportFilterProvider);
  final estimateState = ref.watch(estimateNotifierProvider);

  // Если выбраны объекты, договоры или системы — фильтруем по ним
  final filteredEstimates = estimateState.estimates.where((estimate) {
    final byObject = filter.objectIds.isEmpty ||
        filter.objectIds.contains(estimate.objectId);
    final byContract = filter.contractIds.isEmpty ||
        filter.contractIds.contains(estimate.contractId);
    final bySystem =
        filter.systems.isEmpty || filter.systems.contains(estimate.system);
    return byObject && byContract && bySystem;
  });

  final subsystems = filteredEstimates
      .map((e) => e.subsystem)
      .where((s) => s.isNotEmpty)
      .toSet()
      .toList();
  subsystems.sort();
  return subsystems;
});
