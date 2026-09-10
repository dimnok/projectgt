"use client";

import {
  CalendarIcon,
  InfoIcon,
  Loader2Icon,
  LockIcon,
  SparklesIcon,
  Trash2Icon,
} from "lucide-react";
import { useEffect, useMemo, useState } from "react";
import { toast } from "sonner";

import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Label } from "@/components/ui/label";
import {
  Select,
  SelectContent,
  SelectGroup,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Spinner } from "@/components/ui/spinner";
import type { Employee } from "@/features/employees/types/employee.types";
import { employeeFullName } from "@/features/employees/utils/employee.utils";
import type { SiteObject } from "@/features/objects/types/object.types";
import {
  getEmployeeAttendanceData,
  saveEmployeeAttendanceBatch,
  type AttendanceBatchRow,
} from "@/features/timesheet/api/save-employee-attendance";
import {
  getMonthDaysHeader,
  getMonthLabel,
  getStartAndEndDates,
} from "@/features/timesheet/utils/timesheet-date";
import { cn } from "@/lib/utils";

type TimesheetAttendanceDialogProps = {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  employee: Employee | null;
  year: number;
  month: number;
  objects: SiteObject[];
  onSuccess?: () => void;
};

export function TimesheetAttendanceDialog({
  open,
  onOpenChange,
  employee,
  year,
  month,
  objects,
  onSuccess,
}: TimesheetAttendanceDialogProps) {
  const [selectedObjectId, setSelectedObjectId] = useState<string>("");
  const [hoursMap, setHoursMap] = useState<Record<string, string>>({});
  const [allManualByObject, setAllManualByObject] = useState<
    Map<string, Map<string, number>>
  >(new Map());
  const [shiftHoursMap, setShiftHoursMap] = useState<Map<string, number>>(
    new Map()
  );
  const [isLoading, setIsLoading] = useState(false);
  const [isSaving, setIsSaving] = useState(false);

  // Available objects for employee: prioritize assigned objects
  const availableObjects = useMemo(() => {
    if (!employee) return objects;
    const assignedIds = new Set(employee.objectIds);
    const assigned = objects.filter((o) => assignedIds.has(o.id));
    const others = objects.filter((o) => !assignedIds.has(o.id));
    return [...assigned, ...others];
  }, [employee, objects]);

  // Object options for Select component
  const objectItems = useMemo(() => {
    if (!employee) return [];
    return availableObjects.map((obj) => {
      const isAssigned = employee.objectIds.includes(obj.id);
      return {
        value: obj.id,
        label: `${obj.name}${isAssigned ? " (назначен)" : ""}`,
      };
    });
  }, [availableObjects, employee]);

  // Load data when dialog opens
  useEffect(() => {
    if (!open || !employee) return;

    let isMounted = true;
    setIsLoading(true);

    getEmployeeAttendanceData({
      employeeId: employee.id,
      year,
      month,
    })
      .then((res) => {
        if (!isMounted) return;

        setAllManualByObject(res.manualRecordsByObjectId);
        setShiftHoursMap(res.shiftHoursByDate);

        // Pick object: either first found with records, or employee's first object, or first in available list
        const initialObj =
          res.initialObjectId ??
          employee.objectIds.find((id) =>
            objects.some((obj) => obj.id === id)
          ) ??
          objects[0]?.id ??
          "";

        setSelectedObjectId(initialObj);

        // Load hours for this object
        const objHours = res.manualRecordsByObjectId.get(initialObj);
        const nextMap: Record<string, string> = {};
        if (objHours) {
          for (const [d, h] of objHours.entries()) {
            if (h > 0) {
              nextMap[d] = String(h);
            }
          }
        }
        setHoursMap(nextMap);
      })
      .catch((err) => {
        if (!isMounted) return;
        toast.error(
          err instanceof Error
            ? err.message
            : "Не удалось загрузить данные посещаемости"
        );
      })
      .finally(() => {
        if (isMounted) setIsLoading(false);
      });

    return () => {
      isMounted = false;
    };
  }, [open, employee, year, month, objects]);

  // When selected object changes, swap hoursMap
  const handleObjectChange = (newObjId: string | null) => {
    if (!newObjId) return;
    setSelectedObjectId(newObjId);
    const objHours = allManualByObject.get(newObjId);
    const nextMap: Record<string, string> = {};
    if (objHours) {
      for (const [d, h] of objHours.entries()) {
        if (h > 0) {
          nextMap[d] = String(h);
        }
      }
    }
    setHoursMap(nextMap);
  };

  const daysHeader = useMemo(() => {
    return getMonthDaysHeader(year, month);
  }, [year, month]);

  // Day offset for Monday-first grid (0 for Mon, 1 for Tue, ..., 6 for Sun)
  const firstDayOffset = useMemo(() => {
    if (daysHeader.length === 0) return 0;
    const firstDayOfWeek = daysHeader[0].dayOfWeek; // 0 is Sun
    return firstDayOfWeek === 0 ? 6 : firstDayOfWeek - 1;
  }, [daysHeader]);

  const handleHourChange = (dateStr: string, value: string) => {
    const sanitized = value.replace(",", ".");
    // Allow empty or partial decimal numbers up to 24
    if (sanitized === "") {
      setHoursMap((prev) => {
        const next = { ...prev };
        delete next[dateStr];
        return next;
      });
      return;
    }

    if (/^\d{0,2}(\.\d{0,2})?$/.test(sanitized)) {
      const num = parseFloat(sanitized);
      if (isNaN(num) || num <= 24) {
        setHoursMap((prev) => ({
          ...prev,
          [dateStr]: sanitized,
        }));
      }
    }
  };

  const fillWeekdays = () => {
    setHoursMap((prev) => {
      const next = { ...prev };
      for (const day of daysHeader) {
        const hasShift = (shiftHoursMap.get(day.date) ?? 0) > 0;
        if (!day.isWeekend && !hasShift) {
          next[day.date] = "8";
        }
      }
      return next;
    });
  };

  const clearAllManualHours = () => {
    setHoursMap({});
  };

  // Calculate totals
  const totalManualHours = useMemo(() => {
    let sum = 0;
    for (const val of Object.values(hoursMap)) {
      const num = parseFloat(val);
      if (!isNaN(num) && num > 0) {
        sum += num;
      }
    }
    return sum;
  }, [hoursMap]);

  const totalShiftHours = useMemo(() => {
    let sum = 0;
    for (const h of shiftHoursMap.values()) {
      sum += h;
    }
    return sum;
  }, [shiftHoursMap]);

  const handleSave = async () => {
    if (!employee) return;
    if (!selectedObjectId) {
      toast.error("Выберите объект");
      return;
    }

    try {
      setIsSaving(true);

      const rows: AttendanceBatchRow[] = [];
      const { daysCount } = getStartAndEndDates(year, month);

      // Save entries for all days: if in hoursMap, save hours; if previously existed and now absent, save 0
      const existingObjHours =
        allManualByObject.get(selectedObjectId) ?? new Map();

      for (let d = 1; d <= daysCount; d += 1) {
        const dateStr = `${year}-${String(month).padStart(2, "0")}-${String(d).padStart(2, "0")}`;
        const hasShift = (shiftHoursMap.get(dateStr) ?? 0) > 0;
        if (hasShift) continue; // Skip shift days

        const rawVal = hoursMap[dateStr];
        const currentVal = rawVal ? parseFloat(rawVal) : 0;
        const hadVal = existingObjHours.get(dateStr) ?? 0;

        if (currentVal > 0 || hadVal > 0) {
          rows.push({
            date: dateStr,
            hours: currentVal > 0 ? currentVal : 0,
            attendanceType: "work",
          });
        }
      }

      await saveEmployeeAttendanceBatch({
        employeeId: employee.id,
        objectId: selectedObjectId,
        rows,
      });

      toast.success("Посещаемость успешно сохранена");
      onSuccess?.();
      onOpenChange(false);
    } catch (err) {
      toast.error(
        err instanceof Error ? err.message : "Ошибка при сохранении"
      );
    } finally {
      setIsSaving(false);
    }
  };

  if (!employee) return null;

  const monthTitle = getMonthLabel(year, month);
  const fullName = employeeFullName(employee);
  const weekdaysLabels = ["Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс"];

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-xl md:max-w-2xl max-h-[92vh] overflow-y-auto p-5 sm:p-6">
        <DialogHeader>
          <div className="flex items-center gap-2 text-primary">
            <CalendarIcon className="h-5 w-5" />
            <DialogTitle className="text-base sm:text-lg">
              Посещаемость сотрудника
            </DialogTitle>
          </div>
          <DialogDescription className="text-xs sm:text-sm text-foreground">
            <span className="font-semibold text-foreground">{fullName}</span>
            {employee.position.trim() ? (
              <span className="text-muted-foreground ml-1.5">
                ({employee.position.trim()})
              </span>
            ) : null}
            <span className="text-muted-foreground ml-1.5">· {monthTitle}</span>
          </DialogDescription>
        </DialogHeader>

        {isLoading ? (
          <div className="flex flex-col items-center justify-center py-12">
            <Spinner className="h-7 w-7 text-primary mb-2" />
            <span className="text-xs text-muted-foreground">Загрузка данных...</span>
          </div>
        ) : (
          <div className="flex flex-col gap-4 pt-1">
            {/* Object selector */}
            <div className="flex flex-col gap-1.5">
              <Label className="text-xs font-medium">Объект для учета часов</Label>
              <Select
                value={selectedObjectId}
                items={objectItems}
                onValueChange={handleObjectChange}
              >
                <SelectTrigger className="h-9 w-full rounded-lg bg-card px-3 text-xs sm:text-sm hover:bg-muted/40">
                  <SelectValue placeholder="Выберите объект" />
                </SelectTrigger>
                <SelectContent align="start">
                  <SelectGroup>
                    {objectItems.map((obj) => (
                      <SelectItem key={obj.value} value={obj.value} className="text-xs">
                        {obj.label}
                      </SelectItem>
                    ))}
                  </SelectGroup>
                </SelectContent>
              </Select>
            </div>

            {/* Quick action buttons & stats bar */}
            <div className="flex flex-wrap items-center justify-between gap-2.5 rounded-lg border border-border/80 bg-muted/20 px-3 py-2">
              <div className="flex items-center gap-2">
                <Button
                  type="button"
                  variant="outline"
                  size="sm"
                  onClick={fillWeekdays}
                  className="h-8 gap-1.5 text-xs font-medium bg-card hover:bg-muted"
                >
                  <SparklesIcon className="h-3.5 w-3.5 text-primary" />
                  <span>Будни по 8ч</span>
                </Button>
                <Button
                  type="button"
                  variant="ghost"
                  size="sm"
                  onClick={clearAllManualHours}
                  className="h-8 gap-1 text-xs text-muted-foreground hover:text-destructive hover:bg-destructive/10"
                >
                  <Trash2Icon className="h-3.5 w-3.5" />
                  <span>Очистить</span>
                </Button>
              </div>

              <div className="flex items-center gap-3 text-xs">
                <span className="text-muted-foreground">
                  Ручные:{" "}
                  <strong className="text-foreground font-semibold">
                    {totalManualHours} ч
                  </strong>
                </span>
                {totalShiftHours > 0 ? (
                  <span className="text-muted-foreground">
                    Смены:{" "}
                    <strong className="text-foreground font-semibold">
                      {totalShiftHours} ч
                    </strong>
                  </span>
                ) : null}
                <span className="rounded-md bg-primary/10 px-2 py-0.5 text-xs font-bold text-primary">
                  Всего: {totalManualHours + totalShiftHours} ч
                </span>
              </div>
            </div>

            {/* Calendar card */}
            <div className="overflow-hidden rounded-xl border border-border bg-card shadow-xs">
              {/* Period banner */}
              <div className="bg-muted/40 px-3 py-1.5 text-center text-xs font-semibold text-foreground border-b border-border">
                Период: {monthTitle}
              </div>

              {/* Weekday headers row */}
              <div className="grid grid-cols-7 border-b border-border bg-muted/20 text-center text-xs font-semibold">
                {weekdaysLabels.map((lbl, idx) => (
                  <div
                    key={lbl}
                    className={cn(
                      "py-2 border-r border-border last:border-r-0 select-none",
                      idx === 5 || idx === 6
                        ? "text-destructive font-bold bg-destructive/5"
                        : "text-muted-foreground"
                    )}
                  >
                    {lbl}
                  </div>
                ))}
              </div>

              {/* Day cells grid with single-pixel dividers */}
              <div className="grid grid-cols-7 divide-x divide-y divide-border border-b-0">
                {/* Empty prefix cells for alignment */}
                {Array.from({ length: firstDayOffset }).map((_, i) => (
                  <div
                    key={`empty-${i}`}
                    className="min-h-[58px] bg-muted/10"
                  />
                ))}

                {daysHeader.map((d) => {
                  const shiftH = shiftHoursMap.get(d.date) ?? 0;
                  const hasShift = shiftH > 0;
                  const manualH = hoursMap[d.date] ?? "";

                  return (
                    <div
                      key={d.date}
                      className={cn(
                        "relative flex flex-col justify-between p-1.5 min-h-[58px] transition-colors",
                        d.isWeekend && "bg-destructive/5 dark:bg-destructive/10",
                        !d.isWeekend && hasShift && "bg-muted/30",
                        !d.isWeekend && !hasShift && "bg-card hover:bg-muted/15"
                      )}
                    >
                      {/* Top row: day number + shift indicator */}
                      <div className="flex items-center justify-between leading-none select-none">
                        {d.isToday ? (
                          <span className="inline-flex size-5 items-center justify-center rounded-full bg-primary text-primary-foreground text-[11px] font-bold">
                            {d.dayNumber}
                          </span>
                        ) : (
                          <span
                            className={cn(
                              "text-xs font-semibold px-0.5",
                              d.isWeekend
                                ? "text-destructive font-bold"
                                : "text-foreground"
                            )}
                          >
                            {d.dayNumber}
                          </span>
                        )}

                        {hasShift ? (
                          <span
                            className="inline-flex items-center gap-0.5 text-[9px] font-semibold text-muted-foreground bg-muted px-1 py-0.5 rounded"
                            title="Часы учтены в смене"
                          >
                            <LockIcon className="size-2.5" />
                            <span>смена</span>
                          </span>
                        ) : null}
                      </div>

                      {/* Bottom row: hours display or borderless input */}
                      {hasShift ? (
                        <div className="flex flex-1 items-center justify-center text-sm font-bold text-foreground">
                          {shiftH} ч
                        </div>
                      ) : (
                        <div className="flex flex-1 items-center justify-center pt-0.5">
                          <input
                            type="text"
                            inputMode="decimal"
                            value={manualH}
                            placeholder=""
                            disabled={isSaving}
                            onChange={(e) =>
                              handleHourChange(d.date, e.target.value)
                            }
                            className={cn(
                              "w-full text-center text-sm font-bold bg-transparent border-0 rounded py-0.5 transition-colors focus:outline-none focus:bg-muted/50 focus:ring-1 focus:ring-primary/40",
                              manualH
                                ? "text-foreground font-extrabold"
                                : "text-muted-foreground/30"
                            )}
                          />
                        </div>
                      )}
                    </div>
                  );
                })}
              </div>
            </div>

            {/* Helper explanation note */}
            <div className="flex items-center gap-2 rounded-lg bg-muted/40 px-3 py-2 text-xs text-muted-foreground">
              <InfoIcon className="size-4 shrink-0 text-primary" />
              <span>
                Введите часы напрямую в ячейки дней. Часы из смен (<LockIcon className="inline size-3 mb-0.5 text-muted-foreground" />) защищены от редактирования.
              </span>
            </div>
          </div>
        )}

        {/* Footer buttons */}
        <div className="flex items-center justify-end gap-2 pt-4 border-t border-border/60">
          <Button
            type="button"
            variant="outline"
            size="sm"
            onClick={() => onOpenChange(false)}
            disabled={isSaving}
          >
            Отмена
          </Button>
          <Button
            type="button"
            size="sm"
            onClick={handleSave}
            disabled={isSaving || isLoading}
          >
            {isSaving ? <Loader2Icon className="h-4 w-4 animate-spin mr-1" /> : null}
            Сохранить
          </Button>
        </div>
      </DialogContent>
    </Dialog>
  );
}
