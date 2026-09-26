import type {
  PurchaseRequest,
  PurchaseRequestHistoryEntry,
  PurchaseRequestSettings,
} from "@/features/purchase-requests/types/purchase-request.types";

/** Маршрут заполнен целиком: без этого создать заявку нельзя. */
export function isPurchaseRequestSettingsConfigured(
  settings: PurchaseRequestSettings | null | undefined
) {
  if (!settings) {
    return false;
  }
  if (
    settings.firstApproverIds.length === 0 ||
    settings.invoicePreparerIds.length === 0 ||
    settings.invoiceApproverIds.length === 0 ||
    settings.accountantIds.length === 0
  ) {
    return false;
  }
  if (settings.receiverMode === "fixed_user") {
    return settings.fixedReceiverIds.length > 0;
  }
  return true;
}

/**
 * Участник ли человек текущего этапа заявки.
 *
 * На этапах действует любой из списка маршрута (не цепочка); в черновике
 * и на доработке это автор заявки, а на получении — автор или назначенный
 * получатель. Те же правила применяет база.
 */
export function isPurchaseRequestStageAssignee({
  request,
  settings,
  userId,
}: {
  request: PurchaseRequest;
  settings: PurchaseRequestSettings | null | undefined;
  userId: string;
}) {
  const status = request.status;
  if (status === "draft" || status === "revision") {
    return request.createdBy === userId;
  }
  if (status === "received") {
    return false;
  }
  if (!settings) {
    return false;
  }
  if (status === "paid") {
    if (settings.receiverMode === "fixed_user") {
      return settings.fixedReceiverIds.includes(userId);
    }
    return request.createdBy === userId;
  }

  const ids =
    status === "approval"
      ? settings.firstApproverIds
      : status === "invoice_preparation"
        ? settings.invoicePreparerIds
        : status === "invoice_approval"
          ? settings.invoiceApproverIds
          : status === "accounting" || status === "payment_queue"
            ? settings.accountantIds
            : [];

  return ids.includes(userId);
}

/** Последняя причина возврата на доработку: показывается автору заявки. */
export function latestPurchaseRequestReworkComment(
  entries: PurchaseRequestHistoryEntry[]
) {
  for (let index = entries.length - 1; index >= 0; index -= 1) {
    const entry = entries[index];
    if (entry.action !== "returned") {
      continue;
    }
    const comment = entry.comment?.trim();
    if (comment) {
      return comment;
    }
  }
  return null;
}
