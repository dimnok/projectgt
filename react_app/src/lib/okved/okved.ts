import okved2 from "./okved2.json";

/**
 * ОКВЭД 2 (ОК 029-2014), изменение №89 от 01.08.2026.
 * Справочник: classifikators.ru, файл okved.csv от 10.08.2026.
 */
const OKVED_NAMES = okved2 as Record<string, string>;

const CODE_PATTERN = /\d{2}(?:\.\d{1,2}){0,3}/;
const EXACT_CODE_PATTERN = /^\d{2}(?:\.\d{1,2}){0,3}$/;

/**
 * Приводит ввод к виду кода: 43323 → 43.32.3, 011111 → 01.11.11.
 */
export function formatOkvedInput(raw: string): string {
  const digits = raw.replace(/\D/g, "").slice(0, 6);
  if (digits.length <= 2) {
    return digits;
  }
  if (digits.length <= 4) {
    return `${digits.slice(0, 2)}.${digits.slice(2)}`;
  }
  return `${digits.slice(0, 2)}.${digits.slice(2, 4)}.${digits.slice(4)}`;
}

/**
 * Достаёт код из значения в базе: `43.29`, `[43.29] Название`, `Название (43.29)`.
 */
export function parseOkvedCode(value: string | null | undefined): string {
  const text = value?.trim() ?? "";
  if (!text) {
    return "";
  }

  const bracket = text.match(/^\[(\d{2}(?:\.\d{1,2}){0,3})\]/);
  if (bracket) {
    return formatOkvedInput(bracket[1]);
  }

  const trailing = text.match(/\((\d{2}(?:\.\d{1,2}){0,3})\)\s*$/);
  if (trailing) {
    return formatOkvedInput(trailing[1]);
  }

  if (EXACT_CODE_PATTERN.test(text)) {
    return formatOkvedInput(text);
  }

  const embedded = text.match(CODE_PATTERN);
  return embedded ? formatOkvedInput(embedded[0]) : "";
}

export function getOkvedName(code: string): string | null {
  const normalized = formatOkvedInput(code);
  if (!normalized) {
    return null;
  }
  return OKVED_NAMES[normalized] ?? null;
}

export function toStoredOkved(value: string): string {
  const code = parseOkvedCode(value);
  if (code) {
    return code;
  }
  return value.trim();
}

/**
 * Значение для поля ввода: код, если его удалось разобрать, иначе исходный текст.
 */
export function okvedInputValue(stored: string | null | undefined): string {
  const code = parseOkvedCode(stored);
  if (code) {
    return code;
  }
  return stored?.trim() ?? "";
}

export function formatOkvedLabel(
  value: string | null | undefined
): string | null {
  const raw = value?.trim() ?? "";
  if (!raw) {
    return null;
  }
  const code = parseOkvedCode(raw);
  if (!code) {
    return raw;
  }
  const name = OKVED_NAMES[code];
  if (name) {
    return `${name} (${code})`;
  }
  return code;
}

export function okvedFieldHint(codeInput: string): string | null {
  const code = formatOkvedInput(codeInput);
  if (!EXACT_CODE_PATTERN.test(code)) {
    return null;
  }
  return OKVED_NAMES[code] ?? "Название по этому коду не найдено";
}

export function onOkvedInputChange(raw: string): string {
  const parsed = parseOkvedCode(raw);
  if (parsed && (raw.includes("[") || raw.includes("("))) {
    return parsed;
  }
  if (/[A-Za-zА-Яа-яЁё]/.test(raw)) {
    return raw;
  }
  return formatOkvedInput(raw);
}
