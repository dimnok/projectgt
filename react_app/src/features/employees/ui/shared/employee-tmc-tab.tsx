"use client";

import { useQuery } from "@tanstack/react-query";
import {
  BoxesIcon,
  CalendarIcon,
  MapPinIcon,
  TagIcon,
} from "lucide-react";

import { Badge } from "@/components/ui/badge";
import { Spinner } from "@/components/ui/spinner";
import { getEmployeeTmcAssignments } from "@/features/employees/api/get-employee-tmc";
import type { Employee } from "@/features/employees/types/employee.types";
import { formatRuDate } from "@/features/employees/utils/employee.utils";

type EmployeeTmcTabProps = {
  employee: Employee;
  objectNamesById: Map<string, string>;
};

function formatCurrencyRub(amount: number) {
  return new Intl.NumberFormat("ru-RU", {
    style: "currency",
    currency: "RUB",
    maximumFractionDigits: 0,
  }).format(amount);
}

export function EmployeeTmcTab({
  employee,
  objectNamesById,
}: EmployeeTmcTabProps) {
  const { data, isLoading, isError, error } = useQuery({
    queryKey: ["employee-tmc", employee.id],
    queryFn: () => getEmployeeTmcAssignments(employee.id),
  });

  const assignments = data ?? [];

  const totalCost = assignments.reduce(
    (sum, item) => sum + (item.totalCost || 0),
    0
  );

  return (
    <div className="flex flex-col gap-6">
      {/* Шапка раздела ТМЦ со сводкой */}
      <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h3 className="text-base font-bold tracking-tight text-foreground">
            Выданное имущество (ТМЦ)
          </h3>
          <p className="text-xs text-muted-foreground">
            Активные материальные ценности, числящиеся за сотрудником
          </p>
        </div>

        <div className="flex items-center gap-3">
          <div className="flex items-center gap-2 rounded-xl border border-border/80 bg-card px-3.5 py-2">
            <span className="text-xs text-muted-foreground">Позиций:</span>
            <span className="text-base font-bold text-foreground">
              {assignments.length}
            </span>
          </div>

          <div className="flex items-center gap-2 rounded-xl border border-border/80 bg-card px-3.5 py-2">
            <span className="text-xs text-muted-foreground">На сумму:</span>
            <span className="text-base font-bold text-emerald-600 dark:text-emerald-400">
              {formatCurrencyRub(totalCost)}
            </span>
          </div>
        </div>
      </div>

      {isLoading ? (
        <div className="flex min-h-48 items-center justify-center">
          <Spinner className="size-6 text-primary" />
        </div>
      ) : isError ? (
        <div className="rounded-xl border border-destructive/30 bg-destructive/5 p-4 text-center text-sm text-destructive">
          {error instanceof Error ? error.message : "Не удалось загрузить ТМЦ"}
        </div>
      ) : assignments.length === 0 ? (
        <div className="flex min-h-48 flex-col items-center justify-center gap-2 rounded-2xl border border-dashed border-border p-8 text-center">
          <div className="flex size-10 items-center justify-center rounded-xl bg-muted text-muted-foreground">
            <BoxesIcon className="size-5" />
          </div>
          <p className="text-sm font-semibold text-foreground">
            За сотрудником не числится выданных ТМЦ
          </p>
          <p className="max-w-sm text-xs text-muted-foreground">
            Инструменты, спецодежда или оборудование выдаются через общий модуль
            учёта ТМЦ компании.
          </p>
        </div>
      ) : (
        <div className="flex flex-col gap-2.5">
          {assignments.map((item, index) => {
            const objectName =
              (item.objectId ? objectNamesById.get(item.objectId) : null) ||
              item.objectName ||
              "Объект не привязан";

            return (
              <div
                key={item.id}
                className="flex flex-col justify-between gap-3 rounded-xl border border-border/70 bg-card p-4 transition-all hover:border-border hover:shadow-2xs sm:flex-row sm:items-center"
              >
                <div className="flex min-w-0 items-start gap-3.5">
                  <span className="flex size-6 shrink-0 items-center justify-center rounded-lg bg-muted text-xs font-semibold text-muted-foreground">
                    {index + 1}
                  </span>

                  <div className="flex min-w-0 flex-col gap-1">
                    <div className="flex flex-wrap items-center gap-2">
                      <span className="text-sm font-semibold text-foreground">
                        {item.itemName}
                      </span>
                      {item.inventoryNumber ? (
                        <Badge
                          variant="outline"
                          className="font-mono text-[11px] h-4.5"
                        >
                          № {item.inventoryNumber}
                        </Badge>
                      ) : null}
                    </div>

                    <div className="flex flex-wrap items-center gap-x-4 gap-y-1 text-xs text-muted-foreground">
                      <div className="flex items-center gap-1">
                        <MapPinIcon className="size-3 text-muted-foreground shrink-0" />
                        <span>{objectName}</span>
                      </div>

                      <div className="flex items-center gap-1">
                        <CalendarIcon className="size-3 text-muted-foreground shrink-0" />
                        <span>Выдано: {formatRuDate(item.issuedAt)}</span>
                      </div>

                      {item.plannedReturnDate ? (
                        <div className="flex items-center gap-1">
                          <span>Возврат до: {formatRuDate(item.plannedReturnDate)}</span>
                        </div>
                      ) : null}
                    </div>
                  </div>
                </div>

                <div className="flex shrink-0 items-center justify-between gap-4 border-t border-border/50 pt-2 sm:border-0 sm:pt-0">
                  <div className="flex items-center gap-1.5 text-xs text-muted-foreground">
                    <TagIcon className="size-3 text-muted-foreground" />
                    <span>{item.quantity} шт.</span>
                  </div>

                  <div className="text-right">
                    <span className="text-sm font-bold text-foreground">
                      {formatCurrencyRub(item.totalCost)}
                    </span>
                    {item.quantity > 1 ? (
                      <div className="text-[10px] text-muted-foreground">
                        {formatCurrencyRub(item.unitPrice)} / шт.
                      </div>
                    ) : null}
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
}
