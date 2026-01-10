import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/di/providers.dart';

/// Провайдеры для фильтрации данных модуля ФОТ
///
/// Обеспечивают фильтрацию расчётов, премий, штрафов и выплат
/// по объектам сотрудников.

/// Доступные объекты для фильтрации ФОТ
final availableObjectsForPayrollProvider = Provider<List<dynamic>>((ref) {
  final objectState = ref.watch(objectProvider);
  return objectState.objects;
});

/// Состояние фильтров модуля ФОТ
class PayrollFilterState {
  /// Выбранные объекты для фильтрации
  final List<String> selectedObjectIds;

  /// Выбранный год
  final int selectedYear;

  /// Выбранный месяц
  final int selectedMonth;

  /// Конструктор состояния фильтров
  PayrollFilterState({
    this.selectedObjectIds = const [],
    int? selectedYear,
    int? selectedMonth,
  })  : selectedYear = selectedYear ?? DateTime.now().year,
        selectedMonth = selectedMonth ?? DateTime.now().month;

  /// Создаёт копию состояния с изменениями
  PayrollFilterState copyWith({
    List<String>? selectedObjectIds,
    int? selectedYear,
    int? selectedMonth,
  }) {
    return PayrollFilterState(
      selectedObjectIds: selectedObjectIds ?? this.selectedObjectIds,
      selectedYear: selectedYear ?? this.selectedYear,
      selectedMonth: selectedMonth ?? this.selectedMonth,
    );
  }

  /// Проверяет, активны ли какие-либо фильтры (кроме текущего месяца/года)
  bool get hasActiveFilters {
    final now = DateTime.now();
    final hasNonDefaultPeriod =
        selectedYear != now.year || selectedMonth != now.month;
    return selectedObjectIds.isNotEmpty || hasNonDefaultPeriod;
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

/// Провайдер состояния поиска в модуле ФОТ (текстовый запрос)
final payrollSearchQueryProvider = StateProvider<String>((ref) => '');

/// Провайдер видимости поля поиска в AppBar модуля ФОТ
final payrollSearchVisibleProvider = StateProvider<bool>((ref) => false);
