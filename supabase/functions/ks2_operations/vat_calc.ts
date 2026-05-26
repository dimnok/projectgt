/** Параметры НДС договора. */
export type ContractVatTerms = {
  vatRate: number;
  isVatIncluded: boolean;
};

/** Округление до копеек. */
export function roundMoney(value: number): number {
  if (!Number.isFinite(value)) return 0;
  return Math.round(value * 100) / 100;
}

/** НДС от суммы по правилам договора. */
export function computeVatAmount(
  baseAmount: number,
  terms: ContractVatTerms,
): number {
  const { vatRate, isVatIncluded } = terms;
  if (vatRate <= 0 || baseAmount <= 0) return 0;
  const raw = isVatIncluded
    ? (baseAmount * vatRate) / (100 + vatRate)
    : (baseAmount * vatRate) / 100;
  return roundMoney(raw);
}

/** Итог строк ВОР без НДС → `amount` + начисленный сверху `vat_amount`. */
export function splitActAmountForStorage(
  lineTotal: number,
  terms: ContractVatTerms,
): { amount: number; vatAmount: number } {
  if (!Number.isFinite(lineTotal) || lineTotal <= 0) {
    return { amount: 0, vatAmount: 0 };
  }
  const amount = roundMoney(lineTotal);
  if (terms.vatRate <= 0) {
    return { amount, vatAmount: 0 };
  }
  return {
    amount,
    vatAmount: computeVatAmount(amount, {
      vatRate: terms.vatRate,
      isVatIncluded: false,
    }),
  };
}

type VatTermsRow = {
  vat_rate: string | number | null;
  is_vat_included: boolean | null;
};

/** Загружает ставку и режим НДС договора. */
export async function loadContractVatTerms(
  supabase: {
    from: (table: string) => {
      select: (cols: string) => {
        eq: (col: string, val: string) => {
          eq: (col: string, val: string) => {
            maybeSingle: () => Promise<{
              data: VatTermsRow | null;
              error: unknown;
            }>;
          };
        };
      };
    };
  },
  contractId: string,
  companyId: string,
): Promise<ContractVatTerms> {
  const { data, error } = await supabase
    .from("contracts")
    .select("vat_rate, is_vat_included")
    .eq("id", contractId)
    .eq("company_id", companyId)
    .maybeSingle();

  if (error) throw error;
  if (!data) throw new Error("Договор не найден");

  const rateRaw = data.vat_rate;
  const vatRate = rateRaw == null ? 0 : Number(rateRaw);
  return {
    vatRate: Number.isFinite(vatRate) ? vatRate : 0,
    isVatIncluded: data.is_vat_included ?? true,
  };
}
