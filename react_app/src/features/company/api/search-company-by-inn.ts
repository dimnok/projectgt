import type { CompanyInnSuggestion } from "@/features/company/types/company.types";
import { getRequiredClient } from "@/lib/supabase/client";

/**
 * Looks up company details by INN via the `dadata-proxy` Edge function.
 * Returns `null` when the company is not found.
 */
export async function searchCompanyByInn(
  inn: string
): Promise<CompanyInnSuggestion | null> {
  const value = inn.trim();
  if (value.length < 10) {
    throw new Error("Введите корректный ИНН (10 или 12 цифр)");
  }

  const { data, error } = await getRequiredClient().functions.invoke(
    "dadata-proxy",
    { body: { inn: value } }
  );

  if (error) {
    throw new Error("Не удалось получить данные. Попробуйте позже.");
  }

  if (!data) {
    return null;
  }

  return data as CompanyInnSuggestion;
}
