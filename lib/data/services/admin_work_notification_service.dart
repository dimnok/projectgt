import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Отправляет push-уведомление админам и владельцам о событии смены.
///
/// [action] — `open` или `close`.
/// Ошибки не пробрасываются — вызов не должен блокировать UX пользователя.
Future<void> notifyAdminsWorkEvent({
  required SupabaseClient client,
  required String workId,
  required String action,
}) async {
  final accessToken = client.auth.currentSession?.accessToken;
  if (accessToken == null) return;

  try {
    final resp = await client.functions.invoke(
      'send_admin_work_event',
      body: {
        'action': action,
        'work_id': workId,
        'notify_all': false,
      },
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );
    debugPrint(
      'send_admin_work_event($action): status=${resp.status}, data=${resp.data}',
    );
  } catch (e) {
    debugPrint('send_admin_work_event($action) error: $e');
  }
}

/// Push админам и владельцам при открытии смены.
Future<void> notifyAdminsWorkOpened({
  required SupabaseClient client,
  required String workId,
}) =>
    notifyAdminsWorkEvent(client: client, workId: workId, action: 'open');

/// Push админам и владельцам при закрытии смены.
Future<void> notifyAdminsWorkClosed({
  required SupabaseClient client,
  required String workId,
}) =>
    notifyAdminsWorkEvent(client: client, workId: workId, action: 'close');
