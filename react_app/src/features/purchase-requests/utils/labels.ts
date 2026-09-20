import type { PurchaseRequestStatus } from "@/features/purchase-requests/types/purchase-request.types";

export function historyActionPhrase(action: string) {
  switch (action) {
    case "created":
      return "создал заявку";
    case "submitted":
      return "отправил на согласование";
    case "resubmitted":
      return "повторно отправил заявку";
    case "approved":
      return "согласовал";
    case "returned":
      return "вернул на доработку";
    case "invoices_submitted":
      return "отправил счета на согласование";
    case "invoice_approved":
      return "согласовал счет";
    case "invoice_returned":
      return "вернул счета на доработку";
    case "queued_for_payment":
      return "завёл на оплату";
    case "paid":
      return "оплатил";
    case "received":
      return "подтвердил получение";
    default:
      return action;
  }
}

export function idleActionsMessage(status: PurchaseRequestStatus) {
  if (status === "received") {
    return "Заявка получена";
  }
  return "Ожидает действия ответственного";
}

export const STATUS_BADGE_CLASS: Record<PurchaseRequestStatus, string> = {
  draft: "bg-slate-500/10 text-slate-700 dark:text-slate-300",
  approval: "bg-blue-600/10 text-blue-800 dark:text-blue-300",
  revision: "bg-orange-600/10 text-orange-800 dark:text-orange-300",
  invoice_preparation: "bg-purple-600/10 text-purple-800 dark:text-purple-300",
  invoice_approval: "bg-sky-600/10 text-sky-800 dark:text-sky-300",
  accounting: "bg-cyan-700/10 text-cyan-800 dark:text-cyan-300",
  payment_queue: "bg-amber-500/15 text-amber-800 dark:text-amber-300",
  paid: "bg-green-600/10 text-green-800 dark:text-green-300",
  received: "bg-emerald-800/10 text-emerald-900 dark:text-emerald-300",
  unknown: "bg-stone-600/10 text-stone-800 dark:text-stone-300",
};
