import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:projectgt/core/notifications/web_foreground_notification.dart';

/// Настраивает обработку входящих FCM push-сообщений.
///
/// [onWorkEventTap] вызывается при нажатии на уведомление о смене
/// (передаётся `work_id` из data payload).
Future<void> initializeFcmPushHandler({
  required void Function(String workId) onWorkEventTap,
}) async {
  void handleMessage(RemoteMessage message) {
    final workId = message.data['work_id'];
    if (workId != null && workId.isNotEmpty) {
      onWorkEventTap(workId);
    }
  }

  FirebaseMessaging.onMessageOpenedApp.listen(handleMessage);

  final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
  if (initialMessage != null) {
    handleMessage(initialMessage);
  }

  FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    if (!kIsWeb) return;

    final notification = message.notification;
    if (notification == null) return;

    await showWebForegroundNotification(
      title: notification.title ?? 'Стройка PRO',
      body: notification.body ?? '',
      workId: message.data['work_id'],
    );
  });
}
