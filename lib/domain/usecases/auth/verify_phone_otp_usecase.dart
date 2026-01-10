import 'package:projectgt/domain/entities/user.dart';
import 'package:projectgt/domain/repositories/auth_repository.dart';

/// UseCase для проверки одноразового кода (OTP) и завершения входа по номеру телефона.
class VerifyPhoneOtpUseCase {
  /// Репозиторий аутентификации.
  final AuthRepository repository;

  /// Создает экземпляр [VerifyPhoneOtpUseCase].
  VerifyPhoneOtpUseCase(this.repository);

  /// Выполняет проверку кода [code] для номера [phone] с использованием токена [token].
  ///
  /// Возвращает объект [User] при успешной проверке.
  Future<User> execute({
    required String phone,
    required String code,
    required String token,
  }) async {
    return await repository.verifyPhoneOtp(
      phone: phone,
      code: code,
      token: token,
    );
  }
}

