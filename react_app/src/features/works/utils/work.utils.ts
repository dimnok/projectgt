import type { Work, WorkHour, WorkItem, WorkStatus } from "@/features/works/types/work.types";

export function toNumber(value: unknown): number {
  if (typeof value === "number" && Number.isFinite(value)) {
    return value;
  }
  if (typeof value === "string" && value.trim() !== "") {
    const parsed = Number(value.replace(",", "."));
    return Number.isFinite(parsed) ? parsed : 0;
  }
  return 0;
}

export function unwrapRelation<T>(value: T | T[] | null | undefined): T | null {
  if (!value) {
    return null;
  }
  if (Array.isArray(value)) {
    return value[0] ?? null;
  }
  return value;
}

export function toMonthKey(value: string): string {
  return value.slice(0, 7);
}

/** Local calendar date from `YYYY-MM-DD` (avoids UTC shift from `Date.parse`). */
export function parseLocalDate(value: string): Date {
  const [year, month, day] = value.slice(0, 10).split("-").map(Number);
  return new Date(year, (month ?? 1) - 1, day ?? 1);
}

export function toDateKey(date: Date): string {
  return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, "0")}-${String(date.getDate()).padStart(2, "0")}`;
}

export function currentMonthKey(): string {
  return toMonthKey(toDateKey(new Date()));
}

export function monthStartDate(month: string): Date {
  const [year, monthIndex] = month.split("-").map(Number);
  return new Date(year, monthIndex - 1, 1);
}

export function shiftMonthKey(month: string, delta: number): string {
  const [year, monthIndex] = month.split("-").map(Number);
  const next = new Date(year, monthIndex - 1 + delta, 1);
  return `${next.getFullYear()}-${String(next.getMonth() + 1).padStart(2, "0")}`;
}

export function defaultDayInMonth(month: string): string {
  const today = toDateKey(new Date());
  if (toMonthKey(today) === month) {
    return today;
  }
  return `${month}-01`;
}

export function monthRange(month: string): { start: string; end: string } {
  const [year, monthIndex] = month.split("-").map(Number);
  const start = `${year}-${String(monthIndex).padStart(2, "0")}-01`;
  const nextYear = monthIndex === 12 ? year + 1 : year;
  const nextMonth = monthIndex === 12 ? 1 : monthIndex + 1;
  const end = `${nextYear}-${String(nextMonth).padStart(2, "0")}-01`;
  return { start, end };
}

export function formatMonthYear(month: string): string {
  const [year, monthIndex] = month.split("-").map(Number);
  const label = new Intl.DateTimeFormat("ru-RU", {
    month: "long",
    year: "numeric",
  }).format(new Date(year, monthIndex - 1, 1));
  return label.charAt(0).toUpperCase() + label.slice(1);
}

/** Month name in Russian, capitalized (`Сентябрь`). */
export function formatMonthName(month: string): string {
  const [year, monthIndex] = month.split("-").map(Number);
  const label = new Intl.DateTimeFormat("ru-RU", {
    month: "long",
  }).format(new Date(year, monthIndex - 1, 1));
  return label.charAt(0).toUpperCase() + label.slice(1);
}

export function daysInMonth(month: string): number {
  const [year, monthIndex] = month.split("-").map(Number);
  return new Date(year, monthIndex, 0).getDate();
}

export function isCurrentMonth(month: string): boolean {
  const now = new Date();
  const current = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, "0")}`;
  return month === current;
}

export function isTodayInMonth(month: string, day: number): boolean {
  const now = new Date();
  const today = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, "0")}-${String(now.getDate()).padStart(2, "0")}`;
  const date = `${month}-${String(day).padStart(2, "0")}`;
  return today === date;
}

export function formatCurrency(value: number): string {
  return new Intl.NumberFormat("ru-RU", {
    style: "currency",
    currency: "RUB",
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  }).format(value);
}

export function formatQuantity(value: number): string {
  return new Intl.NumberFormat("ru-RU", {
    maximumFractionDigits: 3,
  }).format(value);
}

export function formatRuDate(value: string | null | undefined): string {
  if (!value) {
    return "—";
  }
  const clean = value.split("T")[0];
  const [year, month, day] = clean.split("-");
  if (!year || !month || !day) {
    return value;
  }
  return `${day}.${month}.${year}`;
}

export function formatPersonName(parts: {
  lastName?: string | null;
  firstName?: string | null;
  middleName?: string | null;
}): string {
  return [parts.lastName, parts.firstName, parts.middleName]
    .map((part) => part?.trim() ?? "")
    .filter(Boolean)
    .join(" ");
}

export function resolveProfileName(profile: {
  short_name?: string | null;
  full_name?: string | null;
} | null): string {
  const shortName = profile?.short_name?.trim();
  if (shortName) {
    return shortName;
  }
  const fullName = profile?.full_name?.trim();
  if (fullName) {
    return fullName;
  }
  return "Не указан";
}

export function resolveContractorName(contractor: {
  short_name?: string | null;
  full_name?: string | null;
} | null): string | null {
  const shortName = contractor?.short_name?.trim();
  if (shortName) {
    return shortName;
  }
  const fullName = contractor?.full_name?.trim();
  if (fullName) {
    return fullName;
  }
  return null;
}

export function isWorkStatus(value: string): value is WorkStatus {
  return value === "open" || value === "closed";
}

export function extractPhotoTime(url: string): string | null {
  try {
    const last = new URL(url).pathname.split("/").pop() ?? "";
    const match = /(\d{4})-(\d{2})-(\d{2})_(\d{2})-(\d{2})-(\d{2})/.exec(last);
    if (!match) {
      return null;
    }
    return `${match[4]}:${match[5]}`;
  } catch {
    return null;
  }
}

export function ownItems(items: WorkItem[]): WorkItem[] {
  return items.filter((item) => !item.contractorId);
}

export function ownItemsTotal(items: WorkItem[]): number {
  return ownItems(items).reduce((sum, item) => sum + item.total, 0);
}

export function contractorTotals(items: WorkItem[]): {
  contractorId: string;
  name: string;
  total: number;
}[] {
  const map = new Map<string, { name: string; total: number }>();
  for (const item of items) {
    if (!item.contractorId) {
      continue;
    }
    const current = map.get(item.contractorId);
    const name = item.contractorName ?? "Подрядчик";
    map.set(item.contractorId, {
      name,
      total: (current?.total ?? 0) + item.total,
    });
  }
  return [...map.entries()]
    .map(([contractorId, value]) => ({ contractorId, ...value }))
    .sort((a, b) => a.name.localeCompare(b.name, "ru"));
}

export function uniqueEmployeeCount(hours: WorkHour[]): number {
  return new Set(hours.map((row) => row.employeeId)).size;
}

export function filterWorks(
  works: Work[],
  search: string
): Work[] {
  const query = search.trim().toLowerCase();
  if (!query) {
    return works;
  }
  return works.filter((work) => {
    const date = formatRuDate(work.date);
    return (
      work.objectName.toLowerCase().includes(query) ||
      work.openedByName.toLowerCase().includes(query) ||
      date.includes(query) ||
      work.status.includes(query)
    );
  });
}

export type WorkItemPlaceFilter = {
  system: string | null;
  section: string | null;
  floor: string | null;
};

function uniqueSorted(values: string[]): string[] {
  return [...new Set(values.map((value) => value.trim()).filter(Boolean))].sort(
    (a, b) => a.localeCompare(b, "ru")
  );
}

export function uniqueWorkItemSystems(items: WorkItem[]): string[] {
  return uniqueSorted(items.map((item) => item.system));
}

export function uniqueWorkItemSections(
  items: WorkItem[],
  system: string | null
): string[] {
  return uniqueSorted(
    items
      .filter((item) => !system || item.system.trim() === system)
      .map((item) => item.section)
  );
}

export function uniqueWorkItemFloors(
  items: WorkItem[],
  system: string | null,
  section: string | null
): string[] {
  return uniqueSorted(
    items
      .filter(
        (item) =>
          (!system || item.system.trim() === system) &&
          (!section || item.section.trim() === section)
      )
      .map((item) => item.floor)
  );
}

/** Filters shift items by place dropdowns and name substring, same as Flutter. */
export function filterWorkItems(
  items: WorkItem[],
  search: string,
  place?: WorkItemPlaceFilter
): WorkItem[] {
  const query = search.trim().toLowerCase();
  const system = place?.system?.trim() || null;
  const section = place?.section?.trim() || null;
  const floor = place?.floor?.trim() || null;

  return items.filter((item) => {
    if (system && item.system.trim() !== system) {
      return false;
    }
    if (section && item.section.trim() !== section) {
      return false;
    }
    if (floor && item.floor.trim() !== floor) {
      return false;
    }
    if (!query) {
      return true;
    }
    return item.name.toLowerCase().includes(query);
  });
}

export function parseWorkQuantity(raw: string): number | null {
  const normalized = raw.trim().replace(",", ".");
  if (!normalized) {
    return null;
  }
  const value = Number(normalized);
  if (!Number.isFinite(value)) {
    return null;
  }
  return value;
}

export function workItemLineTotal(price: number, quantity: number): number {
  return quantity > 0 ? price * quantity : 0;
}

export function canModifyWorkItems(params: {
  canUpdate: boolean;
  userId: string | null;
  openedBy: string;
  status: WorkStatus;
  isSuperAdmin: boolean;
}): boolean {
  if (!params.canUpdate || !params.userId) {
    return false;
  }
  if (params.isSuperAdmin) {
    return true;
  }
  return params.openedBy === params.userId && params.status === "open";
}

export type WorkCloseCheck = {
  id: string;
  label: string;
  done: boolean;
};

/**
 * Same close rules as Flutter `WorkValidationBlock._canCloseWork`.
 */
export function getWorkCloseChecks(
  work: Work,
  items: WorkItem[] | undefined,
  hours: WorkHour[] | undefined
): { ready: boolean; checks: WorkCloseCheck[]; message: string | null } {
  if (work.status === "closed") {
    return { ready: false, checks: [], message: "Смена уже закрыта" };
  }
  if (!items || !hours) {
    return { ready: false, checks: [], message: null };
  }

  const hasItems = items.length > 0;
  const hasHours = hours.length > 0;
  const quantitiesFilled = hasItems && !items.some((item) => item.quantity <= 0);
  const hoursFilled = hasHours && !hours.some((row) => row.hours <= 0);
  const hasEvening = Boolean(work.eveningPhotoUrl?.trim());

  const checks: WorkCloseCheck[] = [
    { id: "items", label: "Добавить работы", done: hasItems },
    { id: "employees", label: "Добавить сотрудников", done: hasHours },
    { id: "qty", label: "Заполнить кол-во у работ", done: quantitiesFilled },
    { id: "hours", label: "Заполнить часы сотрудников", done: hoursFilled },
    { id: "evening", label: "Загрузить вечернее фото", done: hasEvening },
  ];

  let message: string | null = null;
  if (!hasItems) {
    message = "Невозможно закрыть смену без работ";
  } else if (!hasHours) {
    message = "Невозможно закрыть смену без сотрудников";
  } else if (!quantitiesFilled) {
    message =
      "У некоторых работ не указано количество. Необходимо заполнить все поля количества перед закрытием смены.";
  } else if (!hoursFilled) {
    message =
      "У некоторых сотрудников не указаны часы. Необходимо заполнить все поля часов перед закрытием смены.";
  } else if (!hasEvening) {
    message = "Необходимо добавить вечернее фото перед закрытием смены.";
  }

  return {
    ready: checks.every((check) => check.done),
    checks,
    message,
  };
}

export function formatWorkItemPlace(section: string, floor: string): string {
  const parts = [section.trim(), floor.trim()].filter(Boolean);
  return parts.length > 0 ? parts.join(" · ") : "—";
}

export function filterWorkHours(hours: WorkHour[], search: string): WorkHour[] {
  const query = search.trim().toLowerCase();
  const list = !query
    ? hours
    : hours.filter((row) =>
        [row.employeeName, row.employeePosition, row.comment]
          .filter(Boolean)
          .some((value) => String(value).toLowerCase().includes(query))
      );

  return [...list].sort(
    (a, b) =>
      a.employeeName.localeCompare(b.employeeName, "ru", { sensitivity: "base" }) ||
      a.id.localeCompare(b.id)
  );
}

export type DailyWorkStat = {
  day: number;
  dateStr: string;
  weekday: string;
  totalAmount: number;
  ownAmount: number;
  subAmount: number;
  worksCount: number;
  openCount: number;
  closedCount: number;
  employeesCount: number;
  objectNames: string[];
};

export function detailedDailyStats(
  works: Work[],
  month: string,
  objectId?: string | null
): DailyWorkStat[] {
  const days = daysInMonth(month);
  const [year, monthIndex] = month.split("-").map(Number);

  const stats: DailyWorkStat[] = Array.from({ length: days }, (_, i) => {
    const day = i + 1;
    const date = new Date(year, monthIndex - 1, day);
    const dateStr = `${month}-${String(day).padStart(2, "0")}`;
    const weekday = new Intl.DateTimeFormat("ru-RU", { weekday: "short" }).format(date);
    return {
      day,
      dateStr,
      weekday,
      totalAmount: 0,
      ownAmount: 0,
      subAmount: 0,
      worksCount: 0,
      openCount: 0,
      closedCount: 0,
      employeesCount: 0,
      objectNames: [],
    };
  });

  const objectNameSets = Array.from({ length: days }, () => new Set<string>());

  for (const work of works) {
    if (objectId && work.objectId !== objectId) {
      continue;
    }
    const day = Number(work.date.slice(8, 10));
    if (day >= 1 && day <= days) {
      const stat = stats[day - 1];
      stat.totalAmount += work.totalAmount;
      stat.ownAmount += work.ownTotalAmount;
      stat.subAmount += Math.max(0, work.totalAmount - work.ownTotalAmount);
      stat.worksCount += 1;
      if (work.status === "open") {
        stat.openCount += 1;
      } else {
        stat.closedCount += 1;
      }
      stat.employeesCount += work.employeesCount;
      if (work.objectName) {
        objectNameSets[day - 1].add(work.objectName);
      }
    }
  }

  for (let i = 0; i < days; i++) {
    stats[i].objectNames = Array.from(objectNameSets[i]);
  }

  return stats;
}

export function formatPercent(value: number): string {
  if (!Number.isFinite(value)) {
    return "0%";
  }
  return `${new Intl.NumberFormat("ru-RU", {
    minimumFractionDigits: 1,
    maximumFractionDigits: 1,
  }).format(value)}%`;
}

export function formatDayFullRu(dateStr: string): string {
  const [year, month, day] = dateStr.split("-").map(Number);
  if (!year || !month || !day) return dateStr;
  const d = new Date(year, month - 1, day);
  return new Intl.DateTimeFormat("ru-RU", {
    day: "numeric",
    month: "long",
    weekday: "short",
  }).format(d);
}
