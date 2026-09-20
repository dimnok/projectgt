import { getActiveCompanyId } from "@/lib/supabase/company";
import { getRequiredClient } from "@/lib/supabase/client";
import type { CompaniesRow } from "@/types/database.types";
import type { CompanyProfile } from "@/features/company/types/company.types";
import { COMPANY_SELECT, mapCompanyRow } from "@/features/company/utils/company.utils";

/**
 * Загружает карточку активной компании пользователя.
 * Возвращает `null`, если компания не выбрана или не найдена (без ошибки).
 */
export async function getCompany(): Promise<CompanyProfile | null> {
  const client = getRequiredClient();
  const companyId = await getActiveCompanyId();

  const { data, error } = await client
    .from("companies")
    .select(COMPANY_SELECT)
    .eq("id", companyId)
    .maybeSingle();

  if (error) {
    throw new Error(error.message);
  }

  if (!data) {
    return null;
  }

  return mapCompanyRow(data as unknown as CompaniesRow & Record<string, unknown>);
}
