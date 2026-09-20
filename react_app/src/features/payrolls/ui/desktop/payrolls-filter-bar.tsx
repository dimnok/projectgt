"use client";

import type { ReactNode } from "react";

import type { PayrollPeriod } from "@/features/payrolls/types/payroll.types";

type PayrollFilterBarProps = {
  /** Контролы слева: период, объекты, статус. */
  controls: ReactNode;
  /** Поиск по ФИО. */
  search?: ReactNode;
  /** Кнопки справа: выгрузка в Excel. */
  actions?: ReactNode;
};

/** Строка фильтров над таблицей: слева контролы, справа поиск и действия. */
export function PayrollFilterBar({
  controls,
  search,
  actions,
}: PayrollFilterBarProps) {
  return (
    <div className="flex shrink-0 flex-wrap items-center justify-between gap-3 border-b border-border/80 bg-muted/30 px-4 py-2.5 sm:px-5">
      {controls}
      <div className="flex min-w-0 flex-1 items-center justify-end gap-2">
        {search}
        {actions}
      </div>
    </div>
  );
}

/** Группа контролов слева в панели фильтров. */
export function PayrollFilterControls({ children }: { children: ReactNode }) {
  return (
    <div className="flex flex-wrap items-center gap-x-3 gap-y-2 lg:gap-x-4">
      {children}
    </div>
  );
}

/** Общие фильтры вкладок-списков: период и поиск. */
export type PayrollListFilterProps = {
  period: PayrollPeriod;
  /** Подпись выбранного месяца — нужна и в режиме «всё время». */
  monthLabel: string;
  isCurrentMonth: boolean;
  allTime: boolean;
  setAllTime: (value: boolean) => void;
  goToPreviousMonth: () => void;
  goToNextMonth: () => void;
  search: string;
  setSearch: (query: string) => void;
  /** Право на выгрузку в Excel. */
  canExport: boolean;
};

/** Фильтр по объектам — есть у премий и удержаний, у выплат его нет. */
export type PayrollObjectFilterProps = {
  objectOptions: { key: string; label: string }[];
  selectedObjectIds: string[];
  setSelectedObjectIds: (ids: string[]) => void;
};
