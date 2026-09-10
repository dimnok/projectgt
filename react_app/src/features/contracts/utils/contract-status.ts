export const CONTRACT_STATUSES = ["active", "suspended", "completed"] as const;

export type ContractStatus = (typeof CONTRACT_STATUSES)[number];

const CONTRACT_STATUS_LABELS: Record<ContractStatus, string> = {
  active: "В работе",
  suspended: "Приостановлен",
  completed: "Завершён",
};

export const CONTRACT_STATUS_OPTIONS = CONTRACT_STATUSES.map((value) => ({
  value,
  label: CONTRACT_STATUS_LABELS[value],
}));

export function isContractStatus(value: unknown): value is ContractStatus {
  return CONTRACT_STATUSES.includes(value as ContractStatus);
}

export function contractStatusLabel(status: ContractStatus): string {
  return CONTRACT_STATUS_LABELS[status];
}
