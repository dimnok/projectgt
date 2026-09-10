export const EMPLOYEE_STATUSES = [
  "working",
  "vacation",
  "sickLeave",
  "unpaidLeave",
  "fired",
] as const;

export type EmployeeStatus = (typeof EMPLOYEE_STATUSES)[number];

const EMPLOYEE_STATUS_LABELS: Record<EmployeeStatus, string> = {
  working: "Работает",
  vacation: "Отпуск",
  sickLeave: "Больничный",
  unpaidLeave: "Без содержания",
  fired: "Уволен",
};

export const EMPLOYEE_STATUS_OPTIONS = EMPLOYEE_STATUSES.map((value) => ({
  value,
  label: EMPLOYEE_STATUS_LABELS[value],
}));

export function isEmployeeStatus(value: unknown): value is EmployeeStatus {
  return EMPLOYEE_STATUSES.includes(value as EmployeeStatus);
}

export function employeeStatusLabel(status: EmployeeStatus): string {
  return EMPLOYEE_STATUS_LABELS[status];
}
