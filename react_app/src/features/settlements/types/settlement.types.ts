/** Тип операции счёта: акт, аванс или прочее. */
export type SettlementOperationType = "act" | "advance" | "other";

/** Статус оплаты счёта (считает база). */
export type SettlementPaymentStatus =
  | "unpaid"
  | "partial"
  | "paid"
  | "overpaid";

/** Счёт взаиморасчётов (акт / аванс / прочее). */
export type Settlement = {
  id: string;
  operationType: SettlementOperationType;
  objectId: string;
  objectName: string;
  contractorId: string;
  contractorName: string;
  contractId: string;
  contractNumber: string;
  actNumber: string | null;
  actDate: string | null;
  invoiceNumber: string;
  invoiceDate: string;
  /** Базовая сумма без НДС. */
  amount: number;
  isVatIncluded: boolean;
  /** Ставка НДС в процентах. null — без НДС. */
  vatRate: number | null;
  vatAmount: number;
  advanceRetention: number;
  warrantyRetention: number;
  /** К оплате (считает база). */
  totalToPay: number;
  /** Оплачено (считает база). */
  paidAmount: number;
  /** Статус оплаты (считает база триггером). */
  paymentStatus: SettlementPaymentStatus;
  purpose: string | null;
  note: string | null;
};

/** Черновик счёта из формы. */
export type SettlementDraft = {
  objectId: string;
  contractorId: string;
  contractId: string;
  operationType: SettlementOperationType;
  actNumber: string;
  invoiceNumber: string;
  invoiceDate: string;
  /** Сумма, как её ввёл пользователь (с НДС или без — по режиму НДС). */
  amount: string;
  isVatEnabled: boolean;
  vatRate: string;
  isVatIncluded: boolean;
  note: string;
};

/** Оплата по счёту. */
export type SettlementPayment = {
  id: string;
  companyId: string;
  settlementOperationId: string;
  paymentDate: string;
  amount: number;
  note: string | null;
  cashFlowTransactionId: string | null;
  createdAt: string | null;
  createdBy: string | null;
};

/** Черновик оплаты из формы. */
export type SettlementPaymentDraft = {
  paymentDate: string;
  amount: string;
  note: string;
};

/** Файл, прикреплённый к счёту. */
export type SettlementFile = {
  id: string;
  companyId: string;
  settlementOperationId: string;
  name: string;
  filePath: string;
  size: number;
  type: string;
  description: string | null;
  createdAt: string | null;
  createdBy: string | null;
};

/** Фильтры реестра: поиск, тип, статус оплаты, контрагент, объект, договор. */
export type SettlementFilters = {
  search: string;
  operationType: SettlementOperationType | "all";
  paymentStatus: SettlementPaymentStatus | "all";
  contractorId: string;
  objectId: string;
  contractId: string;
};

/** Пара «идентификатор — подпись» для выпадающих списков формы. */
export type SettlementPickItem = {
  id: string;
  label: string;
};
