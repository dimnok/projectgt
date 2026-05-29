import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/domain/entities/employee.dart';
import '../../domain/entities/timesheet_entry.dart';
import '../../domain/repositories/timesheet_repository.dart';
import 'repositories_providers.dart';

/// Состояние для таймшита
class TimesheetState {
  /// Список записей табеля
  final List<TimesheetEntry> entries;

  /// Сотрудники компании (загружаются вместе с табелем).
  final List<Employee> employees;

  /// Флаг загрузки данных
  final bool isLoading;

  /// Текст ошибки, если есть
  final String? error;

  /// Начальная дата для фильтрации
  final DateTime startDate;

  /// Конечная дата для фильтрации
  final DateTime endDate;

  /// Выбранные объекты для фильтрации (мультивыбор)
  final List<String>? selectedObjectIds;

  /// Специальный sentinel-объект для различения null и отсутствия значения в copyWith.
  static const _sentinel = Object();

  /// Создает экземпляр состояния [TimesheetState].
  ///
  /// [entries] — список записей табеля (по умолчанию пустой).
  /// [isLoading] — флаг загрузки данных (по умолчанию false).
  /// [error] — текст ошибки, если есть (по умолчанию null).
  /// [startDate] — начальная дата для фильтрации (обязательный параметр).
  /// [endDate] — конечная дата для фильтрации (обязательный параметр).
  /// [selectedObjectIds] — выбранные объекты для фильтрации (мультивыбор, по умолчанию null).
  TimesheetState({
    this.entries = const [],
    this.employees = const [],
    this.isLoading = false,
    this.error,
    required this.startDate,
    required this.endDate,
    this.selectedObjectIds,
  });

  /// Создаёт копию состояния [TimesheetState] с обновлёнными свойствами.
  ///
  /// Позволяет частично изменить поля состояния без необходимости указывать все параметры.
  ///
  /// [entries] — новый список записей табеля (опционально).
  /// [isLoading] — новое состояние загрузки (опционально).
  /// [error] — новый текст ошибки (опционально).
  /// [startDate] — новая начальная дата фильтрации (опционально).
  /// [endDate] — новая конечная дата фильтрации (опционально).
  /// [selectedObjectIds] — новые выбранные объекты для фильтрации (опционально, поддерживает sentinel для различения null и отсутствия значения).
  ///
  /// Возвращает новый экземпляр [TimesheetState] с обновлёнными значениями.
  TimesheetState copyWith({
    List<TimesheetEntry>? entries,
    List<Employee>? employees,
    bool? isLoading,
    String? error,
    DateTime? startDate,
    DateTime? endDate,
    Object? selectedObjectIds = _sentinel,
  }) {
    return TimesheetState(
      entries: entries ?? this.entries,
      employees: employees ?? this.employees,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      selectedObjectIds: selectedObjectIds == _sentinel
          ? this.selectedObjectIds
          : selectedObjectIds as List<String>?,
    );
  }
}

/// StateNotifier для управления состоянием табеля учёта рабочего времени (таймшита).
///
/// Позволяет загружать, фильтровать, группировать и сбрасывать данные табеля, а также управлять ошибками и состоянием загрузки.
class TimesheetNotifier extends StateNotifier<TimesheetState> {
  /// Репозиторий таймшита
  final TimesheetRepository repository;

  /// Создает экземпляр [TimesheetNotifier]
  TimesheetNotifier(this.repository)
      : super(TimesheetState(
          startDate: DateTime(DateTime.now().year, DateTime.now().month, 1),
          endDate: DateTime(DateTime.now().year, DateTime.now().month + 1, 0),
        )) {
    loadTimesheet();
  }

  /// Загружает данные табеля за текущий период (фильтр объектов — на клиенте).
  Future<void> loadTimesheet() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await repository.loadTimesheet(
        startDate: state.startDate,
        endDate: state.endDate,
      );

      state = state.copyWith(
        entries: result.entries,
        employees: result.employees,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: 'Ошибка загрузки данных: $e',
        isLoading: false,
      );
    }
  }

  /// Устанавливает диапазон дат для фильтрации
  void setDateRange(DateTime startDate, DateTime endDate) {
    state = state.copyWith(startDate: startDate, endDate: endDate);
    loadTimesheet();
  }

  /// Выбранные объекты для клиентского фильтра (без перезапроса к серверу).
  void setSelectedObjects(List<String> objectIds) {
    state = state.copyWith(selectedObjectIds: objectIds);
  }

  /// Сбрасывает все фильтры
  void resetFilters() {
    final now = DateTime.now();
    state = state.copyWith(
      startDate: DateTime(now.year, now.month, 1),
      endDate: DateTime(now.year, now.month + 1, 0),
      selectedObjectIds: <String>[],
    );
    loadTimesheet();
  }
}

/// Глобальный провайдер состояния табеля учёта рабочего времени (таймшита).
///
/// Позволяет получать и изменять состояние табеля, управлять фильтрами, загрузкой и ошибками.
final timesheetProvider =
    StateNotifierProvider<TimesheetNotifier, TimesheetState>((ref) {
  final repository = ref.watch(timesheetRepositoryProvider);
  return TimesheetNotifier(repository);
});

/// ID сотрудников, отмеченных чекбоксами в сетке табеля (экспорт, будущие действия).
final timesheetGridSelectedEmployeeIdsProvider =
    StateProvider<Set<String>>((ref) => <String>{});
