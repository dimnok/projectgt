import type { CompanyDraft } from "@/features/company/types/company.types";
import { getRequiredClient } from "@/lib/supabase/client";

/**
 * Creates a company for the signed-in user via `create_company_for_user`.
 * The function makes the caller the owner and sets it as the active company.
 */
export async function createCompany(draft: CompanyDraft): Promise<string> {
  const nameFull = draft.nameFull.trim();
  const nameShort = draft.nameShort.trim();

  if (!nameFull) {
    throw new Error("Введите полное наименование");
  }
  if (!nameShort) {
    throw new Error("Введите краткое наименование");
  }

  const { data, error } = await getRequiredClient().rpc("create_company_for_user", {
    p_data: {
      name_full: nameFull,
      name_short: nameShort,
      inn: draft.inn.trim(),
      kpp: draft.kpp.trim(),
      ogrn: draft.ogrn.trim(),
      okpo: draft.okpo.trim(),
      legal_address: draft.legalAddress.trim(),
      actual_address: draft.actualAddress.trim(),
      director_name: draft.directorName.trim(),
      director_position: draft.directorPosition.trim(),
      director_basis: draft.directorBasis.trim(),
      director_phone: draft.directorPhone.trim(),
      chief_accountant_name: draft.chiefAccountantName.trim(),
      chief_accountant_phone: draft.chiefAccountantPhone.trim(),
      contact_person: draft.contactPerson.trim(),
      website: draft.website.trim(),
      email: draft.email.trim(),
      phone: draft.phone.trim(),
      activity_description: draft.activityDescription.trim(),
      taxation_system: draft.taxationSystem.trim(),
      is_vat_payer: draft.isVatPayer,
      vat_rate: Number(draft.vatRate) || 0,
    },
  });

  if (error) {
    throw new Error(companyErrorMessage(error.message));
  }

  return data as string;
}

function companyErrorMessage(message: string): string {
  const text = message.toLowerCase();
  if (text.includes("not_authenticated")) {
    return "Войдите в аккаунт.";
  }
  if (text.includes("invalid_company_name")) {
    return "Укажите полное и краткое наименование организации.";
  }
  if (text.includes("create_company_for_user") || text.includes("does not exist")) {
    return "Создание организации недоступно. Обратитесь к администратору.";
  }
  return "Не удалось создать организацию. Попробуйте позже.";
}
