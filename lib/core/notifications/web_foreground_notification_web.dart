import 'package:universal_html/html.dart' as html;

/// Показывает системное уведомление браузера, когда вкладка PWA активна.
Future<void> showWebForegroundNotification({
  required String title,
  required String body,
  String? workId,
}) async {
  if (html.Notification.permission != 'granted') return;

  html.Notification(
    title,
    body: body,
    icon: 'icons/Icon-192.png',
    tag: workId ?? 'work_event',
  );
}
