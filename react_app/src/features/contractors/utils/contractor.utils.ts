import type {
  Contractor,
  ContractorDraft,
  ContractorFilters,
} from "@/features/contractors/types/contractor.types";
import type { ContractorsRow } from "@/types/database.types";
import {
  isContractorType,
  type ContractorType,
} from "@/features/contractors/utils/contractor-type";
import { formatOkvedLabel, toStoredOkved } from "@/lib/okved/okved";

export const CONTRACTOR_SELECT =
  "id, company_id, full_name, short_name, inn, type, director, legal_address, actual_address, phone, email, website, activity_description, kpp, ogrn, okpo, director_basis, director_phone, chief_accountant_name, chief_accountant_phone, contact_person, taxation_system, is_vat_payer, vat_rate";

function text(value: string | null | undefined): string {
  return value?.trim() ?? "";
}

/**
 * Keeps only digits and caps length at 12 (legal entity 10, individual 12).
 */
export function digitsInn(value: string): string {
  return value.replace(/\D/g, "").slice(0, 12);
}

/**
 * Returns true when the value is a 10- or 12-digit INN.
 */
export function isValidInn(value: string): boolean {
  return /^\d{10}$/.test(value) || /^\d{12}$/.test(value);
}

/**
 * Finds another contractor in the same list with the same INN digits.
 */
export function findContractorByInn(
  contractors: Contractor[],
  inn: string,
  excludeId?: string
): Contractor | undefined {
  const digits = digitsInn(inn);
  if (!digits) {
    return undefined;
  }

  return contractors.find(
    (contractor) =>
      contractor.id !== excludeId && digitsInn(contractor.inn) === digits
  );
}

export function duplicateInnMessage(contractor: Contractor): string {
  const name = contractor.shortName || contractor.fullName;
  return `Контрагент с таким ИНН уже есть: ${name}`;
}

/**
 * Maps a Supabase write error to a user-facing message.
 */
export function contractorWriteError(error: {
  code?: string;
  message: string;
}): Error {
  if (error.code === "23505") {
    return new Error("Контрагент с таким ИНН уже есть");
  }
  return new Error(error.message);
}

function optionalText(value: string): string | null {
  const trimmed = value.trim();
  return trimmed ? trimmed : null;
}

function toNumber(value: unknown): number {
  if (typeof value === "number" && Number.isFinite(value)) {
    return value;
  }
  if (typeof value === "string") {
    const parsed = Number(value.replace(",", "."));
    return Number.isFinite(parsed) ? parsed : 0;
  }
  return 0;
}

export function mapContractorRow(row: ContractorsRow): Contractor {
  return {
    id: row.id,
    companyId: row.company_id,
    fullName: text(row.full_name),
    shortName: text(row.short_name),
    inn: text(row.inn),
    type: isContractorType(row.type) ? row.type : "customer",
    director: text(row.director),
    legalAddress: text(row.legal_address),
    actualAddress: text(row.actual_address),
    phone: text(row.phone),
    email: text(row.email),
    website: optionalText(row.website ?? ""),
    activityDescription: optionalText(row.activity_description ?? ""),
    kpp: optionalText(row.kpp ?? ""),
    ogrn: optionalText(row.ogrn ?? ""),
    okpo: optionalText(row.okpo ?? ""),
    directorBasis: optionalText(row.director_basis ?? ""),
    directorPhone: optionalText(row.director_phone ?? ""),
    chiefAccountantName: optionalText(row.chief_accountant_name ?? ""),
    chiefAccountantPhone: optionalText(row.chief_accountant_phone ?? ""),
    contactPerson: optionalText(row.contact_person ?? ""),
    taxationSystem: optionalText(row.taxation_system ?? ""),
    isVatPayer: Boolean(row.is_vat_payer),
    vatRate: toNumber(row.vat_rate),
  };
}

export function toContractorPayload(draft: ContractorDraft) {
  const vatRate = draft.isVatPayer ? toNumber(draft.vatRate) : 0;

  return {
    full_name: draft.fullName.trim(),
    short_name: draft.shortName.trim(),
    inn: digitsInn(draft.inn),
    type: draft.type,
    director: draft.director.trim(),
    legal_address: optionalText(draft.legalAddress),
    actual_address: optionalText(draft.actualAddress),
    phone: optionalText(draft.phone),
    email: optionalText(draft.email),
    website: optionalText(draft.website),
    activity_description: optionalText(toStoredOkved(draft.activityDescription)),
    kpp: optionalText(draft.kpp),
    ogrn: optionalText(draft.ogrn),
    okpo: optionalText(draft.okpo),
    director_basis: optionalText(draft.directorBasis),
    director_phone: optionalText(draft.directorPhone),
    chief_accountant_name: optionalText(draft.chiefAccountantName),
    chief_accountant_phone: optionalText(draft.chiefAccountantPhone),
    contact_person: optionalText(draft.contactPerson),
    taxation_system: optionalText(draft.taxationSystem),
    is_vat_payer: draft.isVatPayer,
    vat_rate: vatRate,
  };
}

export function sortContractorsByName(contractors: Contractor[]): Contractor[] {
  return [...contractors].sort((a, b) =>
    a.shortName.localeCompare(b.shortName, "ru", { sensitivity: "base" })
  );
}

export function filterContractors(
  contractors: Contractor[],
  filters: ContractorFilters
): Contractor[] {
  const query = filters.search.trim().toLowerCase();

  return contractors.filter((contractor) => {
    if (filters.type !== "all" && contractor.type !== filters.type) {
      return false;
    }
    if (!query) {
      return true;
    }
    const haystack = [
      contractor.shortName,
      contractor.fullName,
      contractor.inn,
      contractor.director,
      contractor.email,
      contractor.phone,
      contractor.phone.replace(/\D/g, ""),
      contractor.activityDescription ?? "",
      formatOkvedLabel(contractor.activityDescription) ?? "",
    ]
      .join(" ")
      .toLowerCase();
    return haystack.includes(query);
  });
}

export function formatContractorCount(count: number): string {
  const n10 = count % 10;
  const n100 = count % 100;
  if (n10 === 1 && n100 !== 11) {
    return `${count} контрагент`;
  }
  if (n10 >= 2 && n10 <= 4 && (n100 < 12 || n100 > 14)) {
    return `${count} контрагента`;
  }
  return `${count} контрагентов`;
}

export function countContractorsByType(contractors: Contractor[]) {
  const byType: Record<ContractorType, number> = {
    customer: 0,
    contractor: 0,
    supplier: 0,
  };

  for (const contractor of contractors) {
    byType[contractor.type] += 1;
  }

  return {
    total: contractors.length,
    byType,
  };
}

export function formatVatRate(rate: number): string {
  return Number.isInteger(rate) ? `${rate}` : String(rate);
}
