/// Метаданные устройства для записи в `public.user_tokens`.
class FcmDeviceMetadata {
  /// Создаёт метаданные устройства для FCM-токена.
  const FcmDeviceMetadata({
    this.deviceId,
    this.deviceModel,
    this.osVersion,
    this.appVersion,
  });

  /// Короткий идентификатор устройства (если доступен).
  final String? deviceId;

  /// Человекочитаемое название: «iPhone PWA», «Chrome (Windows)» и т.п.
  final String? deviceModel;

  /// Версия ОС.
  final String? osVersion;

  /// Версия приложения.
  final String? appVersion;
}
