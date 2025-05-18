import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/presentation/state/employee_state.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/features/timesheet/presentation/providers/timesheet_provider.dart';

class PayrollFilterState {
  final List<String> employeeIds;
  final List<String> objectIds;
  final List<String> positionNames;
  final int year;
  final int month;
  final List<dynamic> employees;
  final List<dynamic> objects;
  
  PayrollFilterState({
    this.employeeIds = const [],
    this.objectIds = const [],
    this.positionNames = const [],
    DateTime? dateTime,
    this.employees = const [],
    this.objects = const [],
  }) : year = dateTime?.year ?? DateTime.now().year,
       month = dateTime?.month ?? DateTime.now().month;

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
  
  // Конструктор с явными значениями года и месяца
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
  
  // Получение первого и последнего дня месяца
  DateTime get startDate => DateTime(year, month, 1);
  DateTime get endDate => DateTime(year, month + 1, 0);
}

class PayrollFilterNotifier extends StateNotifier<PayrollFilterState> {
  final Ref _ref;
  bool _isInitializing = false;
  
  PayrollFilterNotifier(this._ref) : super(PayrollFilterState()) {
    // Безопасно инициализируем данные при создании провайдера
    Future.microtask(() {
      _initializeData();
    });
  }

  Future<void> _initializeData() async {
    if (_isInitializing) return;
    _isInitializing = true;
    
    try {
      // Обновляем данные из уже доступных провайдеров
      updateDataFromProviders();
      
      // Загружаем сотрудников и объекты, если они еще не загружены
      final employeeState = _ref.read(employeeProvider);
      final objectState = _ref.read(objectProvider);
      
      // Инициируем загрузку данных и дожидаемся результатов
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
        // Дожидаемся завершения загрузки данных
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Обновляем состояние с новыми данными
        updateDataFromProviders();
      }
    } catch (e) {
      // Игнорируем ошибку
    } finally {
      _isInitializing = false;
    }
  }
  
  // Обновляет данные сотрудников и объектов из соответствующих провайдеров
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

  void setEmployeeFilter(List<String> ids) => state = state.copyWith(employeeIds: ids);
  void setObjectFilter(List<String> ids) => state = state.copyWith(objectIds: ids);
  void setPositionFilter(List<String> positions) => state = state.copyWith(positionNames: positions);
  void setYearMonth(int year, int month) => state = state.copyWith(year: year, month: month);
  void setYear(int year) => state = state.copyWith(year: year);
  void setMonth(int month) => state = state.copyWith(month: month);
  
  // Получение должностей сотрудников из табеля
  List<String> getPositionsFromTimesheet() {
    try {
      final timesheetState = _ref.read(timesheetProvider);
      
      return timesheetState.entries
          .map((e) => e.employeePosition)
          .where((p) => p != null && p.isNotEmpty)
          .map((p) => p!)
          .toSet()
          .toList()
        ..sort();
    } catch (e) {
      return [];
    }
  }
  
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

final payrollFilterProvider = StateNotifierProvider<PayrollFilterNotifier, PayrollFilterState>((ref) {
  return PayrollFilterNotifier(ref);
}); 