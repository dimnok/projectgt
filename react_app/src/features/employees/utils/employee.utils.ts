import type {
  Employee,
  EmployeeCreateDraft,
  EmployeeDraft,
  EmployeeFilters,
} from "@/features/employees/types/employee.types";
import { isEmployeeEmploymentType } from "@/features/employees/utils/employee-employment";
import {
  EMPLOYEE_STATUSES,
  isEmployeeStatus,
  type EmployeeStatus,
} from "@/features/employees/utils/employee-status";
import type { EmployeeRatesRow, EmployeesRow } from "@/types/database.types";
import { formatPhone } from "@/lib/utils/phone";

export const EMPLOYEE_SELECT = [
  "id",
  "company_id",
  "photo_url",
  "last_name",
  "first_name",
  "middle_name",
  "birth_date",
  "birth_place",
  "citizenship",
  "phone",
  "clothing_size",
  "shoe_size",
  "height",
  "employment_date",
  "employment_type",
  "position",
  "status",
  "include_in_timesheet",
  "object_ids",
  "passport_series",
  "passport_number",
  "passport_issued_by",
  "passport_issue_date",
  "passport_department_code",
  "registration_address",
  "inn",
  "snils",
  "kig",
  "patent_number",
].join(", ");

export const CLOTHING_SIZE_OPTIONS = [
  "40-42(S)",
  "44-46(M)",
  "48-50(L)",
  "50-52(XL)",
  "54-56(2XL)",
  "56-58(3XL)",
  "60-62(4XL)",
  "64-66(5XL)",
];

export const SHOE_SIZE_OPTIONS = [
  "36",
  "37",
  "38",
  "39",
  "40",
  "41",
  "42",
  "43",
  "44",
  "45",
  "46",
  "47",
  "48",
];

export const HEIGHT_OPTIONS = [
  "150-160",
  "160-170",
  "170-180",
  "180-190",
  "190-200",
];

const NONE_VALUE = "__none__";

export function optionalSelectValue(value: string): string {
  return value.trim() ? value : NONE_VALUE;
}

export function fromOptionalSelectValue(value: string): string {
  return value === NONE_VALUE ? "" : value;
}

function text(value: string | null | undefined): string {
  return value?.trim() ?? "";
}

function dateInput(value: string | null | undefined): string | null {
  const raw = value?.trim();
  if (!raw) {
    return null;
  }
  const day = raw.split("T")[0];
  return day || null;
}

function mapObjectIds(value: unknown): string[] {
  if (!Array.isArray(value)) {
    return [];
  }
  return value.filter(
    (id): id is string => typeof id === "string" && id.length > 0
  );
}

function toNumber(value: unknown): number | null {
  if (typeof value === "number" && Number.isFinite(value)) {
    return value;
  }
  if (typeof value === "string" && value.trim()) {
    const parsed = Number(value);
    return Number.isFinite(parsed) ? parsed : null;
  }
  return null;
}

export function employeeFullName(employee: {
  lastName: string;
  firstName: string;
  middleName: string;
}): string {
  return [employee.lastName, employee.firstName, employee.middleName]
    .map((part) => part.trim())
    .filter(Boolean)
    .join(" ");
}

export function employeeInitials(employee: {
  lastName: string;
  firstName: string;
}): string {
  const last = employee.lastName.trim().charAt(0);
  const first = employee.firstName.trim().charAt(0);
  return `${last}${first}`.toUpperCase() || "?";
}

export function mapEmployeeRow(
  row: EmployeesRow,
  currentHourlyRate: number | null = null
): Employee {
  return {
    id: row.id,
    companyId: row.company_id,
    photoUrl: row.photo_url,
    lastName: text(row.last_name),
    firstName: text(row.first_name),
    middleName: text(row.middle_name),
    birthDate: dateInput(row.birth_date),
    birthPlace: text(row.birth_place),
    citizenship: text(row.citizenship),
    phone: text(row.phone),
    clothingSize: text(row.clothing_size),
    shoeSize: text(row.shoe_size),
    height: text(row.height),
    employmentDate: dateInput(row.employment_date),
    employmentType: isEmployeeEmploymentType(row.employment_type)
      ? row.employment_type
      : "official",
    position: text(row.position),
    status: isEmployeeStatus(row.status) ? row.status : "working",
    includeInTimesheet: row.include_in_timesheet ?? true,
    objectIds: mapObjectIds(row.object_ids),
    passportSeries: text(row.passport_series),
    passportNumber: text(row.passport_number),
    passportIssuedBy: text(row.passport_issued_by),
    passportIssueDate: dateInput(row.passport_issue_date),
    passportDepartmentCode: text(row.passport_department_code),
    registrationAddress: text(row.registration_address),
    inn: text(row.inn),
    snils: text(row.snils),
    kig: text(row.kig),
    patentNumber: text(row.patent_number),
    currentHourlyRate,
  };
}

export function mapRatesByEmployeeId(
  rows: EmployeeRatesRow[]
): Map<string, number> {
  const rates = new Map<string, number>();
  for (const row of rows) {
    const rate = toNumber(row.hourly_rate);
    if (rate !== null) {
      rates.set(row.employee_id, rate);
    }
  }
  return rates;
}

export function sortEmployeesByName(employees: Employee[]): Employee[] {
  return [...employees].sort((a, b) =>
    employeeFullName(a).localeCompare(employeeFullName(b), "ru", {
      sensitivity: "base",
    })
  );
}

export function filterEmployees(
  employees: Employee[],
  filters: EmployeeFilters
): Employee[] {
  const query = filters.search.trim().toLowerCase();
  const queryDigits = query.replace(/\D/g, "");

  return employees.filter((employee) => {
    if (filters.status !== "all" && employee.status !== filters.status) {
      return false;
    }
    if (
      filters.objectId !== "all" &&
      !employee.objectIds.includes(filters.objectId)
    ) {
      return false;
    }
    if (!query) {
      return true;
    }

    const fullName = employeeFullName(employee).toLowerCase();
    const position = employee.position.toLowerCase();
    const phoneDisplay = formatPhone(employee.phone).toLowerCase();
    const phoneDigits = employee.phone.replace(/\D/g, "");

    if (
      fullName.includes(query) ||
      position.includes(query) ||
      phoneDisplay.includes(query)
    ) {
      return true;
    }
    return Boolean(queryDigits) && phoneDigits.includes(queryDigits);
  });
}

export function formatEmployeeCount(count: number): string {
  const n10 = count % 10;
  const n100 = count % 100;
  if (n10 === 1 && n100 !== 11) {
    return `${count} сотрудник`;
  }
  if (n10 >= 2 && n10 <= 4 && (n100 < 12 || n100 > 14)) {
    return `${count} сотрудника`;
  }
  return `${count} сотрудников`;
}

export function countEmployeesByStatus(employees: Employee[]) {
  const byStatus = Object.fromEntries(
    EMPLOYEE_STATUSES.map((status) => [status, 0])
  ) as Record<EmployeeStatus, number>;

  for (const employee of employees) {
    byStatus[employee.status] += 1;
  }

  return {
    total: employees.length,
    byStatus,
  };
}

export function uniquePositions(employees: Employee[]): string[] {
  const names = new Set<string>();
  for (const employee of employees) {
    if (employee.position) {
      names.add(employee.position);
    }
  }
  return [...names].sort((a, b) => a.localeCompare(b, "ru", { sensitivity: "base" }));
}

export function todayDateInput(): string {
  const now = new Date();
  const year = now.getFullYear();
  const month = String(now.getMonth() + 1).padStart(2, "0");
  const day = String(now.getDate()).padStart(2, "0");
  return `${year}-${month}-${day}`;
}

export function emptyToNull(value: string): string | null {
  const trimmed = value.trim();
  return trimmed ? trimmed : null;
}

export function digitsOnly(value: string): string {
  return value.replace(/\D/g, "");
}

/**
 * Same storage format as Flutter `normalizeRuPhoneForStorage`:
 * `7XXXXXXXXXX` (11 digits, no plus).
 */
export function phoneForStorage(value: string): string | null {
  let digits = digitsOnly(value);
  if (!digits) {
    return null;
  }
  if (digits.length === 11 && digits.startsWith("8")) {
    digits = `7${digits.slice(1)}`;
  } else if (digits.length === 10) {
    digits = `7${digits}`;
  }
  if (digits.length === 11 && digits.startsWith("7")) {
    return digits;
  }
  return null;
}

export function dateForStorage(value: string): string | null {
  return dateInput(value);
}

export function toCreateDraft(): EmployeeCreateDraft {
  return {
    lastName: "",
    firstName: "",
    middleName: "",
    phone: "",
    objectIds: [],
  };
}

export function toDraft(employee: Employee): EmployeeDraft {
  return {
    lastName: employee.lastName,
    firstName: employee.firstName,
    middleName: employee.middleName,
    birthDate: employee.birthDate ?? "",
    birthPlace: employee.birthPlace,
    citizenship: employee.citizenship,
    phone: employee.phone,
    clothingSize: employee.clothingSize,
    shoeSize: employee.shoeSize,
    height: employee.height,
    employmentDate: employee.employmentDate ?? "",
    employmentType: employee.employmentType,
    position: employee.position,
    status: employee.status,
    includeInTimesheet: employee.includeInTimesheet,
    objectIds: [...employee.objectIds],
    passportSeries: employee.passportSeries,
    passportNumber: employee.passportNumber,
    passportIssuedBy: employee.passportIssuedBy,
    passportIssueDate: employee.passportIssueDate ?? "",
    passportDepartmentCode: employee.passportDepartmentCode,
    registrationAddress: employee.registrationAddress,
    inn: employee.inn,
    snils: employee.snils,
    kig: employee.kig,
    patentNumber: employee.patentNumber,
  };
}

export function formatHourlyRate(value: number): string {
  return new Intl.NumberFormat("ru-RU", {
    style: "currency",
    currency: "RUB",
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  }).format(value);
}

export function formatRuDate(value: string | null | undefined): string {
  if (!value) {
    return "";
  }
  const clean = value.split("T")[0];
  const [year, month, day] = clean.split("-");
  if (!year || !month || !day) {
    return value;
  }
  return `${day}.${month}.${year}`;
}

export function objectNamesLabel(
  objectIds: string[],
  namesById: Map<string, string>
): string {
  if (objectIds.length === 0) {
    return "";
  }
  return objectIds
    .map((id) => namesById.get(id) ?? "")
    .filter(Boolean)
    .join(", ");
}

export type SizeSelectOption = {
  value: string;
  label: string;
};

export function sizeSelectItems(options: string[]): SizeSelectOption[] {
  return [
    { value: NONE_VALUE, label: "Не указан" },
    ...options.map((value) => ({ value, label: value })),
  ];
}
