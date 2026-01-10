import 'package:projectgt/features/company/domain/repositories/company_repository.dart';

/// UseCase для обновления данных участника компании.
class UpdateMemberUseCase {
  /// Репозиторий для работы с данными компании.
  final CompanyRepository repository;

  /// Создает экземпляр [UpdateMemberUseCase].
  UpdateMemberUseCase(this.repository);

  /// Выполняет обновление данных участника.
  ///
  /// [userId] — ID пользователя.
  /// [companyId] — ID компании.
  /// [roleId] — ID новой роли (опционально).
  /// [isActive] — Статус активности (опционально).
  Future<void> execute({
    required String userId,
    required String companyId,
    String? roleId,
    bool? isActive,
  }) async {
    return await repository.updateMember(
      userId: userId,
      companyId: companyId,
      roleId: roleId,
      isActive: isActive,
    );
  }
}
