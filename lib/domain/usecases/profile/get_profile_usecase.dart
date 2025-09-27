import 'package:projectgt/domain/entities/profile.dart';
import 'package:projectgt/domain/repositories/profile_repository.dart';

/// UseCase для получения профиля пользователя по идентификатору.
///
/// Используется для поиска профиля по id через [ProfileRepository].
///
/// Пример использования:
/// ```dart
/// final useCase = GetProfileUseCase(profileRepository);
/// final profile = await useCase.call('profileId');
/// if (profile != null) print(profile.email);
/// ```
///
/// [id] — идентификатор профиля.
/// Возвращает [Profile] или null, если не найден.
/// Бросает [Exception] при ошибке.
class GetProfileUseCase {
  /// Репозиторий профилей для получения данных.
  final ProfileRepository repository;

  /// Создаёт use case с указанным репозиторием.
  const GetProfileUseCase(this.repository);

  /// Получение профиля по id.
  ///
  /// [id] — идентификатор профиля.
  /// Возвращает [Profile] или null, если не найден.
  /// Бросает [Exception] при ошибке.
  Future<Profile?> call(String id) async {
    return await repository.getProfile(id);
  }
}
