import '../../entities/estimate.dart';
import '../../repositories/estimate_repository.dart';

/// UseCase для обновления существующей сметы.
class UpdateEstimateUseCase {
  /// Репозиторий смет.
  final EstimateRepository repository;

  /// Создаёт экземпляр [UpdateEstimateUseCase] с репозиторием [repository].
  UpdateEstimateUseCase(this.repository);

  /// Обновляет смету [estimate] в репозитории.
  ///
  /// [estimate] — объект сметы, который требуется обновить.
  Future<void> call(Estimate estimate) async {
    await repository.updateEstimate(estimate);
  }
}
