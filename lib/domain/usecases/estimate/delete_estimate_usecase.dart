import '../../repositories/estimate_repository.dart';

/// UseCase для удаления сметы по идентификатору.
class DeleteEstimateUseCase {
  /// Репозиторий смет.
  final EstimateRepository repository;

  /// Создаёт экземпляр [DeleteEstimateUseCase] с репозиторием [repository].
  DeleteEstimateUseCase(this.repository);

  /// Удаляет смету по идентификатору [id].
  ///
  /// [id] — идентификатор сметы для удаления.
  Future<void> call(String id) async {
    await repository.deleteEstimate(id);
  }
} 