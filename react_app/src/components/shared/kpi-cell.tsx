"use client";

import type { LucideIcon } from "lucide-react";
import type { ReactNode } from "react";

/** Ячейка полосы ключевых показателей: подпись, крупное число, значок. */
export function KpiCell({
  label,
  value,
  subtext,
  icon: Icon,
  customIcon,
  customContent,
}: {
  label: string;
  value: string;
  subtext?: string;
  icon?: LucideIcon;
  customIcon?: ReactNode;
  customContent?: ReactNode;
}) {
  return (
    <div className="flex items-center justify-between gap-3 px-3.5 py-2 transition-colors hover:bg-muted/15 sm:px-5 sm:py-2.5">
      <div className="flex min-w-0 flex-1 flex-col justify-between">
        <span className="text-xs font-medium text-muted-foreground">
          {label}
        </span>
        <div className="mt-0.5 font-heading text-base font-semibold tracking-tight tabular-nums text-foreground lg:text-lg xl:text-xl">
          {value}
        </div>
        {customContent ? (
          customContent
        ) : subtext ? (
          <p className="truncate text-[11px] text-muted-foreground leading-tight">
            {subtext}
          </p>
        ) : null}
      </div>
      {customIcon ? (
        <div className="shrink-0">{customIcon}</div>
      ) : Icon ? (
        <div className="flex size-6 shrink-0 self-start items-center justify-center rounded-md bg-muted text-foreground/70 [&_svg]:size-3.5">
          <Icon />
        </div>
      ) : null}
    </div>
  );
}

/** Полоса показателей: 2 колонки на телефоне, 4 на широком экране. */
export function KpiStrip({
  children,
  className,
}: {
  children: ReactNode;
  className?: string;
}) {
  return (
    <div
      className={
        className ??
        "grid grid-cols-2 divide-y divide-border/60 border-b border-border/80 bg-card sm:divide-y-0 sm:divide-x lg:grid-cols-4"
      }
    >
      {children}
    </div>
  );
}
