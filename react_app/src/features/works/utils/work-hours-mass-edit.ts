import type { WorkHour } from "@/features/works/types/work.types";
import { parseWorkQuantity } from "@/features/works/utils/work.utils";

export const WORK_HOUR_PRESETS = [8, 10, 12] as const;

export type WorkHourBulkUpdate = {
  hourId: string;
  hours: number;
};

export function hoursDraftFromValue(hours: number): string {
  if (hours === 0) {
    return "";
  }
  return String(hours).replace(".", ",");
}

export function draftsFromHours(hours: WorkHour[]): Record<string, string> {
  return Object.fromEntries(
    hours.map((row) => [row.id, hoursDraftFromValue(row.hours)])
  );
}

export function applyPresetToDrafts(
  hours: WorkHour[],
  preset: number
): Record<string, string> {
  return Object.fromEntries(hours.map((row) => [row.id, String(preset)]));
}

export function hasInvalidHourDrafts(
  hours: WorkHour[],
  drafts: Record<string, string>
): boolean {
  return hours.some((row) => {
    const raw = drafts[row.id];
    if (raw == null) {
      return false;
    }
    const trimmed = raw.trim();
    if (!trimmed) {
      return false;
    }
    const parsed = parseWorkQuantity(trimmed);
    return parsed == null || parsed < 0;
  });
}

export function collectHourChanges(
  hours: WorkHour[],
  drafts: Record<string, string>
): WorkHourBulkUpdate[] {
  const updates: WorkHourBulkUpdate[] = [];
  for (const row of hours) {
    const raw = drafts[row.id];
    if (raw == null) {
      continue;
    }
    const parsed = parseWorkQuantity(raw);
    if (parsed == null || parsed < 0) {
      continue;
    }
    if (parsed !== row.hours) {
      updates.push({ hourId: row.id, hours: parsed });
    }
  }
  return updates;
}
