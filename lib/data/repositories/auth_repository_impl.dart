import 'package:projectgt/data/datasources/auth_data_source.dart';
import 'package:projectgt/domain/entities/user.dart';
import 'package:projectgt/domain/repositories/auth_repository.dart';

/// Имплементация [AuthRepository] для работы с аутентификацией через data source.
///
/// Инкапсулирует преобразование моделей и делегирует вызовы data-слою.
class AuthRepositoryImpl implements AuthRepository {
  /// Data source для аутентификации.
  final AuthDataSource dataSource;

  /// Создаёт [AuthRepositoryImpl] с указанным [dataSource].
  AuthRepositoryImpl(this.dataSource);

  @override
  Future<User> login(String email, String password) async {
    final userModel = await dataSource.login(email, password);
    return userModel.toDomain();
  }

  @override
  Future<User> register(String name, String email, String password) async {
    final userModel = await dataSource.register(name, email, password);
    return userModel.toDomain();
  }

  @override
  Future<void> logout() async {
    await dataSource.logout();
  }

  @override
  Future<User?> getCurrentUser() async {
    final userModel = await dataSource.getCurrentUser();
    return userModel?.toDomain();
  }
} 