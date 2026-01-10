import 'package:projectgt/features/company/domain/repositories/company_repository.dart';

/// UseCase для вступления в существующую компанию по коду приглашения.
class JoinCompanyUseCase {
  /// Репозиторий для работы с данными компании.
  final CompanyRepository repository;

  /// Создает экземпляр [JoinCompanyUseCase].
  JoinCompanyUseCase(this.repository);

  /// Выполняет вступление в компанию.
  ///
  /// [invitationCode] — уникальный код приглашения.
  Future<void> execute({required String invitationCode}) async {
    return await repository.joinCompany(invitationCode: invitationCode);
  }
}
