import 'package:projectgt/domain/entities/user.dart';
import 'package:projectgt/domain/repositories/auth_repository.dart';

/// UseCase для получения текущего пользователя.
///
/// Используется для получения авторизованного пользователя через [AuthRepository].
///
/// Пример использования:
/// ```dart
/// final useCase = GetCurrentUserUseCase(authRepository);
/// final user = await useCase.execute();
/// if (user != null) print(user.email);
/// ```
///
/// Бросает [Exception], если возникла ошибка при получении пользователя.
class GetCurrentUserUseCase {
  /// Репозиторий аутентификации для получения пользователя.
  final AuthRepository repository;

  /// Создаёт use case с указанным репозиторием.
  GetCurrentUserUseCase(this.repository);

  /// Получение текущего пользователя.
  ///
  /// Возвращает [User] или null, если пользователь не найден.
  /// Бросает [Exception] при ошибке.
  Future<User?> execute() {
    return repository.getCurrentUser();
  }
}
