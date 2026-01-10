import 'package:projectgt/domain/entities/profile.dart';

/// Абстракция репозитория для работы с профилями пользователей.
abstract class ProfileRepository {
  /// Получи профиль пользователя по [userId].
  ///
  /// [companyId] — опциональный идентификатор компании.
  /// Возвращает [Profile] или null, если не найден. Бросает [Exception] при ошибке.
  Future<Profile?> getProfile(String userId, [String? companyId]);

  /// Получи список всех профилей для конкретной компании [companyId].
  ///
  /// [companyId] — идентификатор компании.
  /// Возвращает список [Profile]. Бросает [Exception] при ошибке.
  Future<List<Profile>> getProfiles(String companyId);

  /// Обнови профиль [profile] в источнике данных.
  ///
  /// Возвращает обновлённый [Profile]. Бросает [Exception] при ошибке.
  Future<Profile> updateProfile(Profile profile);

  /// Удали профиль пользователя по [userId].
  ///
  /// Возвращает void. Бросает [Exception] при ошибке.
  Future<void> deleteProfile(String userId);
}
