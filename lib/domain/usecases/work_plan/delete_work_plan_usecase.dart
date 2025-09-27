import '../../repositories/work_plan_repository.dart';

/// UseCase для удаления плана работ.
class DeleteWorkPlanUseCase {
  /// Репозиторий планов работ.
  final WorkPlanRepository repository;

  /// Создаёт экземпляр [DeleteWorkPlanUseCase] с репозиторием [repository].
  DeleteWorkPlanUseCase(this.repository);

  /// Удаляет план работ по его ID.
  ///
  /// [id] — уникальный идентификатор плана работ.
  /// Возвращает void. Бросает [Exception] при ошибке.
  Future<void> call(String id) async {
    return await repository.deleteWorkPlan(id);
  }
}
