import type { ContractKind } from "@/features/contracts/utils/contract-kind";
import type { ContractStatus } from "@/features/contracts/utils/contract-status";

export type Contract = {
  id: string;
  companyId: string;
  number: string;
  date: string;
  endDate: string | null;
  contractorId: string;
  contractorName: string;
  objectId: string;
  objectName: string;
  amount: number;
  vatRate: number;
  isVatIncluded: boolean;
  vatAmount: number;
  advanceAmount: number;
  warrantyRetentionAmount: number;
  warrantyRetentionRate: number;
  warrantyPeriodMonths: number;
  generalContractorFeeAmount: number;
  generalContractorFeeRate: number;
  status: ContractStatus;
  kind: ContractKind;
  contractorLegalName: string | null;
  contractorPosition: string | null;
  contractorSigner: string | null;
  customerLegalName: string | null;
  customerPosition: string | null;
  customerSigner: string | null;
};

export type ContractDraft = {
  number: string;
  kind: ContractKind;
  date: string;
  endDate: string;
  contractorId: string;
  objectId: string;
  amount: string;
  vatRate: string;
  isVatIncluded: boolean;
  advanceAmount: string;
  warrantyRetentionRate: string;
  warrantyRetentionAmount: string;
  warrantyPeriodMonths: string;
  generalContractorFeeRate: string;
  generalContractorFeeAmount: string;
  status: ContractStatus;
  contractorLegalName: string;
  contractorPosition: string;
  contractorSigner: string;
  customerLegalName: string;
  customerPosition: string;
  customerSigner: string;
};

export type ContractFilters = {
  search: string;
  kind: ContractKind | "all";
  status: ContractStatus | "all";
};

export type ContractPickItem = {
  id: string;
  label: string;
};
