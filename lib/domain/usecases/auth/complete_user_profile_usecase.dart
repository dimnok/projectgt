import 'package:projectgt/domain/repositories/auth_repository.dart';

/// UseCase для завершения заполнения профиля пользователя при первой авторизации
class CompleteUserProfileUseCase {
  final AuthRepository _repository;

  /// Создаёт use case для завершения заполнения профиля.
  ///
  /// Принимает репозиторий аутентификации для выполнения операции.
  CompleteUserProfileUseCase(this._repository);

  /// Обновляет данные профиля пользователя.
  ///
  /// [fullName] — полное ФИО пользователя
  /// [phone] — номер телефона в формате +7-(XXX)-XXX-XXXX
  ///
  /// Возвращает [Future], завершающийся после обновления профиля.
  Future<void> execute({
    required String fullName,
    required String phone,
  }) {
    return _repository.updateProfile(
      fullName: fullName,
      phone: phone,
    );
  }
}
