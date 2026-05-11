import 'package:supabase_flutter/supabase_flutter.dart';

/// Запускает Edge Function `process_telegram_outbox` для обработки очереди Telegram.
///
/// Вызывается после постановки задачи в БД (`enqueue_telegram_outbox_opening` или триггер
/// при закрытии смены). Ошибки игнорируются — повторная доставка выполнится по ретраям
/// на сервере или при следующем вызове воркера (cron с `OUTBOX_WORKER_SECRET`).
Future<void> kickProcessTelegramOutbox(SupabaseClient client) async {
  final token = client.auth.currentSession?.accessToken;
  if (token == null) return;
  try {
    await client.functions.invoke(
      'process_telegram_outbox',
      headers: {'Authorization': 'Bearer $token'},
    );
  } catch (_) {}
}
