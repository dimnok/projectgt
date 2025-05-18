import 'package:projectgt/domain/entities/profile.dart';
import 'package:projectgt/domain/repositories/profile_repository.dart';

/// UseCase для получения списка всех профилей пользователей.
///
/// Используется для загрузки списка профилей через [ProfileRepository].
///
/// Пример использования:
/// ```dart
/// final useCase = GetProfilesUseCase(profileRepository);
/// final profiles = await useCase.call();
/// print(profiles.length);
/// ```
///
/// Возвращает список [Profile].
/// Бросает [Exception] при ошибке.
class GetProfilesUseCase {
  /// Репозиторий профилей для получения данных.
  final ProfileRepository repository;

  /// Создаёт use case с указанным репозиторием.
  const GetProfilesUseCase(this.repository);

  /// Получение списка всех профилей.
  ///
  /// Возвращает список [Profile].
  /// Бросает [Exception] при ошибке.
  Future<List<Profile>> call() async {
    return await repository.getProfiles();
  }
}