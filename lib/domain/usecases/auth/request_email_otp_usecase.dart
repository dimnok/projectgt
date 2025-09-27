import 'package:projectgt/domain/repositories/auth_repository.dart';

/// UseCase для отправки 6-значного кода на email
class RequestEmailOtpUseCase {
  final AuthRepository _repository;

  /// Создаёт use case для отправки 6-значного кода на email.
  ///
  /// Принимает репозиторий аутентификации для выполнения операции.
  RequestEmailOtpUseCase(this._repository);

  /// Отправляет одноразовый 6-значный код на указанный [email].
  ///
  /// Возвращает [Future], завершающийся после отправки кода.
  Future<void> execute({required String email}) {
    return _repository.requestEmailOtp(email: email);
  }
}
