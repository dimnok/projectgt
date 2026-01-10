import 'package:projectgt/data/datasources/auth_data_source.dart';
import 'package:projectgt/domain/entities/user.dart';
import 'package:projectgt/domain/repositories/auth_repository.dart';

/// Имплементация [AuthRepository] для работы с аутентификацией через data sources.
///
/// Инкапсулирует преобразование моделей и делегирует вызовы data-слою.
class AuthRepositoryImpl implements AuthRepository {
  /// Data source для аутентификации.
  final AuthDataSource authDataSource;

  /// Создаёт [AuthRepositoryImpl] с указанными data sources.
  AuthRepositoryImpl({
    required this.authDataSource,
  });

  // === Стандартные методы авторизации ===

  @override
  @Deprecated('Используйте телефонную авторизацию через OTP')
  Future<User> login(String email, String password) async {
    final userModel = await authDataSource.login(email, password);
    return userModel.toDomain();
  }

  @override
  @Deprecated('Используйте телефонную авторизацию через OTP')
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
      final userModel = await authDataSource.getCurrentUser();
      if (userModel != null) {
        return userModel.toDomain();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // === OTP (Email) methods ===

  @override
  @Deprecated('Используйте requestPhoneOtp')
  Future<void> requestEmailOtp({required String email}) async {
    await authDataSource.requestEmailOtp(email);
  }

  @override
  @Deprecated('Используйте verifyPhoneOtp')
  Future<User> verifyEmailOtp(
      {required String email, required String code}) async {
    final model = await authDataSource.verifyEmailOtp(email, code);
    return model.toDomain();
  }

  // === OTP (Phone) methods ===

  @override
  Future<String> requestPhoneOtp({required String phone}) async {
    return await authDataSource.requestPhoneOtp(phone);
  }

  @override
  Future<User> verifyPhoneOtp({
    required String phone,
    required String code,
    required String token,
  }) async {
    final model = await authDataSource.verifyPhoneOtp(
      phone: phone,
      code: code,
      token: token,
    );
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
}
