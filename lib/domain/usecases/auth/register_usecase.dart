import 'package:projectgt/domain/entities/user.dart';
import 'package:projectgt/domain/repositories/auth_repository.dart';

/// UseCase для регистрации нового пользователя.
///
/// Используется для регистрации пользователя по имени, email и паролю через [AuthRepository].
///
/// Пример использования:
/// ```dart
/// final useCase = RegisterUseCase(authRepository);
/// final user = await useCase.execute('Имя', 'user@email.com', 'password');
/// ```
///
/// Бросает [Exception], если регистрация не удалась.
class RegisterUseCase {
  /// Репозиторий аутентификации для регистрации пользователей.
  final AuthRepository repository;

  /// Создаёт use case с указанным репозиторием.
  RegisterUseCase(this.repository);

  /// Регистрация пользователя.
  ///
  /// [name] — имя пользователя.
  /// [email] — email пользователя.
  /// [password] — пароль пользователя.
  /// Возвращает созданного [User].
  /// Бросает [Exception] при ошибке.
  Future<User> execute(String name, String email, String password) {
    return repository.register(name, email, password);
  }
} 