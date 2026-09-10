"use client";

import { useMemo, useState } from "react";
import { toast } from "sonner";

import {
  MobileSheetBody,
  MobileSheetChrome,
} from "@/components/shared/mobile-sheet-chrome";
import { Button } from "@/components/ui/button";
import { DialogFooter } from "@/components/ui/dialog";
import { Field, FieldDescription, FieldLabel } from "@/components/ui/field";
import { Input } from "@/components/ui/input";
import {
  Select,
  SelectContent,
  SelectGroup,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Spinner } from "@/components/ui/spinner";
import { Textarea } from "@/components/ui/textarea";
import { useEmployees } from "@/features/employees/hooks/use-employees";
import { employeeFullName } from "@/features/employees/utils/employee.utils";
import {
  useAddWorkHour,
  useUpdateWorkHour,
} from "@/features/works/hooks/use-work-item-mutations";
import type { WorkHour } from "@/features/works/types/work.types";
import { parseWorkQuantity } from "@/features/works/utils/work.utils";

type WorkHourFormProps = {
  layout: "dialog" | "sheet";
  workId: string;
  objectId: string;
  existingHours: WorkHour[];
  initial: WorkHour | null;
  onCancel: () => void;
};

export function WorkHourForm({
  layout,
  workId,
  objectId,
  existingHours,
  initial,
  onCancel,
}: WorkHourFormProps) {
  const isEdit = Boolean(initial);
  const employeesQuery = useEmployees();
  const addMutation = useAddWorkHour(workId);
  const updateMutation = useUpdateWorkHour(workId);
  const [employeeId, setEmployeeId] = useState(initial?.employeeId ?? "");
  const [hours, setHours] = useState(
    initial ? String(initial.hours).replace(".", ",") : ""
  );
  const [comment, setComment] = useState(initial?.comment ?? "");

  const busyIds = useMemo(
    () => new Set(existingHours.map((row) => row.employeeId)),
    [existingHours]
  );

  const availableEmployees = useMemo(() => {
    const list = (employeesQuery.data ?? []).filter((employee) => {
      if (employee.status !== "working") {
        return false;
      }
      if (objectId && !employee.objectIds.includes(objectId)) {
        return false;
      }
      if (busyIds.has(employee.id) && employee.id !== initial?.employeeId) {
        return false;
      }
      return true;
    });
    return [...list].sort((a, b) =>
      employeeFullName(a).localeCompare(employeeFullName(b), "ru")
    );
  }, [employeesQuery.data, objectId, busyIds, initial?.employeeId]);

  const employeeItems = availableEmployees.map((employee) => ({
    value: employee.id,
    label: employeeFullName(employee),
  }));

  const isSaving = addMutation.isPending || updateMutation.isPending;
  const canSave = isEdit ? !isSaving : Boolean(employeeId) && !isSaving;

  async function handleSave() {
    const parsed = parseWorkQuantity(hours);
    if (hours.trim() && parsed == null) {
      toast.error("Введите корректное число часов");
      return;
    }
    if (parsed != null && parsed < 0) {
      toast.error("Часы не могут быть отрицательными");
      return;
    }
    const nextHours = parsed ?? 0;
    const nextComment = comment.trim() ? comment.trim() : null;

    try {
      if (isEdit && initial) {
        await updateMutation.mutateAsync({
          hourId: initial.id,
          workId,
          hours: nextHours,
          comment: nextComment,
        });
        toast.success("Часы сохранены");
      } else {
        if (!employeeId) {
          return;
        }
        await addMutation.mutateAsync({
          employeeId,
          hours: nextHours,
          comment: nextComment,
        });
        toast.success("Сотрудник добавлен");
      }
      onCancel();
    } catch (error) {
      toast.error(
        error instanceof Error
          ? error.message
          : isEdit
            ? "Не удалось сохранить часы"
            : "Не удалось добавить сотрудника"
      );
    }
  }

  const actions = (
    <>
      <Button type="button" variant="outline" onClick={onCancel}>
        Отмена
      </Button>
      <Button type="button" disabled={!canSave} onClick={() => void handleSave()}>
        {isSaving ? <Spinner data-icon="inline-start" /> : null}
        Сохранить
      </Button>
    </>
  );

  const fields = (
    <>
      {isEdit ? (
        <Field>
          <FieldLabel>Сотрудник</FieldLabel>
          <p className="rounded-lg border bg-muted/40 px-2.5 py-2 text-sm font-medium">
            {initial?.employeeName}
          </p>
        </Field>
      ) : (
        <Field>
          <FieldLabel htmlFor="shift-employee">Сотрудник</FieldLabel>
          <Select
            value={employeeId || null}
            items={employeeItems}
            disabled={employeesQuery.isLoading || employeeItems.length === 0}
            onValueChange={(next) => {
              if (typeof next === "string") {
                setEmployeeId(next);
              }
            }}
          >
            <SelectTrigger id="shift-employee" className="w-full">
              <SelectValue
                placeholder={
                  employeesQuery.isLoading
                    ? "Загрузка…"
                    : employeeItems.length === 0
                      ? "Нет свободных сотрудников"
                      : "Выберите сотрудника"
                }
              />
            </SelectTrigger>
            <SelectContent
              align="start"
              side={layout === "sheet" ? "top" : "bottom"}
              alignItemWithTrigger={layout !== "sheet"}
              className={
                layout === "sheet" ? "max-h-[min(50vh,16rem)] z-[70]" : undefined
              }
            >
              <SelectGroup>
                {employeeItems.map((item) => (
                  <SelectItem key={item.value} value={item.value}>
                    {item.label}
                  </SelectItem>
                ))}
              </SelectGroup>
            </SelectContent>
          </Select>
        </Field>
      )}

      <Field>
        <FieldLabel htmlFor="shift-hours">Часы</FieldLabel>
        <Input
          id="shift-hours"
          value={hours}
          inputMode="decimal"
          placeholder="0"
          onChange={(event) => setHours(event.target.value)}
        />
        <FieldDescription>
          Можно оставить пустым — часы проставляются позже.
        </FieldDescription>
      </Field>

      <Field>
        <FieldLabel htmlFor="shift-comment">Комментарий</FieldLabel>
        <Textarea
          id="shift-comment"
          value={comment}
          rows={3}
          placeholder="Необязательно"
          onChange={(event) => setComment(event.target.value)}
        />
      </Field>
    </>
  );

  if (layout === "sheet") {
    return (
      <>
        <MobileSheetChrome
          title={isEdit ? "Изменить часы" : "Добавить сотрудника"}
          description={
            isEdit
              ? "Можно изменить часы и комментарий."
              : "Выберите сотрудника. Часы можно указать позже."
          }
          confirmLabel="Сохранить"
          confirmDisabled={!canSave}
          confirmPending={isSaving}
          onConfirm={() => void handleSave()}
        />
        <MobileSheetBody>{fields}</MobileSheetBody>
      </>
    );
  }

  return (
    <div className="flex flex-col gap-3">
      {fields}
      <DialogFooter>{actions}</DialogFooter>
    </div>
  );
}
