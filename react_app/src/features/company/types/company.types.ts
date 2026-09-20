export type CompanyDraft = {
  nameFull: string;
  nameShort: string;
  inn: string;
  kpp: string;
  ogrn: string;
  okpo: string;
  legalAddress: string;
  actualAddress: string;
  directorName: string;
  directorPosition: string;
  directorBasis: string;
  directorPhone: string;
  chiefAccountantName: string;
  chiefAccountantPhone: string;
  contactPerson: string;
  website: string;
  email: string;
  phone: string;
  activityDescription: string;
  taxationSystem: string;
  isVatPayer: boolean;
  vatRate: string;
};

export const emptyCompanyDraft: CompanyDraft = {
  nameFull: "",
  nameShort: "",
  inn: "",
  kpp: "",
  ogrn: "",
  okpo: "",
  legalAddress: "",
  actualAddress: "",
  directorName: "",
  directorPosition: "",
  directorBasis: "",
  directorPhone: "",
  chiefAccountantName: "",
  chiefAccountantPhone: "",
  contactPerson: "",
  website: "",
  email: "",
  phone: "",
  activityDescription: "",
  taxationSystem: "",
  isVatPayer: false,
  vatRate: "0",
};

/** Ответ Edge-функции `dadata-proxy` (поиск организации по ИНН). */
export type CompanyInnSuggestion = {
  nameFull?: string | null;
  nameShort?: string | null;
  inn?: string | null;
  kpp?: string | null;
  ogrn?: string | null;
  okpo?: string | null;
  legalAddress?: string | null;
  directorName?: string | null;
  directorPosition?: string | null;
  activityDescription?: string | null;
  email?: string | null;
  phone?: string | null;
};

/** Системы налогообложения РФ. Совпадают с приложением. */
export const taxationSystems = [
  "ОСНО",
  "УСН «Доходы»",
  "УСН «Доходы минус расходы»",
  "АУСН «Доходы»",
  "АУСН «Доходы минус расходы»",
  "ЕСХН",
] as const;

/** Реквизиты компании из таблицы `companies`. */
export type CompanyProfile = {
  id: string;
  nameFull: string;
  nameShort: string;
  logoUrl: string | null;
  website: string | null;
  email: string | null;
  phone: string | null;
  activityDescription: string | null;
  inn: string | null;
  kpp: string | null;
  ogrn: string | null;
  okpo: string | null;
  legalAddress: string | null;
  actualAddress: string | null;
  directorName: string | null;
  directorPosition: string | null;
  directorBasis: string | null;
  directorPhone: string | null;
  chiefAccountantName: string | null;
  chiefAccountantPhone: string | null;
  contactPerson: string | null;
  taxationSystem: string | null;
  isVatPayer: boolean;
  vatRate: number;
  ownerId: string | null;
  isActive: boolean;
};

export type CompanyBankAccount = {
  id: string;
  companyId: string;
  bankName: string;
  bankCity: string | null;
  accountNumber: string;
  corrAccount: string | null;
  bik: string | null;
  isPrimary: boolean;
};

export type CompanyBankAccountDraft = {
  bankName: string;
  bankCity: string;
  accountNumber: string;
  corrAccount: string;
  bik: string;
  isPrimary: boolean;
};

export type CompanyDocument = {
  id: string;
  companyId: string;
  type: string;
  title: string;
  number: string | null;
  issueDate: string | null;
  expiryDate: string | null;
  fileUrl: string | null;
};

export type CompanyDocumentDraft = {
  type: string;
  title: string;
  number: string;
  issueDate: string;
  expiryDate: string;
  fileUrl: string;
};

export type CompanyInvitation = {
  id: string;
  code: string;
  expiresAt: string;
  usedAt: string | null;
  revokedAt: string | null;
};
