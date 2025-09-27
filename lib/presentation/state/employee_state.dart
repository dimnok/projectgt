import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/domain/entities/employee.dart';

/// Перечисление возможных статусов загрузки и обработки сотрудников.
///
/// Используется для управления состоянием экрана и логики работы с сотрудниками.
enum EmployeeStatus {
  /// Начальное состояние (ничего не загружено).
  initial,

  /// Выполняется загрузка или операция.
  loading,

  /// Операция завершена успешно.
  success,

  /// Произошла ошибка при выполнении операции.
  error,
}

/// Состояние для работы с сотрудниками.
///
/// Хранит список сотрудников, выбранного сотрудника, статус загрузки, ошибку и поисковый запрос.
class EmployeeState {
  /// Текущий статус загрузки/операции ([EmployeeStatus]).
  final EmployeeStatus status;

  /// Текущий выбранный сотрудник (если есть).
  final Employee? employee;

  /// Список всех сотрудников.
  final List<Employee> employees;

  /// Сообщение об ошибке (если есть).
  final String? errorMessage;

  /// Поисковый запрос для фильтрации сотрудников.
  final String searchQuery;

  /// Создаёт новое состояние для работы с сотрудниками.
  ///
  /// [status] — статус загрузки/операции.
  /// [employee] — выбранный сотрудник (опционально).
  /// [employees] — список сотрудников (по умолчанию пустой).
  /// [errorMessage] — сообщение об ошибке (опционально).
  /// [searchQuery] — поисковый запрос (по умолчанию пустая строка).
  EmployeeState({
    required this.status,
    this.employee,
    this.employees = const [],
    this.errorMessage,
    this.searchQuery = '',
  });

  /// Возвращает начальное состояние ([EmployeeStatus.initial]).
  factory EmployeeState.initial() {
    return EmployeeState(status: EmployeeStatus.initial);
  }

  /// Создаёт копию состояния с изменёнными полями.
  ///
  /// [status] — новый статус (опционально).
  /// [employee] — новый выбранный сотрудник (опционально).
  /// [employees] — новый список сотрудников (опционально).
  /// [errorMessage] — новое сообщение об ошибке (опционально).
  /// [searchQuery] — новый поисковый запрос (опционально).
  EmployeeState copyWith({
    EmployeeStatus? status,
    Employee? employee,
    List<Employee>? employees,
    String? errorMessage,
    String? searchQuery,
  }) {
    return EmployeeState(
      status: status ?? this.status,
      employee: employee ?? this.employee,
      employees: employees ?? this.employees,
      errorMessage: errorMessage ?? this.errorMessage,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  /// Возвращает отфильтрованный список сотрудников по поисковому запросу [searchQuery].
  ///
  /// Если запрос пустой — возвращает всех сотрудников.
  List<Employee> get filteredEmployees {
    if (searchQuery.isEmpty) {
      return employees;
    }

    final query = searchQuery.toLowerCase();
    return employees.where((employee) {
      final fullName =
          '${employee.lastName} ${employee.firstName} ${employee.middleName ?? ''}'
              .toLowerCase();
      final position = employee.position?.toLowerCase() ?? '';
      final phone = employee.phone?.toLowerCase() ?? '';

      return fullName.contains(query) ||
          position.contains(query) ||
          phone.contains(query);
    }).toList();
  }
}

/// StateNotifier для управления состоянием и операциями с сотрудниками.
///
/// Позволяет загружать, создавать, обновлять, удалять и искать сотрудников, а также получать отдельного сотрудника по id.
class EmployeeNotifier extends StateNotifier<EmployeeState> {
  /// Use case для получения одного сотрудника.
  final getEmployeeUseCase = getEmployeeUseCaseProvider;

  /// Use case для получения всех сотрудников.
  final getEmployeesUseCase = getEmployeesUseCaseProvider;

  /// Use case для создания сотрудника.
  final createEmployeeUseCase = createEmployeeUseCaseProvider;

  /// Use case для обновления сотрудника.
  final updateEmployeeUseCase = updateEmployeeUseCaseProvider;

  /// Use case для удаления сотрудника.
  final deleteEmployeeUseCase = deleteEmployeeUseCaseProvider;

  /// Флаг загрузки списка сотрудников.
  bool _isLoadingEmployees = false;

  /// Кэш деталей сотрудников (по id).
  final Map<String, Employee> _employeeDetailsCache = {};

  /// Создаёт [EmployeeNotifier] и инициализирует состояние.
  EmployeeNotifier(Ref ref)
      : _ref = ref,
        super(EmployeeState.initial());

  final Ref _ref;

  /// Загружает отдельного сотрудника по [id].
  ///
  /// Сначала ищет в кэше, затем в списке, затем асинхронно обновляет детали с сервера.
  /// В случае успеха — обновляет состояние на success, иначе — error с сообщением.
  Future<void> getEmployee(String id) async {
    // 1. Сначала ищем в кэше
    if (_employeeDetailsCache.containsKey(id)) {
      state = state.copyWith(
        status: EmployeeStatus.success,
        employee: _employeeDetailsCache[id],
      );
    } else {
      // 2. Если нет в кэше — ищем в списке
      final fromList = state.employees.where((e) => e.id == id).toList();
      if (fromList.isNotEmpty) {
        state = state.copyWith(
          status: EmployeeStatus.success,
          employee: fromList.first,
        );
      } else {
        // Если нет даже в списке — показываем загрузку
        state = state.copyWith(status: EmployeeStatus.loading);
      }
    }

    // 3. Асинхронно обновляем детали с сервера
    try {
      final employee = await _ref.read(getEmployeeUseCaseProvider).execute(id);
      if (employee != null) {
        _employeeDetailsCache[id] = employee;
        state = state.copyWith(
          status: EmployeeStatus.success,
          employee: employee,
        );
      } else {
        state = state.copyWith(
          status: EmployeeStatus.error,
          errorMessage: 'Сотрудник не найден',
        );
      }
    } catch (e) {
      // Не сбрасываем employee, только статус и ошибку
      state = state.copyWith(
        status: EmployeeStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// Загружает список всех сотрудников.
  ///
  /// В случае успеха — обновляет состояние на success, иначе — error с сообщением.
  Future<void> getEmployees() async {
    if (_isLoadingEmployees ||
        (state.employees.isNotEmpty &&
            state.status == EmployeeStatus.success)) {
      return;
    }

    _isLoadingEmployees = true;
    state = state.copyWith(status: EmployeeStatus.loading);

    try {
      final employees = await _ref.read(getEmployeesUseCaseProvider).execute();
      state = state.copyWith(
        status: EmployeeStatus.success,
        employees: employees,
      );
    } catch (e) {
      state = state.copyWith(
        status: EmployeeStatus.error,
        errorMessage: e.toString(),
      );
    } finally {
      _isLoadingEmployees = false;
    }
  }

  /// Создаёт нового сотрудника.
  ///
  /// После успешного создания — добавляет сотрудника к текущему списку.
  Future<void> createEmployee(Employee employee) async {
    state = state.copyWith(status: EmployeeStatus.loading);
    try {
      final createdEmployee =
          await _ref.read(createEmployeeUseCaseProvider).execute(employee);

      // Добавляем нового сотрудника к текущему списку
      final updatedEmployees = [...state.employees, createdEmployee];

      state = state.copyWith(
        status: EmployeeStatus.success,
        employee: createdEmployee,
        employees: updatedEmployees,
      );
    } catch (e) {
      state = state.copyWith(
        status: EmployeeStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// Обновляет существующего сотрудника.
  ///
  /// После успешного обновления — обновляет сотрудника в текущем списке.
  Future<void> updateEmployee(Employee employee) async {
    state = state.copyWith(status: EmployeeStatus.loading);
    try {
      final updatedEmployee =
          await _ref.read(updateEmployeeUseCaseProvider).execute(employee);

      // Обновляем сотрудника в текущем списке
      final updatedEmployees = state.employees
          .map((e) => e.id == updatedEmployee.id ? updatedEmployee : e)
          .toList();

      state = state.copyWith(
        status: EmployeeStatus.success,
        employee: updatedEmployee,
        employees: updatedEmployees,
      );
    } catch (e) {
      state = state.copyWith(
        status: EmployeeStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// Удаляет сотрудника по [id].
  ///
  /// После успешного удаления — удаляет сотрудника из текущего списка.
  Future<void> deleteEmployee(String id) async {
    state = state.copyWith(status: EmployeeStatus.loading);
    try {
      // Удаляем фото сотрудника из Storage
      Employee? employee = state.employee;
      final displayName = employee != null
          ? '${employee.lastName} ${employee.firstName} ${employee.middleName ?? ''}'
              .trim()
          : '';
      await _ref.read(photoServiceProvider).deletePhoto(
            entity: 'employee',
            id: id,
            displayName: displayName,
          );
      await _ref.read(deleteEmployeeUseCaseProvider).execute(id);
      // Удаляем сотрудника из текущего списка
      final updatedEmployees =
          state.employees.where((e) => e.id != id).toList();
      state = state.copyWith(
        status: EmployeeStatus.success,
        employee: null,
        employees: updatedEmployees,
      );
    } catch (e) {
      state = state.copyWith(
        status: EmployeeStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// Устанавливает поисковый запрос для фильтрации сотрудников.
  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  /// Принудительно обновляет данные сотрудника по [id].
  Future<void> refreshEmployee(String id) async {
    return getEmployee(id);
  }

  /// Принудительно обновляет список сотрудников.
  Future<void> refreshEmployees() async {
    _isLoadingEmployees = false;
    return getEmployees();
  }
}

/// Провайдер состояния сотрудников.
///
/// Используется для доступа к [EmployeeNotifier] и [EmployeeState] во всём приложении через Riverpod.
final employeeProvider =
    StateNotifierProvider<EmployeeNotifier, EmployeeState>((ref) {
  return EmployeeNotifier(ref);
});
