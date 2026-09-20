/**
 * Разбор и показ чисел в полях ввода.
 *
 * Пользователь пишет суммы по-русски: «1 767,55», «24 354,99». Пробелы
 * (в том числе неразрывные) считаем разделителями разрядов, запятую — точкой.
 */

/** Формат денег для полей: «1 767,55», «24 354,99». */
const MONEY_FORMAT = new Intl.NumberFormat("ru-RU", {
  minimumFractionDigits: 2,
  maximumFractionDigits: 2,
});

/** «1 767,55» → 1767.55. Пустое или нечисловое значение → null. */
export function parseAmountInput(value: string): number | null {
  const normalized = value.replace(/[\s\u00a0]/g, "").replace(",", ".");
  if (!normalized) {
    return null;
  }
  const parsed = Number(normalized);
  return Number.isFinite(parsed) ? parsed : null;
}

/** Приводит введённое число к виду с разделителями. Нечисловое — как есть. */
export function formatAmountInput(value: string): string {
  const parsed = parseAmountInput(value);
  return parsed === null ? value : MONEY_FORMAT.format(parsed);
}
