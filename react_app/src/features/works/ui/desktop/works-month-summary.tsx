"use client";

import { useState, type ReactNode } from "react";
import type { LucideIcon } from "lucide-react";
import {
  BanknoteIcon,
  BriefcaseIcon,
  Building2Icon,
  CheckCircle2Icon,
  ClockIcon,
  HammerIcon,
  LayersIcon,
  MapPinIcon,
  TrendingUpIcon,
  UsersIcon,
  WalletIcon,
  XIcon,
} from "lucide-react";

import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";
import {
  useMonthEmployeesSummary,
  useMonthHoursSummary,
  useMonthObjectsSummary,
  useMonthSystemsSummary,
  useMonthWorks,
} from "@/features/works/hooks/use-works";
import type { MonthHeader } from "@/features/works/types/work.types";
import { WorksDailyChart } from "@/features/works/ui/desktop/works-daily-chart";
import { WorksPaneHeader } from "@/features/works/ui/desktop/works-pane-header";
import {
  formatCurrency,
  formatMonthYear,
  formatPercent,
  formatQuantity,
  isCurrentMonth,
} from "@/features/works/utils/work.utils";
import { cn } from "@/lib/utils";

type WorksMonthSummaryProps = {
  header: MonthHeader | null;
  selectedObjectId: string | null;
  openedBy?: string;
  onSelectObject: (objectId: string | null) => void;
};

type WorksMonthSummaryHeaderProps = {
  header: MonthHeader | null;
  actions?: ReactNode;
};

export function WorksMonthSummaryHeader({
  header,
  actions,
}: WorksMonthSummaryHeaderProps) {
  return (
    <WorksPaneHeader title="Сводка">
      <div className="flex min-w-0 flex-1 items-center gap-2">
        <span className="min-w-0 truncate font-medium">
          {header ? formatMonthYear(header.month) : "Месяц не выбран"}
        </span>
        {header && isCurrentMonth(header.month) ? (
          <Badge variant="secondary" className="shrink-0 font-medium">
            Текущий месяц
          </Badge>
        ) : null}
        {header ? (
          <Badge variant="outline" className="shrink-0 tabular-nums">
            {header.worksCount} {pluralShifts(header.worksCount)}
          </Badge>
        ) : null}
      </div>
      {actions ? (
        <div className="flex shrink-0 flex-wrap items-center gap-1.5">{actions}</div>
      ) : null}
    </WorksPaneHeader>
  );
}

export function WorksMonthSummary({
  header,
  selectedObjectId,
  openedBy,
  onSelectObject,
}: WorksMonthSummaryProps) {
  const [showAllSystems, setShowAllSystems] = useState(false);

  const month = header?.month ?? null;
  const objectsQuery = useMonthObjectsSummary(month);
  const systemsQuery = useMonthSystemsSummary(
    month,
    selectedObjectId ?? undefined
  );
  const hoursQuery = useMonthHoursSummary(month, selectedObjectId ?? undefined);
  const employeesQuery = useMonthEmployeesSummary(
    month,
    selectedObjectId ?? undefined
  );
  const worksQuery = useMonthWorks(month ?? "", openedBy, Boolean(month));

  if (!header) {
    return (
      <Card className="shadow-float">
        <CardHeader className="border-b">
          <CardTitle>Сводка по сменам</CardTitle>
          <CardDescription>
            Выберите месяц в списке слева для просмотра подробной аналитики
          </CardDescription>
        </CardHeader>
        <CardContent className="flex flex-col items-center justify-center gap-3 py-12 text-center text-muted-foreground">
          <BriefcaseIcon className="size-10 stroke-1 text-muted-foreground/40" />
          <p className="text-sm">Нет выбранного месяца</p>
        </CardContent>
      </Card>
    );
  }

  const objects = objectsQuery.data ?? [];
  const systems = systemsQuery.data ?? [];
  const works = worksQuery.data ?? [];

  const selectedObject = objects.find(
    (item) => item.objectId === selectedObjectId
  );

  // Financial calculations
  const totalAmount = selectedObject?.totalAmount ?? header.totalAmount;
  const ownAmount = selectedObject?.ownTotalAmount ?? header.ownTotalAmount;
  const subAmount = Math.max(0, totalAmount - ownAmount);

  const ownPercent = totalAmount > 0 ? (ownAmount / totalAmount) * 100 : 0;
  const subPercent = totalAmount > 0 ? (subAmount / totalAmount) * 100 : 0;

  // Operational calculations
  const worksCount = selectedObject?.worksCount ?? header.worksCount;
  const filteredWorks = selectedObjectId
    ? works.filter((w) => w.objectId === selectedObjectId)
    : works;

  const openWorksCount = filteredWorks.filter((w) => w.status === "open").length;
  const closedWorksCount = Math.max(0, worksCount - openWorksCount);

  const totalHours = hoursQuery.data ?? 0;
  const totalEmployees = employeesQuery.data ?? 0;

  const averageShift = worksCount > 0 ? totalAmount / worksCount : 0;
  const productivity = totalEmployees > 0 ? ownAmount / totalEmployees : 0;
  const hourlyRateTotal = totalHours > 0 ? totalAmount / totalHours : 0;
  const hourlyRateOwn = totalHours > 0 ? ownAmount / totalHours : 0;
  const avgHoursPerShift = worksCount > 0 ? totalHours / worksCount : 0;
  const avgEmployeesPerShift = worksCount > 0 ? totalEmployees / worksCount : 0;

  // Systems sorting & slicing
  const sortedSystems = [...systems].sort(
    (a, b) => b.totalAmount - a.totalAmount
  );
  const totalSystemsAmount = systems.reduce(
    (sum, item) => sum + item.totalAmount,
    0
  );
  const displayedSystems = showAllSystems
    ? sortedSystems
    : sortedSystems.slice(0, 5);

  // Objects sorting
  const sortedObjects = [...objects].sort(
    (a, b) => b.totalAmount - a.totalAmount
  );

  return (
    <div className="flex min-w-0 flex-col gap-5">
      {selectedObject ? (
        <div className="flex items-center gap-2 rounded-xl bg-card px-4 py-3 text-xs text-foreground ring-1 ring-foreground/10 shadow-float">
          <MapPinIcon className="size-4 shrink-0 text-muted-foreground" />
          <span className="text-muted-foreground">Фильтр по объекту:</span>
          <strong className="font-medium">{selectedObject.objectName}</strong>
          <Button
            type="button"
            variant="outline"
            size="sm"
            onClick={() => onSelectObject(null)}
            className="ml-auto gap-1.5 text-xs"
          >
            <XIcon className="size-3.5" />
            <span>Сбросить</span>
          </Button>
        </div>
      ) : null}

      {/* 2. Primary Financial Overview Card */}
      <Card className="shadow-float">
        <CardHeader className="border-b pb-3.5">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2">
              <span className="flex size-7 items-center justify-center rounded-md bg-muted text-foreground/80">
                <WalletIcon className="size-4" />
              </span>
              <div>
                <CardTitle className="text-sm font-semibold text-foreground">
                  Финансовый объём выработки
                </CardTitle>
                <CardDescription className="text-xs">
                  Распределение между собственными силами и субподрядом
                </CardDescription>
              </div>
            </div>
            {totalHours > 0 ? (
              <span className="hidden text-xs text-muted-foreground tabular-nums sm:inline-block">
                Средняя ставка:{" "}
                <strong className="font-medium text-foreground">
                  {formatCurrency(hourlyRateTotal)}
                </strong>{" "}
                / час
              </span>
            ) : null}
          </div>
        </CardHeader>
        <CardContent className="flex flex-col gap-5 pt-4">
          <div className="grid grid-cols-1 gap-4 sm:grid-cols-3">
            {/* Total volume */}
            <div className="flex flex-col gap-1 rounded-lg bg-muted/30 p-3.5 ring-1 ring-border/60">
              <span className="text-xs font-medium text-muted-foreground">
                Общий объём
              </span>
              <p className="font-heading text-2xl font-bold tracking-tight tabular-nums text-foreground">
                {formatCurrency(totalAmount)}
              </p>
              {totalHours > 0 ? (
                <span className="text-xs text-muted-foreground tabular-nums">
                  {formatCurrency(hourlyRateTotal)} / час
                </span>
              ) : null}
            </div>

            {/* Own work */}
            <div className="flex flex-col gap-1 rounded-lg bg-muted/30 p-3.5 ring-1 ring-border/60">
              <div className="flex items-center justify-between">
                <span className="text-xs font-medium text-muted-foreground">
                  Своими силами
                </span>
                <Badge variant="secondary" className="h-4.5 px-1.5 text-[11px]">
                  {formatPercent(ownPercent)}
                </Badge>
              </div>
              <p className="font-heading text-xl font-bold tracking-tight tabular-nums text-foreground">
                {formatCurrency(ownAmount)}
              </p>
              {totalHours > 0 ? (
                <span className="text-xs text-muted-foreground tabular-nums">
                  {formatCurrency(hourlyRateOwn)} / час
                </span>
              ) : null}
            </div>

            {/* Subcontractor work */}
            <div className="flex flex-col gap-1 rounded-lg bg-muted/30 p-3.5 ring-1 ring-border/60">
              <div className="flex items-center justify-between">
                <span className="text-xs font-medium text-muted-foreground">
                  Субподряд
                </span>
                <Badge variant="outline" className="h-4.5 px-1.5 text-[11px]">
                  {formatPercent(subPercent)}
                </Badge>
              </div>
              <p className="font-heading text-xl font-bold tracking-tight tabular-nums text-foreground">
                {formatCurrency(subAmount)}
              </p>
              <span className="text-xs text-muted-foreground">
                Сторонние исполнители
              </span>
            </div>
          </div>

          {/* Allocation Progress Bar */}
          {totalAmount > 0 ? (
            <div className="space-y-1.5">
              <div className="flex h-2.5 w-full overflow-hidden rounded-full bg-muted">
                <div
                  className="bg-primary transition-all duration-300"
                  style={{ width: `${Math.max(ownPercent, 2)}%` }}
                  title={`Своими силами: ${formatPercent(ownPercent)}`}
                />
                <div
                  className="bg-muted-foreground/35 transition-all duration-300"
                  style={{ width: `${subPercent}%` }}
                  title={`Субподряд: ${formatPercent(subPercent)}`}
                />
              </div>
              <div className="flex flex-wrap items-center justify-between gap-2 text-xs text-muted-foreground">
                <span className="flex items-center gap-1.5">
                  <span className="size-2 rounded-full bg-primary" />
                  <span>Свои силы:</span>
                  <strong className="font-medium text-foreground">
                    {formatCurrency(ownAmount)}
                  </strong>
                  <span>({formatPercent(ownPercent)})</span>
                </span>
                <span className="flex items-center gap-1.5">
                  <span className="size-2 rounded-full bg-muted-foreground/35" />
                  <span>Субподряд:</span>
                  <strong className="font-medium text-foreground">
                    {formatCurrency(subAmount)}
                  </strong>
                  <span>({formatPercent(subPercent)})</span>
                </span>
              </div>
            </div>
          ) : null}
        </CardContent>
      </Card>

      {/* 3. Daily Activity & Production Chart */}
      <WorksDailyChart
        month={header.month}
        works={works}
        objectId={selectedObjectId}
        isLoading={worksQuery.isLoading}
      />

      {/* 4. Production & Team KPIs */}
      <div className="grid grid-cols-2 gap-3.5 lg:grid-cols-4">
        {/* Shifts */}
        <KpiTile
          label="Всего смен"
          value={String(worksCount)}
          icon={BriefcaseIcon}
          footer={
            <div className="flex items-center gap-2 text-[11px] text-muted-foreground">
              <span className="flex items-center gap-1">
                <span className="size-1.5 rounded-full bg-foreground/60" />
                <span>{closedWorksCount} закр.</span>
              </span>
              {openWorksCount > 0 ? (
                <span className="flex items-center gap-1 font-medium text-success">
                  <span className="size-1.5 rounded-full bg-success" />
                  <span>{openWorksCount} открыто</span>
                </span>
              ) : null}
            </div>
          }
        />

        {/* Hours */}
        <KpiTile
          label="Отработано часов"
          value={hoursQuery.isLoading ? "…" : formatQuantity(totalHours)}
          icon={ClockIcon}
          footer={
            avgHoursPerShift > 0 ? (
              <span className="text-[11px] text-muted-foreground tabular-nums">
                ~{formatQuantity(avgHoursPerShift)} ч на смену
              </span>
            ) : undefined
          }
        />

        {/* Specialists */}
        <KpiTile
          label="Специалистов"
          value={employeesQuery.isLoading ? "…" : String(totalEmployees)}
          icon={UsersIcon}
          footer={
            avgEmployeesPerShift > 0 ? (
              <span className="text-[11px] text-muted-foreground tabular-nums">
                ~{formatQuantity(avgEmployeesPerShift)} чел. на смену
              </span>
            ) : undefined
          }
        />

        {/* Efficiency */}
        <KpiTile
          label="Средняя смена"
          value={formatCurrency(averageShift)}
          icon={TrendingUpIcon}
          footer={
            productivity > 0 ? (
              <span className="text-[11px] text-muted-foreground tabular-nums">
                {formatCurrency(productivity)} / чел.
              </span>
            ) : undefined
          }
        />
      </div>

      {/* 5. Breakdown by Objects and Systems */}
      <div className="grid min-w-0 grid-cols-1 gap-5 lg:grid-cols-2">
        {/* Breakdown by Objects */}
        <Card className="shadow-float">
          <CardHeader className="border-b pb-3">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-2">
                <span className="flex size-7 items-center justify-center rounded-md bg-muted text-foreground/80">
                  <Building2Icon className="size-4" />
                </span>
                <div>
                  <CardTitle className="text-sm font-semibold text-foreground">
                    По объектам
                  </CardTitle>
                  <CardDescription className="text-xs">
                    Нажмите на объект для фильтрации сводки
                  </CardDescription>
                </div>
              </div>
              <Badge variant="outline" className="text-xs">
                {sortedObjects.length}
              </Badge>
            </div>
          </CardHeader>
          <CardContent className="pt-3">
            {objectsQuery.isLoading ? (
              <div className="space-y-1.5">
                <Skeleton className="h-8 w-full rounded-lg" />
                <Skeleton className="h-8 w-full rounded-lg" />
              </div>
            ) : sortedObjects.length === 0 ? (
              <p className="py-6 text-center text-xs text-muted-foreground">
                Нет данных по объектам за этот месяц
              </p>
            ) : (
              <div className="flex flex-col gap-1">
                {sortedObjects.map((item, index) => {
                  const isSelected = selectedObjectId === item.objectId;
                  const share =
                    totalAmount > 0
                      ? (item.totalAmount / totalAmount) * 100
                      : 0;

                  return (
                    <button
                      key={item.objectId}
                      type="button"
                      onClick={() =>
                        onSelectObject(isSelected ? null : item.objectId)
                      }
                      className={cn(
                        "group relative flex w-full items-center justify-between overflow-hidden rounded-lg px-2.5 py-2 text-left transition-all focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring",
                        isSelected
                          ? "bg-primary/10 ring-1 ring-primary"
                          : "hover:bg-muted/40"
                      )}
                    >
                      {/* Ambient background progress bar */}
                      <div
                        className={cn(
                          "pointer-events-none absolute inset-y-0 left-0 rounded-lg transition-all duration-300",
                          isSelected
                            ? "bg-primary/20"
                            : "bg-foreground/5 group-hover:bg-foreground/10"
                        )}
                        style={{ width: `${Math.max(share, 1)}%` }}
                      />

                      {/* Content: Left */}
                      <div className="relative z-10 flex min-w-0 flex-1 items-center gap-2 pr-2">
                        <span className="w-4 shrink-0 text-center text-[11px] font-semibold text-muted-foreground/80">
                          #{index + 1}
                        </span>
                        <span className="truncate text-xs font-medium text-foreground">
                          {item.objectName}
                        </span>
                        <span className="shrink-0 text-[11px] text-muted-foreground">
                          · {item.worksCount} {pluralShifts(item.worksCount)}
                        </span>
                        {isSelected ? (
                          <Badge
                            variant="secondary"
                            className="h-4 gap-1 px-1.5 text-[10px] font-medium text-primary"
                          >
                            <CheckCircle2Icon className="size-2.5" />
                            выбран
                          </Badge>
                        ) : null}
                      </div>

                      {/* Content: Right */}
                      <div className="relative z-10 flex shrink-0 items-center gap-2.5 pl-2">
                        <span className="font-heading text-xs font-semibold tabular-nums text-foreground">
                          {formatCurrency(item.totalAmount)}
                        </span>
                        <span className="w-11 text-right text-[11px] tabular-nums text-muted-foreground">
                          {formatPercent(share)}
                        </span>
                      </div>
                    </button>
                  );
                })}
              </div>
            )}
          </CardContent>
        </Card>

        {/* Breakdown by Systems */}
        <Card className="shadow-float">
          <CardHeader className="border-b pb-3">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-2">
                <span className="flex size-7 items-center justify-center rounded-md bg-muted text-foreground/80">
                  <LayersIcon className="size-4" />
                </span>
                <div>
                  <CardTitle className="text-sm font-semibold text-foreground">
                    По системам и работам
                  </CardTitle>
                  <CardDescription className="text-xs">
                    Распределение объемов по видам работ
                  </CardDescription>
                </div>
              </div>
              <Badge variant="outline" className="text-xs">
                {sortedSystems.length}
              </Badge>
            </div>
          </CardHeader>
          <CardContent className="pt-3">
            {systemsQuery.isLoading ? (
              <div className="space-y-1.5">
                <Skeleton className="h-8 w-full rounded-lg" />
                <Skeleton className="h-8 w-full rounded-lg" />
                <Skeleton className="h-8 w-full rounded-lg" />
              </div>
            ) : sortedSystems.length === 0 ? (
              <p className="py-6 text-center text-xs text-muted-foreground">
                Нет данных по системам за этот месяц
              </p>
            ) : (
              <div className="flex flex-col gap-1">
                {displayedSystems.map((item, index) => {
                  const share =
                    totalSystemsAmount > 0
                      ? (item.totalAmount / totalSystemsAmount) * 100
                      : 0;

                  return (
                    <div
                      key={item.system}
                      className="group relative flex w-full items-center justify-between overflow-hidden rounded-lg px-2.5 py-2 text-left transition-colors hover:bg-muted/40"
                    >
                      {/* Ambient background progress bar */}
                      <div
                        className="pointer-events-none absolute inset-y-0 left-0 rounded-lg bg-foreground/5 transition-all duration-300 group-hover:bg-foreground/10"
                        style={{ width: `${Math.max(share, 1)}%` }}
                      />

                      {/* Content: Left */}
                      <div className="relative z-10 flex min-w-0 flex-1 items-center gap-2 pr-2">
                        <span className="w-4 shrink-0 text-center text-[11px] font-semibold text-muted-foreground/80">
                          #{index + 1}
                        </span>
                        <span className="truncate text-xs font-medium text-foreground">
                          {item.system}
                        </span>
                        <span className="shrink-0 text-[11px] text-muted-foreground">
                          · {item.itemsCount} {pluralJobs(item.itemsCount)}
                        </span>
                      </div>

                      {/* Content: Right */}
                      <div className="relative z-10 flex shrink-0 items-center gap-2.5 pl-2">
                        <span className="font-heading text-xs font-semibold tabular-nums text-foreground">
                          {formatCurrency(item.totalAmount)}
                        </span>
                        <span className="w-11 text-right text-[11px] tabular-nums text-muted-foreground">
                          {formatPercent(share)}
                        </span>
                      </div>
                    </div>
                  );
                })}

                {sortedSystems.length > 5 ? (
                  <Button
                    type="button"
                    variant="ghost"
                    size="xs"
                    className="mt-1 w-full text-xs text-muted-foreground hover:text-foreground"
                    onClick={() => setShowAllSystems((prev) => !prev)}
                  >
                    {showAllSystems
                      ? "Свернуть список"
                      : `Показать все системы (${sortedSystems.length})`}
                  </Button>
                ) : null}
              </div>
            )}
          </CardContent>
        </Card>
      </div>
    </div>
  );
}

function KpiTile({
  label,
  value,
  icon: Icon,
  footer,
}: {
  label: string;
  value: string;
  icon: LucideIcon;
  footer?: React.ReactNode;
}) {
  return (
    <div className="flex flex-col justify-between gap-3 rounded-xl bg-card p-4 ring-1 ring-foreground/10 shadow-float">
      <div className="flex items-center justify-between gap-2">
        <span className="text-xs font-medium text-muted-foreground">
          {label}
        </span>
        <span className="flex size-7 items-center justify-center rounded-md bg-muted text-foreground/70">
          <Icon className="size-3.5" />
        </span>
      </div>

      <div className="space-y-1">
        <p className="font-heading text-xl font-bold tracking-tight tabular-nums text-foreground sm:text-2xl">
          {value}
        </p>
        {footer}
      </div>
    </div>
  );
}

function pluralShifts(count: number): string {
  const mod10 = count % 10;
  const mod100 = count % 100;
  if (mod100 >= 11 && mod100 <= 19) {
    return "смен";
  }
  if (mod10 === 1) {
    return "смена";
  }
  if (mod10 >= 2 && mod10 <= 4) {
    return "смены";
  }
  return "смен";
}

function pluralJobs(count: number): string {
  const mod10 = count % 10;
  const mod100 = count % 100;
  if (mod100 >= 11 && mod100 <= 19) {
    return "позиций";
  }
  if (mod10 === 1) {
    return "позиция";
  }
  if (mod10 >= 2 && mod10 <= 4) {
    return "позиции";
  }
  return "позиций";
}
