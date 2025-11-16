import 'package:projectgt/domain/entities/user.dart';

/// Абстракция репозитория аутентификации пользователя.
///
/// Определяет методы для входа, регистрации, выхода и получения текущего пользователя.
/// Используется в слое домена для инкапсуляции логики работы с аутентификацией.
///
/// Пример использования:
/// ```dart
/// final user = await authRepository.requestEmailOtp('email@example.com');
/// final user = await authRepository.verifyEmailOtp('email@example.com', '123456');
/// ```
abstract class AuthRepository {
  /// Выполняет вход пользователя по email и паролю.
  ///
  /// [email] — email пользователя.
  /// [password] — пароль пользователя.
  /// Возвращает [User] при успешной аутентификации.
  /// Бросает исключение при ошибке.
  Future<User> login(String email, String password);

  /// Регистрирует нового пользователя.
  ///
  /// [name] — имя пользователя.
  /// [email] — email пользователя.
  /// [password] — пароль пользователя.
  /// Возвращает созданного [User].
  /// Бросает исключение при ошибке.
  Future<User> register(String name, String email, String password);

  /// Выполняет выход пользователя из системы.
  ///
  /// Очищает токены и локальные данные сессии.
  Future<void> logout();

  /// Получает текущего авторизованного пользователя.
  ///
  /// Проверяет стандартную авторизацию.
  /// Возвращает [User], если пользователь авторизован, иначе — null.
  Future<User?> getCurrentUser();

  // === OTP (Email) auth methods ===

  /// Отправляет 6-значный код подтверждения на указанный email.
  Future<void> requestEmailOtp({required String email});

  /// Подтверждает 6-значный код для указанного email и возвращает пользователя.
  Future<User> verifyEmailOtp({required String email, required String code});

  /// Обновляет профиль пользователя при первой авторизации.
  ///
  /// [fullName] — полное ФИО пользователя.
  /// [phone] — номер телефона в формате +7-(XXX)-XXX-XXXX.
  Future<void> updateProfile({
    required String fullName,
    required String phone,
  });
}
