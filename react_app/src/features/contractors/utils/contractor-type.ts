export const CONTRACTOR_TYPES = ["customer", "contractor", "supplier"] as const;

export type ContractorType = (typeof CONTRACTOR_TYPES)[number];

const CONTRACTOR_TYPE_LABELS: Record<ContractorType, string> = {
  customer: "Заказчик",
  contractor: "Подрядчик",
  supplier: "Поставщик",
};

export const CONTRACTOR_TYPE_OPTIONS = CONTRACTOR_TYPES.map((value) => ({
  value,
  label: CONTRACTOR_TYPE_LABELS[value],
}));

export function isContractorType(value: unknown): value is ContractorType {
  return CONTRACTOR_TYPES.includes(value as ContractorType);
}

export function contractorTypeLabel(type: ContractorType): string {
  return CONTRACTOR_TYPE_LABELS[type];
}

export const CONTRACTOR_TYPE_RING_CLASS: Record<ContractorType, string> = {
  customer: "ring-2 ring-inset ring-primary",
  contractor: "ring-2 ring-inset ring-success",
  supplier: "ring-2 ring-inset ring-warning",
};

export const CONTRACTOR_TYPE_HEADER_CLASS: Record<ContractorType, string> = {
  customer: "bg-primary/10 hover:bg-primary/15",
  contractor: "bg-success/10 hover:bg-success/15",
  supplier: "bg-warning/10 hover:bg-warning/15",
};
