import type {
  PurchaseRequestInvoiceItem,
  PurchaseRequestInvoiceItemDraft,
} from "@/features/purchase-requests/types/purchase-request.types";
import { parseAmountInput } from "@/features/purchase-requests/utils/amount";

/** Строка редактора позиций счёта. */
export type InvoiceItemRow = {
  key: string;
  id?: string;
  requestItemId?: string | null;
  article: string;
  name: string;
  unit: string;
  quantity: string;
  price: string;
  amount: string;
};

/** Новая пустая строка позиций счёта. */
export function createInvoiceItemRow(): InvoiceItemRow {
  return {
    key: crypto.randomUUID(),
    article: "",
    name: "",
    unit: "",
    quantity: "",
    price: "",
    amount: "",
  };
}

/** Формат денег для полей: «1 767,55», «24 354,99». */
const MONEY_FORMAT = new Intl.NumberFormat("ru-RU", {
  minimumFractionDigits: 2,
  maximumFractionDigits: 2,
});

/** Число для поля ввода: «5» без лишних нулей. */
function toQuantityValue(value: number | null | undefined): string {
  return typeof value === "number" && Number.isFinite(value) ? String(value) : "";
}

/** Деньги для поля ввода: «1 767,55». */
function toMoneyValue(value: number | null | undefined): string {
  return typeof value === "number" && Number.isFinite(value)
    ? MONEY_FORMAT.format(value)
    : "";
}

/** Строки редактора из позиций счёта (сохранённых или распознанных). */
export function invoiceItemRowsFromItems(
  items: (PurchaseRequestInvoiceItem | PurchaseRequestInvoiceItemDraft)[]
): InvoiceItemRow[] {
  if (items.length === 0) {
    return [];
  }
  return items.map((item) => ({
    key: item.id ?? crypto.randomUUID(),
    id: item.id,
    requestItemId: item.requestItemId ?? null,
    article: item.article ?? "",
    name: item.name,
    unit: item.unit ?? "",
    quantity: toQuantityValue(item.quantity),
    price: toMoneyValue(item.price),
    amount: toMoneyValue(item.amount),
  }));
}

/**
 * Собирает позиции счёта из строк редактора. Строки без наименования
 * пропускаются — так же их проверяет сервер.
 */
export function collectInvoiceItemDrafts(
  rows: InvoiceItemRow[]
): PurchaseRequestInvoiceItemDraft[] {
  const items: PurchaseRequestInvoiceItemDraft[] = [];
  for (const row of rows) {
    const name = row.name.trim();
    if (!name) {
      continue;
    }
    items.push({
      id: row.id,
      requestItemId: row.requestItemId ?? null,
      article: row.article.trim() || null,
      name,
      unit: row.unit.trim() || null,
      quantity: parseAmountInput(row.quantity),
      price: parseAmountInput(row.price),
      amount: parseAmountInput(row.amount),
    });
  }
  return items;
}
