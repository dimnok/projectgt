import '../../entities/estimate.dart';
import '../../repositories/estimate_repository.dart';

/// UseCase для создания новой сметы.
class CreateEstimateUseCase {
  /// Репозиторий смет.
  final EstimateRepository repository;

  /// Создаёт экземпляр [CreateEstimateUseCase] с репозиторием [repository].
  CreateEstimateUseCase(this.repository);

  /// Создаёт новую смету [estimate].
  Future<void> call(Estimate estimate) async {
    await repository.createEstimate(estimate);
  }
} 