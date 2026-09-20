/**
 * Minimal database types for migrated tables.
 * Replace with generated Supabase types when the client is connected.
 */
export type ObjectsRow = {
  id: string;
  company_id: string;
  name: string;
  address: string;
  description: string | null;
  status: "active" | "paused" | "completed";
};

export type ContractorsRow = {
  id: string;
  company_id: string;
  full_name: string;
  short_name: string;
  inn: string;
  type: string | null;
  director: string | null;
  legal_address: string | null;
  actual_address: string | null;
  phone: string | null;
  email: string | null;
  website: string | null;
  activity_description: string | null;
  kpp: string | null;
  ogrn: string | null;
  okpo: string | null;
  director_basis: string | null;
  director_phone: string | null;
  chief_accountant_name: string | null;
  chief_accountant_phone: string | null;
  contact_person: string | null;
  taxation_system: string | null;
  is_vat_payer: boolean | null;
  vat_rate: number | string | null;
};

export type ContractorBankAccountsRow = {
  id: string;
  company_id: string | null;
  contractor_id: string;
  bank_name: string;
  bank_city: string | null;
  bik: string | null;
  corr_account: string | null;
  account_number: string;
  is_primary: boolean | null;
};

export type ContractsRow = {
  id: string;
  company_id: string;
  number: string;
  date: string;
  end_date: string | null;
  contractor_id: string | null;
  amount: number | string | null;
  object_id: string | null;
  status: string;
  contract_kind: string;
  vat_rate: number | string | null;
  is_vat_included: boolean | null;
  vat_amount: number | string | null;
  advance_amount: number | string | null;
  warranty_retention_amount: number | string | null;
  warranty_retention_rate: number | string | null;
  warranty_period_months: number | null;
  general_contractor_fee_amount: number | string | null;
  general_contractor_fee_rate: number | string | null;
  contractor_legal_name: string | null;
  contractor_position: string | null;
  contractor_signer: string | null;
  customer_legal_name: string | null;
  customer_position: string | null;
  customer_signer: string | null;
};

export type ContractJoinRow = ContractsRow & {
  contractor: { short_name: string | null; full_name: string | null } | null;
  object: { name: string | null } | null;
};

export type EstimateGroupRow = {
  estimate_title: string | null;
  object_id: string | null;
  contract_id: string | null;
  contract_number: string | null;
  items_count: number | string | null;
  total_amount: number | string | null;
  completion_percent: number | string | null;
};

export type EstimateItemRow = {
  id: string;
  company_id: string;
  system: string | null;
  subsystem: string | null;
  number: string | number | null;
  name: string | null;
  article: string | null;
  manufacturer: string | null;
  unit: string | null;
  quantity: number | string | null;
  price: number | string | null;
  total: number | string | null;
  created_at?: string | null;
  created_by_name?: string | null;
  estimate_title?: string | null;
  object_id?: string | null;
  contract_id?: string | null;
};

export type EstimateCompletionRow = {
  estimate_id: string | null;
  completed_quantity: number | string | null;
  remaining_quantity: number | string | null;
};

export type EmployeesRow = {
  id: string;
  company_id: string;
  photo_url: string | null;
  last_name: string;
  first_name: string;
  middle_name: string | null;
  birth_date: string | null;
  birth_place: string | null;
  citizenship: string | null;
  phone: string | null;
  clothing_size: string | null;
  shoe_size: string | null;
  height: string | null;
  employment_date: string | null;
  employment_type: string;
  position: string | null;
  status: string;
  include_in_timesheet: boolean;
  object_ids: string[] | null;
  passport_series: string | null;
  passport_number: string | null;
  passport_issued_by: string | null;
  passport_issue_date: string | null;
  passport_department_code: string | null;
  registration_address: string | null;
  inn: string | null;
  snils: string | null;
  kig: string | null;
  patent_number: string | null;
};

export type EmployeeRatesRow = {
  id?: string;
  company_id?: string;
  employee_id: string;
  hourly_rate: number | string | null;
  valid_from?: string;
  valid_to?: string | null;
  created_at?: string | null;
  created_by?: string | null;
};

export type BusinessTripRatesRow = {
  id: string;
  company_id: string;
  object_id: string;
  employee_id: string | null;
  rate: number | string;
  minimum_hours: number | string | null;
  valid_from: string;
  valid_to: string | null;
  created_at: string | null;
  updated_at: string | null;
  created_by: string | null;
};

export type EmployeePositionRow = {
  position_name: string | null;
};

export type ProfilesRow = {
  id: string;
  full_name: string | null;
  short_name: string | null;
  photo_url: string | null;
  email: string;
  phone: string | null;
  status: boolean | null;
  employee_id: string | null;
  last_company_id: string | null;
  object_ids: string[] | null;
  prefer_web_app?: boolean | null;
  slot_times: string[] | null;
  telegram_user_id: number | null;
  created_at: string | null;
};

export type CompanyMembersRow = {
  company_id: string;
  user_id: string;
  system_role: string | null;
  role_id: string | null;
  is_active: boolean | null;
  is_owner: boolean | null;
};

export type CompaniesRow = {
  id: string;
  name_full: string | null;
  name_short: string | null;
  min_output_per_person_hour?: number | string | null;
};

export type RolesRow = {
  id: string;
  role_name: string | null;
};

export type SettlementOperationsRow = {
  id: string;
  company_id: string;
  operation_type: string;
  object_id: string;
  contractor_id: string;
  contract_id: string;
  period_from: string | null;
  period_to: string | null;
  act_number: string | null;
  act_date: string | null;
  invoice_number: string;
  invoice_date: string;
  amount: number | string;
  is_vat_included: boolean;
  vat_rate: number | string | null;
  vat_amount: number | string;
  advance_retention: number | string;
  warranty_retention: number | string;
  total_to_pay: number | string;
  paid_amount: number | string;
  payment_status: string;
  purpose: string | null;
  note: string | null;
  created_at: string | null;
  created_by: string | null;
};

export type SettlementOperationJoinRow = SettlementOperationsRow & {
  objects: { name: string | null } | null;
  contractors: { short_name: string | null } | null;
  contracts: { number: string | null } | null;
};

/** Строка страницы реестра из функции `get_settlements_page`. */
export type SettlementOperationsListRow = SettlementOperationsRow & {
  object_name: string | null;
  contractor_name: string | null;
  contract_number: string | null;
};

/** Ответ функции `get_settlements_page`: страница строк и общее число счетов. */
export type SettlementListPageRow = {
  items: SettlementOperationsListRow[];
  total_count: number | string;
};

/** Итоги реестра из функции `get_settlements_summary`. */
export type SettlementSummaryRow = {
  total_count: number | string;
  total_amount: number | string;
  total_paid: number | string;
  total_debt: number | string;
  by_status: Record<string, number> | null;
};

export type SettlementPaymentsRow = {
  id: string;
  company_id: string;
  settlement_operation_id: string;
  payment_date: string;
  amount: number | string;
  note: string | null;
  cash_flow_transaction_id: string | null;
  created_at: string | null;
  created_by: string | null;
};

export type SettlementFilesRow = {
  id: string;
  company_id: string;
  settlement_operation_id: string;
  name: string;
  file_path: string;
  size: number | string;
  type: string;
  description: string | null;
  created_at: string | null;
  created_by: string | null;
};
