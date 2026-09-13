import type { Employee } from "@/features/employees/types/employee.types";

export type TimesheetEntry = {
  id: string;
  workId: string;
  employeeId: string;
  hours: number;
  comment: string | null;
  date: string; // YYYY-MM-DD
  objectId: string;
  isManualEntry: boolean;
};

export type TimesheetEmployeeListScope = "all" | "withHours" | "withoutHours";

export type TimesheetOpenShiftFilterScope = "all" | "inOpenShift" | "notInOpenShift";

export type TodayOpenShiftInfo = {
  employeeIds: Set<string>;
  hintByEmployeeId: Map<string, string>;
  objectIdsByEmployeeId: Map<string, Set<string>>;
};

export type TimesheetFilters = {
  year: number;
  month: number; // 1-12
  selectedObjectIds: string[];
  selectedPositionKeys: string[];
  listScope: TimesheetEmployeeListScope;
  openShiftScope: TimesheetOpenShiftFilterScope;
  searchQuery: string;
};

export type DayCellData = {
  date: string; // YYYY-MM-DD
  dayNumber: number;
  dayOfWeek: number; // 0 for Sun, 1 for Mon, ..., 6 for Sat
  isToday: boolean;
  isWeekend: boolean;
  totalHours: number;
  entries: TimesheetEntry[];
  isInTodayOpenShift: boolean;
  todayOpenShiftHint?: string;
};

export type TimesheetGridRow = {
  employee: Employee;
  fullName: string;
  position: string;
  days: DayCellData[];
  totalHours: number;
  totalDays: number;
};

export type TimesheetObjectOption = {
  id: string;
  name: string;
  colorHex: string;
};
