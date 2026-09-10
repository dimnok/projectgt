"use client";

import { useCallback, useMemo, useSyncExternalStore } from "react";

import {
  WORK_JOURNAL_COLUMNS,
  WORK_JOURNAL_TABLE_STORAGE_KEY,
  isWorkJournalColumnId,
  type WorkJournalColumn,
  type WorkJournalColumnId,
} from "@/features/work-journal/utils/work-journal-table-columns";

type LayoutState = {
  hidden: WorkJournalColumnId[];
};

let layoutVersion = 0;
const layoutListeners = new Set<() => void>();

function emitLayoutChange() {
  layoutVersion += 1;
  layoutListeners.forEach((listener) => listener());
}

function subscribeToLayout(onChange: () => void) {
  layoutListeners.add(onChange);
  window.addEventListener("storage", onChange);
  return () => {
    layoutListeners.delete(onChange);
    window.removeEventListener("storage", onChange);
  };
}

function getLayoutSnapshot() {
  return `${layoutVersion}:${window.localStorage.getItem(WORK_JOURNAL_TABLE_STORAGE_KEY) ?? ""}`;
}

function getServerLayoutSnapshot() {
  return "0:";
}

function parseStoredHidden(stored?: string[]): WorkJournalColumnId[] {
  const hidden: WorkJournalColumnId[] = [];
  for (const id of stored ?? []) {
    if (!isWorkJournalColumnId(id)) {
      continue;
    }
    const column = WORK_JOURNAL_COLUMNS.find((entry) => entry.id === id);
    if (column?.hideable) {
      hidden.push(id);
    }
  }
  return hidden;
}

function parseLayoutSnapshot(snapshot: string): LayoutState {
  const separator = snapshot.indexOf(":");
  const raw = separator >= 0 ? snapshot.slice(separator + 1) : "";
  if (!raw) {
    return { hidden: [] };
  }
  try {
    const parsed = JSON.parse(raw) as { hidden?: string[] };
    return { hidden: parseStoredHidden(parsed.hidden) };
  } catch {
    return { hidden: [] };
  }
}

function writeLayout(layout: LayoutState) {
  window.localStorage.setItem(
    WORK_JOURNAL_TABLE_STORAGE_KEY,
    JSON.stringify(layout)
  );
  emitLayoutChange();
}

export function useWorkJournalTableLayout() {
  const snapshot = useSyncExternalStore(
    subscribeToLayout,
    getLayoutSnapshot,
    getServerLayoutSnapshot
  );
  const layout = useMemo(() => parseLayoutSnapshot(snapshot), [snapshot]);
  const hidden = useMemo(() => new Set(layout.hidden), [layout.hidden]);
  const visibleColumns = useMemo(
    () => WORK_JOURNAL_COLUMNS.filter((column) => !hidden.has(column.id)),
    [hidden]
  );

  const setColumnVisible = useCallback(
    (column: WorkJournalColumn, visible: boolean) => {
      if (!column.hideable && !visible) {
        return;
      }
      const nextHidden = new Set(layout.hidden);
      if (visible) {
        nextHidden.delete(column.id);
      } else {
        if (WORK_JOURNAL_COLUMNS.length - nextHidden.size <= 1) {
          return;
        }
        nextHidden.add(column.id);
      }
      writeLayout({ hidden: [...nextHidden] });
    },
    [layout]
  );

  const resetLayout = useCallback(() => {
    writeLayout({ hidden: [] });
  }, []);

  return {
    hidden,
    visibleColumns,
    setColumnVisible,
    resetLayout,
  };
}
