import {
  formatCurrency,
  formatQuantity,
  formatRuDateTime,
} from "@/features/estimates/utils/estimate.utils";
import type {
  EstimateItem,
  EstimateItemEditHistoryEntry,
  EstimateItemFieldChange,
} from "@/features/estimates/types/estimate.types";

const FIELD_ORDER: readonly string[] = [
  "quantity",
  "price",
  "name",
  "number",
  "unit",
  "system",
  "subsystem",
  "article",
  "manufacturer",
  "visible_in_estimates_module",
];

const FIELD_LABELS: Record<string, string> = {
  quantity: "количество",
  price: "цена",
  name: "наименование",
  number: "номер",
  unit: "ед. изм.",
  system: "система",
  subsystem: "подсистема",
  article: "артикул",
  manufacturer: "производитель",
  visible_in_estimates_module: "видимость",
};

function formatChangeValue(field: string, value: unknown): string {
  if (value === null || value === undefined) {
    return "—";
  }
  if (field === "quantity" && (typeof value === "number" || typeof value === "string")) {
    const num = typeof value === "number" ? value : Number(String(value).replace(",", "."));
    return Number.isFinite(num) ? formatQuantity(num) : String(value);
  }
  if (field === "price" && (typeof value === "number" || typeof value === "string")) {
    const num = typeof value === "number" ? value : Number(String(value).replace(",", "."));
    return Number.isFinite(num) ? formatCurrency(num) : String(value);
  }
  if (field === "visible_in_estimates_module") {
    if (value === true || value === "true") return "да";
    if (value === false || value === "false") return "нет";
  }
  const text = String(value).trim();
  if (!text) return "—";
  if (text.length > 40) return `${text.substring(0, 37)}...`;
  return text;
}

function formatFieldChange(field: string, change: EstimateItemFieldChange): string {
  const label = FIELD_LABELS[field] ?? field;
  return `${label}: ${formatChangeValue(field, change.from)} → ${formatChangeValue(field, change.to)}`;
}

export type EstimateTimelineEvent = {
  id: string;
  type: "create" | "update";
  action: string;
  date: string;
  formattedDate: string;
  author: string;
  changeDetails: string[];
};

export function buildEstimateItemTimeline(
  item: EstimateItem,
  entries: EstimateItemEditHistoryEntry[]
): EstimateTimelineEvent[] {
  const events: EstimateTimelineEvent[] = [];

  // 1. Событие создания позиции
  if (item.createdAt) {
    events.push({
      id: "created",
      type: "create",
      action: "Добавление позиции",
      date: item.createdAt,
      formattedDate: formatRuDateTime(item.createdAt),
      author: item.createdByName || "Не указан",
      changeDetails: [],
    });
  }

  // 2. События ручных правок
  for (const entry of entries) {
    const changes = entry.changes || {};
    const details: string[] = [];

    // Поля в заданном порядке
    for (const field of FIELD_ORDER) {
      if (changes[field]) {
        details.push(formatFieldChange(field, changes[field]));
      }
    }
    // Прочие поля, если есть
    for (const [key, change] of Object.entries(changes)) {
      if (!FIELD_ORDER.includes(key)) {
        details.push(formatFieldChange(key, change));
      }
    }

    events.push({
      id: entry.id,
      type: "update",
      action: "Изменение",
      date: entry.createdAt,
      formattedDate: formatRuDateTime(entry.createdAt),
      author: entry.userName || "Не указан",
      changeDetails: details,
    });
  }

  // Сортировка: самые свежие сверху (descending)
  return events.sort((a, b) => {
    const ta = new Date(a.date).getTime() || 0;
    const tb = new Date(b.date).getTime() || 0;
    return tb - ta;
  });
}
