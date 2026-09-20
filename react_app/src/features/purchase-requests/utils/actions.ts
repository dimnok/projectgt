import type {
  PurchaseRequest,
  PurchaseRequestActionSet,
  PurchaseRequestSettings,
} from "@/features/purchase-requests/types/purchase-request.types";
import { isPurchaseRequestStageAssignee } from "@/features/purchase-requests/utils/settings";

const EMPTY_ACTIONS: PurchaseRequestActionSet = {
  canSubmit: false,
  canApprove: false,
  canReturn: false,
  canSubmitInvoices: false,
  canApproveInvoice: false,
  canReturnInvoice: false,
  canQueuePayment: false,
  canMarkPaid: false,
  canMarkReceived: false,
  canEditItems: false,
  canEditDraft: false,
  canDeleteDraft: false,
};

export function resolvePurchaseRequestActions({
  request,
  currentUserId,
  can,
  settings,
}: {
  request: PurchaseRequest;
  currentUserId: string | null | undefined;
  can: (module: string, action: string) => boolean;
  settings?: PurchaseRequestSettings | null;
}): PurchaseRequestActionSet {
  if (!currentUserId) {
    return EMPTY_ACTIONS;
  }

  const isCreator = request.createdBy === currentUserId;
  const isAssignee = isPurchaseRequestStageAssignee({
    request,
    settings,
    userId: currentUserId,
  });
  const status = request.status;
  const canMutateDraft =
    isCreator &&
    can("purchase_requests", "create") &&
    (status === "draft" || status === "revision");
  const canOwnDraft =
    isCreator && can("purchase_requests", "create") && status === "draft";

  return {
    canEditItems: canMutateDraft,
    canEditDraft: canOwnDraft,
    canDeleteDraft: canOwnDraft,
    canSubmit: canMutateDraft,
    canApprove:
      isAssignee &&
      can("purchase_requests", "approve") &&
      status === "approval",
    canReturn:
      isAssignee &&
      can("purchase_requests", "approve") &&
      status === "approval",
    canSubmitInvoices:
      isAssignee &&
      can("purchase_requests", "prepare_invoice") &&
      status === "invoice_preparation",
    canApproveInvoice:
      isAssignee &&
      can("purchase_requests", "approve_invoice") &&
      status === "invoice_approval",
    canReturnInvoice:
      isAssignee &&
      can("purchase_requests", "approve_invoice") &&
      status === "invoice_approval",
    canQueuePayment:
      isAssignee &&
      can("purchase_requests", "payment") &&
      status === "accounting",
    canMarkPaid:
      isAssignee &&
      can("purchase_requests", "payment") &&
      status === "payment_queue",
    canMarkReceived:
      isAssignee &&
      can("purchase_requests", "receive") &&
      status === "paid",
  };
}

export function purchaseRequestActionsHasAny(actions: PurchaseRequestActionSet) {
  return (
    actions.canSubmit ||
    actions.canApprove ||
    actions.canReturn ||
    actions.canSubmitInvoices ||
    actions.canApproveInvoice ||
    actions.canReturnInvoice ||
    actions.canQueuePayment ||
    actions.canMarkPaid ||
    actions.canMarkReceived
  );
}
