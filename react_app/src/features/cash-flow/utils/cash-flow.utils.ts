import type {
  CashFlowCategoryRow,
  CashFlowListRow,
} from "@/types/database.types";
import type {
  CashFlowCategory,
  CashFlowDraft,
  CashFlowTransaction,
  CashFlowType,
} from "@/features/cash-flow/types/cash-flow.types";

/** Колонки статьи ДДС для выборки. */
export const CASH_FLOW_CATEGORY_SELECT = "id, name, type";

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

/** Сумма с символом рубля: «1 234,56 ₽». */
export function formatCurrency(value: number): string {
  return new Intl.NumberFormat("ru-RU", {
    style: "currency",
    currency: "RUB",
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  }).format(value);
}

/**
 * Короткая сумма для подписей оси: «1,5 млн ₽», «240 тыс. ₽», «950 ₽».
 *
 * Знак минус выносится перед числом — по оси графика видны и отрицательные
 * значения сальдо.
 */
export function formatCompactCurrency(value: number): string {
  if (value === 0) {
    return "0 ₽";
  }
  const sign = value < 0 ? "−" : "";
  const absolute = Math.abs(value);
  if (absolute >= 1_000_000) {
    const millions = (absolute / 1_000_000)
      .toFixed(1)
      .replace(".0", "")
      .replace(".", ",");
    return `${sign}${millions} млн ₽`;
  }
  if (absolute >= 1_000) {
    return `${sign}${Math.round(absolute / 1_000)} тыс. ₽`;
  }
  return `${sign}${Math.round(absolute)} ₽`;
}

/** Сумма без символа валюты — для полей ввода. */
export function formatAmount(value: number): string {
  return new Intl.NumberFormat("ru-RU", {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  }).format(value);
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

/** Сужает тип операции из базы до известного вебу. */
function toType(value: string): CashFlowType {
  return value === "income" ? "income" : "expense";
}

/** Строка реестра из функции `get_cash_flow_page` → операция для интерфейса. */
export function mapCashFlowRow(row: CashFlowListRow): CashFlowTransaction {
  return {
    id: row.id,
    date: row.date,
    type: toType(row.type),
    amount: toNumber(row.amount),
    categoryId: row.category_id,
    categoryName: text(row.category_name),
    objectId: row.object_id,
    objectName: text(row.object_name),
    contractId: row.contract_id,
    contractNumber: text(row.contract_number),
    contractorId: row.contractor_id,
    // Контрагент показывается по справочнику; у импортированных операций
    // справочника может не быть — тогда остаётся текст из выписки.
    contractorName: text(row.contractor_short_name) || text(row.contractor_name),
    contractorInn: text(row.contractor_inn),
    comment: text(row.comment),
    operationHash: row.operation_hash,
  };
}

/** Строка статьи ДДС → статья для интерфейса. */
export function mapCashFlowCategoryRow(
  row: CashFlowCategoryRow
): CashFlowCategory {
  return {
    id: row.id,
    name: text(row.name),
    type: toType(row.type),
  };
}

/** Пустой черновик операции: дата — сегодня, тип — расход. */
export function emptyCashFlowDraft(): CashFlowDraft {
  return {
    type: "expense",
    date: todayDateInput(),
    amount: "",
    categoryId: "",
    objectId: "",
    contractorId: "",
    contractId: "",
    comment: "",
  };
}

/** Черновик из операции для формы редактирования. */
export function cashFlowToDraft(transaction: CashFlowTransaction): CashFlowDraft {
  return {
    type: transaction.type,
    date: transaction.date,
    amount: formatAmount(transaction.amount),
    categoryId: transaction.categoryId ?? "",
    objectId: transaction.objectId ?? "",
    contractorId: transaction.contractorId ?? "",
    contractId: transaction.contractId ?? "",
    comment: transaction.comment,
  };
}

/** Колонки операции, которые пишет веб. */
export type CashFlowPayload = {
  date: string;
  type: CashFlowType;
  amount: number;
  category_id: string | null;
  object_id: string | null;
  contract_id: string | null;
  contractor_id: string | null;
  comment: string | null;
};

/** Данные для записи в базу. */
export function cashFlowDraftToPayload(draft: CashFlowDraft): CashFlowPayload {
  return {
    date: draft.date,
    type: draft.type,
    amount: roundMoney(parseAmount(draft.amount) ?? 0),
    category_id: draft.categoryId || null,
    object_id: draft.objectId || null,
    contract_id: draft.contractId || null,
    contractor_id: draft.contractorId || null,
    comment: draft.comment.trim() || null,
  };
}

/** Уникальный индекс хеша операции — см. миграцию `..._add_operation_hash_to_bank_entries`. */
const CASH_FLOW_OPERATION_HASH_INDEX = "idx_cash_flow_operation_hash";

/**
 * Понятный текст ошибки записи операции по коду ответа базы.
 *
 * Хеш операции повторяется при импорте одной и той же банковской выписки —
 * база не даёт записать такую операцию второй раз.
 */
export function cashFlowWriteError(error: {
  code?: string;
  message: string;
}): Error {
  if (
    error.code === "23505" &&
    error.message.includes(CASH_FLOW_OPERATION_HASH_INDEX)
  ) {
    return new Error("Такая операция уже есть в реестре");
  }
  if (error.code === "23514") {
    return new Error("Проверьте заполнение операции: тип, дату и сумму");
  }
  if (error.code === "23503") {
    return new Error("Статья, объект или договор уже удалены");
  }
  return new Error(error.message);
}

/**
 * Понятный текст ошибки удаления статьи ДДС.
 *
 * Статью нельзя удалить, пока на неё ссылаются операции: в базе ограничение
 * `ON DELETE RESTRICT`.
 */
export function cashFlowCategoryDeleteError(error: {
  code?: string;
  message: string;
}): Error {
  if (error.code === "23503") {
    return new Error(
      "Статья используется в операциях. Сначала назначьте этим операциям другую статью"
    );
  }
  return new Error(error.message);
}
