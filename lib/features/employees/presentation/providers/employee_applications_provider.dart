import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/domain/entities/employee_application.dart';
import 'package:projectgt/domain/repositories/employee_application_repository.dart';

/// Состояние списка заявлений сотрудника.
class EmployeeApplicationsState {
  /// Создаёт состояние.
  const EmployeeApplicationsState({
    this.applications = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  /// Заявления.
  final List<EmployeeApplication> applications;

  /// Идёт загрузка.
  final bool isLoading;

  /// Текст ошибки.
  final String? errorMessage;

  /// Копия с изменениями.
  EmployeeApplicationsState copyWith({
    List<EmployeeApplication>? applications,
    bool? isLoading,
    String? errorMessage,
  }) {
    return EmployeeApplicationsState(
      applications: applications ?? this.applications,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

/// Управление заявлениями сотрудника.
class EmployeeApplicationsNotifier
    extends StateNotifier<EmployeeApplicationsState> {
  /// Создаёт notifier и загружает список.
  EmployeeApplicationsNotifier({
    required this.repository,
    required this.employeeId,
  }) : super(const EmployeeApplicationsState()) {
    loadApplications();
  }

  /// Репозиторий заявлений.
  final EmployeeApplicationRepository repository;

  /// ID сотрудника.
  final String employeeId;

  /// Перезагружает список заявлений.
  Future<void> loadApplications() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final items = await repository.getByEmployee(employeeId);
      state = state.copyWith(applications: items, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  /// Загружает подписанный скан заявления.
  Future<EmployeeApplication> uploadSignedScan({
    required EmployeeApplicationType applicationType,
    required DateTime startDate,
    DateTime? endDate,
    required int durationDays,
    required List<int> bytes,
    required String fileName,
    required String contentType,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final created = await repository.uploadSignedScan(
        employeeId: employeeId,
        applicationType: applicationType,
        startDate: startDate,
        endDate: endDate,
        durationDays: durationDays,
        bytes: bytes,
        fileName: fileName,
        contentType: contentType,
      );
      state = state.copyWith(
        applications: [created, ...state.applications],
        isLoading: false,
      );
      return created;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      rethrow;
    }
  }

  /// Скачивает байты скана.
  Future<List<int>> downloadScan(String scanPath) {
    return repository.downloadScan(scanPath);
  }

  /// Удаляет заявление.
  Future<void> deleteApplication(EmployeeApplication application) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await repository.delete(application.id, application.scanPath);
      state = state.copyWith(
        applications: state.applications
            .where((a) => a.id != application.id)
            .toList(),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      rethrow;
    }
  }
}

/// Провайдер заявлений по [employeeId].
final employeeApplicationsProvider = StateNotifierProvider.autoDispose
    .family<EmployeeApplicationsNotifier, EmployeeApplicationsState, String>(
  (ref, employeeId) {
    final repository = ref.watch(employeeApplicationRepositoryProvider);
    return EmployeeApplicationsNotifier(
      repository: repository,
      employeeId: employeeId,
    );
  },
);

/// Идентификаторы заявлений, для которых идёт скачивание или просмотр.
final employeeApplicationBusyIdsProvider = StateProvider.autoDispose
    .family<Set<String>, String>((ref, employeeId) => {});
