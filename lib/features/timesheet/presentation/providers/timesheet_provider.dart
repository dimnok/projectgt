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

  /// Создает экземпляр состояния [TimesheetState]
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

  /// Создает копию состояния с частично обновленными свойствами
  static const _sentinel = Object();
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