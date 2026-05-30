import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/features/company/presentation/providers/company_providers.dart';
import 'package:projectgt/features/objects/domain/entities/object.dart';

import '../../data/timesheet_company_scope.dart';
import '../../domain/entities/timesheet_entry.dart';
import '../../domain/repositories/timesheet_repository.dart';
import '../state/timesheet_state.dart';
import 'repositories_providers.dart';
import 'timesheet_filters_providers.dart';

/// StateNotifier для управления состоянием табеля учёта рабочего времени.
class TimesheetNotifier extends StateNotifier<TimesheetState> {
  /// Репозиторий табеля.
  final TimesheetRepository repository;

  /// Возвращает ID активной компании из профиля (может быть `null`).
  final String? Function() readActiveCompanyId;

  /// Объекты компании для обогащения записей при точечном обновлении часов.
  final List<ObjectEntity> Function() readObjectsForEnrichment;

  /// Создаёт [TimesheetNotifier] и загружает данные за текущий месяц.
  TimesheetNotifier({
    required this.repository,
    required this.readActiveCompanyId,
    required this.readObjectsForEnrichment,
  }) : super(TimesheetState.initial()) {
    loadTimesheet();
  }

  List<String>? get _objectIdsFilter {
    final ids = state.selectedObjectIds;
    if (ids == null || ids.isEmpty) return null;
    return ids;
  }

  /// Загружает табель за текущий период (включая справочник сотрудников).
  Future<void> loadTimesheet() async {
    if (!timesheetHasActiveCompany(readActiveCompanyId())) {
      state = state.copyWith(
        isLoading: false,
        entries: [],
        employees: [],
        error: timesheetNoActiveCompanyMessage,
      );
      return;
    }

    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await repository.loadTimesheet(
        startDate: state.startDate,
        endDate: state.endDate,
        objectIds: _objectIdsFilter,
      );

      state = state.copyWith(
        entries: result.entries,
        employees: result.employees,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        error: 'Ошибка загрузки данных: $e',
        isLoading: false,
      );
    }
  }

  /// Перезагружает только записи часов (после диалога посещаемости).
  Future<void> reloadHoursEntries() async {
    if (!timesheetHasActiveCompany(readActiveCompanyId())) return;
    if (state.employees.isEmpty) {
      await loadTimesheet();
      return;
    }

    state = state.copyWith(isLoading: true, error: null);
    try {
      final entries = await repository.reloadHoursEntries(
        startDate: state.startDate,
        endDate: state.endDate,
        objectIds: _objectIdsFilter,
        employees: state.employees,
        objects: readObjectsForEnrichment(),
      );

      state = state.copyWith(
        entries: entries,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        error: 'Ошибка обновления часов: $e',
        isLoading: false,
      );
    }
  }

  /// Устанавливает диапазон дат и перезагружает табель.
  void setDateRange(DateTime startDate, DateTime endDate) {
    state = state.copyWith(startDate: startDate, endDate: endDate);
    loadTimesheet();
  }

  /// Выбранные объекты — серверный фильтр, перезагрузка табеля.
  void setSelectedObjects(List<String> objectIds) {
    state = state.copyWith(
      selectedObjectIds: objectIds.isEmpty ? null : objectIds,
    );
    loadTimesheet();
  }
}

/// Провайдер состояния табеля.
final timesheetProvider =
    StateNotifierProvider<TimesheetNotifier, TimesheetState>((ref) {
  final repository = ref.watch(timesheetRepositoryProvider);
  return TimesheetNotifier(
    repository: repository,
    readActiveCompanyId: () => ref.read(activeCompanyIdProvider),
    readObjectsForEnrichment: () =>
        ref.read(availableObjectsForTimesheetProvider),
  );
});

/// Записи табеля для сетки (стабильная ссылка между rebuild, пока не меняется state).
final timesheetGridEntriesProvider = Provider<List<TimesheetEntry>>((ref) {
  return ref.watch(timesheetProvider.select((s) => s.entries));
});

/// ID сотрудников, отмеченных чекбоксами в сетке табеля (экспорт и др.).
final timesheetGridSelectedEmployeeIdsProvider =
    StateProvider<Set<String>>((ref) => <String>{});
