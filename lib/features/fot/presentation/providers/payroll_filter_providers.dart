import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/di/providers.dart';
import '../../../../presentation/state/employee_state.dart';

/// Провайдеры для фильтрации данных модуля ФОТ
///
/// Обеспечивают фильтрацию расчётов, премий, штрафов и выплат
/// по объектам и должностям сотрудников.

/// Доступные объекты для фильтрации ФОТ
final availableObjectsForPayrollProvider = Provider<List<dynamic>>((ref) {
  final objectState = ref.watch(objectProvider);
  return objectState.objects;
});

/// Доступные должности для фильтрации ФОТ
final availablePositionsForPayrollProvider =
    FutureProvider<List<String>>((ref) async {
  final employeeState = ref.watch(employeeProvider);
  final employees = employeeState.employees;

  try {
    final positions = employees
        .map((e) => e.position)
        .whereType<String>()
        .where((p) => p.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return positions;
  } catch (e) {
    return <String>[];
  }
});

/// Состояние фильтров модуля ФОТ
class PayrollFilterState {
  /// Выбранные объекты для фильтрации
  final List<String> selectedObjectIds;

  /// Выбранные должности для фильтрации
  final List<String> selectedPositions;

  /// Выбранный год
  final int selectedYear;

  /// Выбранный месяц
  final int selectedMonth;

  /// Конструктор состояния фильтров
  PayrollFilterState({
    this.selectedObjectIds = const [],
    this.selectedPositions = const [],
    int? selectedYear,
    int? selectedMonth,
  })  : selectedYear = selectedYear ?? DateTime.now().year,
        selectedMonth = selectedMonth ?? DateTime.now().month;

  /// Создаёт копию состояния с изменениями
  PayrollFilterState copyWith({
    List<String>? selectedObjectIds,
    List<String>? selectedPositions,
    int? selectedYear,
    int? selectedMonth,
  }) {
    return PayrollFilterState(
      selectedObjectIds: selectedObjectIds ?? this.selectedObjectIds,
      selectedPositions: selectedPositions ?? this.selectedPositions,
      selectedYear: selectedYear ?? this.selectedYear,
      selectedMonth: selectedMonth ?? this.selectedMonth,
    );
  }

  /// Проверяет, активны ли какие-либо фильтры (кроме текущего месяца/года)
  bool get hasActiveFilters {
    final now = DateTime.now();
    final hasNonDefaultPeriod =
        selectedYear != now.year || selectedMonth != now.month;
    return selectedObjectIds.isNotEmpty ||
        selectedPositions.isNotEmpty ||
        hasNonDefaultPeriod;
  }
}

/// Notifier для управления состоянием фильтров ФОТ
class PayrollFilterNotifier extends StateNotifier<PayrollFilterState> {
  /// Создаёт notifier с начальным состоянием
  PayrollFilterNotifier() : super(PayrollFilterState());

  /// Устанавливает выбранные объекты
  void setSelectedObjects(List<String> objectIds) {
    state = state.copyWith(selectedObjectIds: objectIds);
  }

  /// Устанавливает выбранные должности
  void setSelectedPositions(List<String> positions) {
    state = state.copyWith(selectedPositions: positions);
  }

  /// Устанавливает выбранный год и месяц
  void setYearAndMonth(int year, int month) {
    state = state.copyWith(selectedYear: year, selectedMonth: month);
  }

  /// Сбрасывает все фильтры
  void resetFilters() {
    state = PayrollFilterState();
  }
}

/// Провайдер состояния фильтров модуля ФОТ
final payrollFilterProvider =
    StateNotifierProvider<PayrollFilterNotifier, PayrollFilterState>((ref) {
  return PayrollFilterNotifier();
});
