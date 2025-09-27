import 'package:projectgt/domain/entities/user.dart';
import 'package:projectgt/domain/repositories/auth_repository.dart';

/// UseCase для подтверждения 6-значного кода и входа
class VerifyEmailOtpUseCase {
  final AuthRepository _repository;

  /// Создаёт use case для подтверждения 6-значного кода и входа.
  ///
  /// Принимает репозиторий аутентификации для выполнения операции.
  VerifyEmailOtpUseCase(this._repository);

  /// Подтверждает 6-значный [code], отправленный на [email], и выполняет вход.
  ///
  /// Возвращает [User] при успешной аутентификации.
  Future<User> execute({required String email, required String code}) {
    return _repository.verifyEmailOtp(email: email, code: code);
  }
}
