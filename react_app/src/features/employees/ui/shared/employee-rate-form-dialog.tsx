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
} from "@/components/ui/field";
import { Input } from "@/components/ui/input";
import { Spinner } from "@/components/ui/spinner";
import { findOverlappingEmployeeRates } from "@/features/employees/api/get-employee-rates";
import type {
  Employee,
  EmployeeRateDraft,
  EmployeeRateOverlap,
} from "@/features/employees/types/employee.types";
import {
  formatHourlyRateShort,
  mapRateWriteError,
  overlapActionForRate,
  overlapActionLabel,
  overlapPeriodText,
  parseDecimal,
} from "@/features/employees/utils/employee-pay.utils";
import {
  formatRuDate,
  todayDateInput,
} from "@/features/employees/utils/employee.utils";

type EmployeeRateFormDialogProps = {
  employee: Employee;
  open: boolean;
  isSaving: boolean;
  onOpenChange: (open: boolean) => void;
  onSubmit: (draft: EmployeeRateDraft) => void;
};

type FormErrors = Partial<Record<"hourlyRate" | "validFrom", string>>;

export function EmployeeRateFormDialog({
  employee,
  open,
  isSaving,
  onOpenChange,
  onSubmit,
}: EmployeeRateFormDialogProps) {
  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-md">
        {open ? (
          <RateForm
            key={employee.id}
            employee={employee}
            isSaving={isSaving}
            onCancel={() => onOpenChange(false)}
            onSubmit={onSubmit}
          />
        ) : null}
      </DialogContent>
    </Dialog>
  );
}

function RateForm({
  employee,
  isSaving,
  onCancel,
  onSubmit,
}: {
  employee: Employee;
  isSaving: boolean;
  onCancel: () => void;
  onSubmit: (draft: EmployeeRateDraft) => void;
}) {
  const [hourlyRate, setHourlyRate] = useState(
    employee.currentHourlyRate != null
      ? employee.currentHourlyRate.toFixed(0)
      : ""
  );
  const [validFrom, setValidFrom] = useState(todayDateInput());
  const [errors, setErrors] = useState<FormErrors>({});
  const [formError, setFormError] = useState<string | null>(null);
  const [isChecking, setIsChecking] = useState(false);
  const [pendingDraft, setPendingDraft] = useState<EmployeeRateDraft | null>(
    null
  );
  const [overlaps, setOverlaps] = useState<EmployeeRateOverlap[]>([]);

  function validate(): FormErrors {
    const next: FormErrors = {};
    const amount = parseDecimal(hourlyRate);
    if (amount == null || amount <= 0) {
      next.hourlyRate = "Введите корректную сумму ставки";
    }
    if (!validFrom) {
      next.validFrom = "Укажите дату начала";
    } else if (validFrom > todayDateInput()) {
      next.validFrom = "Дата не может быть позже сегодня";
    }
    return next;
  }

  async function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const nextErrors = validate();
    setErrors(nextErrors);
    setFormError(null);
    if (Object.keys(nextErrors).length > 0) {
      return;
    }
    const amount = parseDecimal(hourlyRate);
    if (amount == null) {
      return;
    }
    const draft: EmployeeRateDraft = {
      hourlyRate: amount,
      validFrom,
    };
    setIsChecking(true);
    try {
      const overlapping = await findOverlappingEmployeeRates(
        employee.id,
        draft.validFrom
      );
      if (overlapping.length > 0) {
        setPendingDraft(draft);
        setOverlaps(
          overlapping.map((rate) => ({
            rate,
            action: overlapActionForRate(rate.validFrom, draft.validFrom),
          }))
        );
        return;
      }
      onSubmit(draft);
    } catch (error) {
      setFormError(
        `Не удалось проверить существующие ставки: ${mapRateWriteError(error)}`
      );
    } finally {
      setIsChecking(false);
    }
  }

  const busy = isSaving || isChecking;

  if (pendingDraft && overlaps.length > 0) {
    return (
      <div className="flex flex-col gap-4">
        <DialogHeader>
          <DialogTitle>Найдены пересекающиеся ставки</DialogTitle>
          <DialogDescription>
            Новая ставка {formatHourlyRateShort(pendingDraft.hourlyRate)} с{" "}
            {formatRuDate(pendingDraft.validFrom)} пересекается со следующими
            записями:
          </DialogDescription>
        </DialogHeader>
        <ul className="flex flex-col gap-3">
          {overlaps.map((overlap) => (
            <li key={overlap.rate.id} className="text-sm">
              <p>
                • {formatHourlyRateShort(overlap.rate.hourlyRate)},{" "}
                {overlapPeriodText(overlap.rate)}
              </p>
              <p className="pl-3 font-medium text-primary">
                {overlapActionLabel(overlap, pendingDraft.validFrom)}
              </p>
            </li>
          ))}
        </ul>
        <p className="text-sm font-medium">Продолжить?</p>
        <DialogFooter>
          <Button
            type="button"
            variant="outline"
            disabled={busy}
            onClick={() => {
              setPendingDraft(null);
              setOverlaps([]);
            }}
          >
            Отмена
          </Button>
          <Button
            type="button"
            disabled={busy}
            onClick={() => onSubmit(pendingDraft)}
          >
            {isSaving ? <Spinner data-icon="inline-start" /> : null}
            Подтвердить и сохранить
          </Button>
        </DialogFooter>
      </div>
    );
  }

  return (
    <form className="flex flex-col gap-4" onSubmit={handleSubmit}>
      <DialogHeader>
        <DialogTitle>Изменение ставки</DialogTitle>
        <DialogDescription>
          Новая ставка начнёт действовать с указанной даты. Если она
          пересекается с уже существующими ставками, вам будет показан список
          изменений до сохранения.
        </DialogDescription>
      </DialogHeader>
      <FieldGroup>
        <Field data-invalid={Boolean(errors.hourlyRate)}>
          <FieldLabel htmlFor="employee-hourly-rate">
            Почасовая ставка (₽/час) *
          </FieldLabel>
          <Input
            id="employee-hourly-rate"
            inputMode="decimal"
            value={hourlyRate}
            disabled={busy}
            aria-invalid={Boolean(errors.hourlyRate)}
            placeholder="Например, 500"
            onChange={(event) => {
              const next = event.target.value;
              if (next === "" || /^\d+\.?\d{0,2}$/.test(next)) {
                setHourlyRate(next);
              }
            }}
          />
          {errors.hourlyRate ? (
            <FieldError>{errors.hourlyRate}</FieldError>
          ) : null}
        </Field>
        <Field data-invalid={Boolean(errors.validFrom)}>
          <FieldLabel htmlFor="employee-rate-from">
            Дата начала действия *
          </FieldLabel>
          <Input
            id="employee-rate-from"
            type="date"
            min="1900-01-01"
            value={validFrom}
            max={todayDateInput()}
            disabled={busy}
            aria-invalid={Boolean(errors.validFrom)}
            onChange={(event) => setValidFrom(event.target.value)}
          />
          {errors.validFrom ? (
            <FieldError>{errors.validFrom}</FieldError>
          ) : null}
        </Field>
        {formError ? (
          <Field>
            <FieldDescription className="text-destructive">
              {formError}
            </FieldDescription>
          </Field>
        ) : null}
      </FieldGroup>
      <DialogFooter>
        <Button
          type="button"
          variant="outline"
          disabled={busy}
          onClick={onCancel}
        >
          Отмена
        </Button>
        <Button type="submit" disabled={busy}>
          {busy ? <Spinner data-icon="inline-start" /> : null}
          Сохранить
        </Button>
      </DialogFooter>
    </form>
  );
}
