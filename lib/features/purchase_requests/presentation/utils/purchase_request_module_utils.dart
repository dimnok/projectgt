import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/features/purchase_requests/domain/entities/purchase_request.dart';
import 'package:projectgt/features/purchase_requests/domain/entities/purchase_request_history_entry.dart';
import 'package:projectgt/features/purchase_requests/domain/entities/purchase_request_settings.dart';
import 'package:projectgt/features/purchase_requests/domain/entities/purchase_request_status.dart';

/// Форматирует сумму заявки: прочерк, если счета ещё не заведены.
String formatPurchaseRequestAmount(double amount) =>
    amount > 0 ? formatCurrency(amount) : '—';

/// Проверяет, что маршрут заявок полностью настроен для компании.
bool isPurchaseRequestSettingsConfigured(PurchaseRequestSettings? settings) {
  if (settings == null) return false;
  if (settings.firstApproverIds.isEmpty ||
      settings.invoicePreparerIds.isEmpty ||
      settings.invoiceApproverIds.isEmpty ||
      settings.accountantIds.isEmpty) {
    return false;
  }
  if (settings.receiverMode == PurchaseRequestReceiverMode.fixedUser) {
    return settings.fixedReceiverIds.isNotEmpty;
  }
  return true;
}

/// Совпадает с SQL `purchase_request_internal_user_is_assignee`:
/// на этапе действует любой пользователь из списка роли.
bool isPurchaseRequestStageAssignee({
  required PurchaseRequest request,
  required PurchaseRequestSettings? settings,
  required String userId,
}) {
  final status = request.status;
  if (status == PurchaseRequestStatus.draft ||
      status == PurchaseRequestStatus.revision) {
    return request.createdBy == userId;
  }
  if (status == PurchaseRequestStatus.received ||
      status == PurchaseRequestStatus.cancelled) {
    return false;
  }
  if (settings == null) return false;

  if (status == PurchaseRequestStatus.paid) {
    if (settings.receiverMode == PurchaseRequestReceiverMode.fixedUser) {
      return settings.fixedReceiverIds.contains(userId);
    }
    return request.createdBy == userId;
  }

  final ids = switch (status) {
    PurchaseRequestStatus.approval => settings.firstApproverIds,
    PurchaseRequestStatus.invoicePreparation => settings.invoicePreparerIds,
    PurchaseRequestStatus.invoiceApproval => settings.invoiceApproverIds,
    PurchaseRequestStatus.accounting ||
    PurchaseRequestStatus.paymentQueue => settings.accountantIds,
    _ => const <String>[],
  };
  return ids.contains(userId);
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
