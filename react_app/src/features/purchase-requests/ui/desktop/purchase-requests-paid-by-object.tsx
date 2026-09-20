"use client";

import { Building2Icon, CoinsIcon } from "lucide-react";

import { Badge } from "@/components/ui/badge";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";
import type { PurchaseRequestPaidByObject } from "@/features/purchase-requests/types/purchase-request.types";
import {
  formatCurrency,
  purchaseRequestCountLabel,
} from "@/features/purchase-requests/utils/format";

type PurchaseRequestsPaidByObjectCardProps = {
  /** Суммы по объектам. Пусто — оплаченных заявок нет. */
  rows?: PurchaseRequestPaidByObject[];
  /** Идёт ли первоначальная загрузка данных с сервера. */
  isLoading?: boolean;
};

/**
 * Премиальная KPI-карточка «Оплачено по объектам».
 *
 * Отображает общий объём фактически оплаченных средств по компании и
 * детальную аналитическую раскладку по строительным объектам с
 * относительной долей затрат каждого объекта в виде прогресс-бара.
 *
 * Ограничение по доступу к объектам и заявкам выполняется на сервере
 * в соответствии с RLS-политиками и правилами видимости компании.
 */
export function PurchaseRequestsPaidByObjectCard({
  rows,
  isLoading = false,
}: PurchaseRequestsPaidByObjectCardProps) {
  const list = rows ?? [];
  const totalAmount = list.reduce((sum, row) => sum + row.paidAmount, 0);
  const totalRequests = list.reduce((sum, row) => sum + row.requestsCount, 0);

  return (
    <Card className="shadow-float max-lg:[--card-spacing:--spacing(3)] border-border/80 overflow-hidden">
      <CardHeader className="border-b pb-3.5 max-lg:hidden">
        <div className="flex items-center justify-between gap-2">
          <div className="flex items-center gap-2">
            <span className="flex size-7 shrink-0 items-center justify-center rounded-lg bg-emerald-500/10 text-emerald-600 dark:text-emerald-400">
              <CoinsIcon className="size-4" />
            </span>
            <CardTitle className="text-sm font-semibold tracking-tight">
              Оплачено по объектам
            </CardTitle>
          </div>
          {!isLoading && list.length > 0 ? (
            <Badge variant="outline" className="text-[11px] font-normal text-muted-foreground">
              {list.length === 1 ? "1 объект" : `${list.length} объекта`}
            </Badge>
          ) : null}
        </div>
        <CardDescription className="text-xs">
          Фактически закрытые счета (статус «Оплачено»), за всё время
        </CardDescription>
      </CardHeader>

      <CardContent className="flex flex-col gap-3.5 pt-4">
        {/* Главный блок общего итога */}
        <div className="relative overflow-hidden rounded-xl border border-emerald-500/20 bg-gradient-to-br from-emerald-500/10 via-emerald-500/5 to-transparent p-3.5 transition-all">
          <div className="flex items-center justify-between gap-2 text-xs font-medium text-muted-foreground">
            <span>Всего оплачено</span>
            {!isLoading && totalRequests > 0 ? (
              <span className="inline-flex items-center gap-1.5 text-[11px] font-medium text-emerald-600 dark:text-emerald-400">
                <span className="size-1.5 rounded-full bg-emerald-500 animate-pulse" />
                {purchaseRequestCountLabel(totalRequests)}
              </span>
            ) : null}
          </div>

          <div className="mt-1 font-heading text-2xl font-bold tracking-tight text-foreground tabular-nums">
            {isLoading ? (
              <Skeleton className="h-8 w-44 mt-0.5" />
            ) : (
              formatCurrency(totalAmount)
            )}
          </div>
        </div>

        {/* Список распределения по объектам */}
        {isLoading ? (
          <div className="flex flex-col gap-2.5">
            <Skeleton className="h-16 w-full rounded-xl" />
            <Skeleton className="h-16 w-full rounded-xl" />
          </div>
        ) : list.length === 0 ? (
          <div className="flex flex-col items-center justify-center py-6 text-center text-xs text-muted-foreground">
            <span className="flex size-9 items-center justify-center rounded-full bg-muted/60 text-muted-foreground/60 mb-2">
              <CoinsIcon className="size-4" />
            </span>
            <span>Оплаченных заявок пока нет</span>
          </div>
        ) : (
          <div className="flex flex-col gap-2">
            {list.map((row) => {
              // Доля затрат данного объекта в общем объёме оплат
              const sharePercent =
                totalAmount > 0 ? (row.paidAmount / totalAmount) * 100 : 0;

              return (
                <div
                  key={row.objectId}
                  className="group relative flex flex-col gap-1.5 rounded-xl border border-border/60 bg-muted/20 p-2.5 transition-all duration-200 hover:border-foreground/20 hover:bg-muted/40"
                >
                  {/* Верхняя строка: название объекта и сумма */}
                  <div className="flex items-center justify-between gap-2">
                    <span className="flex items-center gap-2 min-w-0 flex-1">
                      <span className="flex size-6 shrink-0 items-center justify-center rounded-lg bg-background text-muted-foreground shadow-2xs group-hover:text-foreground transition-colors">
                        <Building2Icon className="size-3.5" />
                      </span>
                      <span
                        className="truncate text-xs font-medium text-foreground"
                        title={row.objectName}
                      >
                        {row.objectName || "—"}
                      </span>
                    </span>

                    <span className="shrink-0 text-right text-xs font-semibold tabular-nums text-foreground">
                      {formatCurrency(row.paidAmount)}
                    </span>
                  </div>

                  {/* Визуальная шкала доли затрат */}
                  <div className="h-1.5 w-full overflow-hidden rounded-full bg-muted/80">
                    <div
                      className="h-full rounded-full bg-emerald-500/80 transition-all duration-500 group-hover:bg-emerald-500"
                      style={{ width: `${Math.max(sharePercent, 3)}%` }}
                    />
                  </div>

                  {/* Подвал карточки объекта: количество заявок и процент */}
                  <div className="flex items-center justify-between text-[11px] text-muted-foreground">
                    <span>{purchaseRequestCountLabel(row.requestsCount)}</span>
                    <span className="font-medium tabular-nums text-foreground/80">
                      {sharePercent.toFixed(1)}%
                    </span>
                  </div>
                </div>
              );
            })}
          </div>
        )}
      </CardContent>
    </Card>
  );
}
