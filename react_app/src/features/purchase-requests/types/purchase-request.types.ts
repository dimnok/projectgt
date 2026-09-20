/**
 * Статусы заявки. `unknown` — запасной вариант для значения, которого нет в списке.
 * Статуса «Отменено» нет: отмена в серверной функции отключена.
 */
export const PURCHASE_REQUEST_STATUSES = [
  "draft",
  "approval",
  "revision",
  "invoice_preparation",
  "invoice_approval",
  "accounting",
  "payment_queue",
  "paid",
  "received",
  "unknown",
] as const;

export type PurchaseRequestStatus = (typeof PURCHASE_REQUEST_STATUSES)[number];

/**
 * Статусы, доступные как фильтр реестра. Без `unknown`: фильтровать
 * по нему нечего, он нужен только как запасной вариант отображения.
 */
export const PURCHASE_REQUEST_FILTER_STATUSES = [
  "draft",
  "approval",
  "revision",
  "invoice_preparation",
  "invoice_approval",
  "accounting",
  "payment_queue",
  "paid",
  "received",
] as const;

export type PurchaseRequestFilterStatus =
  (typeof PURCHASE_REQUEST_FILTER_STATUSES)[number];

/** Фильтр реестра: «Все» или конкретный статус заявки. */
export type PurchaseRequestListFilter = "all" | PurchaseRequestFilterStatus;

export type PurchaseRequestReceiverMode = "initiator" | "fixed_user";

export type PurchaseRequestListItem = {
  id: string;
  number: string;
  objectId: string;
  objectName: string;
  status: PurchaseRequestStatus;
  createdBy: string;
  createdByName: string | null;
  totalAmount: number;
  createdAt: string;
};

export type PurchaseRequest = {
  id: string;
  companyId: string;
  number: string;
  objectId: string;
  objectName: string | null;
  createdBy: string;
  createdByName: string | null;
  status: PurchaseRequestStatus;
  comment: string | null;
  totalAmount: number;
  createdAt: string | null;
};

export type PurchaseRequestItem = {
  id: string;
  requestId: string;
  name: string;
  quantity: number;
  unit: string;
  article: string | null;
  createdAt: string | null;
};

export type PurchaseRequestItemDraft = {
  id?: string;
  name: string;
  quantity: number;
  unit: string;
  article: string | null;
};

export type PurchaseRequestFile = {
  id: string;
  requestId: string;
  invoiceId: string | null;
  storagePath: string;
  fileName: string;
  mimeType: string | null;
};

export type PurchaseRequestInvoice = {
  id: string;
  requestId: string;
  companyId: string;
  supplierId: string;
  supplierName: string | null;
  amount: number;
  invoiceNumber: string | null;
  invoiceDate: string | null;
  comment: string | null;
  createdAt: string | null;
  invoiceFile: PurchaseRequestFile | null;
  /** Позиции «как в счёте»: у поставщика свои названия товаров. */
  items: PurchaseRequestInvoiceItem[];
};

/** Строка счёта. Ссылка на позицию заявки — необязательная. */
export type PurchaseRequestInvoiceItem = {
  id: string;
  invoiceId: string;
  requestItemId: string | null;
  article: string | null;
  name: string;
  unit: string | null;
  quantity: number | null;
  price: number | null;
  amount: number | null;
};

/** Строка счёта для сохранения (id есть — обновляем, нет — добавляем). */
export type PurchaseRequestInvoiceItemDraft = {
  id?: string;
  requestItemId?: string | null;
  article?: string | null;
  name: string;
  unit?: string | null;
  quantity?: number | null;
  price?: number | null;
  amount?: number | null;
};

/** Результат распознавания счёта: шапка и позиции, ничего ещё не сохранено. */
export type RecognizedInvoice = {
  supplierName: string | null;
  supplierInn: string | null;
  invoiceNumber: string | null;
  invoiceDate: string | null;
  total: number | null;
  items: PurchaseRequestInvoiceItemDraft[];
};

export type PurchaseRequestHistoryEntry = {
  id: string;
  requestId: string;
  userId: string;
  userName: string | null;
  action: string;
  fromStatus: PurchaseRequestStatus | null;
  toStatus: PurchaseRequestStatus | null;
  comment: string | null;
  createdAt: string;
};

export type PurchaseRequestSettings = {
  companyId: string;
  firstApproverIds: string[];
  invoicePreparerIds: string[];
  invoiceApproverIds: string[];
  accountantIds: string[];
  receiverMode: PurchaseRequestReceiverMode;
  fixedReceiverIds: string[];
};

export type PurchaseRequestCompanyUser = {
  id: string;
  email: string;
  fullName: string | null;
  shortName: string | null;
};

export type PurchaseRequestCounts = Record<PurchaseRequestListFilter, number>;

export type PurchaseRequestDetails = {
  request: PurchaseRequest;
  items: PurchaseRequestItem[];
  history: PurchaseRequestHistoryEntry[];
  invoices: PurchaseRequestInvoice[];
};

/** Строка KPI «Оплачено по объектам»: суммы счетов оплаченных заявок. */
export type PurchaseRequestPaidByObject = {
  objectId: string;
  objectName: string;
  paidAmount: number;
  requestsCount: number;
};

export type PurchaseRequestActionSet = {
  canSubmit: boolean;
  canApprove: boolean;
  canReturn: boolean;
  canSubmitInvoices: boolean;
  canApproveInvoice: boolean;
  canReturnInvoice: boolean;
  canQueuePayment: boolean;
  canMarkPaid: boolean;
  canMarkReceived: boolean;
  canEditItems: boolean;
  canEditDraft: boolean;
  canDeleteDraft: boolean;
};
