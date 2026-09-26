/**
 * Действия этапов заявки.
 *
 * Каждый шаг — отдельная серверная функция: она проверяет статус, участие
 * в маршруте и права роли, меняет статус и пишет историю. Клиент только
 * вызывает функцию и получает обновлённую заявку. Права этапов выдаёт
 * маршрут: назначили человека в настройках модуля — функция ему доступна.
 */
import { getRequiredClient } from "@/lib/supabase/client";
import type { PurchaseRequest } from "@/features/purchase-requests/types/purchase-request.types";
import { asRow, mapPurchaseRequest } from "@/features/purchase-requests/utils/mappers";
import { throwIfError } from "@/features/purchase-requests/api/errors";

/** Вызов функции этапа: ответ всегда одна заявка. */
async function callWorkflow(
  name: string,
  params: Record<string, string>
): Promise<PurchaseRequest> {
  const client = getRequiredClient();
  const { data, error } = await client.rpc(name, params);
  throwIfError(error);
  const row = asRow(data);
  if (!row) {
    throw new Error("Сервер не вернул заявку");
  }
  return mapPurchaseRequest(row);
}

/** Отправка заявки: черновик или доработка → согласование. */
export function submitPurchaseRequest(requestId: string) {
  return callWorkflow("purchase_request_submit", { p_request_id: requestId });
}

/** Согласование заявки первым согласующим. */
export function approvePurchaseRequest(requestId: string) {
  return callWorkflow("purchase_request_approve", { p_request_id: requestId });
}

/** Возврат заявки на доработку автору. Причина обязательна. */
export function returnPurchaseRequest(requestId: string, comment: string) {
  return callWorkflow("purchase_request_return", {
    p_request_id: requestId,
    p_comment: comment,
  });
}

/** Отправка счетов на согласование: нужен файл у каждого счёта. */
export function submitPurchaseRequestInvoices(requestId: string) {
  return callWorkflow("purchase_request_submit_invoices", {
    p_request_id: requestId,
  });
}

/** Согласование счетов. */
export function approvePurchaseRequestInvoice(requestId: string) {
  return callWorkflow("purchase_request_approve_invoice", {
    p_request_id: requestId,
  });
}

/** Возврат счетов на подготовку. Причина обязательна. */
export function returnPurchaseRequestInvoice(requestId: string, comment: string) {
  return callWorkflow("purchase_request_return_invoice", {
    p_request_id: requestId,
    p_comment: comment,
  });
}

/** Бухгалтер заводит заявку на оплату. */
export function queuePurchaseRequestPayment(requestId: string) {
  return callWorkflow("purchase_request_queue_payment", {
    p_request_id: requestId,
  });
}

/** Бухгалтер отмечает оплату. */
export function markPurchaseRequestPaid(requestId: string) {
  return callWorkflow("purchase_request_mark_paid", { p_request_id: requestId });
}

/** Получение материала: автор заявки или назначенный получатель. */
export function markPurchaseRequestReceived(requestId: string) {
  return callWorkflow("purchase_request_mark_received", {
    p_request_id: requestId,
  });
}
