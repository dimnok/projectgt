"use client";

import { useCallback, useMemo, useSyncExternalStore } from "react";

import {
  ESTIMATE_COLUMNS,
  ESTIMATE_EXECUTION_COLUMNS,
  ESTIMATE_TABLE_STORAGE_KEY,
  isEstimatePlanColumnId,
  type EstimateColumn,
  type EstimatePlanColumnId,
} from "@/features/estimates/utils/estimate-table-columns";

type LayoutState = {
  hidden: EstimatePlanColumnId[];
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
  return `${layoutVersion}:${window.localStorage.getItem(ESTIMATE_TABLE_STORAGE_KEY) ?? ""}`;
}

function getServerLayoutSnapshot() {
  return "0:";
}

function parseStoredHidden(stored?: string[]): EstimatePlanColumnId[] {
  const hidden: EstimatePlanColumnId[] = [];
  for (const id of stored ?? []) {
    if (!isEstimatePlanColumnId(id)) {
      continue;
    }
    const column = ESTIMATE_COLUMNS.find((entry) => entry.id === id);
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
    return {
      hidden: [],
    };
  }
  try {
    const parsed = JSON.parse(raw) as {
      hidden?: string[];
    };
    return {
      hidden: parseStoredHidden(parsed.hidden),
    };
  } catch {
    return {
      hidden: [],
    };
  }
}

function writeLayout(layout: LayoutState) {
  window.localStorage.setItem(
    ESTIMATE_TABLE_STORAGE_KEY,
    JSON.stringify(layout)
  );
  emitLayoutChange();
}

export function useEstimateTableLayout(showExecution = false) {
  const snapshot = useSyncExternalStore(
    subscribeToLayout,
    getLayoutSnapshot,
    getServerLayoutSnapshot
  );
  const layout = useMemo(() => parseLayoutSnapshot(snapshot), [snapshot]);
  const hidden = useMemo(() => new Set(layout.hidden), [layout.hidden]);
  const visibleColumns = useMemo(() => {
    const planColumns = ESTIMATE_COLUMNS.filter(
      (column) => !hidden.has(column.id)
    );
    if (!showExecution) {
      return planColumns;
    }
    return [...planColumns, ...ESTIMATE_EXECUTION_COLUMNS];
  }, [hidden, showExecution]);

  const setColumnVisible = useCallback(
    (column: EstimateColumn<EstimatePlanColumnId>, visible: boolean) => {
      if (!column.hideable && !visible) {
        return;
      }
      const nextHidden = new Set(layout.hidden);
      if (visible) {
        nextHidden.delete(column.id);
      } else {
        if (ESTIMATE_COLUMNS.length - nextHidden.size <= 1) {
          return;
        }
        nextHidden.add(column.id);
      }
      writeLayout({
        hidden: [...nextHidden],
      });
    },
    [layout]
  );

  const resetLayout = useCallback(() => {
    writeLayout({
      hidden: [],
    });
  }, []);

  return {
    hidden,
    visibleColumns,
    setColumnVisible,
    resetLayout,
  };
}
