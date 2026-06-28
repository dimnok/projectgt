import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/core/utils/employee_delete_error_mapper.dart';
import 'package:projectgt/domain/entities/employee.dart';
import 'package:projectgt/domain/entities/employee_blocking_shift.dart';
import 'package:projectgt/features/company/presentation/providers/company_providers.dart';


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

  /// Кэш флага can_be_responsible по сотрудникам (id -> bool).
  final Map<String, bool> canBeResponsibleMap;

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
    this.canBeResponsibleMap = const {},
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
    Map<String, bool>? canBeResponsibleMap,
  }) {
    return EmployeeState(
      status: status ?? this.status,
      employee: employee ?? this.employee,
      employees: employees ?? this.employees,
      errorMessage: errorMessage ?? this.errorMessage,
      searchQuery: searchQuery ?? this.searchQuery,
      canBeResponsibleMap: canBeResponsibleMap ?? this.canBeResponsibleMap,
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
  /// При [forceRefresh] кэш игнорируется и данные запрашиваются заново.
  /// При успешном ответе обновляет и [EmployeeState.employee], и соответствующую
  /// запись в [EmployeeState.employees] (актуальные ставки и прочие денормализованные поля).
  Future<void> getEmployee(String id, {bool forceRefresh = false}) async {
    if (!forceRefresh && _employeeDetailsCache.containsKey(id)) {
      state = state.copyWith(
        status: EmployeeStatus.success,
        employee: _employeeDetailsCache[id],
      );
      return;
    }

    // 1. Если нет в кэше — ищем в списке для мгновенного отображения.
    if (!forceRefresh) {
      final fromList = state.employees.where((e) => e.id == id).toList();
      if (fromList.isNotEmpty) {
        state = state.copyWith(
          status: EmployeeStatus.success,
          employee: fromList.first,
        );
      } else {
        state = state.copyWith(status: EmployeeStatus.loading);
      }
    } else {
      state = state.copyWith(status: EmployeeStatus.loading);
    }

    // 2. Асинхронно обновляем детали с сервера.
    try {
      final employee = await _ref.read(getEmployeeUseCaseProvider).execute(id);
      if (employee != null) {
        _employeeDetailsCache[id] = employee;
        final employees = state.employees;
        final updatedEmployees = employees.any((e) => e.id == employee.id)
            ? employees
                .map((e) => e.id == employee.id ? employee : e)
                .toList()
            : employees;
        state = state.copyWith(
          status: EmployeeStatus.success,
          employee: employee,
          employees: updatedEmployees,
        );
      } else {
        state = state.copyWith(
          status: EmployeeStatus.error,
          errorMessage: 'Сотрудник не найден',
        );
      }
    } catch (e) {
      state = state.copyWith(
        status: EmployeeStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// Подготавливает данные для карточки из уже известного справочника (табель и т.п.).
  ///
  /// Не перезагружает строку `employees`, если она уже есть в [known].
  /// Запрашивает с сервера только текущую ставку, если её нет в кэше.
  Future<void> ensureEmployeeCardDetails(Employee known) async {
    final cached = _employeeDetailsCache[known.id];
    if (cached != null) {
      _setEmployeeDetail(cached);
      return;
    }

    if (known.currentHourlyRate != null) {
      _employeeDetailsCache[known.id] = known;
      _setEmployeeDetail(known);
      return;
    }

    try {
      final rate = await _ref
          .read(employeeRepositoryProvider)
          .getCurrentHourlyRate(known.id);
      final detailed = known.copyWith(currentHourlyRate: rate);
      _employeeDetailsCache[known.id] = detailed;
      _setEmployeeDetail(detailed);
    } catch (e) {
      _setEmployeeDetail(known);
    }
  }

  void _setEmployeeDetail(Employee employee) {
    state = state.copyWith(
      status: EmployeeStatus.success,
      employee: employee,
    );
  }

  /// Загружает список всех сотрудников.
  ///
  /// [includeResponsibilityMap] — если `true`, дополнительно подтягивает карту
  /// `can_be_responsible` из БД отдельным запросом. По умолчанию `false`:
  /// поле сейчас не потребляется ни одним UI-компонентом, а при включении
  /// флага на карточке сотрудника ([toggleCanBeResponsible]) мапа
  /// обновляется точечно. Тем самым исключается лишний round-trip на
  /// каждом открытии/обновлении списка сотрудников.
  ///
  /// В случае успеха — обновляет состояние на success, иначе — error с сообщением.
  Future<void> getEmployees({bool includeResponsibilityMap = false}) async {
    if (_isLoadingEmployees ||
        (state.employees.isNotEmpty &&
            state.status == EmployeeStatus.success)) {
      return;
    }

    _isLoadingEmployees = true;
    state = state.copyWith(status: EmployeeStatus.loading);

    try {
      final employees = await _ref.read(getEmployeesUseCaseProvider).execute();
      Map<String, bool> canMap = state.canBeResponsibleMap;
      if (includeResponsibilityMap) {
        // Подтягиваем фактические значения can_be_responsible из БД в мапу
        final ds = _ref.read(employeeDataSourceProvider);
        canMap = await ds.getCanBeResponsibleMap();
      }
      state = state.copyWith(
        status: EmployeeStatus.success,
        employees: employees,
        canBeResponsibleMap: canMap,
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
      final result =
          await _ref.read(updateEmployeeUseCaseProvider).execute(employee);

      // Сохраняем текущую ставку, так как она не возвращается при обновлении основной таблицы
      final updatedEmployee = result.copyWith(
        currentHourlyRate: result.currentHourlyRate ?? employee.currentHourlyRate,
      );

      _employeeDetailsCache[updatedEmployee.id] = updatedEmployee;

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
      // Ищем удаляемого сотрудника, чтобы достать его photoUrl
      final employeeToDelete = state.employees.where((e) => e.id == id).firstOrNull ??
          (state.employee?.id == id ? state.employee : null);

      final photoService = _ref.read(photoServiceProvider);

      // Удаляем конкретное фото по URL, если оно есть
      if (employeeToDelete?.photoUrl != null) {
        await photoService.deletePhotoByUrl(employeeToDelete!.photoUrl!);
      }

      // На всякий случай зачищаем папку (если там остались старые файлы)
      final displayName = employeeToDelete != null
          ? '${employeeToDelete.lastName} ${employeeToDelete.firstName} ${employeeToDelete.middleName ?? ''}'.trim()
          : '';
      await photoService.deletePhoto(
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
      var workShifts = <EmployeeBlockingShift>[];
      if (EmployeeDeleteErrorMapper.referencesWorkHoursTable(e)) {
        try {
          workShifts = await _ref
              .read(employeeRepositoryProvider)
              .getEmployeeDeleteBlockingShifts(id);
        } catch (_) {
          workShifts = [];
        }
      }
      state = state.copyWith(
        status: EmployeeStatus.error,
        errorMessage:
            EmployeeDeleteErrorMapper.formatDeleteBlockedForUi(e, workShifts),
      );
    }
  }

  /// Устанавливает поисковый запрос для фильтрации сотрудников.
  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  /// Принудительно обновляет данные сотрудника по [id].
  Future<void> refreshEmployee(String id) async {
    return getEmployee(id, forceRefresh: true);
  }

  /// Принудительно обновляет список сотрудников.
  Future<void> refreshEmployees() async {
    _isLoadingEmployees = false;
    return getEmployees();
  }

  /// Переключает флаг can_be_responsible у сотрудника и обновляет состояние.
  Future<void> toggleCanBeResponsible(String employeeId, bool? value) async {
    try {
      final ds = _ref.read(employeeDataSourceProvider);
      // если value не передан, читаем текущее и инвертируем
      bool nextValue;
      if (value == null) {
        final current = await ds.getCanBeResponsible(employeeId);
        nextValue = !current;
      } else {
        nextValue = value;
      }

      final updatedModel = await ds.setCanBeResponsible(
        employeeId: employeeId,
        value: nextValue,
      );
      final updated = updatedModel.toDomain();

      // Обновляем кэш деталей
      _employeeDetailsCache[employeeId] = updated;

      // Обновляем список
      final updatedEmployees =
          state.employees.map((e) => e.id == employeeId ? updated : e).toList();

      state = state.copyWith(
        status: EmployeeStatus.success,
        employee: state.employee?.id == employeeId ? updated : state.employee,
        employees: updatedEmployees,
        canBeResponsibleMap: {
          ...state.canBeResponsibleMap,
          employeeId: nextValue,
        },
      );
    } catch (e) {
      state = state.copyWith(
        status: EmployeeStatus.error,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }
}

/// Провайдер состояния сотрудников.
///
/// Используется для доступа к [EmployeeNotifier] и [EmployeeState] во всём приложении через Riverpod.
final employeeProvider =
    StateNotifierProvider<EmployeeNotifier, EmployeeState>((ref) {
  // [RBAC] Слушаем смену компании для автоматического обновления списка сотрудников
  ref.watch(activeCompanyIdProvider);
  return EmployeeNotifier(ref);
});

/// Провайдер для получения сотрудника по ID.
final employeeByIdProvider =
    FutureProvider.family<Employee?, String>((ref, id) async {
  final getEmployeeUseCase = ref.watch(getEmployeeUseCaseProvider);
  return getEmployeeUseCase.execute(id);
});
