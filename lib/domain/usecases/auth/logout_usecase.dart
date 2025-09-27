import 'package:projectgt/domain/repositories/auth_repository.dart';

/// UseCase для выхода пользователя из системы.
///
/// Используется для выхода пользователя через [AuthRepository].
///
/// Пример использования:
/// ```dart
/// final useCase = LogoutUseCase(authRepository);
/// await useCase.execute();
/// ```
///
/// Бросает [Exception], если выход не удался.
class LogoutUseCase {
  /// Репозиторий аутентификации для выхода пользователя.
  final AuthRepository repository;

  /// Создаёт use case с указанным репозиторием.
  LogoutUseCase(this.repository);

  /// Выход пользователя из системы.
  ///
  /// Возвращает void.
  /// Бросает [Exception] при ошибке.
  Future<void> execute() {
    return repository.logout();
  }
}
