import { getActiveCompanyId } from "@/lib/supabase/company";
import { getRequiredClient } from "@/lib/supabase/client";
import type { CompanyDraft } from "@/features/company/types/company.types";
import { toCompanyUpdatePayload } from "@/features/company/utils/company.utils";

/**
 * Сохраняет реквизиты активной компании.
 * Отправляет только разрешённые поля (без владельца и активности).
 * Изменять компанию может только владелец — это проверяет база.
 */
export async function updateCompany(draft: CompanyDraft): Promise<void> {
  const nameFull = draft.nameFull.trim();
  const nameShort = draft.nameShort.trim();

  if (!nameFull) {
    throw new Error("Введите полное наименование");
  }
  if (!nameShort) {
    throw new Error("Введите краткое наименование");
  }

  const companyId = await getActiveCompanyId();
  const { error } = await getRequiredClient()
    .from("companies")
    .update(toCompanyUpdatePayload(draft))
    .eq("id", companyId);

  if (error) {
    throw new Error(companyUpdateErrorMessage(error.message));
  }
}

function companyUpdateErrorMessage(message: string): string {
  const text = message.toLowerCase();
  if (text.includes("row-level security") || text.includes("permission denied")) {
    return "Менять данные компании может только владелец.";
  }
  if (text.includes("duplicate") || text.includes("unique")) {
    return "Такие данные уже используются.";
  }
  return "Не удалось сохранить компанию. Попробуйте позже.";
}
