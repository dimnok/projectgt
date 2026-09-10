export const EMPLOYEE_EMPLOYMENT_TYPES = [
  "official",
  "unofficial",
  "contractor",
] as const;

export type EmployeeEmploymentType =
  (typeof EMPLOYEE_EMPLOYMENT_TYPES)[number];

const EMPLOYEE_EMPLOYMENT_LABELS: Record<EmployeeEmploymentType, string> = {
  official: "Официально",
  unofficial: "Неофициально",
  contractor: "Подрядчик",
};

export const EMPLOYEE_EMPLOYMENT_OPTIONS = EMPLOYEE_EMPLOYMENT_TYPES.map(
  (value) => ({
    value,
    label: EMPLOYEE_EMPLOYMENT_LABELS[value],
  })
);

export function isEmployeeEmploymentType(
  value: unknown
): value is EmployeeEmploymentType {
  return EMPLOYEE_EMPLOYMENT_TYPES.includes(value as EmployeeEmploymentType);
}

export function employeeEmploymentLabel(
  type: EmployeeEmploymentType
): string {
  return EMPLOYEE_EMPLOYMENT_LABELS[type];
}
