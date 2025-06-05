import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/presentation/state/employee_state.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:collection/collection.dart'; // Добавляем импорт для firstWhereOrNull
import 'payroll_providers.dart'; // Добавляем импорт для payrollWorkHoursProvider

/// Состояние фильтрации расчётов ФОТ.
/// 
/// Хранит выбранные значения фильтров: сотрудники, объекты, должности, год, месяц, а также списки всех сотрудников и объектов.
/// Используется для динамической фильтрации данных в модуле ФОТ.
class PayrollFilterState {
  /// Список выбранных идентификаторов сотрудников для фильтрации.
  final List<String> employeeIds;
  /// Список выбранных идентификаторов объектов для фильтрации.
  final List<String> objectIds;
  /// Список выбранных должностей для фильтрации.
  final List<String> positionNames;
  /// Год расчёта (например, 2024).
  final int year;
  /// Месяц расчёта (1-12).
  final int month;
  /// Список всех сотрудников (для выпадающих списков и фильтрации).
  final List<dynamic> employees;
  /// Список всех объектов (для выпадающих списков и фильтрации).
  final List<dynamic> objects;
  
  /// Конструктор состояния фильтрации ФОТ.
  /// 
  /// @param employeeIds Список выбранных сотрудников
  /// @param objectIds Список выбранных объектов
  /// @param positionNames Список выбранных должностей
  /// @param dateTime Дата для инициализации года и месяца
  /// @param employees Список всех сотрудников
  /// @param objects Список всех объектов
  PayrollFilterState({
    this.employeeIds = const [],
    this.objectIds = const [],
    this.positionNames = const [],
    DateTime? dateTime,
    this.employees = const [],
    this.objects = const [],
  }) : year = dateTime?.year ?? DateTime.now().year,
       month = dateTime?.month ?? DateTime.now().month;

  /// Создаёт копию состояния с изменёнными полями.
  PayrollFilterState copyWith({
    List<String>? employeeIds,
    List<String>? objectIds,
    List<String>? positionNames,
    int? year,
    int? month,
    List<dynamic>? employees,
    List<dynamic>? objects,
  }) => PayrollFilterState.fromValues(
    employeeIds: employeeIds ?? this.employeeIds,
    objectIds: objectIds ?? this.objectIds,
    positionNames: positionNames ?? this.positionNames,
    year: year ?? this.year,
    month: month ?? this.month,
    employees: employees ?? this.employees,
    objects: objects ?? this.objects,
  );
  
  /// Конструктор с явными значениями года и месяца.
  /// @param employeeIds Список выбранных сотрудников
  /// @param objectIds Список выбранных объектов
  /// @param positionNames Список выбранных должностей
  /// @param year Год
  /// @param month Месяц
  /// @param employees Список всех сотрудников
  /// @param objects Список всех объектов
  factory PayrollFilterState.fromValues({
    List<String> employeeIds = const [],
    List<String> objectIds = const [],
    List<String> positionNames = const [],
    required int year,
    required int month,
    List<dynamic> employees = const [],
    List<dynamic> objects = const [],
  }) {
    return PayrollFilterState(
      employeeIds: employeeIds,
      objectIds: objectIds,
      positionNames: positionNames,
      dateTime: DateTime(year, month),
      employees: employees,
      objects: objects,
    );
  }
  
  /// Получение первого дня месяца для фильтрации.
  DateTime get startDate => DateTime(year, month, 1);
  /// Получение последнего дня месяца для фильтрации.
  DateTime get endDate => DateTime(year, month + 1, 0);
}

/// StateNotifier для управления состоянием фильтрации ФОТ.
/// 
/// Отвечает за инициализацию, обновление и сброс фильтров, а также за загрузку данных сотрудников и объектов.
class PayrollFilterNotifier extends StateNotifier<PayrollFilterState> {
  final Ref _ref;
  bool _isInitializing = false;
  
  /// Конструктор.
  /// @param ref Riverpod Ref для доступа к другим провайдерам
  PayrollFilterNotifier(this._ref) : super(PayrollFilterState()) {
    // Безопасно инициализируем данные при создании провайдера
    Future.microtask(() {
      _initializeData();
    });
  }

  /// Инициализация данных сотрудников и объектов из провайдеров.
  Future<void> _initializeData() async {
    if (_isInitializing) return;
    _isInitializing = true;
    
    try {
      // Обновляем данные из уже доступных провайдеров
      updateDataFromProviders();
      
      // Загружаем сотрудников и объекты, если они еще не загружены
      final employeeState = _ref.read(employeeProvider);
      final objectState = _ref.read(objectProvider);
      
      bool needsToWait = false;
      
      if (employeeState.employees.isEmpty) {
        needsToWait = true;
        try {
          // Запускаем загрузку сотрудников
          _ref.read(employeeProvider.notifier).getEmployees();
        } catch (e) {
          // Игнорируем ошибку
        }
      }
      
      if (objectState.objects.isEmpty) {
        needsToWait = true;
        try {
          // Запускаем загрузку объектов
          _ref.read(objectProvider.notifier).loadObjects();
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
  
  /// Обновляет данные сотрудников и объектов из соответствующих провайдеров.
  void updateDataFromProviders() {
    try {
      final employeeState = _ref.read(employeeProvider);
      final objectState = _ref.read(objectProvider);
      
      if (employeeState.employees.isNotEmpty || objectState.objects.isNotEmpty) {
        state = state.copyWith(
          employees: employeeState.employees,
          objects: objectState.objects,
        );
      }
    } catch (e) {
      // Игнорируем ошибку
    }
  }

  /// Установить фильтр по сотрудникам.
  /// @param ids Список идентификаторов сотрудников
  void setEmployeeFilter(List<String> ids) => state = state.copyWith(employeeIds: ids);
  /// Установить фильтр по объектам.
  /// @param ids Список идентификаторов объектов
  void setObjectFilter(List<String> ids) => state = state.copyWith(objectIds: ids);
  /// Установить фильтр по должностям.
  /// @param positions Список должностей
  void setPositionFilter(List<String> positions) => state = state.copyWith(positionNames: positions);
  /// Установить год и месяц фильтрации.
  /// @param year Год
  /// @param month Месяц
  void setYearMonth(int year, int month) => state = state.copyWith(year: year, month: month);
  /// Установить год фильтрации.
  /// @param year Год
  void setYear(int year) => state = state.copyWith(year: year);
  /// Установить месяц фильтрации.
  /// @param month Месяц
  void setMonth(int month) => state = state.copyWith(month: month);
  
  /// Сбросить все фильтры к значениям по умолчанию (текущий месяц, все сотрудники и объекты).
  void resetFilters() {
    final now = DateTime.now();
    state = PayrollFilterState.fromValues(
      employeeIds: [], 
      objectIds: [], 
      positionNames: [],
      year: now.year, 
      month: now.month,
      employees: state.employees,
      objects: state.objects,
    );
  }
}

/// Провайдер состояния фильтрации ФОТ.
/// 
/// Используется для доступа к текущему состоянию фильтров и управления ими во всех слоях модуля ФОТ.
final payrollFilterProvider = StateNotifierProvider<PayrollFilterNotifier, PayrollFilterState>((ref) {
  return PayrollFilterNotifier(ref);
});

/// Провайдер сотрудников за выбранный период с учётом каскадных фильтров
final availableEmployeesForPeriodProvider = Provider<List<dynamic>>((ref) {
  final filter = ref.watch(payrollFilterProvider);
  
  // Используем независимые данные work_hours вместо timesheetEntries
  final workHoursAsync = ref.watch(payrollWorkHoursProvider);
  final workHours = workHoursAsync.asData?.value ?? <dynamic>[];
  
  // Фильтруем по периоду (уже отфильтровано в payrollWorkHoursProvider)
  final periodEntries = workHours;
  
  // Если выбраны объекты или должности — фильтруем по ним
  final filteredEntries = periodEntries.where((entry) {
    final byObject = filter.objectIds.isEmpty || filter.objectIds.contains(entry.objectId);
    
    // Для фильтрации по должности получаем данные из employees
    bool byPosition = true;
    if (filter.positionNames.isNotEmpty) {
      final employee = filter.employees.firstWhereOrNull((e) => e.id == entry.employeeId);
      byPosition = employee != null && employee.position != null && filter.positionNames.contains(employee.position);
    }
    
    return byObject && byPosition;
  });
  
  final employeeIds = filteredEntries.map((e) => e.employeeId).toSet();
  return filter.employees.where((e) => employeeIds.contains(e.id)).toList();
});

/// Провайдер объектов за выбранный период с учётом каскадных фильтров
final availableObjectsForPeriodProvider = Provider<List<dynamic>>((ref) {
  final filter = ref.watch(payrollFilterProvider);
  
  // Используем независимые данные work_hours вместо timesheetEntries
  final workHoursAsync = ref.watch(payrollWorkHoursProvider);
  final workHours = workHoursAsync.asData?.value ?? <dynamic>[];
  
  // Фильтруем по периоду (уже отфильтровано в payrollWorkHoursProvider)
  final periodEntries = workHours;
  
  // Если выбраны сотрудники или должности — фильтруем по ним
  final filteredEntries = periodEntries.where((entry) {
    final byEmployee = filter.employeeIds.isEmpty || filter.employeeIds.contains(entry.employeeId);
    
    // Для фильтрации по должности получаем данные из employees
    bool byPosition = true;
    if (filter.positionNames.isNotEmpty) {
      final employee = filter.employees.firstWhereOrNull((e) => e.id == entry.employeeId);
      byPosition = employee != null && employee.position != null && filter.positionNames.contains(employee.position);
    }
    
    return byEmployee && byPosition;
  });
  
  final objectIds = filteredEntries.map((e) => e.objectId).where((id) => id.isNotEmpty).toSet();
  return filter.objects.where((o) => objectIds.contains(o.id)).toList();
});

/// Провайдер должностей за выбранный период с учётом каскадных фильтров
final availablePositionsForPeriodProvider = Provider<List<String>>((ref) {
  final filter = ref.watch(payrollFilterProvider);
  
  // Используем независимые данные work_hours вместо timesheetEntries
  final workHoursAsync = ref.watch(payrollWorkHoursProvider);
  final workHours = workHoursAsync.asData?.value ?? <dynamic>[];
  
  // Фильтруем по периоду (уже отфильтровано в payrollWorkHoursProvider)
  final periodEntries = workHours;
  
  // Если выбраны сотрудники или объекты — фильтруем по ним
  final filteredEntries = periodEntries.where((entry) {
    final byEmployee = filter.employeeIds.isEmpty || filter.employeeIds.contains(entry.employeeId);
    final byObject = filter.objectIds.isEmpty || filter.objectIds.contains(entry.objectId);
    return byEmployee && byObject;
  });
  
  // Получаем должности из данных employees (так как в work_hours нет поля position)
  final employeeIds = filteredEntries.map((e) => e.employeeId).toSet();
  final positions = filter.employees
      .where((e) => employeeIds.contains(e.id))
      .map((e) => e.position)
      .where((p) => p != null && p.isNotEmpty)
      .cast<String>() // Приводим к String после фильтрации null
      .toSet()
      .toList();
  
  positions.sort();
  return positions;
}); 