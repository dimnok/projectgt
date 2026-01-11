import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/domain/entities/user.dart';
import 'package:projectgt/presentation/state/profile_state.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;
import 'package:universal_html/html.dart' as web;

/// Перечисление возможных статусов аутентификации пользователя.
///
/// Используется для управления состоянием авторизации в приложении.
enum AuthStatus {
  /// Начальное состояние (не определено).
  initial,

  /// Пользователь успешно аутентифицирован.
  authenticated,

  /// Пользователь не аутентифицирован.
  unauthenticated,

  /// Выполняется операция (загрузка, проверка и т.д.).
  loading,

  /// Произошла ошибка аутентификации.
  error,

  /// Ожидает одобрения администратором (профиль status=false при первой авторизации).
  pendingApproval,

  /// Доступ отключён администратором (профиль status=false при активной сессии).
  disabled,

  /// Пользователь аутентифицирован, но ещё не выбрал или не создал компанию.
  onboarding,
}

/// Состояние аутентификации пользователя.
///
/// Хранит текущий статус, пользователя и сообщение об ошибке (если есть).
class AuthState {
  /// Текущий статус аутентификации ([AuthStatus]).
  final AuthStatus status;

  /// Текущий пользователь ([User]), если аутентифицирован.
  final User? user;

  /// Сообщение об ошибке (если есть).
  final String? errorMessage;

  /// Токен верификации для телефонного OTP.
  final String? verificationToken;

  /// Создаёт новое состояние аутентификации.
  ///
  /// [status] — статус аутентификации.
  /// [user] — текущий пользователь (опционально).
  /// [errorMessage] — сообщение об ошибке (опционально).
  /// [verificationToken] — токен верификации (опционально).
  AuthState({
    required this.status,
    this.user,
    this.errorMessage,
    this.verificationToken,
  });

  /// Возвращает начальное состояние ([AuthStatus.initial]).
  factory AuthState.initial() {
    return AuthState(status: AuthStatus.initial);
  }

  /// Создаёт копию состояния с изменёнными полями.
  ///
  /// [status] — новый статус (опционально).
  /// [user] — новый пользователь (опционально).
  /// [errorMessage] — новое сообщение об ошибке (опционально).
  /// [verificationToken] — новый токен верификации (опционально).
  ///
  /// Пример:
  /// ```dart
  /// state = state.copyWith(status: AuthStatus.authenticated, user: user);
  /// ```
  AuthState copyWith({
    AuthStatus? status,
    User? user,
    String? errorMessage,
    String? verificationToken,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage ?? this.errorMessage,
      verificationToken: verificationToken ?? this.verificationToken,
    );
  }
}

/// StateNotifier для управления состоянием аутентификации пользователя.
///
/// Использует use case-ы для входа, регистрации, выхода и проверки статуса пользователя.
class AuthNotifier extends StateNotifier<AuthState> {
  /// Провайдер use case для выхода.
  final logoutUseCase = logoutUseCaseProvider;

  /// Провайдер use case для получения текущего пользователя.
  final getCurrentUserUseCase = getCurrentUserUseCaseProvider;

  /// Провайдер use case для отправки 6-значного кода на телефон.
  final requestPhoneOtpUseCase = requestPhoneOtpUseCaseProvider;

  /// Провайдер use case для подтверждения 6-значного кода на телефоне.
  final verifyPhoneOtpUseCase = verifyPhoneOtpUseCaseProvider;

  /// Флаг для отслеживания состояния проверки аутентификации.
  bool _isCheckingAuth = false;

  /// Создаёт [AuthNotifier] и инициализирует состояние.
  AuthNotifier(Ref ref)
      : _ref = ref,
        super(AuthState.initial()) {
    checkAuthStatus();

    // Слушаем изменения сессии Supabase, чтобы гарантированно подхватывать вход без перезагрузки
    try {
      supa.Supabase.instance.client.auth.onAuthStateChange.listen((_) {
        checkAuthStatus();
      });
    } catch (_) {}
  }

  final Ref _ref;

  /// Сбрасывает состояние ошибки, если оно активно.
  void resetError() {
    if (state.status == AuthStatus.error) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: null,
      );
    }
  }

  /// Проверяет текущий статус аутентификации пользователя.
  ///
  /// Если пользователь аутентифицирован — обновляет состояние, иначе переводит в unauthenticated.
  /// В случае ошибки — состояние становится error с сообщением.
  /// Также проверяет новые Telegram авторизации из localStorage.
  Future<void> checkAuthStatus({bool force = false}) async {
    
    if (!force && (state.status == AuthStatus.pendingApproval || state.status == AuthStatus.disabled)) {
      return;
    }
    if (_isCheckingAuth) return;

    _isCheckingAuth = true;
    
    // ВАЖНО: Не ставим статус loading, если уже есть пользователь, 
    // чтобы избежать лишних перерисовок экрана загрузки
    if (state.user == null) {
      state = state.copyWith(status: AuthStatus.loading);
    }

    try {
      // 1) Проверяем наличие сессии (Web hash обработка остается)
      if (kIsWeb) {
        final hash = web.window.location.hash;
        if (hash.contains('access_token')) {
          final fixedHref = web.window.location.href.replaceFirst('#/#', '#');
          await supa.Supabase.instance.client.auth.getSessionFromUrl(Uri.parse(fixedHref));
        }
      }

      // 2) Получаем текущего пользователя из Auth SDK (без запросов к таблицам профилей)
      final currentUser = supa.Supabase.instance.client.auth.currentUser;
      
      if (currentUser == null) {
        state = state.copyWith(status: AuthStatus.unauthenticated, user: null);
        return;
      }

      // Конвертируем Supabase User в нашу сущность User (UserModel)
      // Базовую информацию берем из Auth metadata
      var user = User(
        id: currentUser.id,
        email: currentUser.email ?? '',
        name: currentUser.userMetadata?['name'] as String?,
        photoUrl: currentUser.userMetadata?['photoUrl'] as String?,
      );
      
      // Загружаем roleId и systemRole из таблицы company_members
      // (где хранится role_id и systemRole активного члена компании)
      try {
        // 1. Получаем last_company_id из profiles
        final profileResponse = await supa.Supabase.instance.client
            .from('profiles')
            .select('last_company_id')
            .eq('id', currentUser.id)
            .single();
        
        var lastCompanyId = profileResponse['last_company_id'] as String?;
        String? roleId;
        String? systemRole;
        
        // 2. Получаем roleId и systemRole из company_members (для активной компании пользователя)
        if (lastCompanyId != null) {
          try {
            final memberData = await supa.Supabase.instance.client
                .from('company_members')
                .select('role_id, system_role')
                .eq('user_id', currentUser.id)
                .eq('company_id', lastCompanyId)
                .eq('is_active', true)
                .single();
            roleId = memberData['role_id'] as String?;
            systemRole = memberData['system_role'] as String?;
          } catch (_) {
            // Если не найдена роль в последней компании, пробуем получить первую активную
            final memberData = await supa.Supabase.instance.client
                .from('company_members')
                .select('role_id, system_role, company_id')
                .eq('user_id', currentUser.id)
                .eq('is_active', true)
                .limit(1)
                .single();
            roleId = memberData['role_id'] as String?;
            systemRole = memberData['system_role'] as String?;
            lastCompanyId = memberData['company_id'] as String?;
          }
        }
        
        user = user.copyWith(
          roleId: roleId,
          systemRole: systemRole,
        );
        
        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
        );
      } catch (e) {
        // Fallback: используем базового пользователя без roleId
        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
        );
      }
    } catch (e) {
      state = state.copyWith(status: AuthStatus.error, errorMessage: e.toString());
    } finally {
      _isCheckingAuth = false;
    }
  }

  /// Вспомогательный метод для проверки статуса профиля и наличия компаний.
  Future<void> _checkProfileAndCompanyStatus(User user) async {
    try {
      // 1. Проверяем статус профиля (активен/заблокирован)
      final profile = await supa.Supabase.instance.client
          .from('profiles')
          .select('status, approved_at')
          .eq('id', user.id)
          .single();

      final bool statusFlag = (profile['status'] as bool?) ?? true;
      final bool everApproved = profile['approved_at'] != null;

      if (!statusFlag) {
        state = state.copyWith(
          status: everApproved ? AuthStatus.disabled : AuthStatus.pendingApproval,
          user: user,
        );
        return;
      }

      // 2. Проверяем наличие компаний у пользователя
      final companyCountResponse = await supa.Supabase.instance.client
          .from('company_members')
          .select('id')
          .eq('user_id', user.id)
          .eq('is_active', true);

      final int companyCount = (companyCountResponse as List).length;

      if (companyCount == 0) {
        state = state.copyWith(
          status: AuthStatus.onboarding,
          user: user,
        );
      } else {
        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
        );
      }
    } catch (e) {
      // Если профиль ещё не создан или произошла ошибка — по умолчанию считаем authenticated,
      // так как RLS и другие механизмы всё равно защитят данные.
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
      );
    }
  }

  /// Отправляет 6-значный код на телефон
  Future<void> requestPhoneOtp(String phone) async {
    try {
      final token = await _ref
          .read(requestPhoneOtpUseCaseProvider)
          .execute(phone: phone);
      state = state.copyWith(verificationToken: token, errorMessage: null);
    } catch (e) {
      state =
          state.copyWith(status: AuthStatus.error, errorMessage: e.toString());
    }
  }

  /// Подтверждает 6-значный код с телефона и аутентифицирует пользователя
  Future<void> verifyPhoneOtp(String phone, String code) async {
    if (state.verificationToken == null) {
      state = state.copyWith(
          status: AuthStatus.error, errorMessage: 'Токен верификации отсутствует');
      return;
    }

    state = state.copyWith(status: AuthStatus.loading);
    try {
      final user = await _ref.read(verifyPhoneOtpUseCaseProvider).execute(
            phone: phone,
            code: code,
            token: state.verificationToken!,
          );
      await _checkProfileAndCompanyStatus(user);
    } catch (e) {
      state =
          state.copyWith(status: AuthStatus.error, errorMessage: e.toString());
    }
  }

  /// Выполняет выход пользователя из системы.
  ///
  /// В случае успеха — состояние становится unauthenticated, иначе — error.
  Future<void> logout() async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      await _ref.read(logoutUseCaseProvider).execute();
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        user: null,
      );
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// Переключает активную компанию пользователя.
  Future<void> switchCompany(String companyId) async {
    final user = state.user;
    if (user == null) return;

    state = state.copyWith(status: AuthStatus.loading);
    try {
      await supa.Supabase.instance.client
          .from('profiles')
          .update({'last_company_id': companyId})
          .eq('id', user.id);
      
      // [RBAC] Принудительно обновляем профиль текущего пользователя, чтобы подхватить новый last_company_id
      await _ref.read(currentUserProfileProvider.notifier).refreshCurrentUserProfile(user.id);
      
      // Обновляем состояние аутентификации
      await checkAuthStatus(force: true);
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Ошибка при смене компании: $e',
      );
    }
  }
}

/// Провайдер состояния аутентификации пользователя.
///
/// Используется для доступа к [AuthNotifier] и [AuthState] во всём приложении через Riverpod.
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});
