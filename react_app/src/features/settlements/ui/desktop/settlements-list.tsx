"use client";

import { useMemo, useState, type ReactNode } from "react";
import { ArrowDownIcon, ArrowUpDownIcon, ArrowUpIcon } from "lucide-react";

import {
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import type { SettlementSort, SettlementSortKey } from "@/features/settlements/api/settlement-list";
import { SettlementStatusBadge } from "@/features/settlements/ui/shared/settlement-status-badge";
import { SettlementTypeBadge } from "@/features/settlements/ui/shared/settlement-type-badge";
import type { Settlement } from "@/features/settlements/types/settlement.types";
import { settlementPaymentStatusLabel } from "@/features/settlements/utils/payment-status";
import { settlementOperationTypeLabel } from "@/features/settlements/utils/operation-type";
import {
  formatCurrency,
  formatRuDate,
  settlementRemaining,
} from "@/features/settlements/utils/settlement.utils";
import { cn } from "@/lib/utils";

type SortDirection = "asc" | "desc";

/** Описание колонки таблицы: заголовок, значение для сортировки и отрисовка. */
type Column = {
  key: SettlementSortKey;
  label: string;
  align?: "left" | "right";
  /** Первое направление сортировки: суммы — по убыванию, тексты — по алфавиту. */
  sortFirst?: SortDirection;
  sortValue: (settlement: Settlement) => string | number;
  render: (settlement: Settlement) => ReactNode;
};

/** Классы шапки таблицы: закреплена при прокрутке. */
const HEAD_CELL =
  "sticky top-0 z-10 border-b border-border/80 bg-muted px-3 py-1.5 text-xs font-semibold whitespace-nowrap text-foreground/75 select-none align-middle";
/** Классы ячейки строки таблицы. */
const BODY_CELL =
  "border-b border-border/50 px-3 py-1.5 whitespace-nowrap text-xs sm:text-sm";

/** Порядок после клика: первое направление → обратное → исходный порядок. */
function nextSort(column: Column, sort: SettlementSort): SettlementSort {
  const first = column.sortFirst ?? "asc";
  if (sort?.key !== column.key) {
    return { key: column.key, direction: first };
  }
  if (sort.direction === first) {
    return { key: column.key, direction: first === "desc" ? "asc" : "desc" };
  }
  return null;
}

type SettlementsListProps = {
  settlements: Settlement[];
  selectedId: string | null;
  onSelect: (settlement: Settlement) => void;
  /** Управляемая сортировка (считает сервер). Без неё — сортировка на клиенте. */
  sort?: SettlementSort;
  onSortChange?: (next: SettlementSort) => void;
};

/**
 * Таблица счетов с сортировкой по клику на заголовок.
 *
 * Сортировку считает сервер, если передан `onSortChange`; иначе она идёт
 * на клиенте — так таблица работает во вкладке договора.
 */
export function SettlementsList({
  settlements,
  selectedId,
  onSelect,
  sort,
  onSortChange,
}: SettlementsListProps) {
  const [internalSort, setInternalSort] = useState<SettlementSort>(null);
  const isControlled = Boolean(onSortChange);
  const activeSort = isControlled ? (sort ?? null) : internalSort;

  const columns = useMemo<Column[]>(
    () => [
      {
        key: "date",
        label: "Дата",
        sortFirst: "desc",
        sortValue: (s) => s.invoiceDate,
        render: (s) => formatRuDate(s.invoiceDate),
      },
      {
        key: "type",
        label: "Тип",
        sortValue: (s) => settlementOperationTypeLabel(s.operationType),
        render: (s) => <SettlementTypeBadge type={s.operationType} />,
      },
      {
        key: "invoice",
        label: "Счёт",
        sortValue: (s) => s.invoiceNumber,
        render: (s) => (
          <span className="block max-w-40 truncate font-medium">
            {s.invoiceNumber}
          </span>
        ),
      },
      {
        key: "act",
        label: "Акт",
        sortValue: (s) => s.actNumber ?? "",
        render: (s) => (
          <span className="block max-w-32 truncate">{s.actNumber || "—"}</span>
        ),
      },
      {
        key: "contract",
        label: "Договор",
        sortValue: (s) => s.contractNumber,
        render: (s) => (
          <span className="block max-w-32 truncate">
            {s.contractNumber || "—"}
          </span>
        ),
      },
      {
        key: "contractor",
        label: "Контрагент",
        sortValue: (s) => s.contractorName,
        render: (s) => (
          <span className="block max-w-56 truncate">
            {s.contractorName || "—"}
          </span>
        ),
      },
      {
        key: "object",
        label: "Объект",
        sortValue: (s) => s.objectName,
        render: (s) => (
          <span className="block max-w-48 truncate">{s.objectName || "—"}</span>
        ),
      },
      {
        key: "totalToPay",
        label: "К оплате",
        align: "right",
        sortFirst: "desc",
        sortValue: (s) => s.totalToPay,
        render: (s) => formatCurrency(s.totalToPay),
      },
      {
        key: "status",
        label: "Статус",
        sortValue: (s) => settlementPaymentStatusLabel(s.paymentStatus),
        render: (s) => <SettlementStatusBadge status={s.paymentStatus} />,
      },
      {
        key: "paid",
        label: "Оплачено",
        align: "right",
        sortFirst: "desc",
        sortValue: (s) => s.paidAmount,
        render: (s) => (s.paidAmount > 0 ? formatCurrency(s.paidAmount) : "—"),
      },
    ],
    []
  );

  // Сортировка на клиенте — только когда её не считает сервер.
  const rows = useMemo(() => {
    if (isControlled || !activeSort) {
      return settlements;
    }
    const column = columns.find((item) => item.key === activeSort.key);
    if (!column) {
      return settlements;
    }
    const factor = activeSort.direction === "asc" ? 1 : -1;
    return [...settlements].sort((a, b) => {
      const left = column.sortValue(a);
      const right = column.sortValue(b);
      if (typeof left === "number" && typeof right === "number") {
        return (left - right) * factor;
      }
      return (
        String(left)
          .toLowerCase()
          .localeCompare(String(right).toLowerCase(), "ru") * factor
      );
    });
  }, [settlements, columns, activeSort, isControlled]);

  function handleSort(next: SettlementSort) {
    if (onSortChange) {
      onSortChange(next);
      return;
    }
    setInternalSort(next);
  }

  return (
    <div className="min-h-0 flex-1 overflow-auto rounded-b-xl [clip-path:inset(0_round_0_0_var(--radius-xl)_var(--radius-xl))]">
      <table className="w-full border-separate border-spacing-0 text-xs sm:text-sm">
        <TableHeader className="sticky top-0 z-10 bg-muted">
          <TableRow className="border-b-0 hover:bg-transparent">
            {columns.map((column, index) => {
              const isSorted = activeSort?.key === column.key;
              const target = nextSort(column, activeSort);
              const sortTitle = !isSorted
                ? `Сортировать по ${(column.sortFirst ?? "asc") === "asc" ? "возрастанию" : "убыванию"}`
                : target === null
                  ? "Вернуть исходный порядок"
                  : "Развернуть порядок";

              return (
                <TableHead
                  key={column.key}
                  aria-sort={
                    isSorted
                      ? activeSort?.direction === "asc"
                        ? "ascending"
                        : "descending"
                      : "none"
                  }
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
                    onClick={() => handleSort(target)}
                    className={cn(
                      "inline-flex items-center gap-1 rounded-sm transition-colors hover:text-foreground focus-visible:ring-2 focus-visible:ring-ring focus-visible:outline-none",
                      column.align === "right" && "flex-row-reverse",
                      isSorted && "font-semibold text-foreground"
                    )}
                  >
                    <span>{column.label}</span>
                    {isSorted ? (
                      activeSort?.direction === "asc" ? (
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
          {rows.map((settlement) => {
            const isSelected = selectedId === settlement.id;
            const remaining = settlementRemaining(settlement);

            return (
              <TableRow
                key={settlement.id}
                data-state={isSelected ? "selected" : undefined}
                className="cursor-pointer transition-colors hover:bg-muted/40 focus-visible:bg-muted/50 focus-visible:outline-none"
                onClick={() => onSelect(settlement)}
                onKeyDown={(event) => {
                  if (event.key === "Enter" || event.key === " ") {
                    event.preventDefault();
                    onSelect(settlement);
                  }
                }}
                tabIndex={0}
              >
                {columns.map((column, index) => (
                  <TableCell
                    key={column.key}
                    className={cn(
                      BODY_CELL,
                      index === 0 && "pl-4 sm:pl-5",
                      index === columns.length - 1 && "pr-4 sm:pr-5",
                      column.align === "right"
                        ? "text-right font-medium tabular-nums"
                        : "text-left",
                      column.key === "paid" &&
                        remaining > 0 &&
                        "text-muted-foreground"
                    )}
                  >
                    {column.render(settlement)}
                  </TableCell>
                ))}
              </TableRow>
            );
          })}
        </TableBody>
      </table>
    </div>
  );
}
