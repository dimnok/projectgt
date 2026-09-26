"use client";

import { useMemo, type ReactNode } from "react";
import { ArrowDownIcon, ArrowUpDownIcon, ArrowUpIcon } from "lucide-react";

import {
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import type {
  CashFlowSort,
  CashFlowSortKey,
} from "@/features/cash-flow/api/cash-flow-list";
import type { CashFlowTransaction } from "@/features/cash-flow/types/cash-flow.types";
import { CashFlowTypeBadge } from "@/features/cash-flow/ui/shared/cash-flow-type-badge";
import {
  formatCurrency,
  formatRuDate,
} from "@/features/cash-flow/utils/cash-flow.utils";
import {
  nextTableSort,
  tableSortAriaSort,
  tableSortTitle,
  type SortDirection,
} from "@/lib/table-sort";
import { cn } from "@/lib/utils";

/** Описание колонки таблицы: заголовок, выравнивание и отрисовка. */
type Column = {
  key: CashFlowSortKey;
  label: string;
  align?: "left" | "right";
  /** Первое направление сортировки: суммы и даты — по убыванию. */
  sortFirst?: SortDirection;
  render: (transaction: CashFlowTransaction) => ReactNode;
};

/** Классы шапки таблицы: закреплена при прокрутке. */
const HEAD_CELL =
  "sticky top-0 z-10 border-b border-border/80 bg-muted px-3 py-1.5 text-xs font-semibold whitespace-nowrap text-foreground/75 select-none align-middle";
/** Классы ячейки строки таблицы. */
const BODY_CELL =
  "border-b border-border/50 px-3 py-1.5 whitespace-nowrap text-xs sm:text-sm";

type CashFlowListProps = {
  transactions: CashFlowTransaction[];
  /** Текущая сортировка. Считает её сервер. */
  sort: CashFlowSort;
  onSortChange: (next: CashFlowSort) => void;
  /** Клик по строке открывает правку — только при праве на изменение. */
  canUpdate: boolean;
  onSelect: (transaction: CashFlowTransaction) => void;
};

/**
 * Таблица операций ДДС: сортировка по клику на заголовок.
 *
 * Сортировку и порядок строк считает сервер — таблица показывает страницу
 * как есть, чтобы строки не повторялись и не пропадали между страницами.
 */
export function CashFlowList({
  transactions,
  sort,
  onSortChange,
  canUpdate,
  onSelect,
}: CashFlowListProps) {
  const columns = useMemo<Column[]>(
    () => [
      {
        key: "date",
        label: "Дата",
        sortFirst: "desc",
        render: (transaction) => formatRuDate(transaction.date),
      },
      {
        key: "type",
        label: "Тип",
        render: (transaction) => <CashFlowTypeBadge type={transaction.type} />,
      },
      {
        key: "category",
        label: "Статья",
        render: (transaction) => (
          <span className="block max-w-56 truncate font-medium">
            {transaction.categoryName || "—"}
          </span>
        ),
      },
      {
        key: "object",
        label: "Объект",
        render: (transaction) => (
          <span className="block max-w-48 truncate">
            {transaction.objectName || "—"}
          </span>
        ),
      },
      {
        key: "contractor",
        label: "Контрагент",
        render: (transaction) => (
          <span className="block max-w-56 truncate">
            {transaction.contractorName || "—"}
          </span>
        ),
      },
      {
        key: "contract",
        label: "Договор",
        render: (transaction) => (
          <span className="block max-w-32 truncate">
            {transaction.contractNumber || "—"}
          </span>
        ),
      },
      {
        key: "amount",
        label: "Сумма",
        align: "right",
        sortFirst: "desc",
        render: (transaction) => (
          <span
            className={cn(
              "font-medium tabular-nums",
              transaction.type === "income"
                ? "text-success"
                : "text-destructive"
            )}
          >
            {transaction.type === "income" ? "+" : "−"}
            {formatCurrency(transaction.amount)}
          </span>
        ),
      },
    ],
    []
  );

  return (
    <div className="min-h-0 flex-1 overflow-auto">
      <table className="w-full border-separate border-spacing-0 text-xs sm:text-sm">
        <TableHeader className="sticky top-0 z-10 bg-muted">
          <TableRow className="border-b-0 hover:bg-transparent">
            {columns.map((column, index) => {
              const isSorted = sort?.key === column.key;
              const sortFirst = column.sortFirst ?? "asc";
              const target = nextTableSort(column.key, sort, sortFirst);
              const sortTitle = tableSortTitle(column.key, sort, sortFirst);

              return (
                <TableHead
                  key={column.key}
                  aria-sort={tableSortAriaSort(column.key, sort)}
                  className={cn(
                    HEAD_CELL,
                    index === 0 && "pl-4 sm:pl-5",
                    index === columns.length - 1 && "pr-4 sm:pr-5",
                    column.align === "right" ? "text-right" : "text-left"
                  )}
                >
                  <button
                    type="button"
                    title={sortTitle}
                    onClick={() => onSortChange(target)}
                    className={cn(
                      "inline-flex items-center gap-1 rounded-sm transition-colors hover:text-foreground focus-visible:ring-2 focus-visible:ring-ring focus-visible:outline-none",
                      column.align === "right" && "flex-row-reverse",
                      isSorted && "font-semibold text-foreground"
                    )}
                  >
                    <span>{column.label}</span>
                    {isSorted ? (
                      sort?.direction === "asc" ? (
                        <ArrowUpIcon className="size-3.5 shrink-0" />
                      ) : (
                        <ArrowDownIcon className="size-3.5 shrink-0" />
                      )
                    ) : (
                      <ArrowUpDownIcon className="size-3.5 shrink-0 opacity-40" />
                    )}
                  </button>
                </TableHead>
              );
            })}
          </TableRow>
        </TableHeader>

        <TableBody>
          {transactions.map((transaction) => (
            <TableRow
              key={transaction.id}
              title={transaction.comment || undefined}
              className={cn(
                "border-b border-border/50 transition-colors",
                canUpdate &&
                  "cursor-pointer hover:bg-muted/40 focus-visible:bg-muted/50 focus-visible:outline-none"
              )}
              onClick={canUpdate ? () => onSelect(transaction) : undefined}
              onKeyDown={
                canUpdate
                  ? (event) => {
                      if (event.key === "Enter" || event.key === " ") {
                        event.preventDefault();
                        onSelect(transaction);
                      }
                    }
                  : undefined
              }
              tabIndex={canUpdate ? 0 : undefined}
            >
              {columns.map((column, index) => (
                <TableCell
                  key={column.key}
                  className={cn(
                    BODY_CELL,
                    index === 0 && "pl-4 sm:pl-5",
                    index === columns.length - 1 && "pr-4 sm:pr-5",
                    column.align === "right" ? "text-right" : "text-left"
                  )}
                >
                  {column.render(transaction)}
                </TableCell>
              ))}
            </TableRow>
          ))}
        </TableBody>
      </table>
    </div>
  );
}
