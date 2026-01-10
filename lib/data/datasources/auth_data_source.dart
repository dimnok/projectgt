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
  @Deprecated('Используйте телефонную авторизацию через OTP')
  Future<UserModel> login(String email, String password);

  /// Регистрирует нового пользователя.
  ///
  /// [name] — имя пользователя.
  /// [email] — email пользователя.
  /// [password] — пароль пользователя.
  /// Возвращает [UserModel] при успешной регистрации.
  /// Генерирует исключение при ошибке.
  @Deprecated('Используйте телефонную авторизацию через OTP')
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
  @Deprecated('Используйте requestPhoneOtp')
  Future<void> requestEmailOtp(String email);

  /// Подтверждает 6-значный код и возвращает пользователя.
  @Deprecated('Используйте verifyPhoneOtp')
  Future<UserModel> verifyEmailOtp(String email, String code);

  /// Отправляет 6-значный код подтверждения на телефон через Notisend Telegram Gateway.
  /// Возвращает токен верификации, который нужно передать в [verifyPhoneOtp].
  Future<String> requestPhoneOtp(String phone);

  /// Подтверждает 6-значный код с телефона и возвращает пользователя.
  /// [phone] — номер телефона.
  /// [code] — код из Telegram.
  /// [token] — токен верификации из [requestPhoneOtp].
  Future<UserModel> verifyPhoneOtp({
    required String phone,
    required String code,
    required String token,
  });

  /// Обновляет профиль пользователя при первой авторизации.
  ///
  /// [fullName] — полное ФИО пользователя.
  /// [phone] — номер телефона в формате +7-(XXX)-XXX-XXXX.
  Future<void> updateProfile({required String fullName, required String phone});
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

    // [RBAC v3] Получаем роль пользователя строго из контекста компании.
    // Сначала определяем активную компанию (last_company_id), затем ищем роль в этой компании.
    String? roleId;
    String? systemRole;
    try {
      final profileData = await client
          .from('profiles')
          .select('last_company_id')
          .eq('id', response.user!.id)
          .single();

      final String? lastCompanyId = profileData['last_company_id'];

      if (lastCompanyId != null) {
        final memberData = await client
            .from('company_members')
            .select('role_id, system_role')
            .eq('company_id', lastCompanyId)
            .eq('user_id', response.user!.id)
            .maybeSingle();
        
        roleId = memberData?['role_id'];
        systemRole = memberData?['system_role'];
      }
    } catch (e) {
      Logger().e('Ошибка при получении роли (login): $e');
    }

    return UserModel(
      id: response.user!.id,
      email: response.user!.email!,
      name: response.user!.userMetadata?['name'] as String?,
      photoUrl: response.user!.userMetadata?['photoUrl'] as String?,
      roleId: roleId,
      systemRole: systemRole,
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
        data: {'name': name},
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
        roleId: null,
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
        final res = await client.auth.getUser().timeout(const Duration(seconds: 15));
        user = res.user;
      } catch (e) {
        // игнорируем, вернём null ниже
      }
      if (user == null) {
        return null;
      }
    }

    // [RBAC v3] Получаем роль пользователя строго из контекста компании.
    // Сначала определяем активную компанию (last_company_id), затем ищем роль в этой компании.
    String? roleId;
    String? systemRole;
    try {
      final profileData = await client
          .from('profiles')
          .select('last_company_id')
          .eq('id', user.id)
          .single()
          .timeout(const Duration(seconds: 15));

      final String? lastCompanyId = profileData['last_company_id'];

      if (lastCompanyId != null && lastCompanyId.isNotEmpty) {
        final memberData = await client
            .from('company_members')
            .select('role_id, system_role')
            .eq('company_id', lastCompanyId)
            .eq('user_id', user.id)
            .maybeSingle()
            .timeout(const Duration(seconds: 15));
        
        roleId = memberData?['role_id'];
        systemRole = memberData?['system_role'];
      }
    } catch (e) {
      Logger().e('Ошибка при получении роли (getCurrentUser): $e');
      if (e.toString().contains('PGRST116')) {
        await client.auth.signOut();
      }
    }

    return UserModel(
      id: user.id,
      email: user.email ?? '',
      name: user.userMetadata?['name'] as String?,
      photoUrl: user.userMetadata?['photoUrl'] as String?,
      roleId: roleId,
      systemRole: systemRole,
    );
  }

  @override
  Future<void> requestEmailOtp(String email) async {
    try {
      await client.auth.signInWithOtp(email: email, shouldCreateUser: true);
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

    // [RBAC v3] Получаем роль пользователя строго из контекста компании.
    // Сначала определяем активную компанию (last_company_id), затем ищем роль в этой компании.
    String? roleId;
    String? systemRole;
    try {
      final profileData = await client
          .from('profiles')
          .select('last_company_id')
          .eq('id', user.id)
          .single();

      final String? lastCompanyId = profileData['last_company_id'];

      if (lastCompanyId != null) {
        final memberData = await client
            .from('company_members')
            .select('role_id, system_role')
            .eq('company_id', lastCompanyId)
            .eq('user_id', user.id)
            .maybeSingle();
        
        roleId = memberData?['role_id'];
        systemRole = memberData?['system_role'];
      }
    } catch (_) {}

    return UserModel(
      id: user.id,
      email: user.email ?? email,
      name: user.userMetadata?['name'] as String?,
      photoUrl: user.userMetadata?['photoUrl'] as String?,
      roleId: roleId,
      systemRole: systemRole,
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
  Future<String> requestPhoneOtp(String phone) async {
    try {
      final response = await client.functions.invoke(
        'otp-notisend',
        body: {'action': 'send', 'phone': phone},
      );

      final data = response.data as Map<String, dynamic>;
      if (data['success'] == true) {
        return data['token'] as String;
      } else {
        throw Exception(data['error'] ?? 'Ошибка отправки кода');
      }
    } catch (e) {
      logger.e('Ошибка requestPhoneOtp: $e');
      throw Exception('Не удалось отправить код в Telegram: $e');
    }
  }

  @override
  Future<UserModel> verifyPhoneOtp({
    required String phone,
    required String code,
    required String token,
  }) async {
    try {
      // 1. Верифицируем код через Edge Function
      final response = await client.functions.invoke(
        'otp-notisend',
        body: {
          'action': 'verify',
          'phone': phone,
          'code': code,
          'token': token,
        },
      );

      final data = response.data as Map<String, dynamic>;
      if (data['success'] != true) {
        throw Exception(data['error'] ?? 'Неверный код');
      }

      // 2. Получаем временный пароль и email для входа
      final tempPass = data['temp_pass']?.toString();
      final email = data['email']?.toString();

      if (tempPass == null || email == null) {
        throw Exception(
          'Ошибка данных авторизации: отсутствуют необходимые поля',
        );
      }

      // 3. Выполняем вход по временному паролю
      final authRes = await client.auth.signInWithPassword(
        email: email,
        password: tempPass,
      );

      final user = authRes.user;
      if (user == null) {
        throw Exception('Ошибка авторизации после проверки кода');
      }

    // [RBAC v3] Получаем роль пользователя строго из контекста компании.
    // Сначала определяем активную компанию (last_company_id), затем ищем роль в этой компании.
    String? roleId;
    String? systemRole;
    try {
      final profileData = await client
          .from('profiles')
          .select('last_company_id')
          .eq('id', user.id)
          .single();

      final String? lastCompanyId = profileData['last_company_id'];

      if (lastCompanyId != null) {
        final memberData = await client
            .from('company_members')
            .select('role_id, system_role')
            .eq('company_id', lastCompanyId)
            .eq('user_id', user.id)
            .maybeSingle();
        
        roleId = memberData?['role_id'];
        systemRole = memberData?['system_role'];
      }
    } catch (_) {}

    return UserModel(
      id: user.id,
      email: user.email ?? email,
      name: user.userMetadata?['name'] as String?,
      photoUrl: user.userMetadata?['photoUrl'] as String?,
      roleId: roleId,
      systemRole: systemRole,
    );
  } catch (e) {
      logger.e('Ошибка verifyPhoneOtp: $e');
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
      await client
          .from('profiles')
          .update({
            'full_name': fullName.trim(),
            'phone': phone.trim(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', currentUser.id);

      // Логируем успешное обновление профиля
      logger.i('Профиль пользователя обновлён: ${currentUser.id}');
    } catch (e) {
      logger.e('Ошибка обновления профиля: $e');
      throw Exception('Не удалось обновить профиль: $e');
    }
  }
}
