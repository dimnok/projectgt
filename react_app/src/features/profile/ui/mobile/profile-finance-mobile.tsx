"use client";

import { useState } from "react";
import {
  ChevronLeftIcon,
  ChevronRightIcon,
  WalletIcon,
} from "lucide-react";

import { EmptyState } from "@/components/shared/empty-state";
import { ErrorState } from "@/components/shared/error-state";
import { Button } from "@/components/ui/button";
import { Skeleton } from "@/components/ui/skeleton";
import { useProfileFinance } from "@/features/profile/hooks/use-profile-finance";
import type {
  ProfileFinanceHourRow,
  ProfileFinanceMoneyRow,
  ProfileFinancePeriod,
} from "@/features/profile/types/profile-finance.types";
import { ProfileMobileShell } from "@/features/profile/ui/mobile/profile-mobile-shell";
import {
  currentFinancePeriod,
  formatFinanceDay,
  formatFinanceHours,
  formatFinanceMoney,
  formatFinanceMonth,
  isFutureFinancePeriod,
  shiftFinancePeriod,
} from "@/features/profile/utils/profile-finance.utils";
import { cn } from "@/lib/utils";

type ProfileFinanceMobileProps = {
  onBack: () => void;
};

type FinanceDetail = "hours" | "bonuses" | "penalties" | "payouts";

export function ProfileFinanceMobile({ onBack }: ProfileFinanceMobileProps) {
  const [period, setPeriod] = useState<ProfileFinancePeriod>(currentFinancePeriod);
  const [detail, setDetail] = useState<FinanceDetail | null>(null);
  const financeQuery = useProfileFinance(period);
  const canGoNext = !isFutureFinancePeriod(shiftFinancePeriod(period, 1));

  function go(delta: number) {
    const next = shiftFinancePeriod(period, delta);
    if (delta > 0 && isFutureFinancePeriod(next)) {
      return;
    }
    setPeriod(next);
  }

  if (financeQuery.isLoading) {
    return (
      <ProfileMobileShell title="Финансы" onBack={onBack}>
        <div className="flex flex-col gap-4">
          <Skeleton className="h-28 rounded-2xl" />
          <Skeleton className="h-48 rounded-2xl" />
        </div>
      </ProfileMobileShell>
    );
  }

  if (financeQuery.isError) {
    return (
      <ProfileMobileShell title="Финансы" onBack={onBack}>
        <ErrorState
          title="Не удалось загрузить финансы"
          message={
            financeQuery.error instanceof Error
              ? financeQuery.error.message
              : "Попробуйте ещё раз"
          }
        />
      </ProfileMobileShell>
    );
  }

  const finance = financeQuery.data;
  if (!finance || finance.linked === false) {
    return (
      <ProfileMobileShell title="Финансы" onBack={onBack}>
        <EmptyState
          icon={WalletIcon}
          title="Нет карточки сотрудника"
          description="Попросите руководителя привязать профиль к сотруднику."
        />
      </ProfileMobileShell>
    );
  }

  if (detail === "hours") {
    return (
      <HoursDetail
        rows={finance.hoursByDate}
        onBack={() => setDetail(null)}
      />
    );
  }

  if (detail === "bonuses") {
    return (
      <MoneyDetail
        title="Премии"
        rows={finance.bonuses}
        onBack={() => setDetail(null)}
      />
    );
  }

  if (detail === "penalties") {
    return (
      <MoneyDetail
        title="Штрафы"
        rows={finance.penalties}
        danger
        onBack={() => setDetail(null)}
      />
    );
  }

  if (detail === "payouts") {
    return (
      <MoneyDetail
        title="Выплаты"
        rows={finance.payouts}
        onBack={() => setDetail(null)}
      />
    );
  }

  return (
    <ProfileMobileShell
      title="Финансы"
      onBack={onBack}
      trailing={
        <div className="flex items-center">
          <Button
            type="button"
            variant="ghost"
            size="icon"
            className="rounded-full"
            aria-label="Предыдущий месяц"
            onClick={() => go(-1)}
          >
            <ChevronLeftIcon />
          </Button>
          <Button
            type="button"
            variant="ghost"
            size="icon"
            className="rounded-full"
            aria-label="Следующий месяц"
            disabled={!canGoNext}
            onClick={() => go(1)}
          >
            <ChevronRightIcon />
          </Button>
        </div>
      }
    >
      <div className="flex flex-col gap-5">
        <p className="text-center text-sm text-muted-foreground">
          {formatFinanceMonth(period)}
        </p>

        <div className="flex flex-col gap-0 overflow-hidden rounded-2xl bg-card ring-1 ring-foreground/10">
          <MetricLine
            label="По ставке"
            value={formatFinanceMoney(finance.baseSalary)}
            hint={`${formatFinanceHours(finance.hours)} ч`}
            onClick={() => setDetail("hours")}
          />
          <MetricLine
            label="Суточные"
            value={formatFinanceMoney(finance.businessTripTotal)}
          />
          <MetricLine
            label="Премии"
            value={formatFinanceMoney(finance.bonusesTotal)}
            onClick={() => setDetail("bonuses")}
          />
          <MetricLine
            label="Штрафы"
            value={formatFinanceMoney(finance.penaltiesTotal)}
            onClick={() => setDetail("penalties")}
          />
          <MetricLine
            label="Итого к оплате"
            value={formatFinanceMoney(finance.netSalary)}
          />
        </div>

        <div className="flex flex-col gap-0 overflow-hidden rounded-2xl bg-card ring-1 ring-foreground/10">
          <MetricLine
            label="Выплаты"
            hint="Все переводы, без привязки к месяцу"
            value={formatFinanceMoney(
              finance.payouts.reduce((sum, row) => sum + row.amount, 0)
            )}
            onClick={() => setDetail("payouts")}
          />
        </div>

        <p className="px-1 text-center text-xs text-muted-foreground">
          Остаток за всё время: {formatFinanceMoney(finance.balance)}
        </p>
      </div>
    </ProfileMobileShell>
  );
}

function MetricLine({
  label,
  value,
  hint,
  onClick,
}: {
  label: string;
  value: string;
  hint?: string;
  onClick?: () => void;
}) {
  const content = (
    <>
      <span className="min-w-0 flex-1">
        <span className="block text-sm text-muted-foreground">{label}</span>
        {hint ? (
          <span className="text-xs text-muted-foreground">{hint}</span>
        ) : null}
      </span>
      <span className="text-sm font-medium text-foreground">{value}</span>
    </>
  );

  if (onClick) {
    return (
      <button
        type="button"
        className="flex min-h-11 w-full items-center gap-3 border-b px-4 py-2.5 text-left last:border-b-0 active:bg-muted/70"
        onClick={onClick}
      >
        {content}
      </button>
    );
  }

  return (
    <div className="flex min-h-11 items-center gap-3 border-b px-4 py-2.5 last:border-b-0">
      {content}
    </div>
  );
}

function HoursDetail({
  rows,
  onBack,
}: {
  rows: ProfileFinanceHourRow[];
  onBack: () => void;
}) {
  return (
    <ProfileMobileShell title="Часы" onBack={onBack}>
      {rows.length === 0 ? (
        <p className="text-sm text-muted-foreground">Нет часов за месяц</p>
      ) : (
        <div className="overflow-hidden rounded-2xl bg-card ring-1 ring-foreground/10">
          {rows.map((row) => (
            <div
              key={row.date}
              className="flex min-h-11 items-center justify-between gap-3 border-b px-4 py-2.5 last:border-b-0"
            >
              <span className="text-sm">{formatFinanceDay(row.date)}</span>
              <span className="text-sm font-medium">
                {formatFinanceHours(row.hours)} ч
              </span>
            </div>
          ))}
        </div>
      )}
    </ProfileMobileShell>
  );
}

function MoneyDetail({
  title,
  rows,
  danger = false,
  onBack,
}: {
  title: string;
  rows: ProfileFinanceMoneyRow[];
  danger?: boolean;
  onBack: () => void;
}) {
  return (
    <ProfileMobileShell title={title} onBack={onBack}>
      {rows.length === 0 ? (
        <p className="text-sm text-muted-foreground">Нет записей</p>
      ) : (
        <div className="flex flex-col gap-2">
          <p className="px-1 text-xs text-muted-foreground">За всё время</p>
          {rows.map((row, index) => (
            <div
              key={`${row.date}-${index}`}
              className="flex flex-col gap-1 rounded-2xl bg-card px-4 py-3 ring-1 ring-foreground/10"
            >
              <div className="flex items-center justify-between gap-3">
                <span className="text-xs text-muted-foreground">
                  {formatFinanceDay(row.date)}
                </span>
                <span
                  className={cn(
                    "text-sm font-medium",
                    danger ? "text-destructive" : "text-foreground"
                  )}
                >
                  {formatFinanceMoney(row.amount)}
                </span>
              </div>
              {row.note ? (
                <p className="text-sm text-muted-foreground">{row.note}</p>
              ) : null}
            </div>
          ))}
        </div>
      )}
    </ProfileMobileShell>
  );
}
