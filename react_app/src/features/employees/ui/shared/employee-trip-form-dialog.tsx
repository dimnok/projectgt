"use client";

import { useState, type FormEvent } from "react";

import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import {
  Field,
  FieldDescription,
  FieldError,
  FieldGroup,
  FieldLabel,
  FieldLegend,
  FieldSet,
} from "@/components/ui/field";
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
import type {
  EmployeeObjectOption,
  EmployeeTripRate,
  EmployeeTripRateDraft,
} from "@/features/employees/types/employee.types";
import { parseDecimal } from "@/features/employees/utils/employee-pay.utils";
import { todayDateInput } from "@/features/employees/utils/employee.utils";

type EmployeeTripFormDialogProps = {
  open: boolean;
  objects: EmployeeObjectOption[];
  rate?: EmployeeTripRate | null;
  isSaving: boolean;
  onOpenChange: (open: boolean) => void;
  onSubmit: (draft: EmployeeTripRateDraft) => void;
};

type FormErrors = Partial<
  Record<"objectId" | "rate" | "minimumHours" | "validFrom" | "validTo", string>
>;

function toDraft(rate?: EmployeeTripRate | null): EmployeeTripRateDraft {
  return {
    objectId: rate?.objectId ?? "",
    rate: rate?.rate ?? 0,
    minimumHours: rate?.minimumHours ?? 0,
    validFrom: rate?.validFrom ?? todayDateInput(),
    validTo: rate?.validTo ?? null,
  };
}

export function EmployeeTripFormDialog({
  open,
  objects,
  rate,
  isSaving,
  onOpenChange,
  onSubmit,
}: EmployeeTripFormDialogProps) {
  const isEdit = Boolean(rate);

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-h-[min(90vh,40rem)] overflow-y-auto sm:max-w-lg">
        <DialogHeader>
          <DialogTitle>
            {isEdit ? "Изменение суточных" : "Добавление суточных"}
          </DialogTitle>
          <DialogDescription>
            Объект, сумма за смену, минимум часов и период действия.
          </DialogDescription>
        </DialogHeader>
        {open ? (
          <TripForm
            key={rate?.id ?? "new"}
            objects={objects}
            rate={rate}
            isSaving={isSaving}
            onCancel={() => onOpenChange(false)}
            onSubmit={onSubmit}
          />
        ) : null}
      </DialogContent>
    </Dialog>
  );
}

function TripForm({
  objects,
  rate,
  isSaving,
  onCancel,
  onSubmit,
}: {
  objects: EmployeeObjectOption[];
  rate?: EmployeeTripRate | null;
  isSaving: boolean;
  onCancel: () => void;
  onSubmit: (draft: EmployeeTripRateDraft) => void;
}) {
  const initial = toDraft(rate);
  const [objectId, setObjectId] = useState(initial.objectId);
  const [amount, setAmount] = useState(
    rate ? String(rate.rate) : ""
  );
  const [minimumHours, setMinimumHours] = useState(
    rate ? String(rate.minimumHours) : ""
  );
  const [validFrom, setValidFrom] = useState(initial.validFrom);
  const [validTo, setValidTo] = useState(initial.validTo ?? "");
  const [errors, setErrors] = useState<FormErrors>({});
  const objectItems = objects.map((object) => ({
    value: object.id,
    label: object.name,
  }));

  function validate(): FormErrors {
    const next: FormErrors = {};
    if (!objectId) {
      next.objectId = "Выберите объект";
    }
    const parsedRate = parseDecimal(amount);
    if (parsedRate == null || parsedRate < 0) {
      next.rate = "Введите корректную сумму";
    }
    const parsedHours = parseDecimal(minimumHours);
    if (parsedHours == null || parsedHours < 0) {
      next.minimumHours = "Введите корректное значение";
    }
    if (!validFrom) {
      next.validFrom = "Укажите дату начала";
    }
    if (validTo && validFrom && validTo < validFrom) {
      next.validTo = "Дата окончания не может быть раньше начала";
    }
    return next;
  }

  function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const nextErrors = validate();
    setErrors(nextErrors);
    if (Object.keys(nextErrors).length > 0) {
      return;
    }
    const parsedRate = parseDecimal(amount);
    const parsedHours = parseDecimal(minimumHours);
    if (parsedRate == null || parsedHours == null) {
      return;
    }
    onSubmit({
      objectId,
      rate: parsedRate,
      minimumHours: parsedHours,
      validFrom,
      validTo: validTo || null,
    });
  }

  return (
    <form className="flex flex-col gap-4" onSubmit={handleSubmit}>
      <FieldGroup>
        <Field data-invalid={Boolean(errors.objectId)}>
          <FieldLabel htmlFor="employee-trip-object">Объект работы</FieldLabel>
          {objects.length === 0 ? (
            <FieldDescription>
              Сначала добавьте объекты в справочник.
            </FieldDescription>
          ) : (
            <Select
              items={objectItems}
              value={objectId || null}
              disabled={isSaving}
              onValueChange={(value) => {
                if (value === null) {
                  return;
                }
                setObjectId(value);
              }}
            >
              <SelectTrigger
                id="employee-trip-object"
                className="w-full"
                aria-invalid={Boolean(errors.objectId)}
              >
                <SelectValue placeholder="Выберите объект" />
              </SelectTrigger>
              <SelectContent>
                <SelectGroup>
                  {objects.map((object) => (
                    <SelectItem key={object.id} value={object.id}>
                      {object.name}
                    </SelectItem>
                  ))}
                </SelectGroup>
              </SelectContent>
            </Select>
          )}
          {errors.objectId ? <FieldError>{errors.objectId}</FieldError> : null}
        </Field>

        <FieldSet>
          <FieldLegend>Настройки выплат</FieldLegend>
          <Field data-invalid={Boolean(errors.rate)}>
            <FieldLabel htmlFor="employee-trip-rate">
              Сумма суточных (₽/смена)
            </FieldLabel>
            <Input
              id="employee-trip-rate"
              inputMode="decimal"
              value={amount}
              disabled={isSaving}
              aria-invalid={Boolean(errors.rate)}
              placeholder="Введите сумму"
              onChange={(event) => {
                const next = event.target.value;
                if (next === "" || /^\d+\.?\d{0,2}$/.test(next)) {
                  setAmount(next);
                }
              }}
            />
            {errors.rate ? <FieldError>{errors.rate}</FieldError> : null}
          </Field>
          <Field data-invalid={Boolean(errors.minimumHours)}>
            <FieldLabel htmlFor="employee-trip-hours">
              Минимум часов для начисления
            </FieldLabel>
            <Input
              id="employee-trip-hours"
              inputMode="decimal"
              value={minimumHours}
              disabled={isSaving}
              aria-invalid={Boolean(errors.minimumHours)}
              placeholder="Например: 5"
              onChange={(event) => {
                const next = event.target.value;
                if (next === "" || /^\d+\.?\d{0,2}$/.test(next)) {
                  setMinimumHours(next);
                }
              }}
            />
            <FieldDescription>
              Суточные будут начислены только если сотрудник отработал не менее
              указанного количества часов
            </FieldDescription>
            {errors.minimumHours ? (
              <FieldError>{errors.minimumHours}</FieldError>
            ) : null}
          </Field>
        </FieldSet>

        <FieldSet>
          <FieldLegend>Период действия</FieldLegend>
          <Field data-invalid={Boolean(errors.validFrom)}>
            <FieldLabel htmlFor="employee-trip-from">Действует с</FieldLabel>
            <Input
              id="employee-trip-from"
              type="date"
              min="2020-01-01"
              max="2030-12-31"
              value={validFrom}
              disabled={isSaving}
              aria-invalid={Boolean(errors.validFrom)}
              onChange={(event) => setValidFrom(event.target.value)}
            />
            {errors.validFrom ? (
              <FieldError>{errors.validFrom}</FieldError>
            ) : null}
          </Field>
          <Field data-invalid={Boolean(errors.validTo)}>
            <FieldLabel htmlFor="employee-trip-to">Действует до</FieldLabel>
            <div className="flex gap-2">
              <Input
                id="employee-trip-to"
                type="date"
                min={validFrom || "2020-01-01"}
                max="2030-12-31"
                value={validTo}
                disabled={isSaving}
                aria-invalid={Boolean(errors.validTo)}
                onChange={(event) => setValidTo(event.target.value)}
              />
              {validTo ? (
                <Button
                  type="button"
                  variant="outline"
                  disabled={isSaving}
                  onClick={() => setValidTo("")}
                >
                  Сбросить
                </Button>
              ) : null}
            </div>
            <FieldDescription>
              {validTo ? "До указанной даты включительно" : "Бессрочно"}
            </FieldDescription>
            {errors.validTo ? <FieldError>{errors.validTo}</FieldError> : null}
          </Field>
        </FieldSet>
      </FieldGroup>
      <DialogFooter>
        <Button
          type="button"
          variant="outline"
          disabled={isSaving}
          onClick={onCancel}
        >
          Отмена
        </Button>
        <Button type="submit" disabled={isSaving || objects.length === 0}>
          {isSaving ? <Spinner data-icon="inline-start" /> : null}
          Сохранить
        </Button>
      </DialogFooter>
    </form>
  );
}
