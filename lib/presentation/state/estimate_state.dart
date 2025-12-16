import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/estimate.dart';
import '../../domain/usecases/estimate/get_estimates_usecase.dart';
import '../../domain/usecases/estimate/get_estimate_usecase.dart';
import '../../domain/usecases/estimate/create_estimate_usecase.dart';
import '../../domain/usecases/estimate/update_estimate_usecase.dart';
import '../../domain/usecases/estimate/delete_estimate_usecase.dart';

/// Состояние для управления списком и деталями смет.
class EstimateState {
  /// Список всех смет.
  final List<Estimate> estimates;

  /// Текущая выбранная смета (детали).
  final Estimate? selectedEstimate;

  /// Флаг загрузки данных.
  final bool isLoading;

  /// Сообщение об ошибке, если есть.
  final String? error;

  /// Создаёт экземпляр [EstimateState].
  EstimateState({
    this.estimates = const [],
    this.selectedEstimate,
    this.isLoading = false,
    this.error,
  });

  /// Копирует состояние с возможностью переопределения отдельных полей.
  EstimateState copyWith({
    List<Estimate>? estimates,
    Estimate? selectedEstimate,
    bool? isLoading,
    String? error,
  }) {
    return EstimateState(
      estimates: estimates ?? this.estimates,
      selectedEstimate: selectedEstimate ?? this.selectedEstimate,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

/// StateNotifier для управления состоянием смет через usecase-слой.
class EstimateNotifier extends StateNotifier<EstimateState> {
  /// UseCase для получения всех смет.
  final GetEstimatesUseCase getEstimatesUseCase;

  /// UseCase для получения одной сметы.
  final GetEstimateUseCase getEstimateUseCase;

  /// UseCase для создания сметы.
  final CreateEstimateUseCase createEstimateUseCase;

  /// UseCase для обновления сметы.
  final UpdateEstimateUseCase updateEstimateUseCase;

  /// UseCase для удаления сметы.
  final DeleteEstimateUseCase deleteEstimateUseCase;

  /// Создаёт экземпляр [EstimateNotifier] с необходимыми usecase-ами.
  EstimateNotifier({
    required this.getEstimatesUseCase,
    required this.getEstimateUseCase,
    required this.createEstimateUseCase,
    required this.updateEstimateUseCase,
    required this.deleteEstimateUseCase,
  }) : super(EstimateState());

  /// Загружает список всех смет и обновляет состояние.
  Future<void> loadEstimates() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final estimates = await getEstimatesUseCase();
      state = state.copyWith(estimates: estimates, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Добавляет новую смету и обновляет список.
  Future<void> addEstimate(Estimate estimate) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await createEstimateUseCase(estimate);
      await loadEstimates();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  /// Обновляет существующую смету и обновляет список.
  Future<void> updateEstimate(Estimate estimate) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await updateEstimateUseCase(estimate);
      await loadEstimates();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Удаляет смету по идентификатору и обновляет список.
  Future<void> deleteEstimate(String id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await deleteEstimateUseCase(id);
      await loadEstimates();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Выбирает смету по идентификатору для просмотра деталей.
  Future<void> selectEstimate(String id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final estimate = await getEstimateUseCase(id);
      state = state.copyWith(selectedEstimate: estimate, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}
