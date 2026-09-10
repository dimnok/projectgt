"use client";

import type { ReactNode } from "react";
import { useEffect, useMemo, useState } from "react";

import {
  TableBody,
  TableCell,
  TableFooter,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { useWorkJournalTableLayout } from "@/features/work-journal/hooks/use-work-journal-table-layout";
import type {
  WorkJournalPage,
  WorkJournalRow,
} from "@/features/work-journal/types/work-journal.types";
import type {
  WorkJournalColumn,
  WorkJournalColumnId,
} from "@/features/work-journal/utils/work-journal-table-columns";
import {
  formatCurrency,
  formatQuantity,
  formatRuDate,
} from "@/features/work-journal/utils/work-journal.utils";
import { cn } from "@/lib/utils";

const CELL_PAD_X = 24;
const EDGE_PAD_X = 8;
const HEADER_FONT = "600 12px Inter, ui-sans-serif, system-ui, sans-serif";
const BODY_FONT = "400 14px Inter, ui-sans-serif, system-ui, sans-serif";

type WorkJournalTableProps = {
  page: WorkJournalPage;
  onDateClick: (row: WorkJournalRow) => void;
};

export function WorkJournalTable({ page, onDateClick }: WorkJournalTableProps) {
  const { visibleColumns } = useWorkJournalTableLayout();
  const footerQuantity = formatQuantity(page.totalQuantity);
  const footerTotal = formatCurrency(page.totalSum);
  const columnWidths = useContentColumnWidths(
    page.items,
    visibleColumns,
    footerQuantity,
    footerTotal
  );
  const minTableWidth = visibleColumns.reduce(
    (sum, column) => sum + (columnWidths[column.id] ?? column.minWidth),
    0
  );

  return (
    <div className="min-h-0 flex-1 overflow-auto rounded-b-none [clip-path:inset(0)]">
      <table
        className="w-full table-fixed border-separate border-spacing-0 caption-bottom text-sm"
        style={{ minWidth: minTableWidth }}
      >
        <colgroup>
          {visibleColumns.map((column) => (
            <col
              key={column.id}
              style={
                column.id === "name"
                  ? { width: "auto" }
                  : { width: columnWidths[column.id] }
              }
            />
          ))}
        </colgroup>
        <TableHeader className="sticky top-0 z-10 bg-muted">
          <TableRow className="hover:bg-transparent border-b-0">
            {visibleColumns.map((column, index) => (
              <TableHead
                key={column.id}
                className={cn(
                  "sticky top-0 z-10 border-b border-border/80 bg-muted px-3 py-1.5 text-xs font-semibold text-foreground/75 select-none align-middle",
                  index === 0 && "pl-4 sm:pl-5",
                  index === visibleColumns.length - 1 && "pr-4 sm:pr-5",
                  column.align === "right" && "text-right",
                  column.align === "center" && "text-center",
                  column.id === "name"
                    ? "w-full min-w-[260px]"
                    : "whitespace-nowrap"
                )}
              >
                {column.label}
              </TableHead>
            ))}
          </TableRow>
        </TableHeader>
        <TableBody>
          {page.items.map((row) => (
            <TableRow
              key={row.workItemId}
              className="transition-colors hover:bg-muted/40"
            >
              {visibleColumns.map((column, index) => (
                <TableCell
                  key={column.id}
                  className={cn(
                    "border-b border-border/50 px-3 py-1.5 text-xs sm:text-sm",
                    index === 0 && "pl-4 sm:pl-5",
                    index === visibleColumns.length - 1 && "pr-4 sm:pr-5",
                    column.align === "right" && "text-right tabular-nums",
                    column.align === "center" && "text-center",
                    column.id === "total" && "font-medium text-foreground",
                    column.id === "name"
                      ? "w-full min-w-[260px] whitespace-normal font-medium"
                      : "whitespace-nowrap"
                  )}
                >
                  <span
                    className={cn(
                      "block",
                      column.id === "name"
                        ? "whitespace-normal break-words"
                        : "truncate"
                    )}
                  >
                    {renderCell(column.id, row, onDateClick)}
                  </span>
                </TableCell>
              ))}
            </TableRow>
          ))}
        </TableBody>
        <TableFooter className="sticky bottom-0 z-10 bg-muted">
          <TableRow className="hover:bg-transparent">
            {visibleColumns.map((column, index) => (
              <TableCell
                key={column.id}
                className={cn(
                  "sticky bottom-0 border-t border-border/80 bg-muted px-3 py-2.5 text-xs sm:text-sm font-medium",
                  index === 0 && "pl-4 sm:pl-5",
                  index === visibleColumns.length - 1 && "pr-4 sm:pr-5",
                  column.align === "right" &&
                    "text-right tabular-nums text-foreground",
                  column.id === "name"
                    ? "w-full min-w-[260px]"
                    : "whitespace-nowrap"
                )}
              >
                {column.id === "date"
                  ? "Итого"
                  : column.id === "quantity"
                    ? footerQuantity
                    : column.id === "total"
                      ? footerTotal
                      : null}
              </TableCell>
            ))}
          </TableRow>
        </TableFooter>
      </table>
    </div>
  );
}

function useContentColumnWidths(
  items: WorkJournalRow[],
  columns: WorkJournalColumn[],
  footerQuantity: string,
  footerTotal: string
) {
  const [canMeasure, setCanMeasure] = useState(false);

  useEffect(() => {
    setCanMeasure(true);
  }, []);

  return useMemo(() => {
    const widths: Partial<Record<WorkJournalColumnId, number>> = {};
    columns.forEach((column, index) => {
      const edgePad =
        index === 0 || index === columns.length - 1 ? EDGE_PAD_X : 0;
      if (column.id === "name") {
        widths[column.id] = column.minWidth;
        return;
      }

      let maxText = canMeasure ? measureText(column.label, HEADER_FONT) : 0;
      if (column.id === "date") {
        maxText = Math.max(maxText, measureText("Итого", HEADER_FONT));
      }
      if (column.id === "quantity") {
        maxText = Math.max(maxText, measureText(footerQuantity, BODY_FONT));
      }
      if (column.id === "total") {
        maxText = Math.max(maxText, measureText(footerTotal, BODY_FONT));
      }
      for (const item of items) {
        maxText = Math.max(
          maxText,
          measureText(cellPlainText(item, column.id), BODY_FONT)
        );
      }
      widths[column.id] = Math.ceil(
        Math.max(column.minWidth, maxText + CELL_PAD_X + edgePad)
      );
    });
    return widths;
  }, [canMeasure, columns, footerQuantity, footerTotal, items]);
}

let measureCanvas: HTMLCanvasElement | null = null;

function measureText(text: string, font: string): number {
  if (typeof document === "undefined" || !text) {
    return 0;
  }
  measureCanvas ??= document.createElement("canvas");
  const context = measureCanvas.getContext("2d");
  if (!context) {
    return text.length * 8;
  }
  context.font = font;
  return context.measureText(text).width;
}

function cellPlainText(row: WorkJournalRow, columnId: WorkJournalColumnId): string {
  switch (columnId) {
    case "date":
      return formatRuDate(row.workDate);
    case "system":
      return row.system || "—";
    case "subsystem":
      return row.subsystem || "—";
    case "section":
      return row.section || "—";
    case "floor":
      return row.floor || "—";
    case "name":
      return row.workName || "—";
    case "unit":
      return row.unit || "—";
    case "quantity":
      return formatQuantity(row.quantity);
    case "price":
      return row.price === null ? "—" : formatCurrency(row.price);
    case "total":
      return row.total === null ? "—" : formatCurrency(row.total);
  }
}

function renderCell(
  columnId: WorkJournalColumnId,
  row: WorkJournalRow,
  onDateClick: (row: WorkJournalRow) => void
): ReactNode {
  switch (columnId) {
    case "date":
      return (
        <button
          type="button"
          className="cursor-pointer text-primary underline-offset-2 hover:underline"
          aria-label={`Открыть смену за ${formatRuDate(row.workDate)}`}
          onClick={() => onDateClick(row)}
        >
          {formatRuDate(row.workDate)}
        </button>
      );
    case "system":
      return row.system || "—";
    case "subsystem":
      return row.subsystem || "—";
    case "section":
      return row.section || "—";
    case "floor":
      return row.floor || "—";
    case "name":
      return row.workName || "—";
    case "unit":
      return row.unit || "—";
    case "quantity":
      return formatQuantity(row.quantity);
    case "price":
      return row.price === null ? "—" : formatCurrency(row.price);
    case "total":
      return row.total === null ? "—" : formatCurrency(row.total);
  }
}
