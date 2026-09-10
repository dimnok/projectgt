import type { ContractorType } from "@/features/contractors/utils/contractor-type";

export type Contractor = {
  id: string;
  companyId: string;
  fullName: string;
  shortName: string;
  inn: string;
  type: ContractorType;
  director: string;
  legalAddress: string;
  actualAddress: string;
  phone: string;
  email: string;
  website: string | null;
  activityDescription: string | null;
  kpp: string | null;
  ogrn: string | null;
  okpo: string | null;
  directorBasis: string | null;
  directorPhone: string | null;
  chiefAccountantName: string | null;
  chiefAccountantPhone: string | null;
  contactPerson: string | null;
  taxationSystem: string | null;
  isVatPayer: boolean;
  vatRate: number;
};

export type ContractorDraft = {
  fullName: string;
  shortName: string;
  inn: string;
  type: ContractorType;
  director: string;
  legalAddress: string;
  actualAddress: string;
  phone: string;
  email: string;
  website: string;
  activityDescription: string;
  kpp: string;
  ogrn: string;
  okpo: string;
  directorBasis: string;
  directorPhone: string;
  chiefAccountantName: string;
  chiefAccountantPhone: string;
  contactPerson: string;
  taxationSystem: string;
  isVatPayer: boolean;
  vatRate: string;
};

export type ContractorFilters = {
  search: string;
  type: ContractorType | "all";
};

/**
 * Payload returned by Edge Function `dadata-proxy`.
 * Same shape as Flutter `searchCompanyByInn`.
 */
export type ContractorInnLookup = {
  nameFull: string | null;
  nameShort: string | null;
  kpp: string | null;
  ogrn: string | null;
  okpo: string | null;
  legalAddress: string | null;
  directorName: string | null;
  activityDescription: string | null;
  email: string | null;
  phone: string | null;
};

export type ContractorBankAccount = {
  id: string;
  companyId: string;
  contractorId: string;
  bankName: string;
  bankCity: string | null;
  bik: string | null;
  corrAccount: string | null;
  accountNumber: string;
  isPrimary: boolean;
};

export type ContractorBankAccountDraft = {
  bankName: string;
  bik: string;
  accountNumber: string;
  corrAccount: string;
  isPrimary: boolean;
};
