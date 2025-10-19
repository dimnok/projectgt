import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/export_filter.dart';
import '../../domain/entities/export_report.dart';
import '../../domain/repositories/export_repository.dart';
import '../services/export_service.dart';
import 'repositories_providers.dart';

/// Состояние для модуля выгрузки.
///
/// Содержит данные отчета [reports], фильтр [filter], флаг загрузки [isLoading] и возможную ошибку [error].
class ExportState {
  /// Список данных отчета.
  final List<ExportReport> reports;

  /// Текущий фильтр.
  final ExportFilter? filter;

  /// Флаг, указывающий на процесс загрузки.
  final bool isLoading;

  /// Сообщение об ошибке, если есть.
  final String? error;

  /// Флаг экспорта.
  final bool isExporting;

  /// Создаёт состояние для модуля выгрузки.
  ExportState({
    required this.reports,
    this.filter,
    this.isLoading = false,
    this.error,
    this.isExporting = false,
  });

  /// Возвращает копию состояния с обновлёнными полями.
  ExportState copyWith({
    List<ExportReport>? reports,
    ExportFilter? filter,
    bool? isLoading,
    String? error,
    bool? isExporting,
  }) {
    return ExportState(
      reports: reports ?? this.reports,
      filter: filter ?? this.filter,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isExporting: isExporting ?? this.isExporting,
    );
  }
}

/// StateNotifier для управления состоянием модуля выгрузки.
class ExportNotifier extends StateNotifier<ExportState> {
  /// Репозиторий для работы с выгрузкой.
  final ExportRepository repository;

  /// Сервис экспорта.
  final ExportService exportService;

  /// Создаёт [ExportNotifier].
  ExportNotifier(this.repository, this.exportService)
      : super(ExportState(reports: []));

  /// Загружает данные отчета согласно фильтру.
  Future<void> loadReportData(ExportFilter filter) async {
    state = state.copyWith(isLoading: true, error: null, filter: filter);
    try {
      final reports = await repository.getExportData(filter);
      state = state.copyWith(reports: reports, isLoading: false);
    } catch (e) {
      state =
          state.copyWith(error: 'Ошибка загрузки данных: $e', isLoading: false);
    }
  }

  /// Экспортирует данные в Excel файл.
  Future<String?> exportToExcel(
    List<ExportReport> reports,
    String fileName, {
    List<String>? columns,
    String? sheetName,
  }) async {
    if (reports.isEmpty) {
      state = state.copyWith(error: 'Нет данных для экспорта');
      return null;
    }

    state = state.copyWith(isExporting: true, error: null);
    try {
      final filePath = await exportService.exportToExcel(
        reports,
        fileName,
        columns: columns,
        sheetName: sheetName,
      );
      state = state.copyWith(isExporting: false);
      return filePath;
    } catch (e) {
      state = state.copyWith(error: 'Ошибка экспорта: $e', isExporting: false);
      return null;
    }
  }

  /// Очищает данные отчета.
  void clearData() {
    state = ExportState(reports: []);
  }
}

/// Провайдер состояния модуля выгрузки.
final exportProvider =
    StateNotifierProvider<ExportNotifier, ExportState>((ref) {
  final repository = ref.watch(exportRepositoryProvider);
  final exportService = ref.watch(exportServiceProvider);
  return ExportNotifier(repository, exportService);
});

/// Провайдер для получения списка доступных объектов.
final availableObjectsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repository = ref.watch(exportRepositoryProvider);
  return await repository.getAvailableObjects();
});

/// Провайдер для получения списка доступных договоров.
final availableContractsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repository = ref.watch(exportRepositoryProvider);
  return await repository.getAvailableContracts();
});

/// Провайдер для получения списка доступных систем.
final availableSystemsProvider = FutureProvider<List<String>>((ref) async {
  final repository = ref.watch(exportRepositoryProvider);
  return await repository.getAvailableSystems();
});

/// Провайдер для получения списка доступных подсистем.
final availableSubsystemsProvider = FutureProvider<List<String>>((ref) async {
  final repository = ref.watch(exportRepositoryProvider);
  return await repository.getAvailableSubsystems();
});
