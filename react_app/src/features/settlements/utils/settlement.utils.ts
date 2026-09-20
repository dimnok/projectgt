import type {
  SettlementOperationJoinRow,
  SettlementOperationsListRow,
  SettlementOperationsRow,
} from "@/types/database.types";
import type {
  Settlement,
  SettlementDraft,
  SettlementOperationType,
} from "@/features/settlements/types/settlement.types";
import {
  AMOUNT_EPSILON,
  isSettlementPaymentStatus,
} from "@/features/settlements/utils/payment-status";
import { computeSettlementVat } from "@/features/settlements/utils/vat";

/**
 * Колонки счёта для выборки, включая подтянутые названия объекта,
 * контрагента и номера договора.
 */
export const SETTLEMENT_SELECT = [
  "id",
  "operation_type",
  "object_id",
  "contractor_id",
  "contract_id",
  "act_number",
  "act_date",
  "invoice_number",
  "invoice_date",
  "amount",
  "is_vat_included",
  "vat_rate",
  "vat_amount",
  "advance_retention",
  "warranty_retention",
  "total_to_pay",
  "paid_amount",
  "payment_status",
  "purpose",
  "note",
  "objects:object_id(name)",
  "contractors:contractor_id(short_name)",
  "contracts:contract_id(number)",
].join(", ");

/** Текст из базы без лишних пробелов; `null` превращается в пустую строку. */
function text(value: string | null | undefined): string {
  return value?.trim() ?? "";
}

/** Приводит значение из базы (число или строка с запятой) к числу. */
export function toNumber(value: unknown): number {
  if (typeof value === "number" && Number.isFinite(value)) {
    return value;
  }
  if (typeof value === "string") {
    const parsed = Number(value.replace(",", "."));
    return Number.isFinite(parsed) ? parsed : 0;
  }
  return 0;
}

/** То же, что `toNumber`, но пустое значение остаётся `null` (например, ставка НДС). */
function toNumberOrNull(value: unknown): number | null {
  if (value === null || value === undefined || value === "") {
    return null;
  }
  const parsed = toNumber(value);
  return Number.isFinite(parsed) ? parsed : null;
}

/** Сужает тип операции из базы до известного вебу. */
function isOperationType(value: string): value is SettlementOperationType {
  return value === "act" || value === "advance" || value === "other";
}

/**
 * Строка счёта → счёт для интерфейса.
 *
 * Разные выборки отдают названия по-разному: PostgREST — вложенными связями,
 * функция реестра — плоскими колонками. Остальные поля одинаковые, поэтому
 * сборка одна, а различается только источник названий.
 */
function settlementFromRow(
  row: SettlementOperationsRow,
  names: { objectName: string; contractorName: string; contractNumber: string }
): Settlement {
  const totalToPay = toNumber(row.total_to_pay);
  const paidAmount = toNumber(row.paid_amount);

  return {
    id: row.id,
    operationType: isOperationType(row.operation_type)
      ? row.operation_type
      : "other",
    objectId: row.object_id,
    objectName: names.objectName,
    contractorId: row.contractor_id,
    contractorName: names.contractorName,
    contractId: row.contract_id,
    contractNumber: names.contractNumber,
    actNumber: row.act_number,
    actDate: row.act_date,
    invoiceNumber: text(row.invoice_number),
    invoiceDate: row.invoice_date,
    amount: toNumber(row.amount),
    isVatIncluded: row.is_vat_included !== false,
    vatRate: toNumberOrNull(row.vat_rate),
    vatAmount: toNumber(row.vat_amount),
    advanceRetention: toNumber(row.advance_retention),
    warrantyRetention: toNumber(row.warranty_retention),
    totalToPay,
    paidAmount,
    paymentStatus: isSettlementPaymentStatus(row.payment_status)
      ? row.payment_status
      : "unpaid",
    purpose: row.purpose,
    note: row.note,
  };
}

/** Строка счёта со связями из PostgREST → счёт для интерфейса. */
export function mapSettlementRow(row: SettlementOperationJoinRow): Settlement {
  return settlementFromRow(row, {
    objectName: text(row.objects?.name),
    contractorName: text(row.contractors?.short_name),
    contractNumber: text(row.contracts?.number),
  });
}

/** Строка реестра из функции `get_settlements_page` → счёт для интерфейса. */
export function mapSettlementListRow(
  row: SettlementOperationsListRow
): Settlement {
  return settlementFromRow(row, {
    objectName: text(row.object_name),
    contractorName: text(row.contractor_name),
    contractNumber: text(row.contract_number),
  });
}

/** Остаток к оплате (может быть отрицательным при переплате). */
export function settlementRemaining(settlement: Settlement): number {
  return settlement.totalToPay - settlement.paidAmount;
}

/** Положительный долг по счёту (0 при переплате или полной оплате). */
export function settlementPositiveDebt(settlement: Settlement): number {
  const remaining = settlementRemaining(settlement);
  return remaining > AMOUNT_EPSILON ? remaining : 0;
}

/** Итоги по списку счетов: к оплате, оплачено и положительный долг. */
export function sumSettlements(settlements: Settlement[]) {
  let totalAmount = 0;
  let totalPaid = 0;
  let totalDebt = 0;
  for (const settlement of settlements) {
    totalAmount += settlement.totalToPay;
    totalPaid += settlement.paidAmount;
    totalDebt += settlementPositiveDebt(settlement);
  }
  return { totalAmount, totalPaid, totalDebt };
}

/**
 * Разбирает введённую сумму: пробелы и неразрывные пробелы убираются,
 * запятая считается десятичным разделителем. Пустая строка — это 0,
 * нечитаемое значение — `null`.
 */
export function parseAmount(value: string): number | null {
  const normalized = value
    .replace(/\u00A0|\u202F/g, "")
    .replace(/\s/g, "")
    .replace(",", ".");
  if (!normalized) {
    return 0;
  }
  const parsed = Number(normalized);
  return Number.isFinite(parsed) ? parsed : null;
}

/** Округляет деньги до копеек. */
function roundMoney(value: number): number {
  return Math.round(value * 100) / 100;
}

/** Сумма с символом рубля: «1 234,56 ₽». */
export function formatCurrency(value: number): string {
  return new Intl.NumberFormat("ru-RU", {
    style: "currency",
    currency: "RUB",
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  }).format(value);
}

/** Сумма без символа валюты — для полей ввода. */
export function formatAmount(value: number): string {
  return new Intl.NumberFormat("ru-RU", {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  }).format(value);
}

/** Число без валюты, до трёх знаков — для ставки НДС. */
export function formatQuantity(value: number): string {
  return new Intl.NumberFormat("ru-RU", { maximumFractionDigits: 3 }).format(
    value
  );
}

/** Дата `2026-09-19` → `19.09.2026`. Пустая дата — прочерк. */
export function formatRuDate(value: string | null | undefined): string {
  if (!value) {
    return "—";
  }
  const clean = value.split("T")[0];
  const [year, month, day] = clean.split("-");
  if (!year || !month || !day) {
    return value;
  }
  return `${day}.${month}.${year}`;
}

/** Сегодняшняя дата в формате поля `date` (`ГГГГ-ММ-ДД`). */
export function todayDateInput(): string {
  const now = new Date();
  const year = now.getFullYear();
  const month = String(now.getMonth() + 1).padStart(2, "0");
  const day = String(now.getDate()).padStart(2, "0");
  return `${year}-${month}-${day}`;
}

/** Пустой черновик нового счёта: дата — сегодня, НДС 22 % в сумме. */
export function emptySettlementDraft(): SettlementDraft {
  return {
    objectId: "",
    contractorId: "",
    contractId: "",
    operationType: "act",
    actNumber: "",
    invoiceNumber: "",
    invoiceDate: todayDateInput(),
    amount: "",
    isVatEnabled: true,
    vatRate: "22",
    isVatIncluded: true,
    note: "",
  };
}

/** Черновик из счёта для формы редактирования. */
export function settlementToDraft(settlement: Settlement): SettlementDraft {
  const entered =
    settlement.vatRate !== null && settlement.isVatIncluded
      ? settlement.amount + settlement.vatAmount
      : settlement.amount;

  return {
    objectId: settlement.objectId,
    contractorId: settlement.contractorId,
    contractId: settlement.contractId,
    operationType: settlement.operationType,
    actNumber: settlement.actNumber ?? "",
    invoiceNumber: settlement.invoiceNumber,
    invoiceDate: settlement.invoiceDate,
    amount: entered ? formatAmount(entered) : "",
    // Ставка 0% (экспорт) — это НДС включён, а не «без НДС».
    isVatEnabled: settlement.vatRate !== null,
    vatRate:
      settlement.vatRate !== null ? formatQuantity(settlement.vatRate) : "22",
    isVatIncluded: settlement.isVatIncluded,
    note: settlement.note ?? "",
  };
}

/** Колонки таблицы счетов, которые пишет веб. */
export type SettlementPayload = {
  operation_type: SettlementOperationType;
  object_id: string;
  contractor_id: string;
  contract_id: string;
  act_number: string | null;
  act_date: string | null;
  invoice_number: string;
  invoice_date: string;
  amount: number;
  is_vat_included: boolean;
  vat_rate: number | null;
  vat_amount: number;
  advance_retention: number;
  warranty_retention: number;
  note: string | null;
  purpose: string | null;
};

/**
 * Данные для записи в базу. `total_to_pay`, `paid_amount`, `payment_status`
 * считает база — их не отправляем.
 *
 * При смене типа на «аванс» или «прочее» дата акта и удержания обнуляются:
 * этого требует ограничение таблицы (иначе смена типа «акт → аванс» падает).
 */
export function settlementDraftToPayload(
  draft: SettlementDraft,
  existing?: Settlement | null
): SettlementPayload {
  const entered = parseAmount(draft.amount) ?? 0;
  const rate = draft.isVatEnabled ? parseAmount(draft.vatRate) ?? 0 : null;
  const breakdown = computeSettlementVat(
    entered,
    rate ?? 0,
    draft.isVatIncluded
  );

  const isAct = draft.operationType === "act";

  return {
    operation_type: draft.operationType,
    object_id: draft.objectId,
    contractor_id: draft.contractorId,
    contract_id: draft.contractId,
    act_number: isAct ? draft.actNumber.trim() || null : null,
    act_date: isAct ? existing?.actDate ?? null : null,
    invoice_number: draft.invoiceNumber.trim(),
    invoice_date: draft.invoiceDate,
    amount: roundMoney(breakdown.base),
    is_vat_included: draft.isVatIncluded,
    vat_rate: rate,
    vat_amount: roundMoney(breakdown.vat),
    advance_retention: isAct ? existing?.advanceRetention ?? 0 : 0,
    warranty_retention: isAct ? existing?.warrantyRetention ?? 0 : 0,
    note: draft.note.trim() || null,
    purpose: existing?.purpose ?? null,
  };
}

/** Уникальный индекс номера счёта — см. миграцию `..._settlement_invoice_number_unique`. */
const SETTLEMENT_INVOICE_UNIQUE_INDEX =
  "settlement_operations_invoice_number_unique";

/**
 * Понятный текст ошибки записи счёта по коду ответа базы.
 *
 * [invoiceNumber] нужен для нарушения уникальности: сама база в тексте ошибки
 * номер не называет, а пользователю важно видеть, какой номер занят.
 */
export function settlementWriteError(
  error: { code?: string; message: string },
  invoiceNumber?: string
): Error {
  if (
    error.code === "23505" &&
    error.message.includes(SETTLEMENT_INVOICE_UNIQUE_INDEX)
  ) {
    const number = invoiceNumber?.trim();
    return new Error(
      number
        ? `Счёт с номером «${number}» уже есть по этому договору`
        : "Счёт с таким номером уже есть по этому договору"
    );
  }
  if (error.code === "23503") {
    return new Error("Нельзя удалить счёт: к нему уже привязаны данные");
  }
  if (error.code === "23514") {
    return new Error("Проверьте заполнение счёта: тип, номер акта и суммы");
  }
  return new Error(error.message);
}
