const RU_MONTH_NAMES = [
  "Январь",
  "Февраль",
  "Март",
  "Апрель",
  "Май",
  "Июнь",
  "Июль",
  "Август",
  "Сентябрь",
  "Октябрь",
  "Ноябрь",
  "Декабрь",
];

const RU_WEEKDAYS = ["вс", "пн", "вт", "ср", "чт", "пт", "сб"];

export function getMonthLabel(year: number, month: number): string {
  const monthName = RU_MONTH_NAMES[month - 1] ?? "";
  return `${monthName} ${year}`;
}

export function getStartAndEndDates(year: number, month: number): {
  startDate: string;
  endDate: string;
  daysCount: number;
} {
  const startDate = `${year}-${String(month).padStart(2, "0")}-01`;
  const lastDay = new Date(year, month, 0).getDate();
  const endDate = `${year}-${String(month).padStart(2, "0")}-${String(lastDay).padStart(2, "0")}`;
  return { startDate, endDate, daysCount: lastDay };
}

export function getTodayDateString(): string {
  const now = new Date();
  const year = now.getFullYear();
  const month = String(now.getMonth() + 1).padStart(2, "0");
  const day = String(now.getDate()).padStart(2, "0");
  return `${year}-${month}-${day}`;
}

export function isCurrentMonth(year: number, month: number): boolean {
  const now = new Date();
  return now.getFullYear() === year && now.getMonth() + 1 === month;
}

export function isFutureMonth(year: number, month: number): boolean {
  const now = new Date();
  const currentYear = now.getFullYear();
  const currentMonth = now.getMonth() + 1;
  return year > currentYear || (year === currentYear && month > currentMonth);
}

export function getPreviousMonth(
  year: number,
  month: number
): { year: number; month: number } {
  if (month === 1) {
    return { year: year - 1, month: 12 };
  }
  return { year, month: month - 1 };
}

export function getNextMonth(
  year: number,
  month: number
): { year: number; month: number } {
  if (isCurrentMonth(year, month)) {
    return { year, month };
  }
  if (month === 12) {
    return { year: year + 1, month: 1 };
  }
  return { year, month: month + 1 };
}

export type DayHeaderInfo = {
  date: string; // YYYY-MM-DD
  dayNumber: number;
  dayOfWeek: number; // 0-6
  weekdayName: string; // пн, вт...
  isWeekend: boolean;
  isToday: boolean;
};

export function getMonthDaysHeader(
  year: number,
  month: number
): DayHeaderInfo[] {
  const lastDay = new Date(year, month, 0).getDate();
  const todayStr = getTodayDateString();
  const headers: DayHeaderInfo[] = [];

  for (let day = 1; day <= lastDay; day += 1) {
    const dateStr = `${year}-${String(month).padStart(2, "0")}-${String(day).padStart(2, "0")}`;
    const dateObj = new Date(year, month - 1, day);
    const dayOfWeek = dateObj.getDay();
    headers.push({
      date: dateStr,
      dayNumber: day,
      dayOfWeek,
      weekdayName: RU_WEEKDAYS[dayOfWeek] ?? "",
      isWeekend: dayOfWeek === 0 || dayOfWeek === 6,
      isToday: dateStr === todayStr,
    });
  }

  return headers;
}

export function formatRuDate(dateStr: string): string {
  if (!dateStr) return "";
  const parts = dateStr.slice(0, 10).split("-");
  if (parts.length === 3) {
    return `${parts[2]}.${parts[1]}.${parts[0]}`;
  }
  return dateStr;
}

export function formatHours(hours: number): string {
  if (hours <= 0) return "";
  if (Number.isInteger(hours)) {
    return String(hours);
  }
  return hours.toFixed(1).replace(".", ",");
}
