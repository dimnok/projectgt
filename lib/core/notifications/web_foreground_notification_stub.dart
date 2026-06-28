/// Заглушка: показ браузерного уведомления не требуется вне Web.
Future<void> showWebForegroundNotification({
  required String title,
  required String body,
  String? workId,
}) async {}
