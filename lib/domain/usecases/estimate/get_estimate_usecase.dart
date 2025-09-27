import '../../entities/estimate.dart';
import '../../repositories/estimate_repository.dart';

/// UseCase для получения одной сметы по идентификатору.
class GetEstimateUseCase {
  /// Репозиторий смет.
  final EstimateRepository repository;

  /// Создаёт экземпляр [GetEstimateUseCase] с репозиторием [repository].
  GetEstimateUseCase(this.repository);

  /// Возвращает смету по идентификатору [id].
  Future<Estimate?> call(String id) async {
    return await repository.getEstimate(id);
  }
}
