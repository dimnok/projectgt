/** Округляет деньги до копеек; нечисловое значение — 0. */
function roundMoney(value: number): number {
  if (!Number.isFinite(value)) {
    return 0;
  }
  return Math.round(value * 100) / 100;
}

/** Разбор суммы на базу, НДС и итог. */
export type SettlementVatBreakdown = {
  /** База без НДС. */
  base: number;
  /** Сумма НДС. */
  vat: number;
  /** Итого с НДС. */
  total: number;
};

/**
 * Разбор введённой суммы в базу, НДС и итог.
 *
 * [entered] — сумма, как её ввёл пользователь. [isVatIncluded] — «НДС в сумме»
 * (true) или «НДС сверху» (false). При нулевой ставке НДС не начисляется.
 * Совпадает с логикой формы в приложении.
 */
export function computeSettlementVat(
  entered: number,
  vatRate: number,
  isVatIncluded: boolean
): SettlementVatBreakdown {
  if (vatRate <= 0 || entered <= 0) {
    const amount = roundMoney(entered);
    return { base: amount, vat: 0, total: amount };
  }

  const base = isVatIncluded
    ? roundMoney((entered * 100) / (100 + vatRate))
    : roundMoney(entered);
  const vat = roundMoney((base * vatRate) / 100);
  return { base, vat, total: roundMoney(base + vat) };
}
