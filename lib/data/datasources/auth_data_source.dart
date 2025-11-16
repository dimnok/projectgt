import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:projectgt/data/models/user_model.dart';
import 'package:logger/logger.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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

  /// Отправляет 6-значный код подтверждения на email (passwordless OTP).
  Future<void> requestEmailOtp(String email);

  /// Подтверждает 6-значный код и возвращает пользователя.
  Future<UserModel> verifyEmailOtp(String email, String code);

  /// Обновляет профиль пользователя при первой авторизации.
  ///
  /// [fullName] — полное ФИО пользователя.
  /// [phone] — номер телефона в формате +7-(XXX)-XXX-XXXX.
  Future<void> updateProfile({
    required String fullName,
    required String phone,
  });

  /// Верифицирует Telegram Mini App initData и возвращает пользователя.
  Future<UserModel> verifyTelegramInitData(String initData);
}

/// Реализация [AuthDataSource] через Supabase.
///
/// Использует Supabase Auth для аутентификации, регистрации, выхода и получения профиля пользователя.
class SupabaseAuthDataSource implements AuthDataSource {
  /// Экземпляр клиента Supabase.
  final SupabaseClient client;

  /// Логгер для записи событий.
  final Logger logger = Logger();

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

      // Профиль создастся серверным триггером handle_new_user(); возвращаем UserModel с базовыми полями
      return UserModel(
        id: response.user!.id,
        email: email,
        name: name,
        photoUrl: null,
        role: 'user',
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
    var user = client.auth.currentUser;
    // Если локально пользователь ещё не подхвачен, пробуем получить через API
    if (user == null) {
      try {
        final res = await client.auth.getUser();
        user = res.user;
      } catch (e) {
        // игнорируем, вернём null ниже
      }
      if (user == null) {
        return null;
      }
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
      email: user.email ?? '',
      name: user.userMetadata?['name'] as String?,
      photoUrl: user.userMetadata?['photoUrl'] as String?,
      role: role,
    );
  }

  @override
  Future<void> requestEmailOtp(String email) async {
    try {
      await client.auth.signInWithOtp(
        email: email,
        shouldCreateUser: true,
      );
      // Доп. гарантия для НОВЫХ пользователей: отправим confirm-signup OTP
      try {
        await client.auth.resend(
          type: OtpType.signup,
          email: email,
        );
      } catch (_) {
        // игнорируем, если пользователь уже существует
      }
    } catch (e) {
      final message = e.toString();
      if (message.contains('network')) {
        throw Exception('Ошибка сети. Проверьте подключение к интернету');
      }
      throw Exception('Не удалось отправить код: $e');
    }
  }

  @override
  Future<UserModel> verifyEmailOtp(String email, String code) async {
    try {
      // Пытаемся сначала как обычный email OTP
      var res = await client.auth.verifyOTP(
        email: email,
        token: code,
        type: OtpType.email,
      );

      final authed = res.user ?? client.auth.currentUser;
      if (authed == null) {
        // Возможен сценарий confirm-signup OTP для нового пользователя
        res = await client.auth.verifyOTP(
          email: email,
          token: code,
          type: OtpType.signup,
        );
      }
      final user = res.user ?? client.auth.currentUser;
      if (user == null) {
        throw Exception('Не удалось подтвердить код');
      }

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
      } catch (_) {}

      return UserModel(
        id: user.id,
        email: user.email ?? email,
        name: user.userMetadata?['name'] as String?,
        photoUrl: user.userMetadata?['photoUrl'] as String?,
        role: role,
      );
    } catch (e) {
      final message = e.toString();
      if (message.contains('Token has expired') ||
          message.contains('Invalid token')) {
        throw Exception('Неверный или просроченный код');
      }
      if (message.contains('network')) {
        throw Exception('Ошибка сети. Проверьте подключение к интернету');
      }
      throw Exception('Ошибка подтверждения кода: $e');
    }
  }

  @override
  Future<void> updateProfile({
    required String fullName,
    required String phone,
  }) async {
    final currentUser = client.auth.currentUser;
    if (currentUser == null) {
      throw Exception('Пользователь не авторизован');
    }

    try {
      // Обновляем только поля full_name и phone для текущего пользователя
      await client.from('profiles').update({
        'full_name': fullName.trim(),
        'phone': phone.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', currentUser.id);

      // Логируем успешное обновление профиля
      logger.i('Профиль пользователя обновлён: ${currentUser.id}');
    } catch (e) {
      logger.e('Ошибка обновления профиля: $e');
      throw Exception('Не удалось обновить профиль: $e');
    }
  }

  @override
  Future<UserModel> verifyTelegramInitData(String initData) async {
    try {
      print('📞 [SupabaseAuthDataSource] Вызываем Edge Function tg-init...');
      print('📄 [SupabaseAuthDataSource] initData length: ${initData.length}');
      
      // Вызываем Edge Function напрямую через HTTP
      // Используем Supabase REST API напрямую с apikey
      final functionUrl = 'https://hzcawspbkvkrsmsklyuj.supabase.co/functions/v1/tg-init';
      
      print('🔗 [SupabaseAuthDataSource] Function URL: $functionUrl');
      
      final response = await http.post(
        Uri.parse(functionUrl),
        headers: {
          'Content-Type': 'application/json',
          'apikey': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imh6Y2F3c3Bia3ZrcnNta3NseXVqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTU1MzgwODgsImV4cCI6MTc3MTE5ODA4OH0.MzIfGKzV-pBz_8Qds0CzzNGMkDIEf1KDLG2J9aCHqU0',
        },
        body: jsonEncode({'initData': initData}),
      );
      
      print('✅ [SupabaseAuthDataSource] Edge Function ответила: ${response.statusCode}');

      if (response.statusCode != 200) {
        print('❌ [SupabaseAuthDataSource] Error body: ${response.body}');
        throw Exception('Edge Function ошибка: ${response.body}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final accessToken = data['access_token'] as String?;
      
      if (accessToken == null) {
        print('❌ [SupabaseAuthDataSource] accessToken is null!');
        throw Exception('Не удалось получить токен от Telegram');
      }
      print('🔑 [SupabaseAuthDataSource] accessToken получен: ${accessToken.substring(0, 20)}...');

      // Устанавливаем сессию и получаем пользователя
      print('🔐 [SupabaseAuthDataSource] Устанавливаем сессию...');
      await client.auth.setSession(accessToken);
      final user = client.auth.currentUser;
      print('👤 [SupabaseAuthDataSource] currentUser: ${user?.id}');
      
      if (user == null) {
        print('❌ [SupabaseAuthDataSource] user is null after setSession!');
        throw Exception('Пользователь не найден после авторизации');
      }

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
      } catch (_) {}

      print('✅ [SupabaseAuthDataSource] Возвращаем UserModel с id: ${user.id}');
      return UserModel(
        id: user.id,
        email: user.email ?? '',
        name: user.userMetadata?['name'] as String?,
        photoUrl: user.userMetadata?['photoUrl'] as String?,
        role: role,
      );
    } catch (e) {
      print('❌ [SupabaseAuthDataSource] Ошибка: $e');
      logger.e('Ошибка верификации Telegram: $e');
      throw Exception('Ошибка авторизации через Telegram: $e');
    }
  }
}
