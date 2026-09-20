"use client";

import { useState } from "react";

import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Spinner } from "@/components/ui/spinner";
import { usePayrollEmployeeHistory } from "@/features/payrolls/hooks/use-payroll-employee-history";
import type {
  PayrollEmployeeTotals,
  PayrollPeriod,
} from "@/features/payrolls/types/payroll.types";
import {
  formatPayrollMoney,
  getPeriodLabel,
} from "@/features/payrolls/utils/payroll.utils";
import { formatRuDate } from "@/features/timesheet/utils/timesheet-date";
import { cn } from "@/lib/utils";

type PayrollEmployeeHistoryDialogProps = {
  employee: { id: string; fullName: string };
  /** Месяц, открытый на вкладке ФОТ: история показывается за него или за всё время. */
  year: number;
  month: number;
  onClose: () => void;
};

type HistoryRow = {
  id: string;
  date: string;
  amount: number;
  note: string;
  negative?: boolean;
};

/**
 * Окно истории операций сотрудника: итоги за всё время, затем премии,
 * удержания и выплаты за выбранный период.
 */
export function PayrollEmployeeHistoryDialog({
  employee,
  year,
  month,
  onClose,
}: PayrollEmployeeHistoryDialogProps) {
  const [allTime, setAllTime] = useState(false);
  const period: PayrollPeriod = allTime
    ? { mode: "all" }
    : { mode: "month", year, month };

  const { bonuses, penalties, payouts, totals, isLoading, isTotalsLoading, isError } =
    usePayrollEmployeeHistory({ employeeId: employee.id, period });

  const bonusRows: HistoryRow[] = bonuses.map((item) => ({
    id: item.id,
    date: item.date,
    amount: item.amount,
    note: item.note || item.objectName,
  }));
  const penaltyRows: HistoryRow[] = penalties.map((item) => ({
    id: item.id,
    date: item.date,
    amount: item.amount,
    note: item.note || item.objectName,
    negative: true,
  }));
  const payoutRows: HistoryRow[] = payouts.map((item) => ({
    id: item.id,
    date: item.date,
    amount: item.amount,
    note: item.comment,
  }));

  const periodLabel = allTime
    ? "за всё время"
    : `за ${getPeriodLabel(period).toLowerCase()}`;

  return (
    <Dialog
      open
      onOpenChange={(next) => {
        if (!next) {
          onClose();
        }
      }}
    >
      <DialogContent className="flex max-h-[min(92vh,52rem)] flex-col sm:max-w-3xl">
        <DialogHeader>
          <DialogTitle>История операций</DialogTitle>
          <DialogDescription>{employee.fullName}</DialogDescription>
        </DialogHeader>

        <TotalsSummary totals={totals} isLoading={isTotalsLoading} />

        <div className="flex items-center gap-2">
          <Button
            type="button"
            size="sm"
            variant={allTime ? "ghost" : "secondary"}
            aria-pressed={!allTime}
            onClick={() => setAllTime(false)}
          >
            {getPeriodLabel({ mode: "month", year, month })}
          </Button>
          <Button
            type="button"
            size="sm"
            variant={allTime ? "secondary" : "ghost"}
            aria-pressed={allTime}
            onClick={() => setAllTime(true)}
          >
            Всё время
          </Button>
        </div>

        <div className="min-h-0 flex-1 overflow-y-auto overscroll-contain pr-1">
          {isLoading ? (
            <div className="flex justify-center py-10">
              <Spinner />
            </div>
          ) : isError ? (
            <p className="py-10 text-center text-sm text-destructive">
              Не удалось загрузить историю
            </p>
          ) : (
            <div className="flex flex-col gap-4">
              <HistorySection title="Премии" rows={bonusRows} />
              <HistorySection title="Удержания" rows={penaltyRows} negative />
              <HistorySection title="Выплаты" rows={payoutRows} />
            </div>
          )}
        </div>

        <DialogFooter>
          <p className="mr-auto text-xs text-muted-foreground">{periodLabel}</p>
          <Button type="button" variant="outline" onClick={onClose}>
            Закрыть
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}

/** Итоги сотрудника за всё время — не зависят от выбранного периода. */
function TotalsSummary({
  totals,
  isLoading,
}: {
  totals: PayrollEmployeeTotals | null;
  isLoading: boolean;
}) {
  return (
    <section className="rounded-lg border border-border/70 bg-muted/20 p-3">
      <p className="mb-2 text-xs font-semibold uppercase tracking-wide text-muted-foreground">
        За всё время
      </p>
      {isLoading || !totals ? (
        <p className="text-sm text-muted-foreground">Загрузка…</p>
      ) : (
        <div className="grid grid-cols-2 gap-2 sm:grid-cols-3">
          <SummaryCell
            label="Заработано"
            hint="База + суточные + премии − удержания"
            value={totals.earnedTotal}
          />
          <SummaryCell label="Суточные" value={totals.tripTotal} />
          <SummaryCell label="Премии" value={totals.bonusTotal} />
          <SummaryCell label="Удержания" value={totals.penaltyTotal} />
          <SummaryCell label="Выплаты" value={totals.payoutTotal} />
          <SummaryCell
            label="Остаток"
            hint="Начислено − выплачено"
            value={totals.balance}
            strong
          />
        </div>
      )}
    </section>
  );
}

/** Ячейка итогов: подпись и сумма. */
function SummaryCell({
  label,
  hint,
  value,
  strong = false,
}: {
  label: string;
  hint?: string;
  value: number;
  strong?: boolean;
}) {
  return (
    <div
      className="rounded-md border border-border/60 bg-card px-2.5 py-1.5"
      title={hint}
    >
      <p className="text-[11px] text-muted-foreground">{label}</p>
      <p
        className={cn(
          "text-sm tabular-nums",
          strong ? "font-semibold" : "font-medium"
        )}
      >
        {formatPayrollMoney(value)}
      </p>
    </div>
  );
}

/** Раздел истории: заголовок с суммой и список операций. */
function HistorySection({
  title,
  rows,
  negative = false,
}: {
  title: string;
  rows: HistoryRow[];
  negative?: boolean;
}) {
  const total = rows.reduce((sum, row) => sum + row.amount, 0);

  return (
    <section className="rounded-lg border border-border/70">
      <header className="flex items-baseline justify-between gap-3 border-b border-border/60 bg-muted/40 px-3 py-1.5">
        <span className="text-xs font-semibold uppercase tracking-wide text-muted-foreground">
          {title}
        </span>
        <span className="text-sm font-semibold tabular-nums">
          {rows.length === 0
            ? "—"
            : `${negative ? "−" : ""}${formatPayrollMoney(total)}`}
        </span>
      </header>
      {rows.length === 0 ? (
        <p className="px-3 py-3 text-sm text-muted-foreground">
          Нет операций
        </p>
      ) : (
        <ul className="divide-y divide-border/50 px-3">
          {rows.map((row) => (
            <li
              key={row.id}
              className="flex items-baseline gap-3 py-1.5 text-sm"
            >
              <span className="shrink-0 text-muted-foreground">
                {formatRuDate(row.date)}
              </span>
              <span
                className="min-w-0 flex-1 truncate text-muted-foreground/80"
                title={row.note}
              >
                {row.note}
              </span>
              <span className="shrink-0 font-medium tabular-nums">
                {row.negative ? "−" : ""}
                {formatPayrollMoney(row.amount)}
              </span>
            </li>
          ))}
        </ul>
      )}
    </section>
  );
}
