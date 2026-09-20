import type { CompaniesRow } from "@/types/database.types";
import type { CompanyDraft, CompanyProfile } from "@/features/company/types/company.types";

export const COMPANY_SELECT = [
  "id",
  "name_full",
  "name_short",
  "logo_url",
  "website",
  "email",
  "phone",
  "activity_description",
  "inn",
  "kpp",
  "ogrn",
  "okpo",
  "legal_address",
  "actual_address",
  "director_name",
  "director_position",
  "director_basis",
  "director_phone",
  "chief_accountant_name",
  "chief_accountant_phone",
  "contact_person",
  "taxation_system",
  "is_vat_payer",
  "vat_rate",
  "owner_id",
  "is_active",
].join(", ");

type CompanyQueryRow = CompaniesRow & Record<string, unknown>;

function asString(value: unknown): string | null {
  if (typeof value !== "string") {
    return null;
  }
  const trimmed = value.trim();
  return trimmed ? trimmed : null;
}

export function mapCompanyRow(row: CompanyQueryRow): CompanyProfile {
  const vatRate = Number(row.vat_rate ?? 0);
  return {
    id: row.id,
    nameFull: asString(row.name_full) ?? "",
    nameShort: asString(row.name_short) ?? "",
    logoUrl: asString(row.logo_url),
    website: asString(row.website),
    email: asString(row.email),
    phone: asString(row.phone),
    activityDescription: asString(row.activity_description),
    inn: asString(row.inn),
    kpp: asString(row.kpp),
    ogrn: asString(row.ogrn),
    okpo: asString(row.okpo),
    legalAddress: asString(row.legal_address),
    actualAddress: asString(row.actual_address),
    directorName: asString(row.director_name),
    directorPosition: asString(row.director_position),
    directorBasis: asString(row.director_basis),
    directorPhone: asString(row.director_phone),
    chiefAccountantName: asString(row.chief_accountant_name),
    chiefAccountantPhone: asString(row.chief_accountant_phone),
    contactPerson: asString(row.contact_person),
    taxationSystem: asString(row.taxation_system),
    isVatPayer: row.is_vat_payer === true,
    vatRate: Number.isFinite(vatRate) ? vatRate : 0,
    ownerId: asString(row.owner_id),
    isActive: row.is_active !== false,
  };
}

function emptyToNull(value: string): string | null {
  const trimmed = value.trim();
  return trimmed ? trimmed : null;
}

/**
 * Поля, которые веб разрешает менять. Владелец и активность не отправляются:
 * их нельзя затирать при сохранении карточки.
 */
export function toCompanyUpdatePayload(draft: CompanyDraft) {
  const vatRate = Number(draft.vatRate);
  return {
    name_full: draft.nameFull.trim(),
    name_short: draft.nameShort.trim(),
    website: emptyToNull(draft.website),
    email: emptyToNull(draft.email),
    phone: emptyToNull(draft.phone),
    activity_description: emptyToNull(draft.activityDescription),
    inn: emptyToNull(draft.inn),
    kpp: emptyToNull(draft.kpp),
    ogrn: emptyToNull(draft.ogrn),
    okpo: emptyToNull(draft.okpo),
    legal_address: emptyToNull(draft.legalAddress),
    actual_address: emptyToNull(draft.actualAddress),
    director_name: emptyToNull(draft.directorName),
    director_position: emptyToNull(draft.directorPosition),
    director_basis: emptyToNull(draft.directorBasis),
    director_phone: emptyToNull(draft.directorPhone),
    chief_accountant_name: emptyToNull(draft.chiefAccountantName),
    chief_accountant_phone: emptyToNull(draft.chiefAccountantPhone),
    contact_person: emptyToNull(draft.contactPerson),
    taxation_system: emptyToNull(draft.taxationSystem),
    is_vat_payer: draft.isVatPayer,
    vat_rate: Number.isFinite(vatRate) ? vatRate : 0,
    updated_at: new Date().toISOString(),
  };
}

/** Заполняет черновик формы из карточки компании. */
export function companyToDraft(company: CompanyProfile): CompanyDraft {
  return {
    nameFull: company.nameFull,
    nameShort: company.nameShort,
    inn: company.inn ?? "",
    kpp: company.kpp ?? "",
    ogrn: company.ogrn ?? "",
    okpo: company.okpo ?? "",
    legalAddress: company.legalAddress ?? "",
    actualAddress: company.actualAddress ?? "",
    directorName: company.directorName ?? "",
    directorPosition: company.directorPosition ?? "",
    directorBasis: company.directorBasis ?? "",
    directorPhone: company.directorPhone ?? "",
    chiefAccountantName: company.chiefAccountantName ?? "",
    chiefAccountantPhone: company.chiefAccountantPhone ?? "",
    contactPerson: company.contactPerson ?? "",
    website: company.website ?? "",
    email: company.email ?? "",
    phone: company.phone ?? "",
    activityDescription: company.activityDescription ?? "",
    taxationSystem: company.taxationSystem ?? "",
    isVatPayer: company.isVatPayer,
    vatRate: company.vatRate ? String(company.vatRate) : "0",
  };
}

export function digitsOnly(value: string, max?: number): string {
  const digits = value.replace(/\D/g, "");
  return max ? digits.slice(0, max) : digits;
}

/** Проверки реквизитов. Пустое поле допустимо — проверяем только заполненные. */
export function validateDigits(
  value: string,
  lengths: number[],
  label: string
): string | null {
  const digits = digitsOnly(value);
  if (!digits) {
    return null;
  }
  return lengths.includes(digits.length)
    ? null
    : `${label}: нужно ${lengths.join(" или ")} цифр`;
}

export const companyValidators = {
  inn: (value: string) => validateDigits(value, [10, 12], "ИНН"),
  kpp: (value: string) => validateDigits(value, [9], "КПП"),
  ogrn: (value: string) => validateDigits(value, [13, 15], "ОГРН"),
  okpo: (value: string) => validateDigits(value, [8, 10], "ОКПО"),
  bik: (value: string) => validateDigits(value, [9], "БИК"),
  account: (value: string) => validateDigits(value, [20], "Счёт"),
};
