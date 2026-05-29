import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/domain/entities/user.dart';
import 'package:projectgt/domain/entities/profile.dart' as entity;
import 'package:projectgt/presentation/state/profile_state.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;
import 'package:universal_html/html.dart' as web;

/// Перечисление возможных статусов аутентификации пользователя.
enum AuthStatus {
  /// Начальное состояние при запуске приложения.
  initial,

  /// Пользователь успешно аутентифицирован и привязан к компании.
  authenticated,

  /// Пользователь не аутентифицирован.
  unauthenticated,

  /// Процесс загрузки или проверки данных.
  loading,

  /// Произошла ошибка в процессе аутентификации.
  error,

  /// Аккаунт пользователя заблокирован (глобально или в компании).
  disabled,

  /// Пользователь вошёл, но ещё не выбрал/не создал компанию.
  onboarding,
}

/// Состояние аутентификации пользователя.
class AuthState {
  /// Текущий статус аутентификации.
  final AuthStatus status;

  /// Данные текущего пользователя (если есть).
  final User? user;

  /// Сообщение об ошибке (если статус [AuthStatus.error]).
  final String? errorMessage;

  /// Временный токен для верификации OTP.
  final String? verificationToken;

  /// Конструктор [AuthState].
  AuthState({
    required this.status,
    this.user,
    this.errorMessage,
    this.verificationToken,
  });

  /// Создает начальное состояние.
  factory AuthState.initial() => AuthState(status: AuthStatus.initial);

  /// Создает копию состояния с измененными полями.
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
class AuthNotifier extends StateNotifier<AuthState> {
  final Ref _ref;

  bool _isCheckingAuth = false;
  bool _isManualVerifying = false;

  /// Указывает, выполняется ли сейчас ручная верификация (login).
  bool get isManualVerifying => _isManualVerifying;

  /// Конструктор [AuthNotifier].
  AuthNotifier(this._ref) : super(AuthState.initial()) {
    _initAuthListener();
    checkAuthStatus();
  }

  void _initAuthListener() {
    try {
      supa.Supabase.instance.client.auth.onAuthStateChange.listen((_) {
        if (!_isManualVerifying) {
          checkAuthStatus();
        }
      });
    } catch (_) {}
  }

  /// Сбрасывает ошибку в состоянии.
  void resetError() {
    if (state.status == AuthStatus.error) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: null,
      );
    }
  }

  /// Определяет [AuthStatus] по загруженному профилю.
  AuthStatus _authStatusFromProfile(entity.Profile? profile) {
    if (profile == null) return AuthStatus.error;
    if (!profile.status) return AuthStatus.disabled;
    if (profile.lastCompanyId == null) return AuthStatus.onboarding;
    return AuthStatus.authenticated;
  }

  User _userWithProfileRoles(User base, entity.Profile profile) {
    return base.copyWith(
      roleId: profile.roleId,
      systemRole: profile.systemRole,
    );
  }

  /// Проверяет текущий статус аутентификации.
  Future<void> checkAuthStatus({bool force = false}) async {
    if (!force && state.status == AuthStatus.disabled) {
      return;
    }
    if (_isCheckingAuth) return;
    if (_isManualVerifying && !force) return;

    _isCheckingAuth = true;

    if (state.user == null) {
      state = state.copyWith(status: AuthStatus.loading);
    }

    try {
      if (kIsWeb) {
        final hash = web.window.location.hash;
        if (hash.contains('access_token')) {
          final fixedHref = web.window.location.href.replaceFirst('#/#', '#');
          await supa.Supabase.instance.client.auth.getSessionFromUrl(
            Uri.parse(fixedHref),
          );
        }
      }

      final currentUser = supa.Supabase.instance.client.auth.currentUser;

      if (currentUser == null) {
        state = state.copyWith(status: AuthStatus.unauthenticated, user: null);
        return;
      }

      var user = User(
        id: currentUser.id,
        email: currentUser.email ?? '',
        name: currentUser.userMetadata?['name'] as String?,
        photoUrl: currentUser.userMetadata?['photoUrl'] as String?,
      );

      if (!force &&
          state.user?.id == user.id &&
          state.status == AuthStatus.authenticated &&
          state.user?.roleId != null) {
        return;
      }

      final profile = await _ref.read(getProfileUseCaseProvider).call(user.id);
      if (profile != null) {
        user = _userWithProfileRoles(user, profile);
      }

      final authStatus = profile == null
          ? AuthStatus.error
          : _authStatusFromProfile(profile);

      state = state.copyWith(
        status: authStatus,
        user: user,
        errorMessage: profile == null ? 'Профиль не найден' : null,
      );
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
    } finally {
      _isCheckingAuth = false;
    }
  }

  /// Отправляет код на телефон.
  Future<void> requestPhoneOtp(String phone) async {
    try {
      await _ref.read(requestPhoneOtpUseCaseProvider).execute(phone: phone);
      state = state.copyWith(verificationToken: 'supabase', errorMessage: null);
    } catch (e) {
      String message = e.toString();
      if (message.contains('FunctionException') ||
          message.contains('hook') ||
          message.contains('SMS')) {
        message = 'Ошибка отправки кода. Попробуйте позже.';
      }
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: message,
      );
      rethrow;
    }
  }

  /// Подтверждает код и запускает процесс входа.
  Future<void> verifyPhoneOtp(String phone, String code) async {
    if (state.verificationToken == null) {
      const err = 'Сначала запросите код подтверждения';
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: err,
      );
      throw Exception(err);
    }

    _isManualVerifying = true;

    try {
      final user = await _ref
          .read(verifyPhoneOtpUseCaseProvider)
          .execute(phone: phone, code: code);

      state = state.copyWith(user: user, errorMessage: null);
      await _finalizeAuthWithDelay(user);
    } catch (e) {
      _isManualVerifying = false;
      String message = e.toString();
      if (message.contains('Invalid or expired code')) {
        message = 'Неверный или просроченный код';
      } else if (message.contains('otp') || message.contains('SMS')) {
        message = 'Ошибка службы отправки кода';
      }

      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: message,
      );
      rethrow;
    }
  }

  /// Подгрузка профиля после OTP и установка финального [AuthStatus].
  Future<void> _finalizeAuthWithDelay(User user) async {
    try {
      final profileFuture = _ref.read(getProfileUseCaseProvider).call(user.id);
      final timerFuture = Future.delayed(const Duration(milliseconds: 1500));

      final results = await Future.wait([profileFuture, timerFuture]);
      final profile = results[0] as entity.Profile?;

      if (profile == null) {
        state = state.copyWith(
          status: AuthStatus.error,
          errorMessage: 'Профиль не найден',
        );
        _isManualVerifying = false;
        return;
      }

      state = state.copyWith(
        status: _authStatusFromProfile(profile),
        user: _userWithProfileRoles(user, profile),
      );

      Future.delayed(const Duration(milliseconds: 500), () {
        _isManualVerifying = false;
      });
    } catch (e) {
      if (mounted) {
        state = state.copyWith(
          status: AuthStatus.error,
          errorMessage: e.toString(),
        );
        _isManualVerifying = false;
      }
    }
  }

  /// Выход из системы.
  Future<void> logout() async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      await _ref.read(logoutUseCaseProvider).execute();
      state = state.copyWith(status: AuthStatus.unauthenticated, user: null);
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// Переключение компании.
  Future<void> switchCompany(String companyId) async {
    final user = state.user;
    if (user == null) return;

    state = state.copyWith(status: AuthStatus.loading);
    try {
      await supa.Supabase.instance.client
          .from('profiles')
          .update({'last_company_id': companyId})
          .eq('id', user.id);

      await _ref
          .read(currentUserProfileProvider.notifier)
          .refreshCurrentUserProfile(user.id);

      await checkAuthStatus(force: true);
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Ошибка при смене компании: $e',
      );
    }
  }
}

/// Провайдер для управления состоянием аутентификации.
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});
