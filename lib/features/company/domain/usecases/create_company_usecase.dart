import 'package:projectgt/features/company/domain/entities/company_profile.dart';
import 'package:projectgt/features/company/domain/repositories/company_repository.dart';

/// UseCase для создания новой компании.
class CreateCompanyUseCase {
  /// Репозиторий для работы с данными компании.
  final CompanyRepository repository;

  /// Создает экземпляр [CreateCompanyUseCase].
  CreateCompanyUseCase(this.repository);

  /// Выполняет создание компании.
  ///
  /// [name] — название компании.
  /// [additionalData] — дополнительные данные для профиля.
  Future<CompanyProfile> execute({
    required String name,
    Map<String, dynamic>? additionalData,
  }) async {
    return await repository.createCompany(
      name: name,
      additionalData: additionalData,
    );
  }
}

