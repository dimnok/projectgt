import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/domain/entities/user.dart';

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
  
  /// Флаг для отслеживания состояния проверки аутентификации.
  bool _isCheckingAuth = false;

  /// Создаёт [AuthNotifier] и инициализирует состояние.
  AuthNotifier(Ref ref)
      : _ref = ref,
        super(AuthState.initial()) {
    checkAuthStatus();
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
  Future<void> checkAuthStatus() async {
    // Избегаем повторных проверок
    if (_isCheckingAuth || 
        state.status == AuthStatus.authenticated || 
        state.status == AuthStatus.unauthenticated) {
      return;
    }
    
    _isCheckingAuth = true;
    state = state.copyWith(status: AuthStatus.loading);
    
    try {
      final user = await _ref.read(getCurrentUserUseCaseProvider).execute();
      if (user != null) {
        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
        );
      } else {
        state = state.copyWith(status: AuthStatus.unauthenticated);
      }
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
    } finally {
      _isCheckingAuth = false;
    }
  }

  /// Выполняет вход пользователя по email и паролю.
  ///
  /// В случае успеха — обновляет состояние на authenticated, иначе — error.
  Future<void> login(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final user = await _ref.read(loginUseCaseProvider).execute(email, password);
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
      );
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// Выполняет регистрацию нового пользователя.
  ///
  /// В случае успеха — обновляет состояние на authenticated, иначе — error.
  Future<void> register(String name, String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final user = await _ref.read(registerUseCaseProvider).execute(name, email, password);
      state = state.copyWith(
        status: AuthStatus.authenticated,
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