import 'package:projectgt/domain/repositories/auth_repository.dart';

/// UseCase для запроса одноразового кода (OTP) на номер телефона.
class RequestPhoneOtpUseCase {
  /// Репозиторий аутентификации.
  final AuthRepository repository;

  /// Создает экземпляр [RequestPhoneOtpUseCase].
  RequestPhoneOtpUseCase(this.repository);

  /// Выполняет запрос OTP для указанного [phone].
  Future<void> execute({required String phone}) async {
    await repository.requestPhoneOtp(phone: phone);
  }
}

