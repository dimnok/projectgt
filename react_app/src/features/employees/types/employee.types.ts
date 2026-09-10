import type { EmployeeEmploymentType } from "@/features/employees/utils/employee-employment";
import type { EmployeeStatus } from "@/features/employees/utils/employee-status";

export type Employee = {
  id: string;
  companyId: string;
  photoUrl: string | null;
  lastName: string;
  firstName: string;
  middleName: string;
  birthDate: string | null;
  birthPlace: string;
  citizenship: string;
  phone: string;
  clothingSize: string;
  shoeSize: string;
  height: string;
  employmentDate: string | null;
  employmentType: EmployeeEmploymentType;
  position: string;
  status: EmployeeStatus;
  includeInTimesheet: boolean;
  objectIds: string[];
  passportSeries: string;
  passportNumber: string;
  passportIssuedBy: string;
  passportIssueDate: string | null;
  passportDepartmentCode: string;
  registrationAddress: string;
  inn: string;
  snils: string;
  kig: string;
  patentNumber: string;
  currentHourlyRate: number | null;
};

export type EmployeeCreateDraft = {
  lastName: string;
  firstName: string;
  middleName: string;
  phone: string;
  objectIds: string[];
};

export type EmployeeDraft = {
  lastName: string;
  firstName: string;
  middleName: string;
  birthDate: string;
  birthPlace: string;
  citizenship: string;
  phone: string;
  clothingSize: string;
  shoeSize: string;
  height: string;
  employmentDate: string;
  employmentType: EmployeeEmploymentType;
  position: string;
  status: EmployeeStatus;
  includeInTimesheet: boolean;
  objectIds: string[];
  passportSeries: string;
  passportNumber: string;
  passportIssuedBy: string;
  passportIssueDate: string;
  passportDepartmentCode: string;
  registrationAddress: string;
  inn: string;
  snils: string;
  kig: string;
  patentNumber: string;
};

export type EmployeeFilters = {
  search: string;
  status: EmployeeStatus | "all";
  objectId: string | "all";
};

export type EmployeeObjectOption = {
  id: string;
  name: string;
};

export type EmployeeRate = {
  id: string;
  employeeId: string;
  hourlyRate: number;
  validFrom: string;
  validTo: string | null;
};

export type EmployeeRateDraft = {
  hourlyRate: number;
  validFrom: string;
};

export type EmployeeRateOverlapAction = "replace" | "close" | "delete";

export type EmployeeRateOverlap = {
  rate: EmployeeRate;
  action: EmployeeRateOverlapAction;
};

export type EmployeeTripRate = {
  id: string;
  objectId: string;
  employeeId: string | null;
  rate: number;
  minimumHours: number;
  validFrom: string;
  validTo: string | null;
  createdAt: string | null;
};

export type EmployeeTripRateDraft = {
  objectId: string;
  rate: number;
  minimumHours: number;
  validFrom: string;
  validTo: string | null;
};
