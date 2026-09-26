import { describe, expect, it } from "vitest";

import type {
  PurchaseRequest,
  PurchaseRequestSettings,
  PurchaseRequestStatus,
} from "@/features/purchase-requests/types/purchase-request.types";
import { resolvePurchaseRequestActions } from "@/features/purchase-requests/utils/actions";

const AUTHOR = "author-1";
const APPROVER = "approver-1";
const PREPARER = "preparer-1";
const INVOICE_APPROVER = "invoice-approver-1";
const ACCOUNTANT = "accountant-1";
const RECEIVER = "receiver-1";
const OUTSIDER = "outsider-1";

function buildRequest(
  status: PurchaseRequestStatus,
  createdBy = AUTHOR
): PurchaseRequest {
  return {
    id: "request-1",
    companyId: "company-1",
    number: "ЗК-1",
    objectId: "object-1",
    objectName: "Объект",
    createdBy,
    createdByName: "Автор",
    status,
    comment: null,
    totalAmount: 0,
    createdAt: null,
  };
}

function buildSettings(
  overrides: Partial<PurchaseRequestSettings> = {}
): PurchaseRequestSettings {
  return {
    companyId: "company-1",
    firstApproverIds: [APPROVER],
    invoicePreparerIds: [PREPARER],
    invoiceApproverIds: [INVOICE_APPROVER],
    accountantIds: [ACCOUNTANT],
    receiverMode: "initiator",
    fixedReceiverIds: [],
    ...overrides,
  };
}

/** Права роли: перечисленные права включены, остальные — нет. */
function permissions(...allowed: string[]) {
  return (_module: string, action: string) => allowed.includes(action);
}

function actionsFor(options: {
  status: PurchaseRequestStatus;
  userId: string | null;
  allowed: string[];
  settings?: PurchaseRequestSettings;
}) {
  return resolvePurchaseRequestActions({
    request: buildRequest(options.status),
    currentUserId: options.userId,
    can: permissions(...options.allowed),
    settings: options.settings ?? buildSettings(),
  });
}

describe("resolvePurchaseRequestActions", () => {
  it("автор с правом создания ведёт свой черновик", () => {
    const actions = actionsFor({
      status: "draft",
      userId: AUTHOR,
      allowed: ["create"],
    });

    expect(actions.canEditDraft).toBe(true);
    expect(actions.canDeleteDraft).toBe(true);
    expect(actions.canEditItems).toBe(true);
    expect(actions.canSubmit).toBe(true);
    expect(actions.canApprove).toBe(false);
  });

  it("автор без права создания не может ничего", () => {
    const actions = actionsFor({
      status: "draft",
      userId: AUTHOR,
      allowed: [],
    });

    expect(actions.canSubmit).toBe(false);
    expect(actions.canEditDraft).toBe(false);
    expect(actions.canDeleteDraft).toBe(false);
  });

  it("на доработке автор правит позиции, но не шапку и не удаляет", () => {
    const actions = actionsFor({
      status: "revision",
      userId: AUTHOR,
      allowed: ["create"],
    });

    expect(actions.canEditItems).toBe(true);
    expect(actions.canSubmit).toBe(true);
    expect(actions.canEditDraft).toBe(false);
    expect(actions.canDeleteDraft).toBe(false);
  });

  it("первый согласующий с правом согласования согласует и возвращает", () => {
    const actions = actionsFor({
      status: "approval",
      userId: APPROVER,
      allowed: ["approve"],
    });

    expect(actions.canApprove).toBe(true);
    expect(actions.canReturn).toBe(true);
  });

  it("участник этапа без права согласования кнопок не получает", () => {
    const actions = actionsFor({
      status: "approval",
      userId: APPROVER,
      allowed: [],
    });

    expect(actions.canApprove).toBe(false);
    expect(actions.canReturn).toBe(false);
  });

  it("посторонний с правом кнопок этапа не получает", () => {
    const actions = actionsFor({
      status: "approval",
      userId: OUTSIDER,
      allowed: ["approve"],
    });

    expect(actions.canApprove).toBe(false);
  });

  it("подготовка счетов: счета отправляет участник этапа с правом на счета", () => {
    expect(
      actionsFor({
        status: "invoice_preparation",
        userId: PREPARER,
        allowed: ["prepare_invoice"],
      }).canSubmitInvoices
    ).toBe(true);

    expect(
      actionsFor({
        status: "invoice_preparation",
        userId: OUTSIDER,
        allowed: ["prepare_invoice"],
      }).canSubmitInvoices
    ).toBe(false);
  });

  it("согласование счетов: участник этапа согласует и возвращает счета", () => {
    const actions = actionsFor({
      status: "invoice_approval",
      userId: INVOICE_APPROVER,
      allowed: ["approve_invoice"],
    });

    expect(actions.canApproveInvoice).toBe(true);
    expect(actions.canReturnInvoice).toBe(true);
  });

  it("бухгалтер заводит на оплату и отмечает оплату", () => {
    const accounting = actionsFor({
      status: "accounting",
      userId: ACCOUNTANT,
      allowed: ["payment"],
    });
    const paymentQueue = actionsFor({
      status: "payment_queue",
      userId: ACCOUNTANT,
      allowed: ["payment"],
    });

    expect(accounting.canQueuePayment).toBe(true);
    expect(paymentQueue.canMarkPaid).toBe(true);
  });

  it("в режиме «инициатор» получение отмечает автор заявки", () => {
    const author = actionsFor({
      status: "paid",
      userId: AUTHOR,
      allowed: ["create", "receive"],
    });
    const outsider = actionsFor({
      status: "paid",
      userId: OUTSIDER,
      allowed: ["receive"],
    });

    expect(author.canMarkReceived).toBe(true);
    expect(outsider.canMarkReceived).toBe(false);
  });

  it("в режиме «назначенные сотрудники» получение отмечает только получатель", () => {
    const fixed = buildSettings({
      receiverMode: "fixed_user",
      fixedReceiverIds: [RECEIVER],
    });

    expect(
      actionsFor({
        status: "paid",
        userId: RECEIVER,
        allowed: ["receive"],
        settings: fixed,
      }).canMarkReceived
    ).toBe(true);

    expect(
      actionsFor({
        status: "paid",
        userId: AUTHOR,
        allowed: ["create", "receive"],
        settings: fixed,
      }).canMarkReceived
    ).toBe(false);
  });

  it("без пользователя кнопок нет", () => {
    const actions = actionsFor({
      status: "approval",
      userId: null,
      allowed: ["approve"],
    });

    expect(actions.canApprove).toBe(false);
    expect(actions.canSubmit).toBe(false);
  });
});
