import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/domain/entities/profile.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/features/company/presentation/providers/company_providers.dart';

/// Notifier для кэширования профилей пользователей по ID.
///
/// Хранит глобальный кэш профилей для избежания повторных запросов к БД.
/// Кэш живёт всё время работы приложения и переиспользуется между экранами.
class ProfilesCacheNotifier extends StateNotifier<Map<String, Profile?>> {
  /// Репозиторий для загрузки профилей.
  final Ref _ref;

  /// Создаёт notifier с пустым кэшем и подписывается на смену компании.
  ProfilesCacheNotifier(this._ref) : super({}) {
    _listenToCompanyChanges();
  }

  /// Подписывается на изменения активной компании и очищает кэш.
  void _listenToCompanyChanges() {
    _ref.listen(activeCompanyIdProvider, (previous, current) {
      if (previous != current) {
        clear();
      }
    });
  }

  /// Получает профиль по [userId].
  ///
  /// Если профиль уже есть в кэше — возвращает его моментально.
  /// Если нет — загружает из БД и кэширует.
  ///
  /// Возвращает null, если профиль не найден или произошла ошибка.
  Future<Profile?> getProfile(String userId) async {
    // Проверяем кэш
    if (state.containsKey(userId)) {
      return state[userId];
    }

    // Загружаем из БД
    try {
      final profile = await _ref
          .read(profileRepositoryProvider)
          .getProfile(userId);

      // Кэшируем результат (даже если null)
      state = {...state, userId: profile};
      return profile;
    } catch (e) {
      // В случае ошибки кэшируем null, чтобы не делать повторные запросы
      state = {...state, userId: null};
      return null;
    }
  }

  /// Очищает весь кэш профилей.
  ///
  /// Используется редко, например при выходе из аккаунта.
  void clear() {
    state = {};
  }

  /// Удаляет конкретный профиль из кэша.
  ///
  /// Используется если профиль был обновлён и нужно перезагрузить.
  void invalidate(String userId) {
    final newState = Map<String, Profile?>.from(state);
    newState.remove(userId);
    state = newState;
  }
}

/// Провайдер глобального кэша профилей.
///
/// Кэш живёт всё время работы приложения и доступен из любого экрана.
/// Автоматически предотвращает дублирование запросов к БД.
final profilesCacheProvider =
    StateNotifierProvider<ProfilesCacheNotifier, Map<String, Profile?>>((ref) {
      return ProfilesCacheNotifier(ref);
    });

/// Family-провайдер для получения профиля по ID с автоматическим кэшированием.
///
/// Использование:
/// ```dart
/// final profileAsync = ref.watch(userProfileProvider(userId));
/// profileAsync.when(
///   data: (profile) => Text(profile?.shortName ?? 'Неизвестен'),
///   loading: () => CircularProgressIndicator(),
///   error: (e, st) => Text('Ошибка'),
/// );
/// ```
final userProfileProvider = FutureProvider.family<Profile?, String>((
  ref,
  userId,
) async {
  return ref.read(profilesCacheProvider.notifier).getProfile(userId);
});
