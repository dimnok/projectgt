export type EstimateFile = {
  key: string;
  estimateTitle: string;
  objectId: string | null;
  objectName: string;
  contractId: string | null;
  contractNumber: string;
  itemsCount: number;
  total: number;
  completionPercent: number;
};

export type EstimateContractGroup = {
  key: string;
  contractId: string | null;
  contractNumber: string;
  total: number;
  files: EstimateFile[];
};

export type EstimateObjectGroup = {
  key: string;
  objectId: string | null;
  objectName: string;
  total: number;
  contracts: EstimateContractGroup[];
};

export type EstimateItem = {
  id: string;
  companyId: string;
  system: string;
  subsystem: string;
  number: string;
  name: string;
  article: string;
  manufacturer: string;
  unit: string;
  quantity: number;
  price: number;
  total: number;
  createdAt?: string | null;
  createdByName?: string | null;
  estimateTitle?: string;
  objectId?: string | null;
  contractId?: string | null;
};

export type EstimateItemFieldChange = {
  from?: unknown;
  to?: unknown;
};

export type EstimateItemEditHistoryEntry = {
  id: string;
  createdAt: string;
  action: string;
  userName: string;
  changes: Record<string, EstimateItemFieldChange>;
};

export type EstimateCompletion = {
  estimateId: string;
  completedQuantity: number;
  remainingQuantity: number;
};

export type EstimateExecution = {
  completedQuantity: number;
  completedTotal: number;
  remainingQuantity: number;
  remainingTotal: number;
};

export type EstimateCompletionHistoryEntry = {
  id: string;
  date: string;
  quantity: number;
  section: string;
  floor: string;
  openedByName: string;
};

export type EstimateFileQuery = {
  estimateTitle?: string | null;
  objectId?: string | null;
  contractId?: string | null;
};
