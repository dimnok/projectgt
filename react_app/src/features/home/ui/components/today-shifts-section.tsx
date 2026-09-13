"use client";

import Link from "next/link";
import Image from "next/image";
import {
  ArrowRightIcon,
  CalendarIcon,
  CameraIcon,
  HardHatIcon,
  PlusIcon,
  UserIcon,
} from "lucide-react";

import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import type { Work } from "@/features/works/types/work.types";
import { WorkStatusBadge } from "@/features/works/ui/shared/work-status-badge";
import { formatCurrency } from "@/features/works/utils/work.utils";
import { cn } from "@/lib/utils";

type TodayShiftsSectionProps = {
  shifts: Work[];
  canOpenShift: boolean;
  onOpenShiftClick: () => void;
  className?: string;
};

export function TodayShiftsSection({
  shifts,
  canOpenShift,
  onOpenShiftClick,
  className,
}: TodayShiftsSectionProps) {
  const openCount = shifts.filter((s) => s.status === "open").length;

  return (
    <Card className={cn("overflow-hidden border-border/80 shadow-xs", className)}>
      <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-3 border-b border-border/50">
        <div className="flex items-center gap-2.5">
          <div className="relative flex size-2.5">
            {openCount > 0 ? (
              <>
                <span className="absolute inline-flex h-full w-full animate-ping rounded-full bg-emerald-400 opacity-75" />
                <span className="relative inline-flex size-2.5 rounded-full bg-emerald-500" />
              </>
            ) : (
              <span className="relative inline-flex size-2.5 rounded-full bg-muted-foreground/40" />
            )}
          </div>
          <CardTitle className="text-base font-medium">
            Сегодня на объектах
          </CardTitle>
          {shifts.length > 0 && (
            <span className="text-xs text-muted-foreground">
              ({shifts.length} {shifts.length === 1 ? "смена" : "смен"})
            </span>
          )}
        </div>

        {canOpenShift && (
          <Button
            size="sm"
            variant="default"
            onClick={onOpenShiftClick}
            className="h-8 gap-1.5 text-xs font-medium"
          >
            <PlusIcon className="size-3.5" />
            <span>Открыть смену</span>
          </Button>
        )}
      </CardHeader>

      <CardContent className="p-3 sm:p-4">
        {shifts.length === 0 ? (
          <div className="flex flex-col items-center justify-center py-8 text-center">
            <div className="flex size-12 items-center justify-center rounded-full bg-muted/80 text-muted-foreground">
              <CalendarIcon className="size-6" />
            </div>
            <h4 className="mt-3 text-sm font-medium text-foreground">
              Сегодня смены ещё не открывались
            </h4>
            <p className="mt-1 max-w-sm text-xs text-muted-foreground">
              Мастера и прорабы могут открыть смену с фиксацией состава бригады и утреннего фото объекта.
            </p>
            {canOpenShift && (
              <Button
                variant="outline"
                size="sm"
                onClick={onOpenShiftClick}
                className="mt-4 h-8 gap-1.5 text-xs"
              >
                <PlusIcon className="size-3.5" />
                <span>Открыть первую смену</span>
              </Button>
            )}
          </div>
        ) : (
          <div className="flex flex-col gap-3">
            {shifts.map((shift) => (
              <div
                key={shift.id}
                className="group relative flex flex-col sm:flex-row items-start sm:items-center justify-between gap-3 rounded-lg border border-border/60 bg-card p-3 sm:p-3.5 transition-colors hover:border-foreground/20 hover:bg-muted/30"
              >
                <div className="flex items-start sm:items-center gap-3 min-w-0 flex-1">
                  {/* Photo or placeholder */}
                  <div className="relative size-12 shrink-0 overflow-hidden rounded-md border border-border/80 bg-muted flex items-center justify-center">
                    {shift.photoUrl ? (
                      <Image
                        src={shift.photoUrl}
                        alt={shift.objectName}
                        fill
                        unoptimized
                        className="object-cover"
                      />
                    ) : (
                      <CameraIcon className="size-5 text-muted-foreground/60" />
                    )}
                  </div>

                  <div className="min-w-0 flex-1">
                    <div className="flex items-center gap-2 flex-wrap">
                      <h4 className="truncate text-sm font-medium text-foreground">
                        {shift.objectName}
                      </h4>
                      <WorkStatusBadge status={shift.status} />
                    </div>

                    <div className="mt-1 flex items-center gap-3 text-xs text-muted-foreground flex-wrap">
                      <span className="flex items-center gap-1 truncate">
                        <UserIcon className="size-3 shrink-0" />
                        <span className="truncate">{shift.openedByName || "Не указан"}</span>
                      </span>

                      <span className="flex items-center gap-1 shrink-0">
                        <HardHatIcon className="size-3" />
                        <span>{shift.employeesCount} чел.</span>
                      </span>

                      {shift.totalAmount > 0 && (
                        <span className="font-medium text-foreground shrink-0">
                          {formatCurrency(shift.totalAmount)}
                        </span>
                      )}
                    </div>
                  </div>
                </div>

                <div className="flex items-center self-end sm:self-center shrink-0">
                  <Button
                    variant="ghost"
                    size="sm"
                    className="h-8 gap-1 text-xs group-hover:text-primary"
                    render={<Link href="/works" />}
                    nativeButton={false}
                  >
                    <span>К смене</span>
                    <ArrowRightIcon className="size-3.5 transition-transform group-hover:translate-x-0.5" />
                  </Button>
                </div>
              </div>
            ))}
          </div>
        )}
      </CardContent>
    </Card>
  );
}
