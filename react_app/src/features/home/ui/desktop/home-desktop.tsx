"use client";

import { useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import {
  Building2Icon,
  ClockIcon,
  FileSpreadsheetIcon,
  HandshakeIcon,
  HardHatIcon,
  PlusIcon,
  RefreshCwIcon,
  ShieldIcon,
  UserCheckIcon,
  UsersIcon,
  WrenchIcon,
} from "lucide-react";
import { toast } from "sonner";

import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { useHomeDashboard } from "@/features/home/hooks/use-home-dashboard";
import { ActiveObjectsCard } from "@/features/home/ui/components/active-objects-card";
import { HomeAnalyticsChart } from "@/features/home/ui/components/home-analytics-chart";
import { HomeKpiCard } from "@/features/home/ui/components/home-kpi-card";
import { ModulesHubCard } from "@/features/home/ui/components/modules-hub-card";
import { RecentActivityCard } from "@/features/home/ui/components/recent-activity-card";
import { TodayShiftsSection } from "@/features/home/ui/components/today-shifts-section";
import { useMyOpenWorkId } from "@/features/works/hooks/use-open-work";
import type { Work } from "@/features/works/types/work.types";
import { WorkOpenDialog } from "@/features/works/ui/shared/work-open-dialog";
import { cn } from "@/lib/utils";

export function HomeDesktop() {
  const router = useRouter();
  const dashboard = useHomeDashboard();
  const myOpenQuery = useMyOpenWorkId();
  const [openShiftDialogOpen, setOpenShiftDialogOpen] = useState(false);

  const canOpenShift = dashboard.can("works", "create");

  function handleOpenShiftClick() {
    if (myOpenQuery.data) {
      toast.error(
        "У вас уже есть открытая смена. Закройте её перед открытием новой."
      );
      router.push("/works");
      return;
    }
    setOpenShiftDialogOpen(true);
  }

  function handleShiftOpened(work: Work) {
    toast.success(`Смена на объекте «${work.objectName}» открыта`);
    void dashboard.refetch();
  }

  if (dashboard.isLoading) {
    return <HomeDesktopSkeleton />;
  }

  return (
    <div className="flex min-w-0 w-full flex-1 flex-col gap-5">
      {/* Hero Banner */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 rounded-xl border border-border/80 bg-gradient-to-r from-muted/50 via-muted/20 to-background p-5 shadow-xs">
        <div className="min-w-0 flex-1">
          <div className="flex items-center gap-2 flex-wrap">
            <Badge variant="outline" className="gap-1.5 py-0.5 px-2 text-xs font-normal">
              <Building2Icon className="size-3.5 text-muted-foreground" />
              <span className="font-medium text-foreground">{dashboard.companyName}</span>
            </Badge>

            <span className="text-xs text-muted-foreground">•</span>

            <span className="text-xs text-muted-foreground">
              {dashboard.dateLabel}
            </span>
          </div>

          <h2 className="mt-2 font-heading text-2xl sm:text-3xl font-semibold tracking-tight text-foreground">
            {dashboard.greeting}
          </h2>

          <div className="mt-1.5 flex items-center gap-2 text-xs text-muted-foreground">
            <span className="flex items-center gap-1">
              <ShieldIcon className="size-3.5" />
              <span>Роль: <strong className="font-medium text-foreground">{dashboard.roleName}</strong></span>
            </span>

            <span>•</span>

            {dashboard.kpi.openShiftsCount > 0 ? (
              <span className="inline-flex items-center gap-1.5 font-medium text-emerald-600 dark:text-emerald-400">
                <span className="size-2 rounded-full bg-emerald-500 animate-pulse" />
                {dashboard.kpi.openShiftsCount} {dashboard.kpi.openShiftsCount === 1 ? "смена открыта" : "смены открыто"}
              </span>
            ) : (
              <span>Все смены закрыты</span>
            )}
          </div>
        </div>

        {/* Top actions */}
        <div className="flex items-center gap-2 self-start sm:self-center shrink-0">
          <Button
            variant="outline"
            size="sm"
            onClick={() => void dashboard.refetch()}
            disabled={dashboard.isRefetching}
            className="h-9 gap-1.5 text-xs"
          >
            <RefreshCwIcon
              className={cn("size-3.5", dashboard.isRefetching && "animate-spin")}
            />
            <span>Обновить</span>
          </Button>

          {canOpenShift && (
            <Button
              variant="default"
              size="sm"
              onClick={handleOpenShiftClick}
              className="h-9 gap-1.5 text-xs font-medium"
            >
              <PlusIcon className="size-4" />
              <span>Открыть смену</span>
            </Button>
          )}
        </div>
      </div>

      {/* 4 KPI Metric Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-3.5">
        <HomeKpiCard
          title="Смены сегодня"
          value={dashboard.kpi.openShiftsCount}
          subtitle={
            dashboard.kpi.todayWorkersCount > 0
              ? `${dashboard.kpi.todayWorkersCount} чел. на объектах`
              : "Нет активных рабочих"
          }
          icon={HardHatIcon}
          accent={dashboard.kpi.openShiftsCount > 0 ? "success" : "default"}
          badge={
            dashboard.kpi.openShiftsCount > 0
              ? { text: "В работе", variant: "success" }
              : undefined
          }
          href="/works"
        />

        <HomeKpiCard
          title="Объекты в работе"
          value={dashboard.kpi.activeObjectsCount}
          subtitle={`Всего объектов: ${dashboard.kpi.totalObjectsCount}`}
          icon={Building2Icon}
          badge={{ text: "Активные", variant: "secondary" }}
          href="/objects"
        />

        <HomeKpiCard
          title="Персонал в штате"
          value={
            dashboard.kpi.totalEmployeesCount !== null
              ? dashboard.kpi.totalEmployeesCount
              : "—"
          }
          subtitle="Сотрудники компании"
          icon={UsersIcon}
          href="/employees"
        />

        <HomeKpiCard
          title="Договоры"
          value={
            dashboard.kpi.activeContractsCount !== null
              ? dashboard.kpi.activeContractsCount
              : "—"
          }
          subtitle="Действующие договоры"
          icon={HandshakeIcon}
          href="/contracts"
        />
      </div>

      {/* Main Grid: Left Column (Content) + Right Column (Aside) */}
      <div className="grid min-h-fit min-w-0 w-full flex-1 grid-cols-1 content-start items-start gap-4 lg:grid-cols-[minmax(0,1fr)_var(--content-aside-width)] lg:gap-6">
        {/* Left main column */}
        <div className="flex min-w-0 flex-1 flex-col gap-5">
          {/* Dual-Axis Analytics Chart: Work Output & Attendance */}
          <HomeAnalyticsChart
            works={dashboard.monthWorks}
            hoursByWorkId={dashboard.hoursByWorkId}
            minOutputPerPersonHour={dashboard.minOutputPerPersonHour}
            activeObjects={dashboard.activeObjects}
            variant="desktop"
          />

          {/* Today's Shifts Live Section */}
          <TodayShiftsSection
            shifts={dashboard.todayShifts}
            canOpenShift={canOpenShift}
            onOpenShiftClick={handleOpenShiftClick}
          />

          {/* Active Projects */}
          <ActiveObjectsCard objects={dashboard.activeObjects} />

          {/* Recent Shifts stream */}
          <RecentActivityCard works={dashboard.recentWorks} />
        </div>

        {/* Right aside column */}
        <aside className="flex min-w-0 flex-col gap-4 lg:sticky lg:top-0 lg:self-start">
          {/* Quick Actions Card */}
          <Card className="overflow-hidden border-border/80 shadow-xs">
            <CardHeader className="pb-3 border-b border-border/50">
              <CardTitle className="text-sm font-medium">Быстрые действия</CardTitle>
            </CardHeader>
            <CardContent className="p-3 flex flex-col gap-2">
              {canOpenShift && (
                <Button
                  variant="default"
                  size="sm"
                  onClick={handleOpenShiftClick}
                  className="w-full justify-start gap-2 h-9 text-xs"
                >
                  <PlusIcon className="size-3.5" />
                  <span>Открыть новую смену</span>
                </Button>
              )}

              <Button
                variant="outline"
                size="sm"
                render={<Link href="/works" />}
                nativeButton={false}
                className="w-full justify-start gap-2 h-9 text-xs"
              >
                <WrenchIcon className="size-3.5" />
                <span>Календарь и журнал смен</span>
              </Button>

              <Button
                variant="outline"
                size="sm"
                render={<Link href="/timesheet" />}
                nativeButton={false}
                className="w-full justify-start gap-2 h-9 text-xs"
              >
                <ClockIcon className="size-3.5" />
                <span>Табель учета времени</span>
              </Button>

              <Button
                variant="outline"
                size="sm"
                render={<Link href="/work-journal" />}
                nativeButton={false}
                className="w-full justify-start gap-2 h-9 text-xs"
              >
                <FileSpreadsheetIcon className="size-3.5" />
                <span>Сводный журнал выработки</span>
              </Button>
            </CardContent>
          </Card>

          {/* Modules Hub */}
          <ModulesHubCard modules={dashboard.navModules} />

          {/* Organization & Profile Card */}
          <Card className="overflow-hidden border-border/80 bg-muted/20 shadow-xs">
            <CardContent className="p-4 flex flex-col gap-2.5">
              <div className="flex items-center justify-between">
                <span className="text-xs font-medium text-muted-foreground">
                  Организация
                </span>
                <Badge variant="outline" className="text-[10px] h-4.5">
                  Multi-tenant
                </Badge>
              </div>

              <div className="text-sm font-semibold text-foreground">
                {dashboard.companyName}
              </div>

              <div className="flex items-center justify-between text-xs text-muted-foreground pt-1 border-t border-border/50">
                <span className="flex items-center gap-1.5">
                  <UserCheckIcon className="size-3.5" />
                  <span>{dashboard.userName}</span>
                </span>
                <span className="font-medium text-foreground">
                  {dashboard.roleName}
                </span>
              </div>

              <Button
                variant="ghost"
                size="sm"
                render={<Link href="/profile" />}
                nativeButton={false}
                className="mt-1 w-full text-xs h-7.5"
              >
                Перейти в личный кабинет
              </Button>
            </CardContent>
          </Card>
        </aside>
      </div>

      {/* Dialog for opening a shift */}
      <WorkOpenDialog
        open={openShiftDialogOpen}
        onOpenChange={setOpenShiftDialogOpen}
        onOpened={handleShiftOpened}
      />
    </div>
  );
}

function HomeDesktopSkeleton() {
  return (
    <div className="flex min-w-0 w-full flex-1 flex-col gap-5 animate-pulse">
      <div className="h-28 rounded-xl border border-border/60 bg-muted/40" />

      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-3.5">
        {Array.from({ length: 4 }).map((_, i) => (
          <div key={i} className="h-24 rounded-xl border border-border/60 bg-muted/40" />
        ))}
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-[minmax(0,1fr)_var(--content-aside-width)] gap-6">
        <div className="flex flex-col gap-5">
          <div className="h-56 rounded-xl border border-border/60 bg-muted/40" />
          <div className="h-44 rounded-xl border border-border/60 bg-muted/40" />
        </div>
        <div className="h-80 rounded-xl border border-border/60 bg-muted/40" />
      </div>
    </div>
  );
}
