import type {
  Contract,
  ContractDraft,
  ContractFilters,
} from "@/features/contracts/types/contract.types";
import type { ContractJoinRow } from "@/types/database.types";
import { isContractKind } from "@/features/contracts/utils/contract-kind";
import {
  isContractStatus,
  type ContractStatus,
} from "@/features/contracts/utils/contract-status";

export const CONTRACT_SELECT = [
  "id",
  "company_id",
  "number",
  "date",
  "end_date",
  "contractor_id",
  "amount",
  "object_id",
  "status",
  "contract_kind",
  "vat_rate",
  "is_vat_included",
  "vat_amount",
  "advance_amount",
  "warranty_retention_amount",
  "warranty_retention_rate",
  "warranty_period_months",
  "general_contractor_fee_amount",
  "general_contractor_fee_rate",
  "contractor_legal_name",
  "contractor_position",
  "contractor_signer",
  "customer_legal_name",
  "customer_position",
  "customer_signer",
  "contractor:contractors(short_name, full_name)",
  "object:objects(name)",
].join(", ");

function text(value: string | null | undefined): string {
  return value?.trim() ?? "";
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

export function parseAmount(value: string): number | null {
  const normalized = value
    .replace(/\u00A0|\u202F/g, "")
    .replace(/\s/g, "")
    .replace(",", ".");
  if (!normalized) {
    return 0;
  }
  const parsed = Number(normalized);
  return Number.isFinite(parsed) ? parsed : null;
}

function roundMoney(value: number): number {
  if (!Number.isFinite(value)) {
    return 0;
  }
  return Math.round(value * 100) / 100;
}

/**
 * VAT from the contract amount. Matches Flutter `computeVatAmount`.
 */
export function computeVatAmount(
  baseAmount: number,
  vatRate: number,
  isVatIncluded: boolean
): number {
  if (vatRate <= 0 || baseAmount <= 0) {
    return 0;
  }
  const raw = isVatIncluded
    ? (baseAmount * vatRate) / (100 + vatRate)
    : (baseAmount * vatRate) / 100;
  return roundMoney(raw);
}

export function formatCurrency(value: number): string {
  return new Intl.NumberFormat("ru-RU", {
    style: "currency",
    currency: "RUB",
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  }).format(value);
}

export function formatRuDate(value: string | null): string {
  if (!value) {
    return "";
  }
  const [year, month, day] = value.split("-");
  if (!year || !month || !day) {
    return value;
  }
  return `${day}.${month}.${year}`;
}

function todayDateInput(): string {
  const now = new Date();
  const year = now.getFullYear();
  const month = String(now.getMonth() + 1).padStart(2, "0");
  const day = String(now.getDate()).padStart(2, "0");
  return `${year}-${month}-${day}`;
}

export function daysUntilEnd(endDate: string | null): number | null {
  if (!endDate) {
    return null;
  }
  const [year, month, day] = endDate.split("-").map(Number);
  if (!year || !month || !day) {
    return null;
  }
  const today = new Date();
  const start = Date.UTC(today.getFullYear(), today.getMonth(), today.getDate());
  const end = Date.UTC(year, month - 1, day);
  return Math.round((end - start) / 86_400_000);
}

function joinName(
  value: { short_name?: string | null; full_name?: string | null; name?: string | null } | null,
  fallbackKeys: Array<"short_name" | "full_name" | "name">
): string {
  if (!value) {
    return "";
  }
  for (const key of fallbackKeys) {
    const next = text(value[key]);
    if (next) {
      return next;
    }
  }
  return "";
}

export function mapContractRow(row: ContractJoinRow): Contract {
  return {
    id: row.id,
    companyId: row.company_id,
    number: text(row.number),
    date: row.date,
    endDate: row.end_date,
    contractorId: row.contractor_id ?? "",
    contractorName: joinName(row.contractor, ["short_name", "full_name"]),
    objectId: row.object_id ?? "",
    objectName: joinName(row.object, ["name"]),
    amount: toNumber(row.amount),
    vatRate: toNumber(row.vat_rate),
    isVatIncluded: row.is_vat_included ?? true,
    vatAmount: toNumber(row.vat_amount),
    advanceAmount: toNumber(row.advance_amount),
    warrantyRetentionAmount: toNumber(row.warranty_retention_amount),
    warrantyRetentionRate: toNumber(row.warranty_retention_rate),
    warrantyPeriodMonths: row.warranty_period_months ?? 0,
    generalContractorFeeAmount: toNumber(row.general_contractor_fee_amount),
    generalContractorFeeRate: toNumber(row.general_contractor_fee_rate),
    status: isContractStatus(row.status) ? row.status : "active",
    kind: isContractKind(row.contract_kind) ? row.contract_kind : "customer",
    contractorLegalName: optionalText(row.contractor_legal_name ?? ""),
    contractorPosition: optionalText(row.contractor_position ?? ""),
    contractorSigner: optionalText(row.contractor_signer ?? ""),
    customerLegalName: optionalText(row.customer_legal_name ?? ""),
    customerPosition: optionalText(row.customer_position ?? ""),
    customerSigner: optionalText(row.customer_signer ?? ""),
  };
}

function moneyText(value: number): string {
  if (value === 0) {
    return "";
  }
  return String(value);
}

export function toDraft(contract?: Contract | null): ContractDraft {
  return {
    number: contract?.number ?? "",
    kind: contract?.kind ?? "customer",
    date: contract?.date ?? todayDateInput(),
    endDate: contract?.endDate ?? "",
    contractorId: contract?.contractorId ?? "",
    objectId: contract?.objectId ?? "",
    amount: moneyText(contract?.amount ?? 0),
    vatRate: moneyText(contract?.vatRate ?? 0),
    isVatIncluded: contract?.isVatIncluded ?? true,
    advanceAmount: moneyText(contract?.advanceAmount ?? 0),
    warrantyRetentionRate: moneyText(contract?.warrantyRetentionRate ?? 0),
    warrantyRetentionAmount: moneyText(contract?.warrantyRetentionAmount ?? 0),
    warrantyPeriodMonths:
      contract && contract.warrantyPeriodMonths > 0
        ? String(contract.warrantyPeriodMonths)
        : "",
    generalContractorFeeRate: moneyText(contract?.generalContractorFeeRate ?? 0),
    generalContractorFeeAmount: moneyText(
      contract?.generalContractorFeeAmount ?? 0
    ),
    status: contract?.status ?? "active",
    contractorLegalName: contract?.contractorLegalName ?? "",
    contractorPosition: contract?.contractorPosition ?? "",
    contractorSigner: contract?.contractorSigner ?? "",
    customerLegalName: contract?.customerLegalName ?? "",
    customerPosition: contract?.customerPosition ?? "",
    customerSigner: contract?.customerSigner ?? "",
  };
}

export function draftToPayload(draft: ContractDraft) {
  const amount = parseAmount(draft.amount) ?? 0;
  const vatRate = parseAmount(draft.vatRate) ?? 0;

  return {
    number: draft.number.trim(),
    date: draft.date,
    end_date: draft.endDate.trim() || null,
    contractor_id: draft.contractorId,
    object_id: draft.objectId,
    amount,
    vat_rate: vatRate,
    is_vat_included: draft.isVatIncluded,
    vat_amount: computeVatAmount(amount, vatRate, draft.isVatIncluded),
    advance_amount: parseAmount(draft.advanceAmount) ?? 0,
    warranty_retention_rate: parseAmount(draft.warrantyRetentionRate) ?? 0,
    warranty_retention_amount: parseAmount(draft.warrantyRetentionAmount) ?? 0,
    warranty_period_months: Number.parseInt(draft.warrantyPeriodMonths, 10) || 0,
    general_contractor_fee_rate: parseAmount(draft.generalContractorFeeRate) ?? 0,
    general_contractor_fee_amount:
      parseAmount(draft.generalContractorFeeAmount) ?? 0,
    status: draft.status,
    contract_kind: draft.kind,
    contractor_legal_name: optionalText(draft.contractorLegalName),
    contractor_position: optionalText(draft.contractorPosition),
    contractor_signer: optionalText(draft.contractorSigner),
    customer_legal_name: optionalText(draft.customerLegalName),
    customer_position: optionalText(draft.customerPosition),
    customer_signer: optionalText(draft.customerSigner),
  };
}

export function sortContractsByDate(contracts: Contract[]): Contract[] {
  return [...contracts].sort((a, b) => b.date.localeCompare(a.date));
}

export function filterContracts(
  contracts: Contract[],
  filters: ContractFilters
): Contract[] {
  const query = filters.search.trim().toLowerCase();

  return contracts.filter((contract) => {
    if (filters.kind !== "all" && contract.kind !== filters.kind) {
      return false;
    }
    if (filters.status !== "all" && contract.status !== filters.status) {
      return false;
    }
    if (!query) {
      return true;
    }
    const haystack =
      `${contract.number} ${contract.contractorName} ${contract.objectName}`.toLowerCase();
    return haystack.includes(query);
  });
}

export function formatContractCount(count: number): string {
  const n10 = count % 10;
  const n100 = count % 100;
  if (n10 === 1 && n100 !== 11) {
    return `${count} договор`;
  }
  if (n10 >= 2 && n10 <= 4 && (n100 < 12 || n100 > 14)) {
    return `${count} договора`;
  }
  return `${count} договоров`;
}

export function countContractsByStatus(contracts: Contract[]) {
  const byStatus: Record<ContractStatus, number> = {
    active: 0,
    suspended: 0,
    completed: 0,
  };
  let totalAmount = 0;

  for (const contract of contracts) {
    byStatus[contract.status] += 1;
    totalAmount += contract.amount;
  }

  return {
    total: contracts.length,
    totalAmount,
    byStatus,
  };
}

export function contractWriteError(error: {
  code?: string;
  message: string;
}): Error {
  if (error.code === "23503") {
    return new Error("Нельзя удалить договор: к нему уже привязаны данные");
  }
  return new Error(error.message);
}
