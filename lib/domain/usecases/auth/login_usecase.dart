import 'package:projectgt/domain/entities/user.dart';
import 'package:projectgt/domain/repositories/auth_repository.dart';

/// UseCase для входа пользователя в систему.
///
/// Используется для аутентификации пользователя по email и паролю через [AuthRepository].
///
/// Пример использования:
/// ```dart
/// final useCase = LoginUseCase(authRepository);
/// final user = await useCase.execute('user@email.com', 'password');
/// ```
///
/// Бросает [Exception], если аутентификация не удалась.
class LoginUseCase {
  /// Репозиторий аутентификации для входа пользователя.
  final AuthRepository repository;

  /// Создаёт use case с указанным репозиторием.
  LoginUseCase(this.repository);

  /// Вход в систему по email и паролю.
  ///
  /// [email] — email пользователя.
  /// [password] — пароль пользователя.
  /// Возвращает [User] при успешной аутентификации.
  /// Бросает [Exception] при ошибке.
  Future<User> execute(String email, String password) {
    return repository.login(email, password);
  }
} 