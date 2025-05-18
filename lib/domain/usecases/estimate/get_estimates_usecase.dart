import '../../entities/estimate.dart';
import '../../repositories/estimate_repository.dart';

/// UseCase для получения списка всех смет.
class GetEstimatesUseCase {
  /// Репозиторий смет.
  final EstimateRepository repository;

  /// Создаёт экземпляр [GetEstimatesUseCase] с репозиторием [repository].
  GetEstimatesUseCase(this.repository);

  /// Возвращает список всех смет.
  Future<List<Estimate>> call() async {
    return await repository.getEstimates();
  }
} 