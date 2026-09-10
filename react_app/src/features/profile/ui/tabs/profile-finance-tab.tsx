"use client";

import { useMemo, useState } from "react";
import { ChevronLeftIcon, ChevronRightIcon, WalletIcon } from "lucide-react";

import { EmptyState } from "@/components/shared/empty-state";
import { ErrorState } from "@/components/shared/error-state";
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
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import {
  Tabs,
  TabsContent,
  TabsIndicator,
  TabsList,
  TabsTrigger,
} from "@/components/ui/tabs";
import { useProfileFinance } from "@/features/profile/hooks/use-profile-finance";
import type {
  ProfileFinanceHourRow,
  ProfileFinanceLinked,
  ProfileFinanceMoneyRow,
  ProfileFinancePeriod,
} from "@/features/profile/types/profile-finance.types";
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

export function ProfileFinanceTab() {
  const [period, setPeriod] = useState<ProfileFinancePeriod>(currentFinancePeriod);
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
    return <FinanceDesktopSkeleton />;
  }

  if (financeQuery.isError) {
    return (
      <ErrorState
        title="Не удалось загрузить финансы"
        message={
          financeQuery.error instanceof Error
            ? financeQuery.error.message
            : "Попробуйте обновить страницу"
        }
      />
    );
  }

  const finance = financeQuery.data;
  if (!finance || finance.linked === false) {
    return (
      <EmptyState
        icon={WalletIcon}
        title="Нет карточки сотрудника"
        description="Финансы появятся, когда руководитель привяжет ваш профиль к сотруднику."
      />
    );
  }

  return (
    <div className="flex flex-col gap-6">
      <div className="flex items-center justify-between gap-3">
        <div>
          <h3 className="font-heading text-lg font-medium">Финансы за месяц</h3>
          <p className="text-sm text-muted-foreground">
            Часы из закрытых смен и табеля. Премии, штрафы и выплаты в списках — за всё время.
          </p>
        </div>
        <div className="flex items-center gap-1">
          <Button
            type="button"
            variant="outline"
            size="icon"
            aria-label="Предыдущий месяц"
            onClick={() => go(-1)}
          >
            <ChevronLeftIcon />
          </Button>
          <p className="min-w-40 text-center text-sm font-medium">
            {formatFinanceMonth(period)}
          </p>
          <Button
            type="button"
            variant="outline"
            size="icon"
            aria-label="Следующий месяц"
            disabled={!canGoNext}
            onClick={() => go(1)}
          >
            <ChevronRightIcon />
          </Button>
        </div>
      </div>

      <Card>
        <CardContent className="flex flex-col gap-0 pt-6">
          <SummaryRow
            label="По ставке"
            value={formatFinanceMoney(finance.baseSalary)}
            hint={`${formatFinanceHours(finance.hours)} ч`}
          />
          <SummaryRow
            label="Суточные"
            value={formatFinanceMoney(finance.businessTripTotal)}
          />
          <SummaryRow
            label="Премии"
            value={formatFinanceMoney(finance.bonusesTotal)}
          />
          <SummaryRow
            label="Штрафы"
            value={formatFinanceMoney(finance.penaltiesTotal)}
            danger={finance.penaltiesTotal > 0}
          />
          <SummaryRow
            label="Итого к оплате"
            value={formatFinanceMoney(finance.netSalary)}
            emphasize
          />
        </CardContent>
      </Card>

      <p className="text-sm text-muted-foreground">
        Остаток за всё время: {formatFinanceMoney(finance.balance)}
      </p>

      <DetailsCard finance={finance} />
    </div>
  );
}

function SummaryRow({
  label,
  value,
  hint,
  danger = false,
  emphasize = false,
}: {
  label: string;
  value: string;
  hint?: string;
  danger?: boolean;
  emphasize?: boolean;
}) {
  return (
    <div className="flex items-center justify-between gap-3 border-b py-3 last:border-b-0">
      <span className="min-w-0">
        <span
          className={cn(
            "block text-sm",
            emphasize ? "font-medium text-foreground" : "text-muted-foreground"
          )}
        >
          {label}
        </span>
        {hint ? (
          <span className="text-xs text-muted-foreground">{hint}</span>
        ) : null}
      </span>
      <span
        className={cn(
          "text-sm font-medium",
          danger ? "text-destructive" : "text-foreground",
          emphasize ? "text-base" : undefined
        )}
      >
        {value}
      </span>
    </div>
  );
}

function DetailsCard({ finance }: { finance: ProfileFinanceLinked }) {
  return (
    <Card className="min-w-0">
      <CardHeader>
        <CardTitle>Детализация</CardTitle>
        <CardDescription>
          Часы за выбранный месяц. Премии, штрафы и выплаты — за всё время.
        </CardDescription>
      </CardHeader>
      <CardContent>
        <Tabs defaultValue="hours" className="flex flex-col gap-4">
          <TabsList variant="pills" className="w-full">
            <TabsTrigger value="hours">Часы</TabsTrigger>
            <TabsTrigger value="bonuses">Премии</TabsTrigger>
            <TabsTrigger value="penalties">Штрафы</TabsTrigger>
            <TabsTrigger value="payouts">Выплаты</TabsTrigger>
            <TabsIndicator />
          </TabsList>
          <TabsContent value="hours">
            <HoursTable rows={finance.hoursByDate} />
          </TabsContent>
          <TabsContent value="bonuses">
            <MoneyTable
              rows={finance.bonuses}
              noteLabel="Основание"
              emptyText="Нет премий"
            />
          </TabsContent>
          <TabsContent value="penalties">
            <MoneyTable
              rows={finance.penalties}
              noteLabel="Основание"
              danger
              emptyText="Нет штрафов"
            />
          </TabsContent>
          <TabsContent value="payouts">
            <MoneyTable
              rows={finance.payouts}
              noteLabel="Комментарий"
              emptyText="Нет выплат"
            />
          </TabsContent>
        </Tabs>
      </CardContent>
    </Card>
  );
}

function HoursTable({ rows }: { rows: ProfileFinanceHourRow[] }) {
  if (rows.length === 0) {
    return <p className="text-sm text-muted-foreground">Нет часов за месяц</p>;
  }

  return (
    <Table>
      <TableHeader>
        <TableRow>
          <TableHead>Дата</TableHead>
          <TableHead className="text-right">Часы</TableHead>
        </TableRow>
      </TableHeader>
      <TableBody>
        {rows.map((row) => (
          <TableRow key={row.date}>
            <TableCell>{formatFinanceDay(row.date)}</TableCell>
            <TableCell className="text-right">
              {formatFinanceHours(row.hours)}
            </TableCell>
          </TableRow>
        ))}
      </TableBody>
    </Table>
  );
}

function MoneyTable({
  rows,
  noteLabel,
  danger = false,
  emptyText = "Нет записей",
}: {
  rows: ProfileFinanceMoneyRow[];
  noteLabel: string;
  danger?: boolean;
  emptyText?: string;
}) {
  const total = useMemo(
    () => rows.reduce((sum, row) => sum + row.amount, 0),
    [rows]
  );

  if (rows.length === 0) {
    return <p className="text-sm text-muted-foreground">{emptyText}</p>;
  }

  return (
    <Table>
      <TableHeader>
        <TableRow>
          <TableHead>Дата</TableHead>
          <TableHead>{noteLabel}</TableHead>
          <TableHead className="text-right">Сумма</TableHead>
        </TableRow>
      </TableHeader>
      <TableBody>
        {rows.map((row, index) => (
          <TableRow key={`${row.date}-${index}`}>
            <TableCell>{formatFinanceDay(row.date)}</TableCell>
            <TableCell className="max-w-56 truncate whitespace-normal">
              {row.note || "—"}
            </TableCell>
            <TableCell
              className={cn(
                "text-right font-medium",
                danger ? "text-destructive" : undefined
              )}
            >
              {formatFinanceMoney(row.amount)}
            </TableCell>
          </TableRow>
        ))}
        <TableRow>
          <TableCell colSpan={2} className="text-muted-foreground">
            Итого
          </TableCell>
          <TableCell
            className={cn(
              "text-right font-medium",
              danger ? "text-destructive" : undefined
            )}
          >
            {formatFinanceMoney(total)}
          </TableCell>
        </TableRow>
      </TableBody>
    </Table>
  );
}

function FinanceDesktopSkeleton() {
  return (
    <div className="flex flex-col gap-6">
      <Skeleton className="h-10 w-64" />
      <Skeleton className="h-64 rounded-xl" />
      <Skeleton className="h-80 rounded-xl" />
    </div>
  );
}
