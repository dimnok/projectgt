export const CONTRACT_KINDS = ["customer", "subcontract", "supply"] as const;

export type ContractKind = (typeof CONTRACT_KINDS)[number];

const CONTRACT_KIND_LABELS: Record<ContractKind, string> = {
  customer: "Заказчик",
  subcontract: "Подряд",
  supply: "Поставка",
};

export const CONTRACT_KIND_OPTIONS = CONTRACT_KINDS.map((value) => ({
  value,
  label: CONTRACT_KIND_LABELS[value],
}));

export function isContractKind(value: unknown): value is ContractKind {
  return CONTRACT_KINDS.includes(value as ContractKind);
}

export function contractKindLabel(kind: ContractKind): string {
  return CONTRACT_KIND_LABELS[kind];
}
