"use client";

import { PencilIcon, Trash2Icon } from "lucide-react";

import {
  TableBody,
  TableCell,
  TableFooter,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { useEstimateTableLayout } from "@/features/estimates/hooks/use-estimate-table-layout";
import type {
  EstimateCompletion,
  EstimateExecution,
  EstimateItem,
} from "@/features/estimates/types/estimate.types";
import {
  isEstimateExecutionColumnId,
  type EstimateColumnId,
} from "@/features/estimates/utils/estimate-table-columns";
import {
  getEstimateExecution,
  sumCompletedTotal,
  sumRemainingTotal,
} from "@/features/estimates/utils/estimate-execution";
import {
  formatCurrency,
  formatQuantity,
} from "@/features/estimates/utils/estimate.utils";
import { EstimateQuantityCell } from "@/features/estimates/ui/shared/estimate-quantity-cell";
import { cn } from "@/lib/utils";

type EstimateItemsTableProps = {
  items: EstimateItem[];
  showExecution?: boolean;
  completionById?: Map<string, EstimateCompletion>;
  isCompletionLoading?: boolean;
  dense?: boolean;
  onEdit?: (item: EstimateItem) => void;
  onDelete?: (item: EstimateItem) => void;
};

const EMPTY_COMPLETION = new Map<string, EstimateCompletion>();

export function EstimateItemsTable({
  items,
  showExecution = false,
  completionById = EMPTY_COMPLETION,
  isCompletionLoading = false,
  dense = false,
  onEdit,
  onDelete,
}: EstimateItemsTableProps) {
  const hasActions = Boolean(onEdit || onDelete);
  const totalAmount = items.reduce((sum, item) => sum + item.total, 0);
  const completedTotal = showExecution
    ? sumCompletedTotal(items, completionById)
    : null;
  const remainingTotal = showExecution
    ? sumRemainingTotal(items, completionById)
    : null;
  const { visibleColumns } = useEstimateTableLayout(showExecution);
  const showExecutionPlaceholder =
    showExecution && isCompletionLoading && completionById.size === 0;

  const minTableWidth =
    visibleColumns.reduce((sum, col) => sum + col.minWidth, 0) +
    (hasActions ? 68 : 0);

  return (
    <div className="min-h-0 flex-1 overflow-auto rounded-b-xl [clip-path:inset(0_round_0_0_var(--radius-xl)_var(--radius-xl))]">
      <table
        className={cn(
          "w-full border-separate border-spacing-0 caption-bottom",
          dense ? "text-xs" : "text-sm"
        )}
        style={{ minWidth: minTableWidth }}
        aria-busy={showExecutionPlaceholder}
      >
        <TableHeader className="sticky top-0 z-10 bg-muted">
          <TableRow className="hover:bg-transparent border-b-0">
            {visibleColumns.map((column, index) => (
              <TableHead
                key={column.id}
                title={column.title ?? column.label}
                className={cn(
                  "sticky top-0 z-10 border-b border-border/80 bg-muted px-3 font-semibold text-foreground/75 select-none align-middle",
                  dense ? "py-1 text-[11px]" : "py-1.5 text-xs",
                  index === 0 && (dense ? "pl-3 sm:pl-4" : "pl-4 sm:pl-5"),
                  index === visibleColumns.length - 1 && !hasActions && (dense ? "pr-3 sm:pr-4" : "pr-4 sm:pr-5"),
                  column.align === "right" && "text-right",
                  column.id === "name"
                    ? "w-full min-w-[260px]"
                    : isEstimateExecutionColumnId(column.id)
                      ? "w-auto whitespace-pre-line leading-tight"
                      : "w-auto whitespace-nowrap",
                  column.id === "completedQuantity" &&
                    "border-l border-border/80"
                )}
                style={{ minWidth: column.minWidth }}
              >
                {column.label}
              </TableHead>
            ))}
            {hasActions ? (
              <TableHead
                className={cn(
                  "sticky top-0 z-10 border-b border-border/80 bg-muted px-2 text-center font-semibold text-foreground/75 select-none align-middle w-16 min-w-16",
                  dense ? "py-1 text-[11px] pr-3 sm:pr-4" : "py-1.5 text-xs pr-4 sm:pr-5"
                )}
              >
                Действия
              </TableHead>
            ) : null}
          </TableRow>
        </TableHeader>
        <TableBody>
          {items.map((item) => {
            const execution = showExecution
              ? getEstimateExecution(item, completionById.get(item.id))
              : null;

            return (
              <TableRow
                key={item.id}
                className="transition-colors hover:bg-muted/40"
              >
                {visibleColumns.map((column, index) => (
                  <TableCell
                    key={column.id}
                    className={cn(
                      "border-b border-border/50 px-3",
                      dense ? "py-1 text-xs" : "py-1.5 text-xs sm:text-sm",
                      index === 0 && (dense ? "pl-3 sm:pl-4" : "pl-4 sm:pl-5"),
                      index === visibleColumns.length - 1 && !hasActions && (dense ? "pr-3 sm:pr-4" : "pr-4 sm:pr-5"),
                      column.align === "right" && "text-right tabular-nums",
                      column.id === "total" && "font-medium text-foreground",
                      column.id === "name"
                        ? "w-full min-w-[260px] whitespace-normal font-medium"
                        : "w-auto whitespace-nowrap",
                      column.id === "completedQuantity" &&
                        "border-l border-border/50",
                      isNegativeExecutionValue(column.id, execution) &&
                        "text-destructive",
                      showExecutionPlaceholder &&
                        isEstimateExecutionColumnId(column.id) &&
                        "text-muted-foreground"
                    )}
                    style={{ minWidth: column.minWidth }}
                  >
                    <span
                      className={cn(
                        "block",
                        column.id === "name"
                          ? "whitespace-normal break-words"
                          : column.id === "quantity" || column.id === "completedQuantity"
                            ? "overflow-visible"
                            : "truncate"
                      )}
                    >
                      {renderCell(
                        item,
                        column.id,
                        execution,
                        showExecutionPlaceholder
                      )}
                    </span>
                  </TableCell>
                ))}
                {hasActions ? (
                  <TableCell
                    className={cn(
                      "border-b border-border/50 px-2 whitespace-nowrap w-16 min-w-16 text-center",
                      dense ? "py-1 pr-3 sm:pr-4" : "py-1 pr-4 sm:pr-5"
                    )}
                  >
                    <div className="flex items-center justify-center gap-1">
                      {onEdit ? (
                        <button
                          type="button"
                          onClick={() => onEdit(item)}
                          className="inline-flex size-6 items-center justify-center rounded text-muted-foreground hover:bg-muted hover:text-foreground transition-colors cursor-pointer"
                          title="Редактировать позицию"
                        >
                          <PencilIcon className="size-3.5" />
                        </button>
                      ) : null}
                      {onDelete ? (
                        <button
                          type="button"
                          onClick={() => onDelete(item)}
                          className="inline-flex size-6 items-center justify-center rounded text-muted-foreground hover:bg-destructive/10 hover:text-destructive transition-colors cursor-pointer"
                          title="Удалить позицию"
                        >
                          <Trash2Icon className="size-3.5" />
                        </button>
                      ) : null}
                    </div>
                  </TableCell>
                ) : null}
              </TableRow>
            );
          })}
        </TableBody>
        <TableFooter className="sticky bottom-0 z-10 bg-muted">
          <TableRow className="hover:bg-transparent">
            {visibleColumns.map((column, index) => (
              <TableCell
                key={column.id}
                className={cn(
                  "sticky bottom-0 border-t border-border/80 bg-muted px-3 font-medium",
                  dense ? "py-2 text-xs" : "py-2.5 text-xs sm:text-sm",
                  index === 0 && "pl-4 sm:pl-5",
                  index === visibleColumns.length - 1 && !hasActions && "pr-4 sm:pr-5",
                  column.align === "right" &&
                    "text-right tabular-nums text-foreground",
                  column.id === "name"
                    ? "w-full min-w-[260px]"
                    : "w-auto whitespace-nowrap",
                  column.id === "completedQuantity" &&
                    "border-l border-border/80",
                  column.id === "remainingTotal" &&
                    remainingTotal !== null &&
                    remainingTotal < 0 &&
                    "text-destructive"
                )}
                style={{ minWidth: column.minWidth }}
              >
                {renderFooterCell(
                  column.id,
                  index,
                  totalAmount,
                  completedTotal,
                  remainingTotal,
                  showExecutionPlaceholder
                )}
              </TableCell>
            ))}
            {hasActions ? (
              <TableCell
                className={cn(
                  "sticky bottom-0 border-t border-border/80 bg-muted px-2 w-16 min-w-16",
                  dense ? "py-2 pr-4 sm:pr-5" : "py-2.5 pr-4 sm:pr-5"
                )}
              />
            ) : null}
          </TableRow>
        </TableFooter>
      </table>
    </div>
  );
}

function isNegativeExecutionValue(
  columnId: EstimateColumnId,
  execution: EstimateExecution | null
) {
  if (!execution) {
    return false;
  }
  if (columnId === "remainingQuantity") {
    return execution.remainingQuantity < 0;
  }
  if (columnId === "remainingTotal") {
    return execution.remainingTotal < 0;
  }
  return false;
}

function renderFooterCell(
  columnId: EstimateColumnId,
  index: number,
  totalAmount: number,
  completedTotal: number | null,
  remainingTotal: number | null,
  showPlaceholder: boolean
) {
  switch (columnId) {
    case "total":
      return formatCurrency(totalAmount);
    case "completedTotal":
      if (showPlaceholder) {
        return "…";
      }
      return completedTotal !== null
        ? formatCurrency(completedTotal)
        : null;
    case "remainingTotal":
      if (showPlaceholder) {
        return "…";
      }
      return remainingTotal !== null
        ? formatCurrency(remainingTotal)
        : null;
    default:
      return index === 0 ? "Итого" : null;
  }
}

function renderCell(
  item: EstimateItem,
  columnId: EstimateColumnId,
  execution: EstimateExecution | null,
  showPlaceholder: boolean
) {
  if (showPlaceholder && isEstimateExecutionColumnId(columnId)) {
    return "…";
  }

  switch (columnId) {
    case "quantity": {
      return (
        <EstimateQuantityCell
          item={item}
        />
      );
    }
    case "price":
      return formatCurrency(item.price);
    case "total":
      return formatCurrency(item.total);
    case "system":
      return item.system || "—";
    case "subsystem":
      return item.subsystem || "—";
    case "number":
      return item.number || "—";
    case "name":
      return item.name || "—";
    case "article":
      return item.article || "—";
    case "manufacturer":
      return item.manufacturer || "—";
    case "unit":
      return item.unit || "—";
    case "completedQuantity": {
      if (!execution) return "—";
      return (
        <EstimateQuantityCell
          item={item}
          displayQuantity={execution.completedQuantity}
        />
      );
    }
    case "completedTotal":
      return execution ? formatCurrency(execution.completedTotal) : "—";
    case "remainingQuantity":
      return execution ? formatQuantity(execution.remainingQuantity) : "—";
    case "remainingTotal":
      return execution ? formatCurrency(execution.remainingTotal) : "—";
  }
}
