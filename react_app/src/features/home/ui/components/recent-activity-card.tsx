"use client";

import Link from "next/link";
import { ArrowRightIcon, CalendarDaysIcon, HardHatIcon, UserIcon } from "lucide-react";

import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import type { Work } from "@/features/works/types/work.types";
import { WorkStatusBadge } from "@/features/works/ui/shared/work-status-badge";
import { formatCurrency, formatRuDate } from "@/features/works/utils/work.utils";
import { cn } from "@/lib/utils";

type RecentActivityCardProps = {
  works: Work[];
  className?: string;
};

export function RecentActivityCard({
  works,
  className,
}: RecentActivityCardProps) {
  return (
    <Card className={cn("overflow-hidden border-border/80 shadow-xs", className)}>
      <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-3 border-b border-border/50">
        <div className="flex items-center gap-2">
          <CalendarDaysIcon className="size-4 text-muted-foreground" />
          <CardTitle className="text-base font-medium">
            Последняя активность
          </CardTitle>
        </div>

        <Button
          variant="ghost"
          size="sm"
          className="h-8 gap-1 text-xs text-muted-foreground hover:text-foreground"
          render={<Link href="/works" />}
          nativeButton={false}
        >
          <span>В журнал смен</span>
          <ArrowRightIcon className="size-3.5" />
        </Button>
      </CardHeader>

      <CardContent className="p-3 sm:p-4">
        {works.length === 0 ? (
          <div className="py-6 text-center text-xs text-muted-foreground">
            История смен за текущий месяц пуста
          </div>
        ) : (
          <div className="flex flex-col divide-y divide-border/40">
            {works.map((work) => (
              <div
                key={work.id}
                className="flex flex-col sm:flex-row sm:items-center justify-between gap-2 py-2.5 first:pt-0 last:pb-0"
              >
                <div className="min-w-0 flex-1">
                  <div className="flex items-center gap-2 flex-wrap">
                    <span className="text-xs font-semibold tabular-nums text-muted-foreground">
                      {formatRuDate(work.date)}
                    </span>
                    <span className="text-xs text-muted-foreground/40">•</span>
                    <h5 className="truncate text-sm font-medium text-foreground">
                      {work.objectName}
                    </h5>
                    <WorkStatusBadge status={work.status} />
                  </div>

                  <div className="mt-1 flex items-center gap-3 text-xs text-muted-foreground">
                    <span className="flex items-center gap-1 truncate">
                      <UserIcon className="size-3 shrink-0" />
                      <span className="truncate">{work.openedByName || "—"}</span>
                    </span>

                    <span className="flex items-center gap-1 shrink-0">
                      <HardHatIcon className="size-3" />
                      <span>{work.employeesCount} чел.</span>
                    </span>
                  </div>
                </div>

                <div className="flex items-center justify-between sm:justify-end gap-3 shrink-0">
                  {work.totalAmount > 0 ? (
                    <span className="text-xs font-semibold tabular-nums text-foreground">
                      {formatCurrency(work.totalAmount)}
                    </span>
                  ) : (
                    <span className="text-xs text-muted-foreground">Без суммы</span>
                  )}
                </div>
              </div>
            ))}
          </div>
        )}
      </CardContent>
    </Card>
  );
}
