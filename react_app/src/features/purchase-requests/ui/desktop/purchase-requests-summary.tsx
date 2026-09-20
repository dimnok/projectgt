"use client";

import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import type { PurchaseRequestCounts } from "@/features/purchase-requests/types/purchase-request.types";
import { PURCHASE_REQUEST_FILTER_OPTIONS } from "@/features/purchase-requests/utils/status";

type PurchaseRequestsSummaryProps = {
  counts?: PurchaseRequestCounts;
  truncated: boolean;
  settingsReady: boolean;
};

export function PurchaseRequestsSummary({
  counts,
  truncated,
  settingsReady,
}: PurchaseRequestsSummaryProps) {
  return (
    <Card className="shadow-float max-lg:[--card-spacing:--spacing(3)]">
      <CardHeader className="border-b max-lg:hidden">
        <CardTitle>Сводка</CardTitle>
        <CardDescription>С учётом поиска и прав доступа</CardDescription>
      </CardHeader>
      <CardContent className="flex flex-col gap-4">
        {!settingsReady ? (
          <p className="text-sm text-muted-foreground">
            Маршрут согласования ещё не настроен. Создать заявку можно после
            указания участников.
          </p>
        ) : null}
        {truncated ? (
          <p className="text-sm text-muted-foreground">
            Показаны первые 50 заявок. Уточните поиск, чтобы найти нужную.
          </p>
        ) : null}
        <ul className="flex flex-col">
          {PURCHASE_REQUEST_FILTER_OPTIONS.map((item) => (
            <li
              key={item.value}
              className="flex items-center justify-between gap-3 border-b py-3 last:border-b-0"
            >
              <span className="text-sm text-muted-foreground">
                {item.label}
              </span>
              <span className="tabular-nums text-sm font-medium">
                {counts?.[item.value] ?? "—"}
              </span>
            </li>
          ))}
        </ul>
      </CardContent>
    </Card>
  );
}
