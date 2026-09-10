import type { EstimateItem } from "@/features/estimates/types/estimate.types";

type NumberCategory = "numeric" | "dotted" | "prefixedD" | "other";

const CATEGORY_PRIORITY: Record<NumberCategory, number> = {
  numeric: 0,
  dotted: 1,
  prefixedD: 2,
  other: 3,
};

type NumberSortKey = {
  category: NumberCategory;
  segments: number[];
  normalized: string;
};

function parseNumberSortKey(value: string): NumberSortKey {
  const normalized = value.trim().toLowerCase();
  if (!normalized) {
    return { category: "other", segments: [], normalized: "" };
  }

  if (/^\d+$/.test(normalized)) {
    return {
      category: "numeric",
      segments: [Number(normalized)],
      normalized,
    };
  }

  if (/^\d+(?:\.\d+)+$/.test(normalized)) {
    return {
      category: "dotted",
      segments: normalized.split(".").map((part) => Number(part) || 0),
      normalized,
    };
  }

  if (normalized.startsWith("д-")) {
    return {
      category: "prefixedD",
      segments: [Number(normalized.slice(2)) || 0],
      normalized,
    };
  }

  return { category: "other", segments: [], normalized };
}

function compareText(
  a: string | null | undefined,
  b: string | null | undefined
): number {
  const normA = (a || "").trim();
  const normB = (b || "").trim();
  if (!normA && !normB) return 0;
  if (!normA) return 1;
  if (!normB) return -1;
  return normA.localeCompare(normB, "ru", {
    numeric: true,
    sensitivity: "base",
  });
}

export function compareEstimateNumbers(
  aNumber: string,
  bNumber: string
): number {
  const keyA = parseNumberSortKey(aNumber);
  const keyB = parseNumberSortKey(bNumber);
  const priorityDiff =
    CATEGORY_PRIORITY[keyA.category] - CATEGORY_PRIORITY[keyB.category];
  if (priorityDiff !== 0) {
    return priorityDiff;
  }

  const minLength = Math.min(keyA.segments.length, keyB.segments.length);
  for (let index = 0; index < minLength; index += 1) {
    const diff = keyA.segments[index] - keyB.segments[index];
    if (diff !== 0) {
      return diff;
    }
  }

  if (keyA.segments.length !== keyB.segments.length) {
    return keyA.segments.length - keyB.segments.length;
  }

  const rawCompare = keyA.normalized.localeCompare(keyB.normalized, "ru", {
    numeric: true,
    sensitivity: "base",
  });
  if (rawCompare !== 0) {
    return rawCompare;
  }

  return 0;
}

/**
 * Sorts estimate items in natural order:
 * 1. System (Система)
 * 2. Subsystem (Подсистема)
 * 3. Number (№)
 * 4. Id (стабильный fallback)
 */
export function compareEstimateItems(a: EstimateItem, b: EstimateItem): number {
  // 1. Сортировка по системе
  const systemDiff = compareText(a.system, b.system);
  if (systemDiff !== 0) {
    return systemDiff;
  }

  // 2. Сортировка по подсистеме
  const subsystemDiff = compareText(a.subsystem, b.subsystem);
  if (subsystemDiff !== 0) {
    return subsystemDiff;
  }

  // 3. Сортировка по номеру (№)
  const numberDiff = compareEstimateNumbers(a.number, b.number);
  if (numberDiff !== 0) {
    return numberDiff;
  }

  // 4. Стабильный tie-break по ID
  return a.id.localeCompare(b.id);
}
