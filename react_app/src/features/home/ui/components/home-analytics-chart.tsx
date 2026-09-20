"use client";

import { useEffect, useId, useMemo, useState } from "react";
import { TrendingUpIcon } from "lucide-react";

import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import {
  Select,
  SelectContent,
  SelectGroup,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import type { SiteObject } from "@/features/objects/types/object.types";
import type { Work } from "@/features/works/types/work.types";
import {
  daysInMonth,
  formatCurrency,
  formatDayFullRu,
  formatPercent,
  toDateKey,
} from "@/features/works/utils/work.utils";
import { cn } from "@/lib/utils";

type ChartPeriod = "14days" | "month";

type AnalyticsPoint = {
  dayNum: number;
  fullDateLabel: string;
  volume: number;
  workersCount: number;
  hours: number;
  plan: number;
  shiftsCount: number;
};

type HomeAnalyticsChartProps = {
  works: Work[];
  hoursByWorkId: Record<string, number>;
  minOutputPerPersonHour: number | null;
  activeObjects: SiteObject[];
  className?: string;
  variant?: "desktop" | "mobile";
};

function dayMetrics(
  dayWorks: Work[],
  hoursByWorkId: Record<string, number>,
  minOutputPerPersonHour: number | null
) {
  const volume = dayWorks.reduce((acc, work) => acc + (work.totalAmount || 0), 0);
  const workersCount = dayWorks.reduce(
    (acc, work) => acc + (work.employeesCount || 0),
    0
  );
  const hours = dayWorks.reduce(
    (acc, work) => acc + (hoursByWorkId[work.id] ?? 0),
    0
  );
  const hasNorm =
    minOutputPerPersonHour !== null && minOutputPerPersonHour > 0;
  const plan = hasNorm ? hours * minOutputPerPersonHour : 0;

  return {
    volume,
    workersCount,
    hours,
    plan,
    shiftsCount: dayWorks.length,
  };
}

function formatCompactRub(value: number): string {
  if (value === 0) return "0 ₽";
  if (value >= 1_000_000) {
    const val = (value / 1_000_000).toFixed(1).replace(".0", "");
    return `${val} млн ₽`;
  }
  if (value >= 1_000) {
    const val = Math.round(value / 1_000);
    return `${val} тыс. ₽`;
  }
  return `${Math.round(value)} ₽`;
}

// Generate smooth cubic bezier SVG path from points
function getSmoothSvgPath(
  points: { x: number; y: number }[],
  closeToY?: number
): string {
  if (points.length === 0) return "";
  if (points.length === 1) return `M ${points[0].x} ${points[0].y}`;

  let path = `M ${points[0].x.toFixed(1)} ${points[0].y.toFixed(1)}`;

  for (let i = 0; i < points.length - 1; i++) {
    const p0 = points[i === 0 ? 0 : i - 1];
    const p1 = points[i];
    const p2 = points[i + 1];
    const p3 = points[i + 2] ?? p2;

    const tension = 0.2;
    const cp1x = p1.x + (p2.x - p0.x) * tension;
    const cp1y = p1.y + (p2.y - p0.y) * tension;
    const cp2x = p2.x - (p3.x - p1.x) * tension;
    const cp2y = p2.y - (p3.y - p1.y) * tension;

    path += ` C ${cp1x.toFixed(1)} ${cp1y.toFixed(1)}, ${cp2x.toFixed(1)} ${cp2y.toFixed(1)}, ${p2.x.toFixed(1)} ${p2.y.toFixed(1)}`;
  }

  if (closeToY !== undefined) {
    const last = points[points.length - 1];
    const first = points[0];
    path += ` L ${last.x.toFixed(1)} ${closeToY.toFixed(1)} L ${first.x.toFixed(1)} ${closeToY.toFixed(1)} Z`;
  }

  return path;
}

export function HomeAnalyticsChart({
  works,
  hoursByWorkId,
  minOutputPerPersonHour,
  activeObjects,
  className,
  variant = "desktop",
}: HomeAnalyticsChartProps) {
  const gradientId = useId();
  const [period, setPeriod] = useState<ChartPeriod>(
    variant === "mobile" ? "14days" : "month"
  );
  const [selectedObjectId, setSelectedObjectId] = useState<string>("all");
  const [showVolume, setShowVolume] = useState(true);
  const [showAttendance, setShowAttendance] = useState(true);
  const [showPlan, setShowPlan] = useState(true);
  const hasNorm =
    minOutputPerPersonHour !== null && minOutputPerPersonHour > 0;
  const [activeIndex, setActiveIndex] = useState<number | null>(null);

  useEffect(() => {
    if (selectedObjectId === "all") {
      return;
    }
    const stillVisible = activeObjects.some((object) => object.id === selectedObjectId);
    if (!stillVisible) {
      setSelectedObjectId("all");
    }
  }, [activeObjects, selectedObjectId]);

  const filteredWorks = useMemo(() => {
    if (selectedObjectId === "all") return works;
    return works.filter((w) => w.objectId === selectedObjectId);
  }, [works, selectedObjectId]);

  // 2. Build Daily Series according to period
  const dataPoints: AnalyticsPoint[] = useMemo(() => {
    const today = new Date();
    const currentYear = today.getFullYear();
    const currentMonth = today.getMonth();
    const worksByDate = new Map<string, Work[]>();
    for (const work of filteredWorks) {
      const key = work.date.slice(0, 10);
      const list = worksByDate.get(key) ?? [];
      list.push(work);
      worksByDate.set(key, list);
    }

    function pointForDate(d: Date): AnalyticsPoint {
      const dateKey = toDateKey(d);
      const dayWorks = worksByDate.get(dateKey) ?? [];
      const metrics = dayMetrics(
        dayWorks,
        hoursByWorkId,
        minOutputPerPersonHour
      );

      return {
        dayNum: d.getDate(),
        fullDateLabel: formatDayFullRu(dateKey),
        ...metrics,
      };
    }

    if (period === "14days") {
      const points: AnalyticsPoint[] = [];
      for (let i = 13; i >= 0; i--) {
        const d = new Date(today);
        d.setDate(today.getDate() - i);
        points.push(pointForDate(d));
      }
      return points;
    }

    const monthKey = `${currentYear}-${String(currentMonth + 1).padStart(2, "0")}`;
    const totalDays = daysInMonth(monthKey);
    const points: AnalyticsPoint[] = [];

    for (let day = 1; day <= totalDays; day++) {
      points.push(pointForDate(new Date(currentYear, currentMonth, day)));
    }

    return points;
  }, [filteredWorks, period, hoursByWorkId, minOutputPerPersonHour]);

  // Aggregated totals
  const totalPeriodVolume = useMemo(
    () => dataPoints.reduce((acc, p) => acc + p.volume, 0),
    [dataPoints]
  );
  const totalPeriodPlan = useMemo(
    () => dataPoints.reduce((acc, p) => acc + p.plan, 0),
    [dataPoints]
  );
  const planCompletion =
    hasNorm && totalPeriodPlan > 0
      ? (totalPeriodVolume / totalPeriodPlan) * 100
      : null;

  const activeDaysWithWorkers = useMemo(
    () => dataPoints.filter((p) => p.workersCount > 0),
    [dataPoints]
  );

  const avgWorkers = useMemo(() => {
    if (activeDaysWithWorkers.length === 0) return 0;
    const sum = activeDaysWithWorkers.reduce((acc, p) => acc + p.workersCount, 0);
    return Math.round(sum / activeDaysWithWorkers.length);
  }, [activeDaysWithWorkers]);

  const totalShiftsCount = useMemo(
    () => dataPoints.reduce((acc, p) => acc + p.shiftsCount, 0),
    [dataPoints]
  );

  // SVG Coordinate Space
  const svgWidth = 800;
  const svgHeight = variant === "mobile" ? 220 : 250;
  const paddingLeft = variant === "mobile" ? 54 : 68;
  const paddingRight = variant === "mobile" ? 44 : 54;
  const paddingTop = 24;
  const paddingBottom = 34;

  const chartInnerWidth = svgWidth - paddingLeft - paddingRight;
  const chartInnerHeight = svgHeight - paddingTop - paddingBottom;

  // Max calculations with sensible padding and rounding
  const rawMaxVolume = Math.max(
    ...dataPoints.map((p) => Math.max(p.volume, hasNorm ? p.plan : 0)),
    0
  );
  const maxVolume = useMemo(() => {
    if (rawMaxVolume === 0) return 100_000;
    // Round up to nearest nice power
    const magnitude = Math.pow(10, Math.floor(Math.log10(rawMaxVolume)));
    return Math.ceil((rawMaxVolume * 1.15) / magnitude) * magnitude;
  }, [rawMaxVolume]);

  const rawMaxWorkers = Math.max(...dataPoints.map((p) => p.workersCount), 0);
  const maxWorkers = useMemo(() => {
    if (rawMaxWorkers === 0) return 10;
    return Math.max(Math.ceil((rawMaxWorkers * 1.2) / 5) * 5, 5);
  }, [rawMaxWorkers]);

  // Map points to SVG coordinates
  const coords = useMemo(() => {
    const n = dataPoints.length;
    if (n === 0) return [];

    return dataPoints.map((p, index) => {
      const x =
        n === 1
          ? paddingLeft + chartInnerWidth / 2
          : paddingLeft + (index / (n - 1)) * chartInnerWidth;

      const yVolume =
        paddingTop +
        chartInnerHeight -
        (p.volume / maxVolume) * chartInnerHeight;

      const yWorkers =
        paddingTop +
        chartInnerHeight -
        (p.workersCount / maxWorkers) * chartInnerHeight;

      const yPlan =
        paddingTop +
        chartInnerHeight -
        (p.plan / maxVolume) * chartInnerHeight;

      return {
        point: p,
        index,
        x,
        yVolume: Math.max(paddingTop, Math.min(paddingTop + chartInnerHeight, yVolume)),
        yWorkers: Math.max(paddingTop, Math.min(paddingTop + chartInnerHeight, yWorkers)),
        yPlan: Math.max(paddingTop, Math.min(paddingTop + chartInnerHeight, yPlan)),
      };
    });
  }, [dataPoints, chartInnerWidth, chartInnerHeight, paddingLeft, paddingTop, maxVolume, maxWorkers]);

  // Paths
  const volumePoints = useMemo(
    () => coords.map((c) => ({ x: c.x, y: c.yVolume })),
    [coords]
  );
  const planPoints = useMemo(
    () => coords.map((c) => ({ x: c.x, y: c.yPlan })),
    [coords]
  );
  const workersPoints = useMemo(
    () => coords.map((c) => ({ x: c.x, y: c.yWorkers })),
    [coords]
  );

  const baselineY = paddingTop + chartInnerHeight;
  const volumeLinePath = useMemo(() => getSmoothSvgPath(volumePoints), [volumePoints]);
  const volumeAreaPath = useMemo(
    () => getSmoothSvgPath(volumePoints, baselineY),
    [volumePoints, baselineY]
  );
  const workersLinePath = useMemo(() => getSmoothSvgPath(workersPoints), [workersPoints]);
  const planLinePath = useMemo(() => getSmoothSvgPath(planPoints), [planPoints]);

  // Hover / Touch interaction
  function handlePointerMove(e: React.PointerEvent<SVGSVGElement>) {
    const rect = e.currentTarget.getBoundingClientRect();
    const clientX = e.clientX - rect.left;
    const ratio = Math.max(0, Math.min(1, clientX / rect.width));
    const targetSvgX = ratio * svgWidth;

    // Find closest index
    let closestIndex = 0;
    let minDiff = Infinity;
    for (let i = 0; i < coords.length; i++) {
      const diff = Math.abs(coords[i].x - targetSvgX);
      if (diff < minDiff) {
        minDiff = diff;
        closestIndex = i;
      }
    }
    setActiveIndex(closestIndex);
  }

  function handlePointerLeave() {
    setActiveIndex(null);
  }

  const activeCoord = activeIndex !== null ? coords[activeIndex] : null;

  // Selected object name for label
  const objectItems = useMemo(
    () => [
      { value: "all", label: `Все объекты (${activeObjects.length})` },
      ...activeObjects.map((obj) => ({ value: obj.id, label: obj.name })),
    ],
    [activeObjects]
  );

  return (
    <Card className={cn("overflow-hidden border-border/80 shadow-xs", className)}>
      <CardHeader className="flex flex-col gap-3 pb-3 border-b border-border/50">
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
          <div>
            <div className="flex items-center gap-2">
              <div className="flex size-7 items-center justify-center rounded-lg bg-primary/10 text-primary">
                <TrendingUpIcon className="size-4" />
              </div>
              <CardTitle className="text-base font-semibold text-foreground">
                Динамика выработки и посещаемости
              </CardTitle>
            </div>
            <p className="mt-0.5 text-xs text-muted-foreground">
              Факт выработки (₽), план по норме компании и выход людей на объекты
            </p>
          </div>

          {/* Period toggle & Object select */}
          <div className="flex items-center gap-2 flex-wrap">
            {/* Period selector pills */}
            <div className="inline-flex rounded-lg border border-border bg-muted/40 p-0.5 text-xs">
              <button
                type="button"
                onClick={() => setPeriod("14days")}
                className={cn(
                  "rounded-md px-2.5 py-1 text-xs font-medium transition-all",
                  period === "14days"
                    ? "bg-background text-foreground shadow-xs"
                    : "text-muted-foreground hover:text-foreground"
                )}
              >
                14 дней
              </button>
              <button
                type="button"
                onClick={() => setPeriod("month")}
                className={cn(
                  "rounded-md px-2.5 py-1 text-xs font-medium transition-all",
                  period === "month"
                    ? "bg-background text-foreground shadow-xs"
                    : "text-muted-foreground hover:text-foreground"
                )}
              >
                Весь месяц
              </button>
            </div>

            {activeObjects.length > 0 && (
              <Select
                value={selectedObjectId}
                items={objectItems}
                onValueChange={(next) => {
                  if (typeof next === "string") {
                    setSelectedObjectId(next);
                  }
                }}
              >
                <SelectTrigger
                  aria-label="Фильтр по объекту"
                  size="sm"
                  className="max-w-[14rem] bg-background text-xs"
                >
                  <SelectValue />
                </SelectTrigger>
                <SelectContent align="end">
                  <SelectGroup>
                    {objectItems.map((item) => (
                      <SelectItem key={item.value} value={item.value}>
                        {item.label}
                      </SelectItem>
                    ))}
                  </SelectGroup>
                </SelectContent>
              </Select>
            )}
          </div>
        </div>

        {/* Aggregate Stats Badges & Series Legend Toggles */}
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-2.5 pt-1">
          {/* Quick stats chips */}
          <div className="flex items-center gap-3 text-xs flex-wrap">
            <span className="flex items-center gap-1.5 text-muted-foreground">
              <span className="text-[11px] uppercase tracking-wider">Выработка:</span>
              <strong className="font-semibold text-foreground tabular-nums">
                {formatCompactRub(totalPeriodVolume)}
              </strong>
            </span>

            <span className="text-muted-foreground/40">•</span>

            {hasNorm ? (
              <>
                <span className="flex items-center gap-1.5 text-muted-foreground">
                  <span className="text-[11px] uppercase tracking-wider">План:</span>
                  <strong className="font-semibold text-foreground tabular-nums">
                    {formatCompactRub(totalPeriodPlan)}
                  </strong>
                </span>
                <span className="text-muted-foreground/40">•</span>
                <span className="flex items-center gap-1.5 text-muted-foreground">
                  <span className="text-[11px] uppercase tracking-wider">Выполнение:</span>
                  <strong className="font-semibold text-foreground tabular-nums">
                    {planCompletion !== null ? formatPercent(planCompletion) : "—"}
                  </strong>
                </span>
                <span className="text-muted-foreground/40">•</span>
              </>
            ) : null}

            <span className="flex items-center gap-1.5 text-muted-foreground">
              <span className="text-[11px] uppercase tracking-wider">Ср. выход:</span>
              <strong className="font-semibold text-foreground tabular-nums">
                {avgWorkers > 0 ? `${avgWorkers} чел./день` : "—"}
              </strong>
            </span>

            <span className="text-muted-foreground/40">•</span>

            <span className="flex items-center gap-1.5 text-muted-foreground">
              <span className="text-[11px] uppercase tracking-wider">Смен:</span>
              <strong className="font-semibold text-foreground tabular-nums">
                {totalShiftsCount}
              </strong>
            </span>
          </div>

          {/* Interactive Legend Pills (Click to toggle line) */}
          <div className="flex items-center gap-2 self-start sm:self-auto">
            <button
              type="button"
              onClick={() => setShowVolume((prev) => !prev)}
              className={cn(
                "inline-flex items-center gap-1.5 rounded-full px-2.5 py-0.5 text-xs font-medium transition-all border",
                showVolume
                  ? "border-primary/40 bg-primary/10 text-primary dark:text-primary-foreground dark:bg-primary/20"
                  : "border-border/60 text-muted-foreground/60 line-through opacity-60"
              )}
            >
              <span
                className={cn(
                  "size-2 rounded-full",
                  showVolume ? "bg-primary" : "bg-muted-foreground/40"
                )}
              />
              <span>Факт (₽)</span>
            </button>

            {hasNorm ? (
              <button
                type="button"
                onClick={() => setShowPlan((prev) => !prev)}
                className={cn(
                  "inline-flex items-center gap-1.5 rounded-full px-2.5 py-0.5 text-xs font-medium transition-all border",
                  showPlan
                    ? "border-foreground/25 bg-muted text-foreground"
                    : "border-border/60 text-muted-foreground/60 line-through opacity-60"
                )}
              >
                <span
                  className={cn(
                    "size-2 rounded-full",
                    showPlan ? "bg-foreground/70" : "bg-muted-foreground/40"
                  )}
                />
                <span>План (₽)</span>
              </button>
            ) : null}

            <button
              type="button"
              onClick={() => setShowAttendance((prev) => !prev)}
              className={cn(
                "inline-flex items-center gap-1.5 rounded-full px-2.5 py-0.5 text-xs font-medium transition-all border",
                showAttendance
                  ? "border-amber-500/40 bg-amber-500/10 text-amber-700 dark:text-amber-300"
                  : "border-border/60 text-muted-foreground/60 line-through opacity-60"
              )}
            >
              <span
                className={cn(
                  "size-2 rounded-full",
                  showAttendance ? "bg-amber-500" : "bg-muted-foreground/40"
                )}
              />
              <span>Посещаемость (чел.)</span>
            </button>
          </div>
        </div>
      </CardHeader>

      <CardContent className="p-3 sm:p-4">
        {/* SVG Chart Area */}
        <div className="relative w-full select-none" style={{ touchAction: "none" }}>
          <svg
            viewBox={`0 0 ${svgWidth} ${svgHeight}`}
            className="w-full h-auto overflow-visible cursor-crosshair"
            onPointerMove={handlePointerMove}
            onPointerLeave={handlePointerLeave}
          >
            <defs>
              <linearGradient id={`${gradientId}-vol`} x1="0" y1="0" x2="0" y2="1">
                <stop offset="0%" stopColor="var(--color-primary)" stopOpacity="0.28" />
                <stop offset="100%" stopColor="var(--color-primary)" stopOpacity="0.0" />
              </linearGradient>
            </defs>

            {/* Horizontal Grid lines (4 ticks) */}
            {[0, 0.33, 0.66, 1].map((pct, idx) => {
              const y = paddingTop + chartInnerHeight * (1 - pct);
              const volVal = maxVolume * pct;
              const workVal = Math.round(maxWorkers * pct);

              return (
                <g key={idx} className="text-muted-foreground/40">
                  <line
                    x1={paddingLeft}
                    y1={y}
                    x2={paddingLeft + chartInnerWidth}
                    y2={y}
                    stroke="currentColor"
                    strokeDasharray={pct === 0 ? "none" : "3,3"}
                    strokeWidth={pct === 0 ? 1.2 : 0.8}
                    className="transition-colors"
                  />

                  {/* Left Y-axis label (Volume) */}
                  {showVolume || (hasNorm && showPlan) ? (
                    <text
                      x={paddingLeft - 8}
                      y={y + 3.5}
                      textAnchor="end"
                      className="fill-muted-foreground text-[10px] font-medium tabular-nums"
                    >
                      {formatCompactRub(volVal)}
                    </text>
                  ) : null}

                  {/* Right Y-axis label (Workers) */}
                  {showAttendance && (
                    <text
                      x={paddingLeft + chartInnerWidth + 8}
                      y={y + 3.5}
                      textAnchor="start"
                      className="fill-amber-600 dark:fill-amber-400 text-[10px] font-medium tabular-nums"
                    >
                      {workVal} чел.
                    </text>
                  )}
                </g>
              );
            })}

            {/* Area under Volume curve */}
            {showVolume && volumeAreaPath && (
              <path
                d={volumeAreaPath}
                fill={`url(#${gradientId}-vol)`}
                className="transition-all duration-300"
              />
            )}

            {/* Volume Line */}
            {showVolume && volumeLinePath && (
              <path
                d={volumeLinePath}
                fill="none"
                stroke="var(--color-primary)"
                strokeWidth={2.4}
                strokeLinecap="round"
                strokeLinejoin="round"
                className="transition-all duration-300"
              />
            )}

            {hasNorm && showPlan && planLinePath ? (
              <path
                d={planLinePath}
                fill="none"
                stroke="currentColor"
                strokeWidth={2}
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeDasharray="7 5"
                className="text-foreground/55 transition-all duration-300"
              />
            ) : null}

            {/* Workers / Attendance Line */}
            {showAttendance && workersLinePath && (
              <path
                d={workersLinePath}
                fill="none"
                stroke="#F59E0B"
                strokeWidth={2.2}
                strokeLinecap="round"
                strokeLinejoin="round"
                className="transition-all duration-300"
              />
            )}

            {/* Attendance Dots (Visible markers) */}
            {showAttendance &&
              coords.map((c) => (
                <circle
                  key={`worker-dot-${c.index}`}
                  cx={c.x}
                  cy={c.yWorkers}
                  r={c.point.workersCount > 0 ? 3.5 : 2}
                  className={cn(
                    "transition-transform duration-150",
                    c.point.workersCount > 0
                      ? "fill-[#F59E0B] stroke-background stroke-2"
                      : "fill-[#F59E0B]/40 stroke-none"
                  )}
                />
              ))}

            {hasNorm && showPlan
              ? coords.map((c) =>
                  c.point.plan > 0 ? (
                    <circle
                      key={`plan-dot-${c.index}`}
                      cx={c.x}
                      cy={c.yPlan}
                      r={2.5}
                      className="fill-foreground/70 stroke-background stroke-2"
                    />
                  ) : null
                )
              : null}

            {/* Volume Dots (Only for non-zero points or active) */}
            {showVolume &&
              coords.map((c) =>
                c.point.volume > 0 ? (
                  <circle
                    key={`vol-dot-${c.index}`}
                    cx={c.x}
                    cy={c.yVolume}
                    r={3}
                    className="fill-primary stroke-background stroke-2"
                  />
                ) : null
              )}

            {/* X-Axis Day Labels */}
            {coords.map((c, i) => {
              // Show label conditionally based on density
              const showLabel =
                period === "14days" ||
                i === 0 ||
                i === coords.length - 1 ||
                i % 5 === 0;

              if (!showLabel) return null;

              return (
                <text
                  key={`x-label-${i}`}
                  x={c.x}
                  y={svgHeight - 10}
                  textAnchor="middle"
                  className={cn(
                    "fill-muted-foreground text-[10px] tabular-nums transition-colors",
                    activeCoord?.index === i && "fill-foreground font-semibold"
                  )}
                >
                  {c.point.dayNum}
                </text>
              );
            })}

            {/* Active Pointer Crosshair Rule */}
            {activeCoord && (
              <g className="pointer-events-none">
                <line
                  x1={activeCoord.x}
                  y1={paddingTop}
                  x2={activeCoord.x}
                  y2={baselineY}
                  stroke="currentColor"
                  strokeDasharray="3,3"
                  strokeWidth={1.5}
                  className="text-foreground/60"
                />

                {hasNorm && showPlan ? (
                  <circle
                    cx={activeCoord.x}
                    cy={activeCoord.yPlan}
                    r={5}
                    className="fill-foreground/70 stroke-background stroke-[2.5]"
                  />
                ) : null}

                {/* Highlight dot for Volume */}
                {showVolume && (
                  <circle
                    cx={activeCoord.x}
                    cy={activeCoord.yVolume}
                    r={5.5}
                    className="fill-primary stroke-background stroke-[2.5]"
                  />
                )}

                {/* Highlight dot for Workers */}
                {showAttendance && (
                  <circle
                    cx={activeCoord.x}
                    cy={activeCoord.yWorkers}
                    r={5.5}
                    className="fill-[#F59E0B] stroke-background stroke-[2.5]"
                  />
                )}
              </g>
            )}
          </svg>

          {/* Interactive Floating Tooltip Popover */}
          {activeCoord && (
            <div
              className={cn(
                "pointer-events-none absolute top-1 z-30 flex flex-col gap-1 rounded-xl border border-border/80 bg-popover/95 p-3 text-xs text-popover-foreground shadow-lg backdrop-blur-md transition-transform duration-75",
                activeCoord.x > svgWidth * 0.65
                  ? "right-2 sm:right-6"
                  : activeCoord.x < svgWidth * 0.35
                    ? "left-2 sm:left-6"
                    : "left-1/2 -translate-x-1/2"
              )}
            >
              <div className="border-b border-border/50 pb-1.5">
                <span className="font-semibold capitalize text-foreground">
                  {activeCoord.point.fullDateLabel}
                </span>
              </div>

              <div className="flex flex-col gap-1 pt-0.5">
                {showVolume && (
                  <div className="flex items-center justify-between gap-4">
                    <span className="flex items-center gap-1.5 text-muted-foreground">
                      <span className="size-2 rounded-full bg-primary" />
                      <span>Факт:</span>
                    </span>
                    <strong className="font-semibold tabular-nums text-foreground">
                      {formatCurrency(activeCoord.point.volume)}
                    </strong>
                  </div>
                )}

                {hasNorm && showPlan ? (
                  <div className="flex items-center justify-between gap-4">
                    <span className="flex items-center gap-1.5 text-muted-foreground">
                      <span className="size-2 rounded-full bg-foreground/70" />
                      <span>План:</span>
                    </span>
                    <strong className="font-semibold tabular-nums text-foreground">
                      {formatCurrency(activeCoord.point.plan)}
                    </strong>
                  </div>
                ) : null}

                {hasNorm && showPlan && activeCoord.point.plan > 0 ? (
                  <div className="flex items-center justify-between gap-4">
                    <span className="text-muted-foreground">Выполнение:</span>
                    <strong className="font-semibold tabular-nums text-foreground">
                      {formatPercent(
                        (activeCoord.point.volume / activeCoord.point.plan) * 100
                      )}
                    </strong>
                  </div>
                ) : null}

                {showAttendance && (
                  <div className="flex items-center justify-between gap-4">
                    <span className="flex items-center gap-1.5 text-muted-foreground">
                      <span className="size-2 rounded-full bg-amber-500" />
                      <span>Посещаемость:</span>
                    </span>
                    <strong className="font-semibold tabular-nums text-foreground">
                      {activeCoord.point.workersCount} чел.
                    </strong>
                  </div>
                )}

                <div className="flex items-center justify-between gap-4 text-[11px] text-muted-foreground pt-0.5 border-t border-border/30">
                  <span>Часы / смены:</span>
                  <span className="font-medium tabular-nums text-foreground">
                    {activeCoord.point.hours > 0
                      ? `${activeCoord.point.hours} ч · ${activeCoord.point.shiftsCount} смен`
                      : activeCoord.point.shiftsCount > 0
                        ? `${activeCoord.point.shiftsCount} смен`
                        : "Нет смен"}
                  </span>
                </div>
              </div>
            </div>
          )}
        </div>

        {/* Tip for touch users */}
        <p className="mt-2 text-center text-[10px] text-muted-foreground/70">
          {variant === "mobile"
            ? "Касайтесь точек на графике для просмотра деталей за конкретный день"
            : "Наведите курсор: факт, план по норме и число людей за день"}
        </p>
      </CardContent>
    </Card>
  );
}
