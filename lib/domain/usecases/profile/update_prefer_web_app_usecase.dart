import 'package:projectgt/domain/entities/profile.dart';
import 'package:projectgt/domain/repositories/profile_repository.dart';

/// UseCase для перевода пользователя на веб-приложение.
class UpdatePreferWebAppUseCase {
  /// Репозиторий профилей.
  final ProfileRepository repository;

  /// Создаёт [UpdatePreferWebAppUseCase].
  const UpdatePreferWebAppUseCase(this.repository);

  /// Сохраняет флаг [preferWebApp] для профиля [userId].
  Future<Profile> call({
    required String userId,
    required bool preferWebApp,
  }) {
    return repository.updatePreferWebApp(
      userId: userId,
      preferWebApp: preferWebApp,
    );
  }
}
