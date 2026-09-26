"use client";

import { useMemo, useState } from "react";
import { ChartColumnIcon, ChevronUpIcon, Table2Icon } from "lucide-react";

import { ErrorState } from "@/components/shared/error-state";
import { Button } from "@/components/ui/button";
import { Switch } from "@/components/ui/switch";
import type { CashFlowMonthAnalytics } from "@/features/cash-flow/types/cash-flow.types";
import { CashFlowChart } from "@/features/cash-flow/ui/desktop/cash-flow-chart";
import { CashFlowAnalyticsSkeleton } from "@/features/cash-flow/ui/shared/cash-flow-skeletons";
import {
  analyticsCategoryNames,
  analyticsCategoryTotal,
  analyticsTotals,
  categoryLabel,
  formatMonthLabel,
  monthCategoryAmount,
} from "@/features/cash-flow/utils/analytics";
import { formatCurrency } from "@/features/cash-flow/utils/cash-flow.utils";
import { cn } from "@/lib/utils";

type CashFlowAnalyticsProps = {
  months: CashFlowMonthAnalytics[];
  isLoading: boolean;
  error: unknown;
};

/** Тон строки отчёта: приход, расход, сальдо или расшифровка по статье. */
type RowTone = "income" | "expense" | "balance" | "category";

/** Вид отчёта: таблица по месяцам или диаграмма. */
type ReportView = "table" | "chart";

/** Виды отчёта в порядке показа. */
const REPORT_VIEWS: { value: ReportView; label: string; icon: typeof Table2Icon }[] =
  [
    { value: "table", label: "Таблица", icon: Table2Icon },
    { value: "chart", label: "График", icon: ChartColumnIcon },
  ];

/** Классы ячейки-подписи (первый столбец, закреплён слева). */
const LABEL_CELL =
  "sticky left-0 z-10 w-44 min-w-44 border-r border-b border-border/50 bg-card px-3 py-1.5 text-left";
/** Классы ячейки итога (последний столбец, закреплён справа). */
const TOTAL_CELL =
  "sticky right-0 z-10 w-32 min-w-32 border-l border-b border-border/50 bg-card px-3 py-1.5 text-right text-[11px] whitespace-nowrap tabular-nums sm:text-xs";
/**
 * Классы ячейки-значения месяца.
 *
 * Суммы идут на шаг мельче подписей: в отчёте их много и в столбце они
 * читаются лучше мелким кеглем.
 */
const VALUE_CELL =
  "border-b border-border/50 px-3 py-1.5 text-right text-[11px] whitespace-nowrap tabular-nums sm:text-xs";

/**
 * Отчёт по месяцам за период: приход, расход и сальдо столбцами по месяцам.
 *
 * Показывается на том же экране, что и реестр операций: сверху видно, как
 * складывался год, ниже — сами операции. Переключатель «По статьям»
 * добавляет строки расшифровки, свёрнутый отчёт оставляет таблице больше места.
 */
export function CashFlowAnalytics({
  months,
  isLoading,
  error,
}: CashFlowAnalyticsProps) {
  const [view, setView] = useState<ReportView>("table");
  const [isDetailed, setIsDetailed] = useState(false);
  const [isOpen, setIsOpen] = useState(true);

  const incomeCategories = useMemo(
    () => analyticsCategoryNames(months, "income"),
    [months]
  );
  const expenseCategories = useMemo(
    () => analyticsCategoryNames(months, "expense"),
    [months]
  );
  const totals = useMemo(() => analyticsTotals(months), [months]);

  const isEmpty = months.length === 0;

  return (
    <section className="shrink-0 border-b border-border/80">
      <div className="flex flex-wrap items-center justify-between gap-x-3 gap-y-2 bg-muted/30 px-4 py-2 sm:px-5">
        <h2 className="text-xs font-semibold tracking-wide text-muted-foreground uppercase">
          Аналитика по месяцам
        </h2>

        <div className="flex flex-wrap items-center gap-3">
          <div className="flex items-center gap-1">
            {REPORT_VIEWS.map((item) => {
              const Icon = item.icon;
              const isActive = view === item.value;
              return (
                <Button
                  key={item.value}
                  type="button"
                  size="sm"
                  variant={isActive ? "default" : "outline"}
                  aria-pressed={isActive}
                  className="gap-1.5"
                  onClick={() => setView(item.value)}
                >
                  <Icon className="size-3.5" />
                  <span>{item.label}</span>
                </Button>
              );
            })}
          </div>

          {/* Расшифровка по статьям есть только в таблице. */}
          {view === "table" ? (
            <label className="flex cursor-pointer items-center gap-2 text-xs text-muted-foreground select-none">
              <Switch
                checked={isDetailed}
                disabled={isEmpty}
                onCheckedChange={setIsDetailed}
                aria-label="Показать расшифровку по статьям"
              />
              <span>По статьям</span>
            </label>
          ) : null}

          <Button
            type="button"
            variant="ghost"
            size="icon-sm"
            aria-expanded={isOpen}
            aria-label={isOpen ? "Свернуть аналитику" : "Развернуть аналитику"}
            title={isOpen ? "Свернуть аналитику" : "Развернуть аналитику"}
            onClick={() => setIsOpen((open) => !open)}
          >
            <ChevronUpIcon
              className={cn("transition-transform", !isOpen && "rotate-180")}
            />
          </Button>
        </div>
      </div>

      {isOpen ? (
        <div className="max-h-[42vh] overflow-auto">
          {isLoading && isEmpty ? (
            <CashFlowAnalyticsSkeleton />
          ) : error && isEmpty ? (
            <div className="p-4">
              <ErrorState
                title="Не удалось загрузить аналитику"
                message={
                  error instanceof Error
                    ? error.message
                    : "Повторите попытку позже"
                }
              />
            </div>
          ) : isEmpty ? (
            <p className="px-4 py-6 text-center text-sm text-muted-foreground">
              Операций за период нет — измените период или фильтры.
            </p>
          ) : view === "chart" ? (
            <CashFlowChart months={months} />
          ) : (
            <table className="w-full border-separate border-spacing-0">
              <caption className="sr-only">
                Приход, расход и сальдо по месяцам за выбранный период
              </caption>
              <thead>
                <tr>
                  <th
                    scope="col"
                    className="sticky top-0 left-0 z-30 w-44 min-w-44 border-r border-b border-border/60 bg-muted px-3 py-1.5 text-left text-[11px] font-semibold tracking-wide text-muted-foreground uppercase"
                  >
                    Показатель
                  </th>
                  {months.map((month) => (
                    <th
                      key={month.month}
                      scope="col"
                      className="sticky top-0 z-20 min-w-28 border-b border-border/60 bg-muted px-3 py-1.5 text-right text-[11px] font-semibold whitespace-nowrap text-foreground/75"
                    >
                      {formatMonthLabel(month.month)}
                    </th>
                  ))}
                  {/* Пустая колонка забирает свободную ширину: месяцы остаются
                      одной ширины и при двух месяцах, и при двенадцати. */}
                  <th
                    aria-hidden
                    className="sticky top-0 z-20 border-b border-border/60 bg-muted"
                  />
                  <th
                    scope="col"
                    className="sticky top-0 right-0 z-30 w-32 min-w-32 border-b border-l border-border/60 bg-muted px-3 py-1.5 text-right text-[11px] font-semibold tracking-wide whitespace-nowrap text-foreground/75 uppercase"
                  >
                    За период
                  </th>
                </tr>
              </thead>

              <tbody>
                <AnalyticsRow
                  label="Приход"
                  tone="income"
                  values={months.map((month) => month.income)}
                  total={totals.income}
                />

                {isDetailed
                  ? incomeCategories.map((name) => (
                      <AnalyticsRow
                        key={`income-${name}`}
                        label={categoryLabel(name)}
                        tone="category"
                        values={months.map((month) =>
                          monthCategoryAmount(month, "income", name)
                        )}
                        total={analyticsCategoryTotal(months, "income", name)}
                      />
                    ))
                  : null}

                <AnalyticsRow
                  label="Расход"
                  tone="expense"
                  values={months.map((month) => month.expense)}
                  total={totals.expense}
                />

                {isDetailed
                  ? expenseCategories.map((name) => (
                      <AnalyticsRow
                        key={`expense-${name}`}
                        label={categoryLabel(name)}
                        tone="category"
                        values={months.map((month) =>
                          monthCategoryAmount(month, "expense", name)
                        )}
                        total={analyticsCategoryTotal(months, "expense", name)}
                      />
                    ))
                  : null}

                <AnalyticsRow
                  label="Сальдо"
                  tone="balance"
                  values={months.map((month) => month.balance)}
                  total={totals.balance}
                  isTotal
                />
              </tbody>
            </table>
          )}
        </div>
      ) : null}
    </section>
  );
}

/** Строка отчёта: подпись слева, значения по месяцам и итог за период. */
function AnalyticsRow({
  label,
  tone,
  values,
  total,
  isTotal = false,
}: {
  label: string;
  tone: RowTone;
  values: number[];
  total: number;
  isTotal?: boolean;
}) {
  const isCategory = tone === "category";

  return (
    <tr>
      <th
        scope="row"
        className={cn(
          LABEL_CELL,
          isCategory
            ? "pl-7 text-xs font-normal text-muted-foreground italic"
            : "text-[11px] font-semibold tracking-wide text-foreground/75 uppercase",
          isTotal && "border-t-2 border-t-border/70 font-semibold text-foreground"
        )}
      >
        {label}
      </th>
      {values.map((value, index) => (
        <td
          key={index}
          className={cn(
            VALUE_CELL,
            valueClassName(tone, value),
            isTotal && "border-t-2 border-t-border/70 font-semibold"
          )}
        >
          {/* Нулевые приход и расход показываем прочерком — так столбец
              читается по значимым числам. */}
          {!isTotal && value === 0 ? "—" : formatCurrency(value)}
        </td>
      ))}
      <td
        aria-hidden
        className={cn(
          "w-full border-b border-border/50",
          isTotal && "border-t-2 border-t-border/70"
        )}
      />
      <td
        className={cn(
          TOTAL_CELL,
          valueClassName(tone, total),
          isTotal && "border-t-2 border-t-border/70 font-semibold"
        )}
      >
        {!isTotal && total === 0 ? "—" : formatCurrency(total)}
      </td>
    </tr>
  );
}

/** Цвет значения: приход зелёный, расход красный, сальдо — по знаку. */
function valueClassName(tone: RowTone, value: number): string {
  switch (tone) {
    case "income":
      return value > 0 ? "text-success" : "text-muted-foreground/50";
    case "expense":
      return value > 0 ? "text-destructive" : "text-muted-foreground/50";
    case "balance":
      return value >= 0 ? "text-success" : "text-destructive";
    default:
      return "text-muted-foreground";
  }
}
