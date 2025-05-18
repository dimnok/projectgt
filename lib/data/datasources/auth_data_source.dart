import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:projectgt/data/models/user_model.dart';
import 'package:logger/logger.dart';

/// Абстракция для источника данных аутентификации.
///
/// Определяет контракт для реализации аутентификации пользователя, регистрации, выхода и получения текущего пользователя.
abstract class AuthDataSource {
  /// Аутентифицирует пользователя по email и паролю.
  ///
  /// [email] — email пользователя.
  /// [password] — пароль пользователя.
  /// Возвращает [UserModel] при успешной аутентификации.
  /// Генерирует исключение при ошибке.
  Future<UserModel> login(String email, String password);

  /// Регистрирует нового пользователя.
  ///
  /// [name] — имя пользователя.
  /// [email] — email пользователя.
  /// [password] — пароль пользователя.
  /// Возвращает [UserModel] при успешной регистрации.
  /// Генерирует исключение при ошибке.
  Future<UserModel> register(String name, String email, String password);

  /// Выходит из аккаунта пользователя.
  ///
  /// Генерирует исключение при ошибке.
  Future<void> logout();

  /// Получает текущего аутентифицированного пользователя.
  ///
  /// Возвращает [UserModel], если пользователь авторизован, иначе null.
  Future<UserModel?> getCurrentUser();
}

/// Реализация [AuthDataSource] через Supabase.
///
/// Использует Supabase Auth для аутентификации, регистрации, выхода и получения профиля пользователя.
class SupabaseAuthDataSource implements AuthDataSource {
  /// Экземпляр клиента Supabase.
  final SupabaseClient client;

  /// Создаёт источник данных аутентификации через Supabase.
  ///
  /// [client] — экземпляр [SupabaseClient].
  SupabaseAuthDataSource(this.client);

  @override
  Future<UserModel> login(String email, String password) async {
    try {
      final response = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      if (response.user == null) {
        throw Exception('Неверные учетные данные');
      }
      
      // Получаем роль пользователя из профиля
      String role = 'user';
      try {
        final profileData = await client
            .from('profiles')
            .select('role')
            .eq('id', response.user!.id)
            .single();
        
        if (profileData['role'] != null) {
          role = profileData['role'];
        }
      } catch (e) {
        Logger().e('Ошибка при получении роли: $e');
      }
      
      return UserModel(
        id: response.user!.id,
        email: response.user!.email!,
        name: response.user!.userMetadata?['name'] as String?,
        photoUrl: response.user!.userMetadata?['photoUrl'] as String?,
        role: role,
      );
    } catch (e) {
      // Обрабатываем конкретные ошибки Supabase
      final errorMessage = e.toString();
      if (errorMessage.contains('invalid_credentials') || 
          errorMessage.contains('Invalid login credentials')) {
        throw Exception('Неверный email или пароль');
      } else if (errorMessage.contains('network')) {
        throw Exception('Ошибка сети. Проверьте подключение к интернету');
      } else {
        throw Exception('Ошибка авторизации: $e');
      }
    }
  }

  @override
  Future<UserModel> register(String name, String email, String password) async {
    try {
      final response = await client.auth.signUp(
        email: email,
        password: password,
        data: {
          'name': name,
        },
      );
      
      if (response.user == null) {
        throw Exception('Ошибка регистрации');
      }
      
      // По умолчанию роль 'user'
      const role = 'user';
      
      // Создаем запись в таблице profiles
      final userId = response.user!.id;
      final fullName = name;
      
      // Генерируем сокращенное имя из полного
      String? shortName;
      if (fullName.isNotEmpty) {
        final nameParts = fullName.split(' ');
        if (nameParts.length > 1) {
          // Если есть несколько частей в имени, используем инициалы
          shortName = '${nameParts[0]} ${nameParts.sublist(1).map((p) => p.isNotEmpty ? '${p[0]}.' : '').join(' ')}';
        } else {
          shortName = fullName;
        }
      }
      
      // Создаем запись в таблице profiles
      await client.from('profiles').insert({
        'id': userId,
        'email': email,
        'full_name': fullName,
        'short_name': shortName,
        'role': role,
        'status': true,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
      
      Logger().i('Профиль пользователя создан: $userId, $fullName, $shortName, роль: $role');
      
      return UserModel(
        id: userId,
        email: email,
        name: name,
        photoUrl: null,
        role: role,
      );
    } catch (e) {
      // Обрабатываем конкретные ошибки Supabase
      final errorMessage = e.toString();
      if (errorMessage.contains('email address is already registered')) {
        throw Exception('Этот email уже зарегистрирован');
      } else if (errorMessage.contains('password should be at least')) {
        throw Exception('Пароль должен содержать не менее 6 символов');
      } else if (errorMessage.contains('network')) {
        throw Exception('Ошибка сети. Проверьте подключение к интернету');
      } else {
        throw Exception('Ошибка регистрации: $e');
      }
    }
  }

  @override
  Future<void> logout() async {
    await client.auth.signOut();
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    final user = client.auth.currentUser;
    
    if (user == null) {
      return null;
    }
    
    // Получаем роль пользователя из профиля
    String role = 'user';
    try {
      final profileData = await client
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .single();
      
      if (profileData['role'] != null) {
        role = profileData['role'];
      }
    } catch (e) {
      Logger().e('Ошибка при получении роли: $e');
    }
    
    return UserModel(
      id: user.id,
      email: user.email!,
      name: user.userMetadata?['name'] as String?,
      photoUrl: user.userMetadata?['photoUrl'] as String?,
      role: role,
    );
  }
} 