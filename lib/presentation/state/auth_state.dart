import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/domain/entities/user.dart';
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

  /// Создаёт новое состояние аутентификации.
  ///
  /// [status] — статус аутентификации.
  /// [user] — текущий пользователь (опционально).
  /// [errorMessage] — сообщение об ошибке (опционально).
  AuthState({
    required this.status,
    this.user,
    this.errorMessage,
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
  ///
  /// Пример:
  /// ```dart
  /// state = state.copyWith(status: AuthStatus.authenticated, user: user);
  /// ```
  AuthState copyWith({
    AuthStatus? status,
    User? user,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// StateNotifier для управления состоянием аутентификации пользователя.
///
/// Использует use case-ы для входа, регистрации, выхода и проверки статуса пользователя.
class AuthNotifier extends StateNotifier<AuthState> {
  /// Провайдер use case для входа.
  final loginUseCase = loginUseCaseProvider;

  /// Провайдер use case для регистрации.
  final registerUseCase = registerUseCaseProvider;

  /// Провайдер use case для выхода.
  final logoutUseCase = logoutUseCaseProvider;

  /// Провайдер use case для получения текущего пользователя.
  final getCurrentUserUseCase = getCurrentUserUseCaseProvider;

  /// Провайдер use case для отправки 6-значного кода на email.
  final requestEmailOtpUseCase = requestEmailOtpUseCaseProvider;

  /// Провайдер use case для подтверждения 6-значного кода и входа.
  final verifyEmailOtpUseCase = verifyEmailOtpUseCaseProvider;

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
    // Если уже на экране ожидания/блокировки — не перезаписываем статус, кроме принудительного вызова
    if (!force &&
        (state.status == AuthStatus.pendingApproval ||
            state.status == AuthStatus.disabled)) {
      // keep status
      return;
    }
    // Избегаем повторных проверок
    if (_isCheckingAuth) {
      // skip
      return;
    }

    _isCheckingAuth = true;
    state = state.copyWith(status: AuthStatus.loading);
    // start

    try {
      // 1) Если есть hash magic-link c access_token — немедленно поднимаем сессию
      String hash = '';
      String hrefWithToken = '';

      if (kIsWeb) {
        hash = web.window.location.hash; // начинается с '#'
        if (hash.isNotEmpty && hash.contains('access_token')) {
          try {
            // Сохраняем исходный href с токеном
            hrefWithToken = web.window.location.href;
            // Нормализуем кейс двойного hash: "#/#access_token" → "#access_token"
            final fixedHref = hrefWithToken.replaceFirst('#/#', '#');
            // Устанавливаем сессию из исходного (нормализованного) URL
            await supa.Supabase.instance.client.auth
                .getSessionFromUrl(Uri.parse(fixedHref));
            // Ждём коротко, пока SDK проставит currentUser
            for (var i = 0; i < 10; i++) {
              final u = supa.Supabase.instance.client.auth.currentUser;
              if (u != null) break;
              await Future.delayed(const Duration(milliseconds: 150));
            }
            // ok
            // Очищаем URL после успешной установки сессии
            final base = web.window.location.href.split('#').first;
            web.window.history.replaceState(null, '', '$base#/');
          } catch (_) {}
        }
      }

      // Telegram callback удалён

      // 2.1) Дополнительная попытка: если hash есть, но currentUser ещё null — повторно поднимем сессию
      if (kIsWeb &&
          supa.Supabase.instance.client.auth.currentUser == null &&
          hash.isNotEmpty &&
          hash.contains('access_token')) {
        try {
          final hrefWithTokenRetry = web.window.location.href;
          final fixedHref = hrefWithTokenRetry.replaceFirst('#/#', '#');
          await supa.Supabase.instance.client.auth
              .getSessionFromUrl(Uri.parse(fixedHref));
          for (var i = 0; i < 10; i++) {
            final u = supa.Supabase.instance.client.auth.currentUser;
            if (u != null) break;
            await Future.delayed(const Duration(milliseconds: 150));
          }
          // После второй попытки также очищаем URL от hash безопасно
          final base2 = web.window.location.href.split('#').first;
          web.window.history.replaceState(null, '', '$base2#/');
        } catch (_) {}

        // 2.2) Фолбэк: вручную устанавливаем сессию из hash, если SDK не успел
        if (supa.Supabase.instance.client.auth.currentUser == null) {
          try {
            final fragment = hash.startsWith('#') ? hash.substring(1) : hash;
            final params = Uri.splitQueryString(fragment);
            final accessToken = params['access_token'];
            final refreshToken = params['refresh_token'];
            if (accessToken != null && refreshToken != null) {
              await supa.Supabase.instance.client.auth.setSession(refreshToken);
              for (var i = 0; i < 10; i++) {
                final u = supa.Supabase.instance.client.auth.currentUser;
                if (u != null) break;
                await Future.delayed(const Duration(milliseconds: 150));
              }
              final base3 = web.window.location.href.split('#').first;
              web.window.history.replaceState(null, '', '$base3#/');
              // fallback used
            }
          } catch (e) {
            // fallback error
          }
        }
      }

      // 3) Единоразово читаем пользователя из use case
      final user = await _ref.read(getCurrentUserUseCaseProvider).execute();
      if (user == null) {
        state = state.copyWith(status: AuthStatus.unauthenticated);
        return;
      }

      // 4) Проверяем статус профиля
      try {
        final profile = await supa.Supabase.instance.client
            .from('profiles')
            .select('status, approved_at')
            .eq('id', user.id)
            .single();
        final bool statusFlag = (profile['status'] as bool?) ?? false;
        final bool everApproved = profile['approved_at'] != null;
        state = state.copyWith(
          status: statusFlag
              ? AuthStatus.authenticated
              : (everApproved
                  ? AuthStatus.disabled
                  : AuthStatus.pendingApproval),
          user: user,
        );
      } catch (_) {
        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
        );
      }
    } catch (e) {
      // error
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
    } finally {
      // finish
      _isCheckingAuth = false;
    }
  }

  /// Выполняет вход пользователя по email и паролю.
  ///
  /// В случае успеха — обновляет состояние на authenticated, иначе — error.
  Future<void> login(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final user =
          await _ref.read(loginUseCaseProvider).execute(email, password);
      // Проверяем статус профиля
      try {
        final profile = await supa.Supabase.instance.client
            .from('profiles')
            .select('status, approved_at')
            .eq('id', user.id)
            .single();
        final bool statusFlag = (profile['status'] as bool?) ?? false;
        final bool everApproved = profile['approved_at'] != null;
        state = state.copyWith(
          status: statusFlag
              ? AuthStatus.authenticated
              : (everApproved
                  ? AuthStatus.disabled
                  : AuthStatus.pendingApproval),
          user: user,
        );
      } catch (_) {
        state = state.copyWith(status: AuthStatus.pendingApproval, user: user);
      }
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// Отправляет 6-значный код на email
  /// ВАЖНО: не переключаем глобальный статус в loading, чтобы LoginScreen не скрывался через AuthGate
  Future<void> requestEmailOtp(String email) async {
    try {
      await _ref.read(requestEmailOtpUseCaseProvider).execute(email: email);
      // Сохраняем текущий статус (обычно unauthenticated), чтобы форма ввода кода оставалась видимой
      state = state.copyWith(errorMessage: null);
    } catch (e) {
      state =
          state.copyWith(status: AuthStatus.error, errorMessage: e.toString());
    }
  }

  /// Подтверждает 6-значный код и аутентифицирует пользователя
  Future<void> verifyEmailOtp(String email, String code) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final user = await _ref
          .read(verifyEmailOtpUseCaseProvider)
          .execute(email: email, code: code);
      // Проверяем статус профиля
      try {
        final profile = await supa.Supabase.instance.client
            .from('profiles')
            .select('status, approved_at')
            .eq('id', user.id)
            .single();
        final bool statusFlag = (profile['status'] as bool?) ?? false;
        final bool everApproved = profile['approved_at'] != null;
        state = state.copyWith(
          status: statusFlag
              ? AuthStatus.authenticated
              : (everApproved
                  ? AuthStatus.disabled
                  : AuthStatus.pendingApproval),
          user: user,
        );
      } catch (_) {
        // Если профиль недоступен — считаем ожидающим
        state = state.copyWith(status: AuthStatus.pendingApproval, user: user);
      }
    } catch (e) {
      state =
          state.copyWith(status: AuthStatus.error, errorMessage: e.toString());
    }
  }

  /// Выполняет регистрацию нового пользователя.
  ///
  /// В случае успеха — обновляет состояние на authenticated, иначе — error.
  Future<void> register(String name, String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final user = await _ref
          .read(registerUseCaseProvider)
          .execute(name, email, password);
      // Новый пользователь всегда с status=false → ожидание
      state = state.copyWith(
        status: AuthStatus.pendingApproval,
        user: user,
      );
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
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
}

/// Провайдер состояния аутентификации пользователя.
///
/// Используется для доступа к [AuthNotifier] и [AuthState] во всём приложении через Riverpod.
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});
