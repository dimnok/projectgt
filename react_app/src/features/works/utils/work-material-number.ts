const D_NUMBER = /^[дДdD]\s*-\s*(\d+)$/;

/**
 * Next extra-line number in an estimate, same rule as the app: `д-N`.
 */
export function nextWorkMaterialNumber(numbers: string[]): string {
  let max = 0;
  for (const raw of numbers) {
    const match = D_NUMBER.exec(raw.trim());
    if (!match) {
      continue;
    }
    const value = Number.parseInt(match[1] ?? "0", 10);
    if (Number.isFinite(value) && value > max) {
      max = value;
    }
  }
  return `д-${max + 1}`;
}

export const WORK_MATERIAL_UNITS = [
  "шт",
  "м",
  "кг",
  "л",
  "м²",
  "м³",
  "компл.",
] as const;

export function workMaterialSaveErrorMessage(error: unknown): string {
  const raw = error instanceof Error ? error.message : String(error);
  const lower = raw.toLowerCase();
  if (
    lower.includes("permission") ||
    lower.includes("row-level security") ||
    lower.includes("42501")
  ) {
    return "Нет доступа к добавлению материалов в смету. Обратитесь к администратору.";
  }
  return "Не удалось сохранить материал. Попробуйте ещё раз или обратитесь к администратору.";
}
