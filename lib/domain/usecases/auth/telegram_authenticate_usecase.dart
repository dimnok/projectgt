import 'package:projectgt/domain/entities/user.dart';
import 'package:projectgt/domain/repositories/auth_repository.dart';

/// Use case для аутентификации пользователя через Telegram Mini App
///
/// Инкапсулирует бизнес-логику проверки initData от Telegram WebApp.
/// Делегирует проверку подписи Edge Function `telegram-auth`.
///
/// Пример использования:
/// ```dart
/// final useCase = TelegramAuthenticateUseCase(repository);
/// final user = await useCase.execute(initData: initDataFromTelegram);
/// ```
class TelegramAuthenticateUseCase {
  /// Репозиторий аутентификации
  final AuthRepository _repository;

  /// Создаёт [TelegramAuthenticateUseCase]
  const TelegramAuthenticateUseCase(this._repository);

  /// Выполняет аутентификацию через Telegram
  ///
  /// [initData] — подписанные данные от TelegramWebApp.init() на веб-версии
  ///
  /// Возвращает [User] при успешной аутентификации
  ///
  /// Выбрасывает исключение если:
  /// - initData невалидны
  /// - подпись не прошла проверку
  /// - ошибка при создании пользователя
  ///
  /// **Процесс:**
  /// 1. Отправляет initData в Edge Function `telegram-auth`
  /// 2. Edge Function проверяет подпись по протоколу Telegram
  /// 3. Создаёт/получает пользователя в Supabase Auth
  /// 4. Создаёт/получает профиль в таблице `profiles` (status=false)
  /// 5. Возвращает JWT токен, который устанавливается в Supabase Auth
  /// 6. Возвращает объект [User] приложению
  Future<User> execute({required String initData}) {
    return _repository.authenticateWithTelegram(initData: initData);
  }
}

