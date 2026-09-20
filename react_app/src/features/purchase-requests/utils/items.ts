import type {
  PurchaseRequestItem,
  PurchaseRequestItemDraft,
} from "@/features/purchase-requests/types/purchase-request.types";
import { parseAmountInput } from "@/features/purchase-requests/utils/amount";

/** Строка редактора позиций в форме заявки. */
export type PurchaseRequestItemRow = {
  key: string;
  id?: string;
  name: string;
  quantity: string;
  unit: string;
  article: string;
};

/** Новая пустая строка редактора позиций. */
export function createItemRow(): PurchaseRequestItemRow {
  return {
    key: crypto.randomUUID(),
    name: "",
    quantity: "1",
    unit: "шт",
    article: "",
  };
}

/** Строки редактора из сохранённых позиций заявки. */
export function rowsFromItems(
  items?: PurchaseRequestItem[]
): PurchaseRequestItemRow[] {
  if (!items || items.length === 0) {
    return [createItemRow()];
  }
  return items.map((item) => ({
    key: item.id,
    id: item.id,
    name: item.name,
    quantity:
      item.quantity === Math.round(item.quantity)
        ? String(Math.round(item.quantity))
        : String(item.quantity),
    unit: item.unit,
    article: item.article ?? "",
  }));
}

/**
 * Собирает позиции из строк редактора. Строки без наименования или
 * с некорректным количеством пропускаются — так же их валидирует сервер.
 */
export function collectItems(
  rows: PurchaseRequestItemRow[]
): PurchaseRequestItemDraft[] {
  const items: PurchaseRequestItemDraft[] = [];
  for (const row of rows) {
    const name = row.name.trim();
    if (!name) {
      continue;
    }
    const quantity = parseAmountInput(row.quantity);
    if (quantity === null || quantity <= 0) {
      continue;
    }
    items.push({
      id: row.id,
      name,
      quantity,
      unit: row.unit.trim() || "шт",
      article: row.article.trim() || null,
    });
  }
  return items;
}

/** Разбор одной позиции из формы: ошибка — понятное пользователю сообщение. */
export function parseItemInput(input: {
  name: string;
  quantity: string;
  unit: string;
  article: string;
}): { ok: true; draft: PurchaseRequestItemDraft } | { ok: false; error: string } {
  const name = input.name.trim();
  if (!name) {
    return { ok: false, error: "Укажите наименование" };
  }
  const quantity = parseAmountInput(input.quantity);
  if (quantity === null || quantity <= 0) {
    return { ok: false, error: "Количество должно быть больше нуля" };
  }
  return {
    ok: true,
    draft: {
      name,
      quantity,
      unit: input.unit.trim() || "шт",
      article: input.article.trim() || null,
    },
  };
}
