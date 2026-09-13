/**
 * Supabase nested selects may return an object or a one-item array.
 */
export function nestedRecord(
  value: unknown
): Record<string, unknown> | null {
  if (Array.isArray(value)) {
    const first = value[0];
    if (first && typeof first === "object") {
      return first as Record<string, unknown>;
    }
    return null;
  }

  if (value && typeof value === "object") {
    return value as Record<string, unknown>;
  }

  return null;
}

export function asString(value: unknown): string | null {
  return typeof value === "string" && value.length > 0 ? value : null;
}

export function asBoolean(value: unknown, fallback = false): boolean {
  return typeof value === "boolean" ? value : fallback;
}

export function asNumber(value: unknown): number | null {
  if (typeof value === "number" && Number.isFinite(value)) {
    return value;
  }
  if (typeof value === "string" && value.trim()) {
    const parsed = Number(value.replace(",", "."));
    return Number.isFinite(parsed) ? parsed : null;
  }
  return null;
}
