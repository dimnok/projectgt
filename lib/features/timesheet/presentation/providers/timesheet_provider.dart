import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/timesheet_entry.dart';
import '../../domain/entities/timesheet_summary.dart';
import '../../domain/repositories/timesheet_repository.dart';
import 'repositories_providers.dart';

/// Состояние для таймшита
class TimesheetState {
  /// Список записей табеля
  final List<TimesheetEntry> entries;
  
  /// Сводные данные по часам сотрудников
  final List<TimesheetSummary> summaries;
  
  /// Флаг загрузки данных
  final bool isLoading;
  
  /// Текст ошибки, если есть
  final String? error;
  
  /// Начальная дата для фильтрации
  final DateTime startDate;
  
  /// Конечная дата для фильтрации
  final DateTime endDate;
  
  /// Выбранные сотрудники для фильтрации (мультивыбор)
  final List<String>? selectedEmployeeIds;
  
  /// Выбранный объект для фильтрации
  final String? selectedObjectId;
  
  /// Флаг группировки по сотрудникам
  final bool isGroupedByEmployee;
  
  /// Выбранные должности для фильтрации
  final List<String>? selectedPositions;

  /// Специальный sentinel-объект для различения null и отсутствия значения в copyWith.
  static const _sentinel = Object();

  /// Создает экземпляр состояния [TimesheetState].
  /// 
  /// [entries] — список записей табеля (по умолчанию пустой).
  /// [summaries] — сводные данные по часам сотрудников (по умолчанию пустой).
  /// [isLoading] — флаг загрузки данных (по умолчанию false).
  /// [error] — текст ошибки, если есть (по умолчанию null).
  /// [startDate] — начальная дата для фильтрации (обязательный параметр).
  /// [endDate] — конечная дата для фильтрации (обязательный параметр).
  /// [selectedEmployeeIds] — выбранные сотрудники для фильтрации (мультивыбор, по умолчанию null).
  /// [selectedObjectId] — выбранный объект для фильтрации (по умолчанию null).
  /// [isGroupedByEmployee] — флаг группировки по сотрудникам (по умолчанию true).
  /// [selectedPositions] — выбранные должности для фильтрации (по умолчанию null).
  TimesheetState({
    this.entries = const [],
    this.summaries = const [],
    this.isLoading = false,
    this.error,
    required this.startDate,
    required this.endDate,
    this.selectedEmployeeIds,
    this.selectedObjectId,
    this.isGroupedByEmployee = true,
    this.selectedPositions,
  });

  /// Создаёт копию состояния [TimesheetState] с обновлёнными свойствами.
  /// 
  /// Позволяет частично изменить поля состояния без необходимости указывать все параметры.
  /// 
  /// [entries] — новый список записей табеля (опционально).
  /// [summaries] — новые сводные данные по часам сотрудников (опционально).
  /// [isLoading] — новое состояние загрузки (опционально).
  /// [error] — новый текст ошибки (опционально).
  /// [startDate] — новая начальная дата фильтрации (опционально).
  /// [endDate] — новая конечная дата фильтрации (опционально).
  /// [selectedEmployeeIds] — новые выбранные сотрудники для фильтрации (опционально, поддерживает sentinel для различения null и отсутствия значения).
  /// [selectedObjectId] — новый выбранный объект для фильтрации (опционально, поддерживает sentinel для различения null и отсутствия значения).
  /// [isGroupedByEmployee] — новое состояние группировки (опционально).
  /// [selectedPositions] — новые выбранные должности для фильтрации (опционально).
  /// 
  /// Возвращает новый экземпляр [TimesheetState] с обновлёнными значениями.
  TimesheetState copyWith({
    List<TimesheetEntry>? entries,
    List<TimesheetSummary>? summaries,
    bool? isLoading,
    String? error,
    DateTime? startDate,
    DateTime? endDate,
    Object? selectedEmployeeIds = _sentinel,
    Object? selectedObjectId = _sentinel,
    bool? isGroupedByEmployee,
    List<String>? selectedPositions,
  }) {
    return TimesheetState(
      entries: entries ?? this.entries,
      summaries: summaries ?? this.summaries,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      selectedEmployeeIds: selectedEmployeeIds == _sentinel
          ? this.selectedEmployeeIds
          : selectedEmployeeIds as List<String>?,
      selectedObjectId: selectedObjectId == _sentinel
          ? this.selectedObjectId
          : selectedObjectId as String?,
      isGroupedByEmployee: isGroupedByEmployee ?? this.isGroupedByEmployee,
      selectedPositions: selectedPositions ?? this.selectedPositions,
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
  TimesheetNotifier(this.repository) : super(TimesheetState(
    startDate: DateTime(DateTime.now().year, DateTime.now().month, 1),
    endDate: DateTime(DateTime.now().year, DateTime.now().month + 1, 0),
  )) {
    loadTimesheet();
  }

  /// Загружает данные табеля с учетом текущих фильтров
  Future<void> loadTimesheet() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final entries = await repository.getTimesheetEntries(
        startDate: state.startDate,
        endDate: state.endDate,
        employeeId: null, // фильтрация по нескольким сотрудникам ниже
        objectId: state.selectedObjectId,
      );
      // Фильтрация по сотрудникам (мультивыбор)
      final filteredByEmployee = (state.selectedEmployeeIds != null && state.selectedEmployeeIds!.isNotEmpty)
          ? entries.where((e) => state.selectedEmployeeIds!.contains(e.employeeId)).toList()
          : entries;
      // Фильтрация по должностям (локально)
      final filteredEntries = (state.selectedPositions != null && state.selectedPositions!.isNotEmpty)
          ? filteredByEmployee.where((e) => e.employeePosition != null && state.selectedPositions!.contains(e.employeePosition)).toList()
          : filteredByEmployee;
      final summaries = await repository.getTimesheetSummary(
        startDate: state.startDate,
        endDate: state.endDate,
        employeeIds: state.selectedEmployeeIds,
        objectIds: state.selectedObjectId != null ? [state.selectedObjectId!] : null,
      );
      state = state.copyWith(
        entries: filteredEntries,
        summaries: summaries,
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

  /// Устанавливает выбранных сотрудников для фильтрации (мультивыбор)
  void setSelectedEmployees(List<String> employeeIds) {
    state = state.copyWith(selectedEmployeeIds: employeeIds);
    loadTimesheet();
  }

  /// Устанавливает выбранный объект для фильтрации
  void setSelectedObject(String? objectId) {
    state = state.copyWith(selectedObjectId: objectId);
    loadTimesheet();
  }

  /// Переключает режим группировки (по сотрудникам/по датам)
  void toggleGrouping() {
    state = state.copyWith(isGroupedByEmployee: !state.isGroupedByEmployee);
  }

  /// Устанавливает выбранные должности для фильтрации
  void setSelectedPositions(List<String> positions) {
    state = state.copyWith(selectedPositions: positions);
    loadTimesheet();
  }

  /// Сбрасывает все фильтры
  void resetFilters() {
    final now = DateTime.now();
    state = state.copyWith(
      startDate: DateTime(now.year, now.month, 1),
      endDate: DateTime(now.year, now.month + 1, 0),
      selectedEmployeeIds: <String>[],
      selectedObjectId: null,
      selectedPositions: <String>[],
    );
    loadTimesheet();
  }
}

/// Глобальный провайдер состояния табеля учёта рабочего времени (таймшита).
/// 
/// Позволяет получать и изменять состояние табеля, управлять фильтрами, загрузкой и ошибками.
final timesheetProvider = StateNotifierProvider<TimesheetNotifier, TimesheetState>((ref) {
  final repository = ref.watch(timesheetRepositoryProvider);
  return TimesheetNotifier(repository);
}); 