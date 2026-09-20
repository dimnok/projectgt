"use client";

import { useState } from "react";
import Link from "next/link";
import Image from "next/image";
import { useRouter } from "next/navigation";
import {
  ArrowRightIcon,
  Building2Icon,
  CameraIcon,
  ClockIcon,
  HardHatIcon,
  MapPinIcon,
  PlusIcon,
  RefreshCwIcon,
  UserCheckIcon,
  UserIcon,
  UsersIcon,
  WrenchIcon,
} from "lucide-react";
import { toast } from "sonner";

import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { useHomeDashboard } from "@/features/home/hooks/use-home-dashboard";
import { HomeAnalyticsChart } from "@/features/home/ui/components/home-analytics-chart";
import { ObjectStatusBadge } from "@/features/objects/ui/shared/object-status-badge";
import { useMyOpenWorkId } from "@/features/works/hooks/use-open-work";
import type { Work } from "@/features/works/types/work.types";
import { WorkOpenSheet } from "@/features/works/ui/mobile/work-open-sheet";
import { WorkStatusBadge } from "@/features/works/ui/shared/work-status-badge";
import { formatCurrency } from "@/features/works/utils/work.utils";
import { MobileAppBar } from "@/layouts/mobile/mobile-app-bar";
import { cn } from "@/lib/utils";

export function HomeMobile() {
  const router = useRouter();
  const dashboard = useHomeDashboard();
  const myOpenQuery = useMyOpenWorkId();
  const [openShiftSheetOpen, setOpenShiftSheetOpen] = useState(false);

  const canOpenShift = dashboard.can("works", "create");

  function handleOpenShiftClick() {
    if (myOpenQuery.data) {
      toast.error(
        "У вас уже есть открытая смена. Закройте её перед открытием новой."
      );
      router.push("/works");
      return;
    }
    setOpenShiftSheetOpen(true);
  }

  function handleShiftOpened(work: Work) {
    toast.success(`Смена на объекте «${work.objectName}» открыта`);
    void dashboard.refetch();
  }

  return (
    <div
      data-fill-viewport
      className="-m-4 flex h-full min-h-0 min-w-0 flex-1 flex-col overflow-hidden bg-background"
    >
      {/* Mobile App Bar */}
      <MobileAppBar
        title="Стройка PRO"
        trailing={
          <Button
            type="button"
            variant="ghost"
            size="icon"
            className="size-8 rounded-full"
            onClick={() => void dashboard.refetch()}
            disabled={dashboard.isRefetching}
            aria-label="Обновить"
          >
            <RefreshCwIcon
              className={cn("size-4", dashboard.isRefetching && "animate-spin")}
            />
          </Button>
        }
      />

      {/* Scrollable Viewport */}
      <div className="min-h-0 min-w-0 flex-1 overflow-x-hidden overflow-y-auto overscroll-contain px-4 pt-3.5 pb-[calc(1.5rem+env(safe-area-inset-bottom))] flex flex-col gap-4">
        {/* User & Company Header Card */}
        <div className="flex flex-col gap-1.5 rounded-xl border border-border/80 bg-gradient-to-b from-muted/40 to-background p-4 shadow-xs">
          <div className="flex items-center justify-between gap-2">
            <span className="text-[11px] font-medium tracking-wide uppercase text-muted-foreground">
              {dashboard.dateLabel}
            </span>

            {dashboard.kpi.openShiftsCount > 0 ? (
              <Badge variant="success" className="h-4.5 px-2 text-[10px] gap-1 font-medium">
                <span className="size-1.5 rounded-full bg-emerald-500 animate-pulse" />
                {dashboard.kpi.openShiftsCount} в работе
              </Badge>
            ) : (
              <Badge variant="secondary" className="h-4.5 px-2 text-[10px]">
                Смены закрыты
              </Badge>
            )}
          </div>

          <h2 className="mt-1 font-heading text-xl font-semibold text-foreground">
            {dashboard.greeting}
          </h2>

          <div className="flex items-center gap-2 text-xs text-muted-foreground">
            <Building2Icon className="size-3.5 shrink-0" />
            <span className="truncate font-medium text-foreground">
              {dashboard.companyName}
            </span>
            <span>•</span>
            <span className="shrink-0">{dashboard.roleName}</span>
          </div>
        </div>

        {/* Primary CTA Button for Foremen */}
        {canOpenShift && (
          <Button
            variant="default"
            size="lg"
            onClick={handleOpenShiftClick}
            className="h-11 w-full gap-2 rounded-xl text-sm font-medium shadow-xs"
          >
            <PlusIcon className="size-4" />
            <span>Открыть новую смену</span>
          </Button>
        )}

        {/* 2x2 KPI Grid */}
        <div className="grid grid-cols-2 gap-2.5">
          <Link href="/works" className="block no-underline">
            <Card className="p-3 transition-colors hover:border-foreground/20">
              <div className="flex items-center justify-between">
                <span className="text-[11px] font-medium text-muted-foreground">Смены сегодня</span>
                <HardHatIcon className="size-3.5 text-muted-foreground" />
              </div>
              <div className="mt-1 text-xl font-semibold tabular-nums text-foreground">
                {dashboard.kpi.openShiftsCount}
              </div>
              <p className="mt-0.5 text-[11px] text-muted-foreground truncate">
                {dashboard.kpi.todayWorkersCount > 0
                  ? `${dashboard.kpi.todayWorkersCount} чел. на объектах`
                  : "Рабочих нет"}
              </p>
            </Card>
          </Link>

          <Link href="/objects" className="block no-underline">
            <Card className="p-3 transition-colors hover:border-foreground/20">
              <div className="flex items-center justify-between">
                <span className="text-[11px] font-medium text-muted-foreground">Объекты</span>
                <Building2Icon className="size-3.5 text-muted-foreground" />
              </div>
              <div className="mt-1 text-xl font-semibold tabular-nums text-foreground">
                {dashboard.kpi.activeObjectsCount}
              </div>
              <p className="mt-0.5 text-[11px] text-muted-foreground truncate">
                Всего объектов: {dashboard.kpi.totalObjectsCount}
              </p>
            </Card>
          </Link>

          <Link href="/employees" className="block no-underline">
            <Card className="p-3 transition-colors hover:border-foreground/20">
              <div className="flex items-center justify-between">
                <span className="text-[11px] font-medium text-muted-foreground">Персонал</span>
                <UsersIcon className="size-3.5 text-muted-foreground" />
              </div>
              <div className="mt-1 text-xl font-semibold tabular-nums text-foreground">
                {dashboard.kpi.totalEmployeesCount ?? "—"}
              </div>
              <p className="mt-0.5 text-[11px] text-muted-foreground truncate">
                Сотрудников в штате
              </p>
            </Card>
          </Link>

          <Link href="/works" className="block no-underline">
            <Card className="p-3 transition-colors hover:border-foreground/20">
              <div className="flex items-center justify-between">
                <span className="text-[11px] font-medium text-muted-foreground">Выработка</span>
                <ClockIcon className="size-3.5 text-muted-foreground" />
              </div>
              <div className="mt-1 text-sm font-semibold tabular-nums text-foreground truncate">
                {dashboard.kpi.todayVolume > 0
                  ? formatCurrency(dashboard.kpi.todayVolume)
                  : "0 ₽"}
              </div>
              <p className="mt-0.5 text-[11px] text-muted-foreground truncate">
                Сумма за сегодня
              </p>
            </Card>
          </Link>
        </div>

        {/* Dual-Axis Analytics Chart: Work Output & Attendance */}
        <HomeAnalyticsChart
          works={dashboard.monthWorks}
          hoursByWorkId={dashboard.hoursByWorkId}
          minOutputPerPersonHour={dashboard.minOutputPerPersonHour}
          activeObjects={dashboard.activeObjects}
          variant="mobile"
        />

        {/* Today's Shifts Section */}
        <div className="flex flex-col gap-2">
          <div className="flex items-center justify-between px-0.5">
            <h3 className="text-sm font-semibold text-foreground">
              Сегодня на объектах
            </h3>
            <Link
              href="/works"
              className="flex items-center gap-1 text-xs font-medium text-muted-foreground hover:text-foreground"
            >
              <span>Все смены</span>
              <ArrowRightIcon className="size-3" />
            </Link>
          </div>

          {dashboard.todayShifts.length === 0 ? (
            <Card className="p-4 text-center">
              <p className="text-xs text-muted-foreground">
                Сегодня смены ещё не открывались
              </p>
              {canOpenShift && (
                <Button
                  variant="outline"
                  size="sm"
                  onClick={handleOpenShiftClick}
                  className="mt-3 h-8 text-xs gap-1.5 w-full"
                >
                  <PlusIcon className="size-3.5" />
                  <span>Открыть первую смену</span>
                </Button>
              )}
            </Card>
          ) : (
            <div className="flex flex-col gap-2.5">
              {dashboard.todayShifts.map((shift) => (
                <Link
                  key={shift.id}
                  href="/works"
                  className="block no-underline"
                >
                  <Card className="p-3 transition-colors hover:border-foreground/20">
                    <div className="flex items-start gap-3">
                      <div className="relative size-11 shrink-0 overflow-hidden rounded-md border border-border/80 bg-muted flex items-center justify-center">
                        {shift.photoUrl ? (
                          <Image
                            src={shift.photoUrl}
                            alt={shift.objectName}
                            fill
                            unoptimized
                            className="object-cover"
                          />
                        ) : (
                          <CameraIcon className="size-4 text-muted-foreground/60" />
                        )}
                      </div>

                      <div className="min-w-0 flex-1">
                        <div className="flex items-center justify-between gap-1.5">
                          <h4 className="truncate text-xs font-medium text-foreground">
                            {shift.objectName}
                          </h4>
                          <WorkStatusBadge status={shift.status} />
                        </div>

                        <div className="mt-1 flex items-center gap-2 text-[11px] text-muted-foreground">
                          <span className="flex items-center gap-1 truncate">
                            <UserIcon className="size-3 shrink-0" />
                            <span className="truncate">{shift.openedByName || "—"}</span>
                          </span>
                          <span>•</span>
                          <span className="shrink-0">{shift.employeesCount} чел.</span>
                        </div>

                        {shift.totalAmount > 0 && (
                          <div className="mt-1 text-[11px] font-medium text-foreground">
                            {formatCurrency(shift.totalAmount)}
                          </div>
                        )}
                      </div>
                    </div>
                  </Card>
                </Link>
              ))}
            </div>
          )}
        </div>

        {/* Quick Hub Navigation Tiles */}
        <div className="flex flex-col gap-2">
          <h3 className="text-sm font-semibold text-foreground px-0.5">
            Быстрый доступ
          </h3>

          <div className="grid grid-cols-2 gap-2">
            <Link
              href="/works"
              className="flex items-center gap-2.5 rounded-lg border border-border/70 bg-card p-2.5 transition-colors hover:border-foreground/20"
            >
              <div className="flex size-8 shrink-0 items-center justify-center rounded-md bg-muted text-foreground">
                <WrenchIcon className="size-4" />
              </div>
              <div className="min-w-0 flex-1">
                <p className="truncate text-xs font-medium text-foreground">Работы</p>
                <p className="truncate text-[10px] text-muted-foreground">Учет смен</p>
              </div>
            </Link>

            <Link
              href="/timesheet"
              className="flex items-center gap-2.5 rounded-lg border border-border/70 bg-card p-2.5 transition-colors hover:border-foreground/20"
            >
              <div className="flex size-8 shrink-0 items-center justify-center rounded-md bg-muted text-foreground">
                <ClockIcon className="size-4" />
              </div>
              <div className="min-w-0 flex-1">
                <p className="truncate text-xs font-medium text-foreground">Табель</p>
                <p className="truncate text-[10px] text-muted-foreground">Часы и выходы</p>
              </div>
            </Link>

            <Link
              href="/objects"
              className="flex items-center gap-2.5 rounded-lg border border-border/70 bg-card p-2.5 transition-colors hover:border-foreground/20"
            >
              <div className="flex size-8 shrink-0 items-center justify-center rounded-md bg-muted text-foreground">
                <Building2Icon className="size-4" />
              </div>
              <div className="min-w-0 flex-1">
                <p className="truncate text-xs font-medium text-foreground">Объекты</p>
                <p className="truncate text-[10px] text-muted-foreground">Стройплощадки</p>
              </div>
            </Link>

            <Link
              href="/profile"
              className="flex items-center gap-2.5 rounded-lg border border-border/70 bg-card p-2.5 transition-colors hover:border-foreground/20"
            >
              <div className="flex size-8 shrink-0 items-center justify-center rounded-md bg-muted text-foreground">
                <UserCheckIcon className="size-4" />
              </div>
              <div className="min-w-0 flex-1">
                <p className="truncate text-xs font-medium text-foreground">Профиль</p>
                <p className="truncate text-[10px] text-muted-foreground">Финансы и роль</p>
              </div>
            </Link>
          </div>
        </div>

        {/* Active Objects List */}
        <div className="flex flex-col gap-2">
          <div className="flex items-center justify-between px-0.5">
            <h3 className="text-sm font-semibold text-foreground">
              Объекты в работе
            </h3>
            <Link
              href="/objects"
              className="text-xs font-medium text-muted-foreground hover:text-foreground"
            >
              Все ({dashboard.activeObjects.length})
            </Link>
          </div>

          <div className="flex flex-col gap-2">
            {dashboard.activeObjects.slice(0, 3).map((obj) => (
              <Card key={obj.id} className="p-3">
                <div className="flex items-center justify-between gap-2">
                  <span className="truncate text-xs font-medium text-foreground">
                    {obj.name}
                  </span>
                  <ObjectStatusBadge status={obj.status} />
                </div>
                {obj.address && (
                  <p className="mt-1 flex items-center gap-1 text-[11px] text-muted-foreground truncate">
                    <MapPinIcon className="size-3 shrink-0" />
                    <span className="truncate">{obj.address}</span>
                  </p>
                )}
              </Card>
            ))}
          </div>
        </div>
      </div>

      {/* Sheet for opening a shift on mobile */}
      <WorkOpenSheet
        open={openShiftSheetOpen}
        onOpenChange={setOpenShiftSheetOpen}
        onOpened={handleShiftOpened}
      />
    </div>
  );
}
