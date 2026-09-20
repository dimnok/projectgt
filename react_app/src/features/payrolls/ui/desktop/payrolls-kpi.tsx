"use client";

import { Loader2Icon } from "lucide-react";
import type { LucideIcon } from "lucide-react";

import { KpiCell, KpiStrip } from "@/components/shared/kpi-cell";
import { cn } from "@/lib/utils";

type PayrollKpiItem = {
  key: string;
  label: string;
  value: string;
  subtext?: string;
  icon: LucideIcon;
};

const GRID_THREE =
  "grid grid-cols-1 divide-y divide-border/60 border-b border-border/80 bg-card sm:grid-cols-3 sm:divide-y-0 sm:divide-x";

type PayrollKpiHeaderProps = {
  items: PayrollKpiItem[];
  /** Сколько ячеек в полосе: 3 или 4 (по умолчанию 4). */
  columns?: 3 | 4;
  isFetching?: boolean;
};

/** Полоса показателей вкладки: ячейки и пометка о фоновом пересчёте. */
export function PayrollKpiHeader({
  items,
  columns = 4,
  isFetching = false,
}: PayrollKpiHeaderProps) {
  return (
    <div className="relative shrink-0">
      <KpiStrip className={columns === 3 ? GRID_THREE : undefined}>
        {items.map((item) => (
          <KpiCell
            key={item.key}
            label={item.label}
            value={item.value}
            subtext={item.subtext}
            icon={item.icon}
          />
        ))}
      </KpiStrip>

      {isFetching ? (
        <div
          className={cn(
            "absolute top-1/2 right-4 z-10 flex -translate-y-1/2 items-center gap-1.5",
            "rounded-full border border-border/80 bg-background/85 px-3 py-1 text-[11px]",
            "text-muted-foreground shadow-xs backdrop-blur-md"
          )}
        >
          <Loader2Icon className="size-3 animate-spin text-primary" />
          <span>Обновление данных...</span>
        </div>
      ) : null}
    </div>
  );
}
