import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/features/purchase_requests/domain/entities/purchase_request_history_entry.dart';
import 'package:projectgt/features/purchase_requests/domain/entities/purchase_request_settings.dart';

/// Форматирует сумму заявки: прочерк, если счета ещё не заведены.
String formatPurchaseRequestAmount(double amount) =>
    amount > 0 ? formatCurrency(amount) : '—';

/// Проверяет, что маршрут заявок полностью настроен для компании.
bool isPurchaseRequestSettingsConfigured(
  PurchaseRequestSettings? settings,
) {
  if (settings == null) return false;
  if (settings.firstApproverId == null ||
      settings.invoicePreparerId == null ||
      settings.invoiceApproverId == null ||
      settings.accountantId == null) {
    return false;
  }
  if (settings.receiverMode == PurchaseRequestReceiverMode.fixedUser) {
    return settings.fixedReceiverId != null;
  }
  return true;
}

/// Последняя причина возврата в черновик из истории заявки.
String? latestPurchaseRequestCancelComment(
  List<PurchaseRequestHistoryEntry> entries,
) {
  for (var i = entries.length - 1; i >= 0; i--) {
    if (entries[i].action != 'cancelled') continue;
    final comment = entries[i].comment?.trim();
    if (comment != null && comment.isNotEmpty) return comment;
  }
  return null;
}
