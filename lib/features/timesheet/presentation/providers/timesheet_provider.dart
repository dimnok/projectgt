import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/timesheet_entry.dart';
import '../../domain/repositories/timesheet_repository.dart';
import 'repositories_providers.dart';

/// Состояние для таймшита
class TimesheetState {
  /// Список записей табеля
  final List<TimesheetEntry> entries;

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

  /// Выбранные должности для фильтрации
  final List<String>? selectedPositions;

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
  /// [selectedPositions] — выбранные должности для фильтрации (по умолчанию null).
  TimesheetState({
    this.entries = const [],
    this.isLoading = false,
    this.error,
    required this.startDate,
    required this.endDate,
    this.selectedObjectIds,
    this.selectedPositions,
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
  /// [selectedPositions] — новые выбранные должности для фильтрации (опционально).
  ///
  /// Возвращает новый экземпляр [TimesheetState] с обновлёнными значениями.
  TimesheetState copyWith({
    List<TimesheetEntry>? entries,
    bool? isLoading,
    String? error,
    DateTime? startDate,
    DateTime? endDate,
    Object? selectedObjectIds = _sentinel,
    List<String>? selectedPositions,
  }) {
    return TimesheetState(
      entries: entries ?? this.entries,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      selectedObjectIds: selectedObjectIds == _sentinel
          ? this.selectedObjectIds
          : selectedObjectIds as List<String>?,
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
  TimesheetNotifier(this.repository)
      : super(TimesheetState(
          startDate: DateTime(DateTime.now().year, DateTime.now().month, 1),
          endDate: DateTime(DateTime.now().year, DateTime.now().month + 1, 0),
        )) {
    loadTimesheet();
  }

  /// Загружает данные табеля с учетом текущих фильтров.
  ///
  /// Все фильтры применяются на серверной стороне для оптимизации производительности.
  Future<void> loadTimesheet() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // Передаём все фильтры в репозиторий для обработки на сервере
      final entries = await repository.getTimesheetEntries(
        startDate: state.startDate,
        endDate: state.endDate,
        employeeId: null,
        objectIds: state.selectedObjectIds?.isNotEmpty == true
            ? state.selectedObjectIds
            : null,
        positions: state.selectedPositions?.isNotEmpty == true
            ? state.selectedPositions
            : null,
      );

      state = state.copyWith(
        entries: entries,
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

  /// Устанавливает выбранные объекты для фильтрации (мультивыбор)
  void setSelectedObjects(List<String> objectIds) {
    state = state.copyWith(selectedObjectIds: objectIds);
    loadTimesheet();
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
      selectedObjectIds: <String>[],
      selectedPositions: <String>[],
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
