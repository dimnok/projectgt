import 'package:projectgt/data/datasources/auth_data_source.dart';
// Telegram auth data source удалён
import 'package:projectgt/domain/entities/user.dart';
// Telegram доменные сущности удалены
import 'package:projectgt/domain/repositories/auth_repository.dart';
// Telegram moderation и модели удалены
// logger removed

/// Имплементация [AuthRepository] для работы с аутентификацией через data sources.
///
/// Инкапсулирует преобразование моделей и делегирует вызовы data-слою.
/// Поддерживает как стандартную авторизацию, так и Telegram OAuth.
class AuthRepositoryImpl implements AuthRepository {
  /// Data source для стандартной аутентификации.
  final AuthDataSource authDataSource;

  // Telegram слои удалены

  // logger removed

  /// Создаёт [AuthRepositoryImpl] с указанными data sources.
  AuthRepositoryImpl({
    required this.authDataSource,
  });

  // === Стандартные методы авторизации ===

  @override
  Future<User> login(String email, String password) async {
    final userModel = await authDataSource.login(email, password);
    return userModel.toDomain();
  }

  @override
  Future<User> register(String name, String email, String password) async {
    final userModel = await authDataSource.register(name, email, password);
    return userModel.toDomain();
  }

  @override
  Future<void> logout() async {
    // Очищаем стандартную авторизацию
    await authDataSource.logout();
  }

  @override
  Future<User?> getCurrentUser() async {
    try {
      // Сначала проверяем стандартную авторизацию
      final userModel = await authDataSource.getCurrentUser();
      if (userModel != null) {
        // user found
        return userModel.toDomain();
      }

      // Telegram авторизация удалена

      // no user
      return null;
    } catch (e) {
      // error
      return null;
    }
  }

  // Telegram методы удалены

  // === OTP (Email) methods ===

  @override
  Future<void> requestEmailOtp({required String email}) async {
    await authDataSource.requestEmailOtp(email);
  }

  @override
  Future<User> verifyEmailOtp(
      {required String email, required String code}) async {
    final model = await authDataSource.verifyEmailOtp(email, code);
    return model.toDomain();
  }

  @override
  Future<void> updateProfile({
    required String fullName,
    required String phone,
  }) async {
    await authDataSource.updateProfile(
      fullName: fullName,
      phone: phone,
    );
  }

  // Telegram OAuth методы удалены

  // Telegram методы удалены

  // Telegram методы удалены

  // Telegram методы удалены

  // Telegram методы удалены

  // === Приватные методы ===

  // Приватные Telegram методы удалены
}
