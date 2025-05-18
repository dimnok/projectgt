import 'package:projectgt/domain/entities/profile.dart';
import 'package:projectgt/domain/repositories/profile_repository.dart';

/// UseCase для обновления данных профиля пользователя.
///
/// Используется для обновления информации о профиле через [ProfileRepository].
///
/// Пример использования:
/// ```dart
/// final useCase = UpdateProfileUseCase(profileRepository);
/// final updated = await useCase.call(profile.copyWith(fullName: 'Новое имя'));
/// ```
///
/// [profile] — обновлённые данные профиля.
/// Возвращает обновлённый [Profile].
/// Бросает [Exception] при ошибке.
class UpdateProfileUseCase {
  /// Репозиторий профилей для обновления данных.
  final ProfileRepository repository;

  /// Создаёт экземпляр [UpdateProfileUseCase] с указанным [repository].
  const UpdateProfileUseCase(this.repository);

  /// Обновление профиля пользователя.
  ///
  /// [profile] — обновлённые данные профиля.
  /// Возвращает обновлённый [Profile].
  /// Бросает [Exception] при ошибке.
  Future<Profile> call(Profile profile) async {
    return await repository.updateProfile(profile);
  }
} 