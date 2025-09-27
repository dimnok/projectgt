import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/presentation/state/employee_state.dart';

/// Состояние фильтрации выплат по ФОТ.
///
/// Хранит выбранные значения фильтров: диапазон дат выплат, способ выплаты, сотрудники.
/// Используется для динамической фильтрации данных выплат в модуле ФОТ.
class PayrollPayoutFilterState {
  /// Список выбранных идентификаторов сотрудников для фильтрации.
  final List<String> employeeIds;

  /// Список выбранных способов выплаты для фильтрации.
  final List<String> payoutMethods;

  /// Начальная дата диапазона выплат.
  final DateTime startDate;

  /// Конечная дата диапазона выплат.
  final DateTime endDate;

  /// Список всех сотрудников (для выпадающих списков и фильтрации).
  final List<dynamic> employees;

  /// Конструктор состояния фильтрации выплат.
  ///
  /// @param employeeIds Список выбранных сотрудников
  /// @param payoutMethods Список выбранных способов выплаты
  /// @param startDate Начальная дата диапазона
  /// @param endDate Конечная дата диапазона
  /// @param employees Список всех сотрудников
  PayrollPayoutFilterState({
    this.employeeIds = const [],
    this.payoutMethods = const [],
    DateTime? startDate,
    DateTime? endDate,
    this.employees = const [],
  })  : startDate =
            startDate ?? DateTime.now().subtract(const Duration(days: 30)),
        endDate = endDate ?? DateTime.now();

  /// Создаёт копию состояния с изменёнными полями.
  PayrollPayoutFilterState copyWith({
    List<String>? employeeIds,
    List<String>? payoutMethods,
    DateTime? startDate,
    DateTime? endDate,
    List<dynamic>? employees,
  }) =>
      PayrollPayoutFilterState(
        employeeIds: employeeIds ?? this.employeeIds,
        payoutMethods: payoutMethods ?? this.payoutMethods,
        startDate: startDate ?? this.startDate,
        endDate: endDate ?? this.endDate,
        employees: employees ?? this.employees,
      );
}

/// StateNotifier для управления состоянием фильтрации выплат.
///
/// Отвечает за инициализацию, обновление и сброс фильтров выплат, а также за загрузку данных сотрудников.
class PayrollPayoutFilterNotifier
    extends StateNotifier<PayrollPayoutFilterState> {
  final Ref _ref;
  bool _isInitializing = false;

  /// Конструктор.
  /// @param ref Riverpod Ref для доступа к другим провайдерам
  PayrollPayoutFilterNotifier(this._ref) : super(PayrollPayoutFilterState()) {
    // Безопасно инициализируем данные при создании провайдера
    Future.microtask(() {
      _initializeData();
    });
  }

  /// Инициализация данных сотрудников из провайдеров.
  Future<void> _initializeData() async {
    if (_isInitializing) return;
    _isInitializing = true;

    try {
      // Обновляем данные из уже доступных провайдеров
      updateDataFromProviders();

      // Загружаем сотрудников, если они еще не загружены
      final employeeState = _ref.read(employeeProvider);

      if (employeeState.employees.isEmpty) {
        try {
          // Запускаем загрузку сотрудников
          _ref.read(employeeProvider.notifier).getEmployees();
          // Ждем небольшой промежуток времени и обновляем состояние
          await Future.delayed(const Duration(milliseconds: 500));
          updateDataFromProviders();
        } catch (e) {
          // Игнорируем ошибку
        }
      }
    } catch (e) {
      // Игнорируем ошибку
    } finally {
      _isInitializing = false;
    }
  }

  /// Обновляет данные сотрудников из соответствующих провайдеров.
  void updateDataFromProviders() {
    try {
      final employeeState = _ref.read(employeeProvider);

      if (employeeState.employees.isNotEmpty) {
        state = state.copyWith(
          employees: employeeState.employees,
        );
      }
    } catch (e) {
      // Игнорируем ошибку
    }
  }

  /// Установить фильтр по сотрудникам.
  /// @param ids Список идентификаторов сотрудников
  void setEmployeeFilter(List<String> ids) =>
      state = state.copyWith(employeeIds: ids);

  /// Установить фильтр по способам выплаты.
  /// @param methods Список способов выплаты
  void setPayoutMethodFilter(List<String> methods) =>
      state = state.copyWith(payoutMethods: methods);

  /// Установить диапазон дат выплат.
  /// @param startDate Начальная дата
  /// @param endDate Конечная дата
  void setDateRange(DateTime startDate, DateTime endDate) =>
      state = state.copyWith(startDate: startDate, endDate: endDate);

  /// Установить начальную дату диапазона.
  /// @param date Начальная дата
  void setStartDate(DateTime date) => state = state.copyWith(startDate: date);

  /// Установить конечную дату диапазона.
  /// @param date Конечная дата
  void setEndDate(DateTime date) => state = state.copyWith(endDate: date);

  /// Сбросить все фильтры к значениям по умолчанию (последние 30 дней, все сотрудники и способы).
  void resetFilters() {
    final now = DateTime.now();
    state = PayrollPayoutFilterState(
      employeeIds: [],
      payoutMethods: [],
      startDate: now.subtract(const Duration(days: 30)),
      endDate: now,
      employees: state.employees,
    );
  }
}

/// Провайдер состояния фильтрации выплат.
///
/// Используется для доступа к текущему состоянию фильтров выплат и управления ими в табе "Выплаты".
final payrollPayoutFilterProvider = StateNotifierProvider<
    PayrollPayoutFilterNotifier, PayrollPayoutFilterState>((ref) {
  return PayrollPayoutFilterNotifier(ref);
});

/// Список доступных способов выплаты.
const List<Map<String, String>> availablePayoutMethods = [
  {'value': 'cash', 'name': 'Наличные'},
  {'value': 'bank_transfer', 'name': 'Банковский перевод'},
  {'value': 'card', 'name': 'Карта'},
];
