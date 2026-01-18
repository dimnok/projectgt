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

  /// Пользователь успешно аутентифицирован.
  authenticated,

  /// Пользователь не аутентифицирован.
  unauthenticated,

  /// Процесс загрузки или проверки данных.
  loading,

  /// Произошла ошибка в процессе аутентификации.
  error,

  /// Регистрация успешна, ожидается одобрение администратором.
  pendingApproval,

  /// Аккаунт пользователя заблокирован.
  disabled,

  /// Пользователь вошел, но еще не завершил настройку профиля/компании.
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

  // Флаги состояния
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

  // --- Методы управления состоянием ---

  /// Сбрасывает ошибку в состоянии.
  void resetError() {
    if (state.status == AuthStatus.error) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: null,
      );
    }
  }

  /// Проверяет текущий статус аутентификации.
  /// Делает легкую проверку сессии. Тяжелые данные загружает только при необходимости.
  Future<void> checkAuthStatus({bool force = false}) async {
    // Защита от повторных вызовов
    if (!force &&
        (state.status == AuthStatus.pendingApproval ||
            state.status == AuthStatus.disabled)) {
      return;
    }
    if (_isCheckingAuth) return;
    if (_isManualVerifying && !force) return;

    _isCheckingAuth = true;

    // Показываем лоадер только если у нас точно нет пользователя
    if (state.user == null) {
      state = state.copyWith(status: AuthStatus.loading);
    }

    try {
      // 1. Обработка Web URL (OAuth callback)
      if (kIsWeb) {
        final hash = web.window.location.hash;
        if (hash.contains('access_token')) {
          final fixedHref = web.window.location.href.replaceFirst('#/#', '#');
          await supa.Supabase.instance.client.auth.getSessionFromUrl(
            Uri.parse(fixedHref),
          );
        }
      }

      // 2. Проверка сессии Supabase (локальная, быстрая)
      final currentUser = supa.Supabase.instance.client.auth.currentUser;

      if (currentUser == null) {
        state = state.copyWith(status: AuthStatus.unauthenticated, user: null);
        return;
      }

      // 3. Формируем базовую модель пользователя
      var user = User(
        id: currentUser.id,
        email: currentUser.email ?? '',
        name: currentUser.userMetadata?['name'] as String?,
        photoUrl: currentUser.userMetadata?['photoUrl'] as String?,
      );

      // 4. Если мы не заставляем (force), пытаемся взять роли из текущего состояния
      // (чтобы не дергать базу при каждом чихе, например при onAuthStateChange)
      if (!force && state.user?.id == user.id && state.user?.roleId != null) {
        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: state.user,
        );
        return;
      }

      // 5. Если нужно (при старте или force) - загружаем полный контекст.
      // Чтобы избежать лоадера в AuthGate, дожидаемся загрузки данных профиля через UseCase.
      final profileFuture = _ref.read(getProfileUseCaseProvider).call(user.id);
      final enrichedUserFuture = _fetchUserContext(user);

      final results = await Future.wait([profileFuture, enrichedUserFuture]);
      final enrichedUser = results[1] as User;

      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: enrichedUser,
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

  /// Универсальный метод для загрузки контекста пользователя (Профиль + Роли + Статус).
  /// Возвращает enriched User с roleId, systemRole и правильным AuthStatus.
  Future<User> _fetchUserContext(User baseUser) async {
    try {
      final client = supa.Supabase.instance.client;

      // 1. Получаем профиль (статус, approved_at, last_company_id)
      final profileData = await client
          .from('profiles')
          .select('status, approved_at, last_company_id')
          .eq('id', baseUser.id)
          .single();

      final bool statusFlag = (profileData['status'] as bool?) ?? true;
      final bool everApproved = profileData['approved_at'] != null;
      final String? lastCompanyId = profileData['last_company_id'] as String?;

      // 2. Проверяем блокировку
      if (!statusFlag) {
        final newStatus = everApproved
            ? AuthStatus.disabled
            : AuthStatus.pendingApproval;
        // Важно: обновляем глобальный статус сразу, так как метод может вызываться из разных мест
        if (state.status != newStatus) {
          state = state.copyWith(status: newStatus, user: baseUser);
        }
        return baseUser; // Возвращаем базового юзера, роли ему не нужны
      }

      // 3. Загружаем роль (roleId, systemRole) из активной компании
      String? roleId;
      String? systemRole;

      if (lastCompanyId != null) {
        try {
          final memberData = await client
              .from('company_members')
              .select('role_id, system_role')
              .eq('user_id', baseUser.id)
              .eq('company_id', lastCompanyId)
              .eq('is_active', true)
              .single();
          roleId = memberData['role_id'] as String?;
          systemRole = memberData['system_role'] as String?;
        } catch (_) {
          // Fallback: если последняя компания не найдена или неактивна, берем любую активную
          try {
            final memberData = await client
                .from('company_members')
                .select('role_id, system_role, company_id')
                .eq('user_id', baseUser.id)
                .eq('is_active', true)
                .limit(1)
                .single();
            roleId = memberData['role_id'] as String?;
            systemRole = memberData['system_role'] as String?;
            // Можно обновить last_company_id здесь, если нужно
          } catch (_) {}
        }
      }

      return baseUser.copyWith(roleId: roleId, systemRole: systemRole);
    } catch (e) {
      // При ошибке базы возвращаем базового юзера, чтобы не ломать вход
      return baseUser;
    }
  }

  /// Отправляет код на телефон
  Future<void> requestPhoneOtp(String phone) async {
    try {
      final token = await _ref
          .read(requestPhoneOtpUseCaseProvider)
          .execute(phone: phone);
      state = state.copyWith(verificationToken: token, errorMessage: null);
    } catch (e) {
      String message = e.toString();
      if (message.contains('FunctionException')) {
        message = 'Ошибка отправки кода. Попробуйте позже.';
      }
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: message,
      );
      rethrow;
    }
  }

  /// Подтверждает код и запускает процесс входа
  Future<void> verifyPhoneOtp(String phone, String code) async {
    if (state.verificationToken == null) {
      const err = 'Токен верификации отсутствует';
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: err,
      );
      throw Exception(err);
    }

    _isManualVerifying = true;

    try {
      // 1. Верификация самого кода (быстро)
      final user = await _ref
          .read(verifyPhoneOtpUseCaseProvider)
          .execute(phone: phone, code: code, token: state.verificationToken!);

      // 2. Сразу обновляем User, чтобы UI показал успех (анимация), статус оставляем старым
      state = state.copyWith(user: user, errorMessage: null);

      // 3. Запускаем фоновую загрузку данных и переход
      _finalizeAuthWithDelay(user);
    } catch (e) {
      _isManualVerifying = false;
      String message = e.toString();
      if (message.contains('Invalid or expired code')) {
        message = 'Неверный или просроченный код';
      } else if (message.contains('otp-notisend')) {
        message = 'Ошибка службы отправки кода';
      }

      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: message,
      );
      rethrow;
    }
  }

  /// Фоновый процесс: подгрузка профиля + задержка для анимации + редирект
  Future<void> _finalizeAuthWithDelay(User user) async {
    try {
      // 1. Запускаем параллельно: таймер 1.5 сек и загрузку профиля через UseCase.
      // Мы НЕ используем currentUserProfileProvider напрямую здесь, чтобы избежать круговой зависимости.
      // CurrentUserProfileNotifier сам подхватит загрузку, так как он слушает изменения authProvider.

      final profileFuture = _ref.read(getProfileUseCaseProvider).call(user.id);
      final timerFuture = Future.delayed(const Duration(milliseconds: 1500));

      // Ждем завершения обоих задач (минимум 1.5 сек)
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

      // 3. Определяем финальный статус на основе профиля.
      if (!profile.status) {
        await _fetchUserContext(user);
        _isManualVerifying = false;
        return;
      }

      final finalStatus = profile.lastCompanyId == null
          ? AuthStatus.onboarding
          : AuthStatus.authenticated;

      state = state.copyWith(
        status: finalStatus,
        user: user.copyWith(
          roleId: profile.roleId,
          systemRole: profile.systemRole,
        ),
      );

      // 4. Снимаем блокировку авто-чека с небольшой задержкой
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

  /// Выход из системы
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

  /// Переключение компании
  Future<void> switchCompany(String companyId) async {
    final user = state.user;
    if (user == null) return;

    state = state.copyWith(status: AuthStatus.loading);
    try {
      await supa.Supabase.instance.client
          .from('profiles')
          .update({'last_company_id': companyId})
          .eq('id', user.id);

      // Обновляем профиль в другом провайдере
      await _ref
          .read(currentUserProfileProvider.notifier)
          .refreshCurrentUserProfile(user.id);

      // Перечитываем статус Auth с учетом новой компании (force)
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
