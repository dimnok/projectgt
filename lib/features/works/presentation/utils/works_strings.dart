/// Константы строк для модуля "Смены" (Works).
class WorksStrings {
  // Заголовки и общие тексты

  /// Заголовок вкладки данных.
  static const String dataTabTitle = 'Данные';

  /// Заголовок блока валидации.
  static const String validationTitle = 'Для закрытия смены:';

  /// Заголовок блока статистики.
  static const String statisticsTitle = 'Показатели';

  /// Заголовок блока распределения работ.
  static const String distributionTitle = 'Распределение работ';

  /// Заголовок блока фотографий.
  static const String photosTitle = 'Фотографии';

  // Кнопки

  /// Текст кнопки закрытия смены.
  static const String closeWorkBtn = 'Закрыть смену';

  /// Текст кнопки добавления фото.
  static const String addPhotoBtn = 'Добавить фото';

  /// Текст кнопки удаления.
  static const String deleteBtn = 'Удалить';

  /// Текст кнопки отмены.
  static const String cancelBtn = 'Отмена';

  /// Текст кнопки выбора камеры.
  static const String cameraBtn = 'Камера';

  /// Текст кнопки выбора галереи.
  static const String galleryBtn = 'Галерея';

  // Чек-лист валидации

  /// Текст проверки наличия работ.
  static const String checkAddItems = 'Добавить работы';

  /// Текст проверки наличия сотрудников.
  static const String checkAddEmployees = 'Добавить сотрудников';

  /// Текст проверки заполнения количеств.
  static const String checkFillQuantities = 'Заполнить кол-во у работ';

  /// Текст проверки заполнения часов.
  static const String checkFillHours = 'Заполнить часы сотрудников';

  /// Текст проверки наличия вечернего фото.
  static const String checkUploadEveningPhoto = 'Загрузить вечернее фото';

  // Сообщения об ошибках и предупреждения (валидация)

  /// Ошибка: смена уже закрыта.
  static const String errorAlreadyClosed = 'Смена уже закрыта';

  /// Ошибка: нет работ.
  static const String errorNoItems = 'Невозможно закрыть смену без работ';

  /// Ошибка: нет сотрудников.
  static const String errorNoEmployees = 'Невозможно закрыть смену без сотрудников';

  /// Ошибка: не заполнены количества.
  static const String errorEmptyQuantities =
      'У некоторых работ не указано количество. Необходимо заполнить все поля количества перед закрытием смены.';

  /// Ошибка: не заполнены часы.
  static const String errorEmptyHours =
      'У некоторых сотрудников не указаны часы. Необходимо заполнить все поля часов перед закрытием смены.';

  /// Ошибка: нет вечернего фото.
  static const String errorNoEveningPhoto =
      'Необходимо добавить вечернее фото перед закрытием смены.';

  // Диалоги и подтверждения

  /// Заголовок диалога подтверждения закрытия смены.
  static const String confirmCloseTitle = 'Подтверждение закрытия смены';

  /// Сообщение диалога подтверждения закрытия смены.
  static const String confirmCloseMessage = '''После закрытия смены будет невозможно:
• Добавлять/удалять работы и сотрудников
• Изменять количество работ и часы
• Редактировать фотографии

Вы уверены, что хотите закрыть смену?''';

  /// Заголовок диалога выбора вечернего фото.
  static const String eveningPhotoDialogTitle = 'Вечернее фото';

  // Уведомления об успехе

  /// Сообщение об успешном закрытии смены.
  static const String successWorkClosed = 'Смена успешно закрыта';

  /// Сообщение об успешном удалении вечернего фото.
  static const String successEveningPhotoDeleted = 'Вечернее фото удалено';

  /// Сообщение об успешном обновлении утреннего отчета.
  static const String successMorningReportUpdated =
      'Утреннее сообщение обновлено';

  /// Сообщение об успешной отправке вечернего отчета.
  static String successEveningReportSent(int count) =>
      'Вечерний отчет отправлен!\nРабот: $count';

  // Ошибки операций

  /// Текст ошибки по умолчанию.
  static const String operationError = 'Ошибка операции';

  /// Ошибка загрузки данных смены.
  static const String loadWorkError = 'Не удалось загрузить данные смены';

  /// Ошибка закрытия смены.
  static String closeWorkError(Object e) => 'Ошибка при закрытии смены: $e';

  /// Ошибка удаления фото.
  static String deletePhotoError(Object e) => 'Ошибка при удалении фото: $e';

  /// Ошибка сохранения фото.
  static String savePhotoError(Object e) => 'Ошибка при сохранении фото: $e';

  /// Ошибка загрузки фото.
  static String uploadPhotoError(Object e) => 'Ошибка при загрузке фото: $e';

  /// Ошибка: ID смены не найден.
  static const String shiftIdNotFoundError = 'ID смены не найден';

  /// Ошибка отправки отчета в Telegram.
  static String telegramSendError(String error) => 'Ошибка отправки: $error';
}
