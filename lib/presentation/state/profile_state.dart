import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/domain/entities/profile.dart';
import 'package:projectgt/presentation/state/auth_state.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Перечисление возможных статусов загрузки и обработки профиля пользователя.
///
/// Используется для управления состоянием экрана и логики работы с профилями.
enum ProfileStatus {
  /// Начальное состояние (ничего не загружено).
  initial,

  /// Выполняется загрузка или операция.
  loading,

  /// Операция завершена успешно.
  success,

  /// Произошла ошибка при выполнении операции.
  error,
}

/// Состояние для работы с профилем пользователя.
///
/// Хранит текущий статус, профиль, список профилей и сообщение об ошибке.
class ProfileState {
  /// Текущий статус загрузки/операции ([ProfileStatus]).
  final ProfileStatus status;

  /// Текущий профиль пользователя (если есть).
  final Profile? profile;

  /// Список всех профилей пользователей.
  final List<Profile> profiles;

  /// Сообщение об ошибке (если есть).
  final String? errorMessage;

  /// Создаёт новое состояние для работы с профилем.
  ///
  /// [status] — статус загрузки/операции.
  /// [profile] — текущий профиль (опционально).
  /// [profiles] — список профилей (по умолчанию пустой).
  /// [errorMessage] — сообщение об ошибке (опционально).
  ProfileState({
    required this.status,
    this.profile,
    this.profiles = const [],
    this.errorMessage,
  });

  /// Возвращает начальное состояние ([ProfileStatus.initial]).
  factory ProfileState.initial() {
    return ProfileState(status: ProfileStatus.initial);
  }

  /// Создаёт копию состояния с изменёнными полями.
  ///
  /// [status] — новый статус (опционально).
  /// [profile] — новый профиль (опционально).
  /// [profiles] — новый список профилей (опционально).
  /// [errorMessage] — новое сообщение об ошибке (опционально).
  ProfileState copyWith({
    ProfileStatus? status,
    Profile? profile,
    List<Profile>? profiles,
    String? errorMessage,
  }) {
    return ProfileState(
      status: status ?? this.status,
      profile: profile ?? this.profile,
      profiles: profiles ?? this.profiles,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// StateNotifier для управления состоянием и операциями с профилями пользователей.
///
/// Позволяет загружать, обновлять и сбрасывать профиль, а также обрабатывать ошибки и слушать изменения авторизации.
class ProfileNotifier extends StateNotifier<ProfileState> {
  /// Провайдер use case для получения профиля.
  final getProfileUseCase = getProfileUseCaseProvider;

  /// Провайдер use case для получения списка профилей.
  final getProfilesUseCase = getProfilesUseCaseProvider;

  /// Провайдер use case для обновления профиля.
  final updateProfileUseCase = updateProfileUseCaseProvider;

  /// Флаг, указывающий, что профиль сейчас загружается.
  bool _isLoadingProfile = false;

  /// Флаг, указывающий, что список профилей сейчас загружается.
  bool _isLoadingProfiles = false;

  /// Создаёт [ProfileNotifier] и подписывается на изменения авторизации.
  ProfileNotifier(Ref ref)
      : _ref = ref,
        super(ProfileState.initial()) {
    _listenToAuthChanges();
  }

  /// Ссылка на [Ref] для доступа к провайдерам.
  final Ref _ref;

  /// Подписывается на изменения статуса авторизации и автоматически загружает профиль при необходимости.
  void _listenToAuthChanges() {
    _ref.listen(authProvider, (previous, current) {
      // Запрашиваем профиль только при смене пользователя или первой авторизации
      if (current.status == AuthStatus.authenticated &&
          current.user != null &&
          (previous?.user?.id != current.user!.id || state.profile == null)) {
        getProfile(current.user!.id);
      } else if (current.status == AuthStatus.unauthenticated) {
        state = ProfileState.initial();
      }
    });

    final authState = _ref.read(authProvider);
    if (authState.status == AuthStatus.authenticated &&
        authState.user != null &&
        state.profile == null) {
      getProfile(authState.user!.id);
    }
  }

  /// Загружает профиль пользователя по [userId].
  ///
  /// Если профиль уже загружается или уже загружен и id совпадает, повторный запрос не выполняется.
  /// В случае успеха — обновляет состояние на success, иначе — error с сообщением.
  Future<void> getProfile(String userId) async {
    if (_isLoadingProfile ||
        (state.profile != null &&
            state.profile!.id == userId &&
            state.status == ProfileStatus.success)) {
      return;
    }

    _isLoadingProfile = true;
    state = state.copyWith(status: ProfileStatus.loading);

    try {
      final profile = await _ref.read(getProfileUseCaseProvider).call(userId);
      if (profile != null) {
        state = state.copyWith(
          status: ProfileStatus.success,
          profile: profile,
        );
      } else {
        state = state.copyWith(
          status: ProfileStatus.error,
          errorMessage: 'Профиль не найден',
        );
      }
    } catch (e) {
      state = state.copyWith(
        status: ProfileStatus.error,
        errorMessage: e.toString(),
      );
    } finally {
      _isLoadingProfile = false;
    }
  }

  /// Загружает список всех профилей пользователей.
  ///
  /// Если список уже загружается или уже загружен, повторный запрос не выполняется.
  /// В случае успеха — обновляет состояние на success, иначе — error с сообщением.
  Future<void> getProfiles() async {
    if (_isLoadingProfiles ||
        (state.profiles.isNotEmpty && state.status == ProfileStatus.success)) {
      return;
    }

    _isLoadingProfiles = true;
    state = state.copyWith(status: ProfileStatus.loading);

    try {
      final profiles = await _ref.read(getProfilesUseCaseProvider).call();
      state = state.copyWith(
        status: ProfileStatus.success,
        profiles: profiles,
      );
    } catch (e) {
      state = state.copyWith(
        status: ProfileStatus.error,
        errorMessage: e.toString(),
      );
    } finally {
      _isLoadingProfiles = false;
    }
  }

  /// Обновляет профиль пользователя.
  ///
  /// После успешного обновления — обновляет состояние с новым профилем.
  Future<void> updateProfile(Profile profile) async {
    state = state.copyWith(status: ProfileStatus.loading);
    try {
      final updatedProfile =
          await _ref.read(updateProfileUseCaseProvider).call(profile);
      // Обновляем как текущий профиль, так и список профилей, если он загружен
      final updatedList = state.profiles.isEmpty
          ? state.profiles
          : state.profiles
              .map((p) => p.id == updatedProfile.id ? updatedProfile : p)
              .toList();
      state = state.copyWith(
        status: ProfileStatus.success,
        profile: updatedProfile,
        profiles: updatedList,
      );
    } catch (e) {
      state = state.copyWith(
        status: ProfileStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// Обновляет профиль без смены статуса на loading (оптимистичное обновление).
  ///
  /// Используется для быстрых обновлений UI (переключение статуса, изменение роли)
  /// без показа индикатора загрузки и перерисовки всего экрана.
  Future<void> updateProfileSilently(Profile profile) async {
    // Оптимистично обновляем UI сразу
    final optimisticList = state.profiles.isEmpty
        ? state.profiles
        : state.profiles.map((p) => p.id == profile.id ? profile : p).toList();

    state = state.copyWith(
      profile: state.profile?.id == profile.id ? profile : state.profile,
      profiles: optimisticList,
    );

    try {
      // Отправляем изменения на сервер в фоне
      final updatedProfile =
          await _ref.read(updateProfileUseCaseProvider).call(profile);

      // Обновляем с реальными данными с сервера (без смены статуса)
      final updatedList = state.profiles.isEmpty
          ? state.profiles
          : state.profiles
              .map((p) => p.id == updatedProfile.id ? updatedProfile : p)
              .toList();

      state = state.copyWith(
        profile: state.profile?.id == updatedProfile.id
            ? updatedProfile
            : state.profile,
        profiles: updatedList,
      );
    } catch (e) {
      // При ошибке откатываем изменения и показываем ошибку
      state = state.copyWith(
        status: ProfileStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// Принудительно обновляет данные профиля по [userId].
  ///
  /// Сбрасывает флаг загрузки и выполняет повторный запрос.
  Future<void> refreshProfile(String userId) async {
    _isLoadingProfile = false;
    // Сбрасываем статус, чтобы не сработало раннее завершение в getProfile
    state = state.copyWith(status: ProfileStatus.loading);
    return getProfile(userId);
  }

  /// Принудительно обновляет список профилей.
  ///
  /// Сбрасывает флаг загрузки и выполняет повторный запрос.
  Future<void> refreshProfiles() async {
    _isLoadingProfiles = false;
    // Сбрасываем статус, чтобы не сработало раннее завершение в getProfiles
    state = state.copyWith(status: ProfileStatus.loading);
    return getProfiles();
  }
}

/// StateNotifier для управления профилем текущего авторизованного пользователя.
///
/// Всегда содержит профиль текущего пользователя и не перезаписывается при просмотре чужих профилей.
/// Используется для UI компонентов, которые должны показывать данные текущего пользователя.
///
/// Подписывается на Realtime изменения статуса — если админ деактивирует пользователя, происходит мгновенный logout.
class CurrentUserProfileNotifier extends StateNotifier<ProfileState> {
  /// Провайдер use case для получения профиля.
  final getProfileUseCase = getProfileUseCaseProvider;

  /// Провайдер use case для обновления профиля.
  final updateProfileUseCase = updateProfileUseCaseProvider;

  /// Флаг, указывающий, что профиль сейчас загружается.
  bool _isLoadingProfile = false;

  /// Realtime канал для отслеживания изменений статуса текущего пользователя.
  RealtimeChannel? _statusChannel;

  /// Создаёт [CurrentUserProfileNotifier] и подписывается на изменения авторизации.
  CurrentUserProfileNotifier(Ref ref)
      : _ref = ref,
        super(ProfileState.initial()) {
    _listenToAuthChanges();
  }

  /// Ссылка на [Ref] для доступа к провайдерам.
  final Ref _ref;

  @override
  void dispose() {
    _unsubscribeFromStatusChanges();
    super.dispose();
  }

  /// Подписывается на изменения статуса авторизации и автоматически загружает профиль текущего пользователя.
  void _listenToAuthChanges() {
    _ref.listen(authProvider, (previous, current) {
      // Загружаем профиль только при смене пользователя или первой авторизации
      if (current.status == AuthStatus.authenticated &&
          current.user != null &&
          (previous?.user?.id != current.user!.id || state.profile == null)) {
        getCurrentUserProfile(current.user!.id);
      } else if (current.status == AuthStatus.unauthenticated) {
        _unsubscribeFromStatusChanges();
        state = ProfileState.initial();
      }
    });

    final authState = _ref.read(authProvider);
    if (authState.status == AuthStatus.authenticated &&
        authState.user != null &&
        state.profile == null) {
      getCurrentUserProfile(authState.user!.id);
    }
  }

  /// Загружает профиль текущего пользователя по [userId].
  ///
  /// Этот метод всегда загружает профиль текущего пользователя и не перезаписывается
  /// при просмотре чужих профилей.
  Future<void> getCurrentUserProfile(String userId) async {
    if (_isLoadingProfile ||
        (state.profile != null &&
            state.profile!.id == userId &&
            state.status == ProfileStatus.success)) {
      return;
    }

    _isLoadingProfile = true;
    state = state.copyWith(status: ProfileStatus.loading);

    try {
      final profile = await _ref.read(getProfileUseCaseProvider).call(userId);
      if (profile != null) {
        state = state.copyWith(
          status: ProfileStatus.success,
          profile: profile,
        );
        // Подписываемся на Realtime изменения статуса
        _subscribeToStatusChanges(userId);
      } else {
        state = state.copyWith(
          status: ProfileStatus.error,
          errorMessage: 'Профиль не найден',
        );
      }
    } catch (e) {
      state = state.copyWith(
        status: ProfileStatus.error,
        errorMessage: e.toString(),
      );
    } finally {
      _isLoadingProfile = false;
    }
  }

  /// Подписывается на Realtime изменения статуса текущего пользователя.
  ///
  /// При деактивации (status = false) мгновенно переводит на экран "Доступ временно отключён".
  void _subscribeToStatusChanges(String userId) {
    _unsubscribeFromStatusChanges();

    final client = _ref.read(supabaseClientProvider);

    _statusChannel = client
        .channel('profile_status:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'profiles',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: userId,
          ),
          callback: (payload) {
            final status = payload.newRecord['status'] as bool?;

            if (status == false) {
              final authNotifier = _ref.read(authProvider.notifier);
              authNotifier.state = authNotifier.state.copyWith(
                status: AuthStatus.disabled,
              );
            }
          },
        )
        .subscribe();
  }

  /// Отписывается от Realtime изменений статуса.
  void _unsubscribeFromStatusChanges() {
    if (_statusChannel != null) {
      final client = _ref.read(supabaseClientProvider);
      _statusChannel!.unsubscribe();
      client.removeChannel(_statusChannel!);
      _statusChannel = null;
    }
  }

  /// Обновляет профиль текущего пользователя.
  ///
  /// После успешного обновления — обновляет состояние с новым профилем.
  Future<void> updateCurrentUserProfile(Profile profile) async {
    state = state.copyWith(status: ProfileStatus.loading);
    try {
      final updatedProfile =
          await _ref.read(updateProfileUseCaseProvider).call(profile);
      state = state.copyWith(
        status: ProfileStatus.success,
        profile: updatedProfile,
      );
    } catch (e) {
      state = state.copyWith(
        status: ProfileStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// Принудительно обновляет данные профиля текущего пользователя.
  ///
  /// Сбрасывает флаг загрузки и выполняет повторный запрос.
  Future<void> refreshCurrentUserProfile(String userId) async {
    _isLoadingProfile = false;
    // Сбрасываем успех, чтобы не сработало раннее завершение в getCurrentUserProfile
    state = state.copyWith(status: ProfileStatus.loading);
    return getCurrentUserProfile(userId);
  }
}

/// Провайдер состояния профиля пользователя.
///
/// Используется для доступа к [ProfileNotifier] и [ProfileState] во всём приложении.
final profileProvider =
    StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  return ProfileNotifier(ref);
});

/// Провайдер профиля текущего авторизованного пользователя.
///
/// Всегда содержит профиль текущего пользователя и не перезаписывается при просмотре чужих профилей.
/// Используется для UI компонентов, которые должны показывать данные текущего пользователя (например, AppDrawer).
final currentUserProfileProvider =
    StateNotifierProvider<CurrentUserProfileNotifier, ProfileState>((ref) {
  return CurrentUserProfileNotifier(ref);
});
