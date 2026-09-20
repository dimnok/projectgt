import { getRequiredClient } from "@/lib/supabase/client";
import type { PurchaseRequest } from "@/features/purchase-requests/types/purchase-request.types";
import { asRow, mapPurchaseRequest } from "@/features/purchase-requests/utils/mappers";
import { throwIfError } from "@/features/purchase-requests/api/errors";

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

export function submitPurchaseRequest(requestId: string) {
  return callWorkflow("purchase_request_submit", { p_request_id: requestId });
}

export function approvePurchaseRequest(requestId: string) {
  return callWorkflow("purchase_request_approve", { p_request_id: requestId });
}

export function returnPurchaseRequest(requestId: string, comment: string) {
  return callWorkflow("purchase_request_return", {
    p_request_id: requestId,
    p_comment: comment,
  });
}

export function submitPurchaseRequestInvoices(requestId: string) {
  return callWorkflow("purchase_request_submit_invoices", {
    p_request_id: requestId,
  });
}

export function approvePurchaseRequestInvoice(requestId: string) {
  return callWorkflow("purchase_request_approve_invoice", {
    p_request_id: requestId,
  });
}

export function returnPurchaseRequestInvoice(requestId: string, comment: string) {
  return callWorkflow("purchase_request_return_invoice", {
    p_request_id: requestId,
    p_comment: comment,
  });
}

export function queuePurchaseRequestPayment(requestId: string) {
  return callWorkflow("purchase_request_queue_payment", {
    p_request_id: requestId,
  });
}

export function markPurchaseRequestPaid(requestId: string) {
  return callWorkflow("purchase_request_mark_paid", { p_request_id: requestId });
}

export function markPurchaseRequestReceived(requestId: string) {
  return callWorkflow("purchase_request_mark_received", {
    p_request_id: requestId,
  });
}
