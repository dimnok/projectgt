import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Отправляет push-уведомление админам о событии смены через Edge Function.
///
/// Ошибки не пробрасываются — вызов не должен блокировать UX пользователя.
Future<void> notifyAdminsWorkOpened({
  required SupabaseClient client,
  required String workId,
}) async {
  final accessToken = client.auth.currentSession?.accessToken;
  if (accessToken == null) return;

  try {
    final resp = await client.functions.invoke(
      'send_admin_work_event',
      body: {
        'action': 'open',
        'work_id': workId,
        'notify_all': false,
      },
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );
    debugPrint(
      'send_admin_work_event(open): status=${resp.status}, data=${resp.data}',
    );
  } catch (e) {
    debugPrint('send_admin_work_event(open) error: $e');
  }
}
