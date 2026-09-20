"use client";

import { ArrowDownIcon, ArrowUpDownIcon, ArrowUpIcon } from "lucide-react";
import type { ReactNode } from "react";

import {
  ContextMenu,
  ContextMenuContent,
  ContextMenuTrigger,
} from "@/components/ui/context-menu";
import {
  TableBody,
  TableCell,
  TableFooter,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import type { PayrollTableSort } from "@/features/payrolls/types/payroll.types";
import { cn } from "@/lib/utils";

export type PayrollTableColumn<T> = {
  key: string;
  label: string;
  /** Подсказка при наведении на заголовок. */
  hint?: string;
  align?: "left" | "right";
  /** Ширина колонки классом Tailwind, например «w-28». */
  widthClass?: string;
  /** Начать смысловую группу: вертикальная линия слева. */
  groupStart?: boolean;
  /** Первое направление сортировки: суммы — по убыванию, ФИО — по алфавиту. */
  sortFirst?: "asc" | "desc";
  cellClassName?: string | ((row: T) => string | undefined);
  render: (row: T) => ReactNode;
  /** Значение в строке ИТОГО. */
  footer?: ReactNode;
  footerClassName?: string;
};

type PayrollTableProps<T> = {
  columns: PayrollTableColumn<T>[];
  rows: T[];
  rowKey: (row: T) => string;
  /** Первая колонка закрепляется слева — нужно для широкой таблицы ФОТ. */
  stickyFirstColumn?: boolean;
  minWidth?: number;
  empty: ReactNode;
  /** Текущая сортировка и обработчик клика по заголовку. */
  sort?: PayrollTableSort | null;
  onSortChange?: (next: PayrollTableSort | null) => void;
  /** Содержимое меню по правому клику на строке. Без него строка без меню. */
  rowMenu?: (row: T) => ReactNode;
};

const HEAD_CELL =
  "sticky top-0 z-40 h-9 border-b border-border/80 bg-muted px-3 text-xs font-semibold whitespace-nowrap text-foreground/75 select-none";
const BODY_CELL = "px-3 py-1.5 tabular-nums whitespace-nowrap";
const FOOT_CELL =
  "sticky bottom-0 z-40 border-t border-border/80 bg-muted px-3 py-2 text-xs font-semibold tabular-nums whitespace-nowrap text-foreground sm:text-sm";
const GROUP_START = "border-l border-border/80";

const STICKY_HEAD =
  "sticky top-0 left-0 z-50 border-r border-border/80 bg-muted";
const STICKY_CELL =
  "sticky left-0 z-20 border-r border-border/80 bg-card group-hover:bg-muted";
const STICKY_FOOT =
  "sticky bottom-0 left-0 z-50 border-r border-border/80 bg-muted uppercase tracking-wide text-muted-foreground";

/**
 * Порядок сортировки после клика по заголовку: первое направление колонки,
 * затем обратное, третий клик возвращает исходный порядок.
 */
function nextSortFor<T>(
  column: PayrollTableColumn<T>,
  sort: PayrollTableSort | null
): PayrollTableSort | null {
  const first = column.sortFirst ?? "desc";

  if (sort?.key !== column.key) {
    return { key: column.key, direction: first };
  }
  if (sort.direction === first) {
    return { key: column.key, direction: first === "desc" ? "asc" : "desc" };
  }
  return null;
}

/**
 * Таблица модуля ФОТ: шапка и строка ИТОГО закреплены, первая колонка может
 * закрепляться слева. Колонки описываются данными, поэтому одна таблица
 * обслуживает и ведомость, и списки операций.
 */
export function PayrollTable<T>({
  columns,
  rows,
  rowKey,
  stickyFirstColumn = false,
  minWidth,
  empty,
  sort = null,
  onSortChange,
  rowMenu,
}: PayrollTableProps<T>) {
  if (rows.length === 0) {
    return (
      <div className="flex min-h-0 flex-1 items-center justify-center p-6">
        {empty}
      </div>
    );
  }

  const isSticky = (index: number) => stickyFirstColumn && index === 0;

  return (
    <div className="min-h-0 flex-1 overflow-auto rounded-b-xl [clip-path:inset(0_round_0_0_var(--radius-xl)_var(--radius-xl))]">
      <table
        className="w-full border-separate border-spacing-0 text-xs sm:text-sm"
        style={minWidth ? { minWidth } : undefined}
      >
        {/*
          Обёртки шапки и итогов не закрепляем и не задаём им слой: иначе они
          создают свой контекст наложения, и закреплённая колонка перекрывает
          заголовки. Закрепление и слои заданы самим ячейкам.
        */}
        <TableHeader className="bg-muted">
          <TableRow className="border-b-0 hover:bg-transparent">
            {columns.map((column, index) => {
              const isSorted = sort?.key === column.key;
              // Сортировка включается там, где таблице передали обработчик.
              const isSortable = Boolean(onSortChange);
              const nextSort = nextSortFor(column, sort);
              const sortTitle = !isSorted
                ? `Сортировать по ${(column.sortFirst ?? "desc") === "asc" ? "возрастанию" : "убыванию"}`
                : nextSort === null
                  ? "Вернуть исходный порядок"
                  : "Развернуть порядок";

              return (
                <TableHead
                  key={column.key}
                  aria-sort={
                    isSortable
                      ? isSorted
                        ? sort?.direction === "asc"
                          ? "ascending"
                          : "descending"
                        : "none"
                      : undefined
                  }
                  title={
                    isSortable
                      ? column.hint
                        ? `${column.hint}. ${sortTitle}`
                        : sortTitle
                      : (column.hint ?? column.label)
                  }
                  className={cn(
                    HEAD_CELL,
                    column.align === "right" ? "text-right" : "text-left",
                    column.widthClass,
                    column.groupStart && GROUP_START,
                    isSticky(index) && cn(STICKY_HEAD, "text-left")
                  )}
                >
                  {isSortable ? (
                    <button
                      type="button"
                      onClick={() => onSortChange?.(nextSort)}
                      title={sortTitle}
                      className={cn(
                        "inline-flex items-center gap-1 rounded-sm transition-colors hover:text-foreground focus-visible:ring-2 focus-visible:ring-ring focus-visible:outline-none",
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
                  ) : (
                    column.label
                  )}
                </TableHead>
              );
            })}
          </TableRow>
        </TableHeader>

        <TableBody>
          {rows.map((row) => {
            const cells = columns.map((column, index) => {
              const extra =
                typeof column.cellClassName === "function"
                  ? column.cellClassName(row)
                  : column.cellClassName;

              return (
                <TableCell
                  key={column.key}
                  className={cn(
                    BODY_CELL,
                    column.align === "right" ? "text-right" : "text-left",
                    column.widthClass,
                    column.groupStart && GROUP_START,
                    isSticky(index) && STICKY_CELL,
                    extra
                  )}
                >
                  {column.render(row)}
                </TableCell>
              );
            });

            if (!rowMenu) {
              return (
                <TableRow
                  key={rowKey(row)}
                  className="transition-colors hover:bg-muted/40"
                >
                  {cells}
                </TableRow>
              );
            }

            return (
              <ContextMenu key={rowKey(row)}>
                <ContextMenuTrigger
                  render={
                    <TableRow className="transition-colors hover:bg-muted/40" />
                  }
                >
                  {cells}
                </ContextMenuTrigger>
                <ContextMenuContent>{rowMenu(row)}</ContextMenuContent>
              </ContextMenu>
            );
          })}
        </TableBody>

        <TableFooter className="bg-muted">
          <TableRow className="hover:bg-transparent">
            {columns.map((column, index) => (
              <TableCell
                key={column.key}
                className={cn(
                  FOOT_CELL,
                  column.align === "right" ? "text-right" : "text-left",
                  column.widthClass,
                  column.groupStart && GROUP_START,
                  isSticky(index) && cn(STICKY_FOOT, "text-left"),
                  column.footerClassName
                )}
              >
                {column.footer}
              </TableCell>
            ))}
          </TableRow>
        </TableFooter>
      </table>
    </div>
  );
}
