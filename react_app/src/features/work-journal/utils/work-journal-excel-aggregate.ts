import type { WorkJournalRow } from "@/features/work-journal/types/work-journal.types";

export type WorkJournalPtoRow = {
  system: string;
  subsystem: string;
  section: string;
  floor: string;
  positionNumber: string;
  workName: string;
  m15Name: string;
  unit: string;
  quantity: number;
};

export type WorkJournalGeneralRow = {
  objectName: string;
  contractNumber: string;
  system: string;
  subsystem: string;
  positionNumber: string;
  workName: string;
  m15Name: string;
  unit: string;
  quantity: number;
  price: number | null;
  total: number;
};

function dash(value: string | null | undefined): string {
  const trimmed = value?.trim() ?? "";
  return trimmed || "—";
}

function parsePositionNumber(num: string): [string, number] {
  const str = num.trim();
  if (!str) {
    return ["", 0];
  }
  const match = str.match(/^([^0-9]*)([-.,]?)(.*)$/);
  if (!match) {
    return [str, 0];
  }
  const prefix = match[1] || "";
  const numPart = match[3] || "";
  let numValue = 0;
  if (numPart) {
    const normalized = numPart.replace(",", ".");
    const numMatch = normalized.match(/\d+(\.?\d+)?/);
    if (numMatch) {
      numValue = Number.parseFloat(numMatch[0]);
    }
  }
  return [prefix, numValue];
}

function comparePosition(a: string, b: string): number {
  const [prefixA, numA] = parsePositionNumber(a);
  const [prefixB, numB] = parsePositionNumber(b);
  if (prefixA !== prefixB) {
    return prefixA.localeCompare(prefixB, "ru");
  }
  return numA - numB;
}

function compareText(a: string, b: string): number {
  return a.localeCompare(b, "ru");
}

/**
 * Same grouping as Flutter PTO sheet in `export-work-search-pto`.
 */
export function aggregatePtoRows(items: WorkJournalRow[]): WorkJournalPtoRow[] {
  const aggregated = new Map<string, WorkJournalPtoRow>();

  for (const item of items) {
    const key = [
      item.system ?? "",
      item.subsystem ?? "",
      item.section ?? "",
      item.floor ?? "",
      item.positionNumber ?? "",
      item.workName ?? "",
      item.m15Name ?? "",
      item.unit ?? "",
    ].join("|");
    const row: WorkJournalPtoRow = {
      system: dash(item.system),
      subsystem: dash(item.subsystem),
      section: dash(item.section),
      floor: dash(item.floor),
      positionNumber: dash(item.positionNumber),
      workName: dash(item.workName),
      m15Name: dash(item.m15Name),
      unit: dash(item.unit),
      quantity: item.quantity,
    };

    const existing = aggregated.get(key);
    if (existing) {
      existing.quantity += item.quantity;
    } else {
      aggregated.set(key, row);
    }
  }

  return [...aggregated.values()].sort((a, b) => {
    if (a.system !== b.system) return compareText(a.system, b.system);
    if (a.subsystem !== b.subsystem) return compareText(a.subsystem, b.subsystem);
    if (a.section !== b.section) return compareText(a.section, b.section);
    if (a.floor !== b.floor) return compareText(a.floor, b.floor);
    return comparePosition(a.positionNumber, b.positionNumber);
  });
}

/**
 * Same grouping as Flutter "Общий" sheet in `export-work-search-pto`.
 */
export function aggregateGeneralRows(
  items: WorkJournalRow[]
): WorkJournalGeneralRow[] {
  const aggregated = new Map<string, WorkJournalGeneralRow>();

  for (const item of items) {
    const key = [
      item.objectName ?? "",
      item.contractNumber ?? "",
      item.system ?? "",
      item.subsystem ?? "",
      item.positionNumber ?? "",
      item.workName ?? "",
      item.m15Name ?? "",
    ].join("|");
    const row: WorkJournalGeneralRow = {
      objectName: dash(item.objectName),
      contractNumber: dash(item.contractNumber),
      system: dash(item.system),
      subsystem: dash(item.subsystem),
      positionNumber: dash(item.positionNumber),
      workName: dash(item.workName),
      m15Name: dash(item.m15Name),
      unit: dash(item.unit),
      quantity: item.quantity,
      price: item.price,
      total: item.total ?? 0,
    };

    const existing = aggregated.get(key);
    if (existing) {
      existing.quantity += item.quantity;
      existing.total += item.total ?? 0;
    } else {
      aggregated.set(key, row);
    }
  }

  return [...aggregated.values()].sort((a, b) => {
    if (a.contractNumber !== b.contractNumber) {
      return compareText(a.contractNumber, b.contractNumber);
    }
    if (a.system !== b.system) return compareText(a.system, b.system);
    if (a.subsystem !== b.subsystem) return compareText(a.subsystem, b.subsystem);
    return comparePosition(a.positionNumber, b.positionNumber);
  });
}
