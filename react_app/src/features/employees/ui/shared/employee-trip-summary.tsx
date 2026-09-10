"use client";

import { useState } from "react";
import {
  ChevronDownIcon,
  ChevronUpIcon,
  MapPinIcon,
  PlusIcon,
  UtensilsCrossedIcon,
} from "lucide-react";
import { toast } from "sonner";

import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Spinner } from "@/components/ui/spinner";
import {
  useEmployeeTripRates,
  useSaveEmployeeTripRate,
} from "@/features/employees/hooks/use-employee-trip-rates";
import type {
  Employee,
  EmployeeObjectOption,
  EmployeeTripRate,
  EmployeeTripRateDraft,
} from "@/features/employees/types/employee.types";
import { EmployeeTripFormDialog } from "@/features/employees/ui/shared/employee-trip-form-dialog";
import {
  formatTripPeriod,
  formatTripRateShort,
  isTripRateActive,
  mapTripWriteError,
  tripRatesSummary,
} from "@/features/employees/utils/employee-pay.utils";
import { cn } from "@/lib/utils";

type EmployeeTripSummaryProps = {
  employee: Employee;
  objects: EmployeeObjectOption[];
  objectNamesById: Map<string, string>;
  canUpdate: boolean;
};

export function EmployeeTripSummary({
  employee,
  objects,
  objectNamesById,
  canUpdate,
}: EmployeeTripSummaryProps) {
  const [isExpanded, setIsExpanded] = useState(false);
  const [editorRate, setEditorRate] = useState<
    EmployeeTripRate | null | undefined
  >(undefined);
  const { data, isLoading, isError } = useEmployeeTripRates(employee.id, true);
  const saveTrip = useSaveEmployeeTripRate(employee.id);
  const rates = data ?? [];
  const summary = isLoading ? "Загрузка…" : tripRatesSummary(rates);
  const isEditorOpen = editorRate !== undefined;

  function handleSave(draft: EmployeeTripRateDraft) {
    saveTrip.mutate(
      { rateId: editorRate?.id, draft },
      {
        onSuccess: () => {
          setEditorRate(undefined);
          setIsExpanded(true);
          toast.success("Суточные сохранены");
        },
        onError: (error) => toast.error(mapTripWriteError(error)),
      }
    );
  }

  const hasRates = rates.length > 0;
  const hasActive = rates.some(isTripRateActive);

  return (
    <div className="flex flex-col gap-2">
      <div
        role="button"
        tabIndex={0}
        className={cn(
          "group/trip relative flex cursor-pointer items-center gap-3 rounded-xl border border-border/80 bg-card p-3.5 transition-all hover:border-border hover:bg-muted/30 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring",
          isExpanded && hasRates && "border-primary/40 bg-muted/20"
        )}
        onClick={() => {
          if (hasRates) {
            setIsExpanded((current) => !current);
          }
        }}
        onKeyDown={(e) => {
          if ((e.key === "Enter" || e.key === " ") && hasRates) {
            e.preventDefault();
            setIsExpanded((current) => !current);
          }
        }}
      >
        <div className="flex size-9 shrink-0 items-center justify-center rounded-lg bg-blue-500/10 text-blue-600 dark:bg-blue-500/20 dark:text-blue-400">
          <UtensilsCrossedIcon className="size-4.5" />
        </div>
        <div className="min-w-0 flex-1">
          <div className="flex items-center gap-1.5">
            <p className="text-xs font-medium text-muted-foreground">Суточные выплаты</p>
            {hasActive && (
              <span className="size-1.5 rounded-full bg-blue-500" />
            )}
          </div>
          <p className="truncate text-base font-semibold tracking-tight text-foreground">
            {summary}
          </p>
        </div>
        <div className="flex items-center gap-1">
          {canUpdate ? (
            <Button
              type="button"
              size="icon-xs"
              variant="outline"
              className="size-7 rounded-lg"
              title="Добавить суточные"
              aria-label="Добавить суточные"
              onClick={(event) => {
                event.stopPropagation();
                setEditorRate(null);
              }}
            >
              <PlusIcon className="size-3.5" />
            </Button>
          ) : null}
          {hasRates ? (
            <div className="flex size-7 items-center justify-center rounded-lg text-muted-foreground transition-transform group-hover/trip:text-foreground">
              {isExpanded ? (
                <ChevronUpIcon className="size-4" />
              ) : (
                <ChevronDownIcon className="size-4" />
              )}
            </div>
          ) : null}
        </div>
      </div>

      {isExpanded && hasRates ? (
        <div className="overflow-hidden rounded-xl border border-border/70 bg-muted/30 p-3.5 animate-in fade-in-0 duration-200">
          {isLoading ? (
            <div className="flex justify-center py-4">
              <Spinner />
            </div>
          ) : isError ? (
            <p className="text-center text-xs text-destructive">
              Ошибка загрузки суточных
            </p>
          ) : (
            <div className="flex flex-col gap-2">
              <p className="text-xs font-semibold text-muted-foreground">
                Настройки суточных по объектам:
              </p>
              <div className="flex flex-col gap-2">
                {rates.map((rate) => {
                  const active = isTripRateActive(rate);
                  const objectName =
                    objectNamesById.get(rate.objectId) ?? "Объект не найден";
                  return (
                    <button
                      key={rate.id}
                      type="button"
                      disabled={!canUpdate}
                      className={cn(
                        "group/rate-btn flex flex-col gap-1.5 rounded-lg border border-border/60 bg-card p-3 text-left transition-all",
                        canUpdate &&
                          "cursor-pointer hover:border-primary/40 hover:bg-muted/40"
                      )}
                      onClick={() => {
                        if (canUpdate) {
                          setEditorRate(rate);
                        }
                      }}
                    >
                      <div className="flex items-center justify-between gap-2">
                        <div className="flex min-w-0 items-center gap-1.5">
                          <MapPinIcon className="size-3.5 shrink-0 text-muted-foreground" />
                          <p className="truncate text-sm font-semibold text-foreground">
                            {objectName}
                          </p>
                        </div>
                        <Badge
                          variant={active ? "success" : "warning"}
                          className="h-4.5 text-[11px]"
                        >
                          {active ? "Активно" : "Неактивно"}
                        </Badge>
                      </div>
                      <div className="flex items-center justify-between gap-2 text-xs">
                        <span className="font-semibold text-foreground">
                          {formatTripRateShort(rate.rate)}
                        </span>
                        <span className="text-muted-foreground">
                          порог: от {rate.minimumHours.toFixed(1)} ч.
                        </span>
                      </div>
                      <p className="text-[11px] text-muted-foreground/80">
                        {formatTripPeriod(rate)}
                      </p>
                    </button>
                  );
                })}
              </div>
            </div>
          )}
        </div>
      ) : null}

      <EmployeeTripFormDialog
        open={isEditorOpen}
        objects={objects}
        rate={editorRate}
        isSaving={saveTrip.isPending}
        onOpenChange={(open) => {
          if (!open) {
            setEditorRate(undefined);
          }
        }}
        onSubmit={handleSave}
      />
    </div>
  );
}
