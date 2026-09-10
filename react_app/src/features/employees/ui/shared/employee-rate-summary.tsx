"use client";

import { useState } from "react";
import {
  BanknoteIcon,
  ChevronDownIcon,
  ChevronUpIcon,
  PlusIcon,
  StarIcon,
} from "lucide-react";
import { toast } from "sonner";

import { Button } from "@/components/ui/button";
import { Spinner } from "@/components/ui/spinner";
import {
  useEmployeeRates,
  useSetEmployeeRate,
} from "@/features/employees/hooks/use-employee-rates";
import type {
  Employee,
  EmployeeRateDraft,
} from "@/features/employees/types/employee.types";
import { EmployeeRateFormDialog } from "@/features/employees/ui/shared/employee-rate-form-dialog";
import {
  formatHourlyRateShort,
  formatRatePeriod,
  mapRateWriteError,
} from "@/features/employees/utils/employee-pay.utils";
import { cn } from "@/lib/utils";

type EmployeeRateSummaryProps = {
  employee: Employee;
  canUpdate: boolean;
};

export function EmployeeRateSummary({
  employee,
  canUpdate,
}: EmployeeRateSummaryProps) {
  const [isExpanded, setIsExpanded] = useState(false);
  const [isEditorOpen, setIsEditorOpen] = useState(false);
  const { data, isLoading, isError } = useEmployeeRates(
    employee.id,
    isExpanded
  );
  const saveRate = useSetEmployeeRate(employee.id);
  const currentText =
    employee.currentHourlyRate != null
      ? formatHourlyRateShort(employee.currentHourlyRate)
      : "Не указана";
  const rates = data ?? [];

  function handleSave(draft: EmployeeRateDraft) {
    saveRate.mutate(draft, {
      onSuccess: () => {
        setIsEditorOpen(false);
        setIsExpanded(true);
        toast.success("Ставка успешно обновлена");
      },
      onError: (error) => toast.error(mapRateWriteError(error)),
    });
  }

  return (
    <div className="flex flex-col gap-2">
      <div
        role="button"
        tabIndex={0}
        className={cn(
          "group/rate relative flex cursor-pointer items-center gap-3 rounded-xl border border-border/80 bg-card p-3.5 transition-all hover:border-border hover:bg-muted/30 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring",
          isExpanded && "border-primary/40 bg-muted/20"
        )}
        onClick={() => setIsExpanded((current) => !current)}
        onKeyDown={(e) => {
          if (e.key === "Enter" || e.key === " ") {
            e.preventDefault();
            setIsExpanded((current) => !current);
          }
        }}
      >
        <div className="flex size-9 shrink-0 items-center justify-center rounded-lg bg-emerald-500/10 text-emerald-600 dark:bg-emerald-500/20 dark:text-emerald-400">
          <BanknoteIcon className="size-4.5" />
        </div>
        <div className="min-w-0 flex-1">
          <div className="flex items-center gap-1.5">
            <p className="text-xs font-medium text-muted-foreground">Текущая ставка</p>
            {employee.currentHourlyRate != null && (
              <span className="size-1.5 rounded-full bg-emerald-500" />
            )}
          </div>
          <p className="text-base font-semibold tracking-tight text-foreground">
            {currentText}
          </p>
        </div>
        <div className="flex items-center gap-1">
          {canUpdate ? (
            <Button
              type="button"
              size="icon-xs"
              variant="outline"
              className="size-7 rounded-lg"
              title="Изменить ставку"
              aria-label="Изменить ставку"
              onClick={(event) => {
                event.stopPropagation();
                setIsEditorOpen(true);
              }}
            >
              <PlusIcon className="size-3.5" />
            </Button>
          ) : null}
          <div className="flex size-7 items-center justify-center rounded-lg text-muted-foreground transition-transform group-hover/rate:text-foreground">
            {isExpanded ? (
              <ChevronUpIcon className="size-4" />
            ) : (
              <ChevronDownIcon className="size-4" />
            )}
          </div>
        </div>
      </div>

      {isExpanded ? (
        <div className="overflow-hidden rounded-xl border border-border/70 bg-muted/30 p-3.5 animate-in fade-in-0 duration-200">
          {isLoading ? (
            <div className="flex justify-center py-4">
              <Spinner />
            </div>
          ) : isError ? (
            <p className="text-center text-xs text-destructive">
              Ошибка загрузки истории ставок
            </p>
          ) : rates.length === 0 ? (
            <p className="text-center text-xs text-muted-foreground">
              История ставок пуста
            </p>
          ) : (
            <div className="flex flex-col gap-2">
              <div className="flex items-center justify-between text-xs font-semibold text-muted-foreground">
                <span>История изменений</span>
                <span className="text-[11px] font-normal text-muted-foreground/80">
                  Период действия
                </span>
              </div>
              <div className="flex flex-col gap-1.5">
                {rates.map((rate) => {
                  const isCurrent = rate.validTo == null;
                  return (
                    <div
                      key={rate.id}
                      className={cn(
                        "flex items-center justify-between gap-3 rounded-lg border px-3 py-2 text-xs transition-colors",
                        isCurrent
                          ? "border-emerald-500/30 bg-emerald-500/5 font-medium dark:bg-emerald-500/10"
                          : "border-border/60 bg-card text-muted-foreground"
                      )}
                    >
                      <div className="flex items-center gap-2">
                        {isCurrent ? (
                          <span className="flex items-center gap-1 rounded-md bg-emerald-500/15 px-1.5 py-0.5 text-[11px] font-semibold text-emerald-700 dark:text-emerald-400">
                            <StarIcon className="size-3 fill-emerald-500 text-emerald-500" />
                            Текущая
                          </span>
                        ) : null}
                        <span
                          className={cn(
                            "text-sm font-semibold",
                            isCurrent ? "text-foreground" : "text-muted-foreground"
                          )}
                        >
                          {formatHourlyRateShort(rate.hourlyRate)}
                        </span>
                      </div>
                      <span className="text-right text-[11px] text-muted-foreground">
                        {formatRatePeriod(rate)}
                      </span>
                    </div>
                  );
                })}
              </div>
            </div>
          )}
        </div>
      ) : null}

      <EmployeeRateFormDialog
        employee={employee}
        open={isEditorOpen}
        isSaving={saveRate.isPending}
        onOpenChange={setIsEditorOpen}
        onSubmit={handleSave}
      />
    </div>
  );
}
