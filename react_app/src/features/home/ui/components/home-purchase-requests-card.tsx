"use client";

import Link from "next/link";
import {
  ArrowRightIcon,
  CheckCircle2Icon,
  ChevronRightIcon,
  CreditCardIcon,
  FileCheck2Icon,
  ShoppingCartIcon,
} from "lucide-react";

import { Badge } from "@/components/ui/badge";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";
import { purchaseRequestCountLabel } from "@/features/purchase-requests/utils/format";

type HomePurchaseRequestsCardProps = {
  /** Количество заявок, ожидающих согласования (статус «На согласовании»). */
  approvalCount: number;
  /** Количество заявок, требующих оплаты (статус «Заведено на оплату»). */
  paymentCount: number;
  /** Идёт ли загрузка данных с сервера. */
  isLoading: boolean;
};

/**
 * Премиальный блок «Заявки на закупку» для главной страницы (дашборда).
 *
 * Чётко обозначает принадлежность к модулю заявок и акцентирует внимание
 * на позициях, требующих конкретного действия: согласования или оплаты счёта.
 * Счётчик оплаты строго совпадает со статусом «Заведено на оплату» в реестре,
 * а клик по карточке сразу открывает реестр заявок с предвыбранным фильтром.
 */
export function HomePurchaseRequestsCard({
  approvalCount,
  paymentCount,
  isLoading,
}: HomePurchaseRequestsCardProps) {
  const totalActionable = approvalCount + paymentCount;

  return (
    <Card className="overflow-hidden border-border/80 shadow-xs">
      {/* Шапка блока с понятным названием модуля и статусным бейджем */}
      <CardHeader className="pb-3 border-b border-border/50">
        <div className="flex items-center justify-between gap-2">
          <div className="flex items-center gap-2">
            <span className="flex size-7 shrink-0 items-center justify-center rounded-lg bg-primary/10 text-primary">
              <ShoppingCartIcon className="size-4" />
            </span>
            <CardTitle className="text-sm font-semibold tracking-tight">
              Заявки на закупку
            </CardTitle>
          </div>

          {!isLoading ? (
            totalActionable > 0 ? (
              <Badge
                variant="outline"
                className="gap-1.5 border-amber-500/30 bg-amber-500/10 text-[11px] font-medium text-amber-700 dark:text-amber-300"
              >
                <span className="size-1.5 rounded-full bg-amber-500 animate-pulse" />
                <span>{totalActionable} в очереди</span>
              </Badge>
            ) : (
              <Badge
                variant="outline"
                className="border-emerald-500/30 bg-emerald-500/10 text-[11px] font-normal text-emerald-700 dark:text-emerald-400"
              >
                Все закрыты
              </Badge>
            )
          ) : null}
        </div>
        <p className="text-[11px] text-muted-foreground mt-1">
          Требуют вашего действия или решения
        </p>
      </CardHeader>

      {/* Основной контент: действия или спокойный статус готовности */}
      <CardContent className="p-2.5 flex flex-col gap-2">
        {isLoading ? (
          <div className="flex flex-col gap-2 p-1">
            <Skeleton className="h-12 w-full rounded-xl" />
            <Skeleton className="h-12 w-full rounded-xl" />
          </div>
        ) : totalActionable === 0 ? (
          <div className="flex items-center gap-3 rounded-xl border border-border/50 bg-muted/20 p-3 text-xs text-muted-foreground">
            <span className="flex size-8 shrink-0 items-center justify-center rounded-lg bg-emerald-500/10 text-emerald-600 dark:text-emerald-400">
              <CheckCircle2Icon className="size-4" />
            </span>
            <div className="min-w-0 flex-1">
              <p className="font-medium text-foreground">Все заявки обработаны</p>
              <p className="text-[11px] text-muted-foreground mt-0.5">
                Нет заявок, ожидающих согласования или оплаты
              </p>
            </div>
          </div>
        ) : (
          <div className="flex flex-col gap-2">
            {/* Строка заявок на согласовании */}
            {approvalCount > 0 ? (
              <Link
                href="/purchase-requests?filter=approval"
                className="group flex items-center justify-between gap-3 rounded-xl border border-amber-500/25 bg-amber-500/5 p-2.5 transition-all duration-200 hover:border-amber-500/50 hover:bg-amber-500/10 no-underline"
              >
                <div className="flex items-center gap-2.5 min-w-0">
                  <span className="flex size-7 shrink-0 items-center justify-center rounded-lg bg-background shadow-2xs text-amber-600 dark:text-amber-400">
                    <FileCheck2Icon className="size-3.5" />
                  </span>
                  <div className="min-w-0 flex-1">
                    <p className="truncate text-xs font-semibold text-foreground group-hover:text-primary transition-colors">
                      Требуют согласования
                    </p>
                    <p className="truncate text-[11px] text-muted-foreground">
                      Статус «На согласовании»
                    </p>
                  </div>
                </div>

                <div className="flex items-center gap-1.5 shrink-0">
                  <span className="rounded-full border border-amber-500/30 bg-amber-500/15 px-2 py-0.5 text-xs font-semibold tabular-nums text-amber-800 dark:text-amber-300">
                    {purchaseRequestCountLabel(approvalCount)}
                  </span>
                  <ChevronRightIcon className="size-3.5 text-muted-foreground group-hover:text-foreground group-hover:translate-x-0.5 transition-all" />
                </div>
              </Link>
            ) : null}

            {/* Строка заявок на оплату */}
            {paymentCount > 0 ? (
              <Link
                href="/purchase-requests?filter=payment_queue"
                className="group flex items-center justify-between gap-3 rounded-xl border border-sky-500/25 bg-sky-500/5 p-2.5 transition-all duration-200 hover:border-sky-500/50 hover:bg-sky-500/10 no-underline"
              >
                <div className="flex items-center gap-2.5 min-w-0">
                  <span className="flex size-7 shrink-0 items-center justify-center rounded-lg bg-background shadow-2xs text-sky-600 dark:text-sky-400">
                    <CreditCardIcon className="size-3.5" />
                  </span>
                  <div className="min-w-0 flex-1">
                    <p className="truncate text-xs font-semibold text-foreground group-hover:text-primary transition-colors">
                      Требуют оплаты
                    </p>
                    <p className="truncate text-[11px] text-muted-foreground">
                      Статус «Заведено на оплату»
                    </p>
                  </div>
                </div>

                <div className="flex items-center gap-1.5 shrink-0">
                  <span className="rounded-full border border-sky-500/30 bg-sky-500/15 px-2 py-0.5 text-xs font-semibold tabular-nums text-sky-800 dark:text-sky-300">
                    {purchaseRequestCountLabel(paymentCount)}
                  </span>
                  <ChevronRightIcon className="size-3.5 text-muted-foreground group-hover:text-foreground group-hover:translate-x-0.5 transition-all" />
                </div>
              </Link>
            ) : null}
          </div>
        )}
      </CardContent>

      {/* Быстрый переход в общий реестр заявок */}
      <div className="border-t border-border/50 bg-muted/20 px-3 py-2 flex items-center justify-between">
        <span className="text-[11px] text-muted-foreground">
          Заявки на закупку
        </span>
        <Link
          href="/purchase-requests"
          className="inline-flex items-center gap-1 text-[11px] font-medium text-foreground hover:text-primary transition-colors no-underline"
        >
          <span>Реестр заявок</span>
          <ArrowRightIcon className="size-3" />
        </Link>
      </div>
    </Card>
  );
}
