"use client";

import { useId, useMemo, useState } from "react";

import { useElementWidth } from "@/hooks/use-element-width";
import type { CashFlowMonthAnalytics } from "@/features/cash-flow/types/cash-flow.types";
import {
  formatMonthLabel,
  formatMonthShort,
} from "@/features/cash-flow/utils/analytics";
import {
  formatCompactCurrency,
  formatCurrency,
} from "@/features/cash-flow/utils/cash-flow.utils";
import { getSmoothSvgPath, type SmoothPathPoint } from "@/lib/chart/smooth-path";
import { cn } from "@/lib/utils";

/** Высота области графика, px. */
const CHART_HEIGHT = 200;
/** Ширина до первого замера — чтобы график не мигал пустым. */
const FALLBACK_WIDTH = 900;
const PADDING_TOP = 16;
const PADDING_BOTTOM = 28;
/** Слева место под подписи оси. */
const PADDING_LEFT = 88;
const PADDING_RIGHT = 16;

/** Ряды графика. */
type SeriesKey = "income" | "expense" | "balance";

/** Описание ряда: подпись, цвет линии и точки в легенде. */
const SERIES: {
  key: SeriesKey;
  label: string;
  line: string;
  legendOn: string;
  legendDot: string;
}[] = [
  {
    key: "income",
    label: "Приход",
    line: "var(--color-success)",
    legendOn: "border-success/40 bg-success/10 text-success",
    legendDot: "bg-success",
  },
  {
    key: "expense",
    label: "Расход",
    line: "var(--color-destructive)",
    legendOn: "border-destructive/40 bg-destructive/10 text-destructive",
    legendDot: "bg-destructive",
  },
  {
    key: "balance",
    label: "Сальдо",
    line: "currentColor",
    legendOn: "border-foreground/25 bg-muted text-foreground",
    legendDot: "bg-foreground/70",
  },
];

/**
 * Диаграмма ДДС по месяцам: приход, расход и сальдо.
 *
 * Как на главной странице: плавные линии с заливкой области, сетка со
 * значениями по оси и легенда-переключатели. Точные суммы месяца видны в
 * подсказке при наведении.
 *
 * Ширина графика совпадает с шириной блока на экране, поэтому линии и подписи
 * не растягиваются вместе с окном.
 */
export function CashFlowChart({
  months,
}: {
  months: CashFlowMonthAnalytics[];
}) {
  const gradientId = useId();
  const { ref, width } = useElementWidth<HTMLDivElement>(FALLBACK_WIDTH);
  const [visible, setVisible] = useState<Record<SeriesKey, boolean>>({
    income: true,
    expense: true,
    balance: true,
  });
  const [activeIndex, setActiveIndex] = useState<number | null>(null);

  const chartWidth = width > 0 ? width : FALLBACK_WIDTH;
  const innerWidth = Math.max(chartWidth - PADDING_LEFT - PADDING_RIGHT, 40);
  const innerHeight = CHART_HEIGHT - PADDING_TOP - PADDING_BOTTOM;

  const geometry = useMemo(() => {
    if (months.length === 0) {
      return null;
    }

    const values = months.flatMap((month) => [
      month.income,
      month.expense,
      month.balance,
    ]);
    const scale = niceScale(Math.min(...values, 0), Math.max(...values, 0));

    const xAt = (index: number) =>
      months.length === 1
        ? PADDING_LEFT + innerWidth / 2
        : PADDING_LEFT + (index / (months.length - 1)) * innerWidth;
    const yAt = (value: number) =>
      PADDING_TOP +
      innerHeight -
      ((value - scale.min) / (scale.max - scale.min)) * innerHeight;

    const pointsFor = (
      pick: (month: CashFlowMonthAnalytics) => number
    ): SmoothPathPoint[] => months.map((month, index) => ({
      x: xAt(index),
      y: yAt(pick(month)),
    }));

    const zeroY = yAt(0);
    const series = (pick: (month: CashFlowMonthAnalytics) => number) => {
      const points = pointsFor(pick);
      return {
        points,
        line: getSmoothSvgPath(points),
        area: getSmoothSvgPath(points, zeroY),
      };
    };

    return {
      xs: months.map((_, index) => xAt(index)),
      zeroY,
      hasNegative: scale.min < 0,
      income: series((month) => month.income),
      expense: series((month) => month.expense),
      balance: series((month) => month.balance),
      // Четыре линии сетки: снизу вверх, как на графике главной.
      ticks: [0, 0.33, 0.66, 1].map((part) => ({
        part,
        value: scale.min + (scale.max - scale.min) * part,
        y: yAt(scale.min + (scale.max - scale.min) * part),
      })),
    };
  }, [months, innerWidth, innerHeight]);

  if (!geometry || months.length === 0) {
    return null;
  }

  const activeX = activeIndex !== null ? geometry.xs[activeIndex] : null;
  const activeMonth = activeIndex !== null ? months[activeIndex] : null;

  function toggleSeries(key: SeriesKey) {
    setVisible((current) => ({ ...current, [key]: !current[key] }));
  }

  function handlePointerMove(event: React.PointerEvent<SVGSVGElement>) {
    const rect = event.currentTarget.getBoundingClientRect();
    const ratio = Math.max(
      0,
      Math.min(1, (event.clientX - rect.left) / rect.width)
    );
    const targetX = ratio * chartWidth;

    let closestIndex = 0;
    let closestDiff = Number.POSITIVE_INFINITY;
    geometry!.xs.forEach((x, index) => {
      const diff = Math.abs(x - targetX);
      if (diff < closestDiff) {
        closestDiff = diff;
        closestIndex = index;
      }
    });
    setActiveIndex(closestIndex);
  }

  return (
    <div className="flex flex-col">
      {/* Легенда-переключатели рядов */}
      <div className="flex flex-wrap items-center justify-end gap-2 px-4 pt-3 sm:px-5">
        {SERIES.map((item) => {
          const isOn = visible[item.key];
          return (
            <button
              key={item.key}
              type="button"
              aria-pressed={isOn}
              onClick={() => toggleSeries(item.key)}
              className={cn(
                "inline-flex items-center gap-1.5 rounded-full border px-2.5 py-0.5 text-xs font-medium transition-all",
                isOn
                  ? item.legendOn
                  : "border-border/60 text-muted-foreground/60 line-through opacity-60"
              )}
            >
              <span
                className={cn(
                  "size-2 rounded-full",
                  isOn ? item.legendDot : "bg-muted-foreground/40"
                )}
              />
              <span>{item.label}</span>
            </button>
          );
        })}
      </div>

      <div ref={ref} className="relative w-full px-4 pt-2 sm:px-5">
        <svg
          width={chartWidth}
          height={CHART_HEIGHT}
          viewBox={`0 0 ${chartWidth} ${CHART_HEIGHT}`}
          className="w-full cursor-crosshair overflow-visible"
          onPointerMove={handlePointerMove}
          onPointerLeave={() => setActiveIndex(null)}
        >
          <defs>
            <linearGradient
              id={`${gradientId}-income`}
              x1="0"
              y1="0"
              x2="0"
              y2="1"
            >
              <stop
                offset="0%"
                stopColor="var(--color-success)"
                stopOpacity="0.26"
              />
              <stop
                offset="100%"
                stopColor="var(--color-success)"
                stopOpacity="0"
              />
            </linearGradient>
            <linearGradient
              id={`${gradientId}-expense`}
              x1="0"
              y1="0"
              x2="0"
              y2="1"
            >
              <stop
                offset="0%"
                stopColor="var(--color-destructive)"
                stopOpacity="0.22"
              />
              <stop
                offset="100%"
                stopColor="var(--color-destructive)"
                stopOpacity="0"
              />
            </linearGradient>
          </defs>

          {/* Сетка и подписи оси */}
          {geometry.ticks.map((tick) => (
            <g key={tick.part} className="text-muted-foreground/40">
              <line
                x1={PADDING_LEFT}
                y1={tick.y}
                x2={PADDING_LEFT + innerWidth}
                y2={tick.y}
                stroke="currentColor"
                strokeDasharray={tick.part === 0 ? "none" : "3,3"}
                strokeWidth={tick.part === 0 ? 1.2 : 0.8}
              />
              <text
                x={PADDING_LEFT - 10}
                y={tick.y + 3.5}
                textAnchor="end"
                className="fill-muted-foreground text-[10px] font-medium tabular-nums"
              >
                {formatCompactCurrency(tick.value)}
              </text>
            </g>
          ))}

          {/* Нулевая линия: когда сальдо уходит в минус */}
          {geometry.hasNegative ? (
            <line
              x1={PADDING_LEFT}
              y1={geometry.zeroY}
              x2={PADDING_LEFT + innerWidth}
              y2={geometry.zeroY}
              className="text-foreground/25"
              stroke="currentColor"
              strokeWidth={1.2}
            />
          ) : null}

          {/* Заливка областей и линии рядов */}
          {visible.income ? (
            <>
              <path
                d={geometry.income.area}
                fill={`url(#${gradientId}-income)`}
              />
              <path
                d={geometry.income.line}
                fill="none"
                stroke="var(--color-success)"
                strokeWidth={2.2}
                strokeLinecap="round"
                strokeLinejoin="round"
              />
            </>
          ) : null}

          {visible.expense ? (
            <>
              <path
                d={geometry.expense.area}
                fill={`url(#${gradientId}-expense)`}
              />
              <path
                d={geometry.expense.line}
                fill="none"
                stroke="var(--color-destructive)"
                strokeWidth={2.2}
                strokeLinecap="round"
                strokeLinejoin="round"
              />
            </>
          ) : null}

          {visible.balance ? (
            <path
              d={geometry.balance.line}
              fill="none"
              stroke="currentColor"
              strokeWidth={2}
              strokeDasharray="7 5"
              strokeLinecap="round"
              strokeLinejoin="round"
              className="text-foreground/60"
            />
          ) : null}

          {/* Точки месяцев */}
          {SERIES.map((item) =>
            visible[item.key]
              ? geometry[item.key].points.map((point, index) => {
                  const value = monthValue(months[index], item.key);
                  return value === 0 ? null : (
                    <circle
                      key={`${item.key}-${index}`}
                      cx={point.x}
                      cy={point.y}
                      r={3}
                      stroke="var(--color-background)"
                      strokeWidth={2}
                      className={cn(
                        item.key === "income" && "fill-success",
                        item.key === "expense" && "fill-destructive",
                        item.key === "balance" && "fill-foreground/70"
                      )}
                    />
                  );
                })
              : null
          )}

          {/* Подписи месяцев */}
          {months.map((month, index) => (
            <text
              key={month.month}
              x={geometry.xs[index]}
              y={CHART_HEIGHT - 8}
              textAnchor="middle"
              className={cn(
                "fill-muted-foreground text-[10px] transition-colors",
                activeIndex === index && "fill-foreground font-semibold"
              )}
            >
              {formatMonthShort(month.month)}
            </text>
          ))}

          {/* Наведение: вертикаль и увеличенные точки */}
          {activeX !== null ? (
            <g className="pointer-events-none">
              <line
                x1={activeX}
                y1={PADDING_TOP}
                x2={activeX}
                y2={PADDING_TOP + innerHeight}
                stroke="currentColor"
                strokeDasharray="3,3"
                strokeWidth={1.5}
                className="text-foreground/60"
              />
              {SERIES.map((item) =>
                visible[item.key] ? (
                  <circle
                    key={`active-${item.key}`}
                    cx={activeX}
                    cy={geometry[item.key].points[activeIndex!].y}
                    r={5}
                    stroke="var(--color-background)"
                    strokeWidth={2.5}
                    className={cn(
                      item.key === "income" && "fill-success",
                      item.key === "expense" && "fill-destructive",
                      item.key === "balance" && "fill-foreground/70"
                    )}
                  />
                ) : null
              )}
            </g>
          ) : null}
        </svg>

        {/* Подсказка месяца */}
        {activeMonth && activeX !== null ? (
          <div
            className={cn(
              "pointer-events-none absolute top-1 z-30 flex flex-col gap-1 rounded-xl border border-border/80 bg-popover/95 p-3 text-xs text-popover-foreground shadow-lg backdrop-blur-md",
              activeX > chartWidth * 0.65
                ? "right-2"
                : activeX < chartWidth * 0.35
                  ? "left-2"
                  : "left-1/2 -translate-x-1/2"
            )}
          >
            <div className="border-b border-border/50 pb-1.5">
              <span className="font-semibold text-foreground">
                {formatMonthLabel(activeMonth.month)}
              </span>
            </div>
            <div className="flex flex-col gap-1 pt-0.5">
              {SERIES.filter((item) => visible[item.key]).map((item) => (
                <div
                  key={item.key}
                  className="flex items-center justify-between gap-4"
                >
                  <span className="flex items-center gap-1.5 text-muted-foreground">
                    <span
                      className={cn("size-2 rounded-full", item.legendDot)}
                    />
                    <span>{item.label}:</span>
                  </span>
                  <strong className="font-semibold tabular-nums text-foreground">
                    {formatCurrency(monthValue(activeMonth, item.key))}
                  </strong>
                </div>
              ))}
            </div>
          </div>
        ) : null}
      </div>

      <p className="px-4 pt-1 pb-3 text-center text-[10px] text-muted-foreground/70 sm:px-5">
        Наведите курсор на месяц — приход, расход и сальдо
      </p>
    </div>
  );
}

/** Значение ряда за месяц. */
function monthValue(
  month: CashFlowMonthAnalytics,
  key: SeriesKey
): number {
  if (key === "income") {
    return month.income;
  }
  if (key === "expense") {
    return month.expense;
  }
  return month.balance;
}

/**
 * Границы оси: сверху и снизу — круглые значения.
 *
 * Округление до разряда самого большого числа не даёт подписям оси быть
 * «рваными» (например, «28 254 100 ₽»).
 */
function niceScale(
  rawMin: number,
  rawMax: number
): { min: number; max: number } {
  const magnitude = Math.pow(
    10,
    Math.floor(Math.log10(Math.max(Math.abs(rawMax), Math.abs(rawMin), 1)))
  );
  const max = Math.max(Math.ceil((rawMax * 1.12) / magnitude) * magnitude, magnitude);
  const min =
    rawMin < 0 ? Math.floor((rawMin * 1.12) / magnitude) * magnitude : 0;

  return { min, max: max > min ? max : min + magnitude };
}
