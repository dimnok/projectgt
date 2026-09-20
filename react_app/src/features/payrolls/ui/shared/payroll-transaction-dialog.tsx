"use client";

import { useState } from "react";
import { toast } from "sonner";

import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Field, FieldLabel } from "@/components/ui/field";
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
import { usePayrollTransactionMutations } from "@/features/payrolls/hooks/use-payroll-mutations";
import type { PayrollTransactionKind } from "@/features/payrolls/types/payroll.types";
import { parsePayrollAmount } from "@/features/payrolls/utils/payroll.utils";
import { getTodayDateString } from "@/features/timesheet/utils/timesheet-date";

/** Данные существующей премии или удержания для правки. */
export type PayrollTransactionInitial = {
  id: string;
  date: string;
  amount: number;
  objectId: string | null;
  reason: string;
};

type PayrollTransactionDialogProps = {
  kind: PayrollTransactionKind;
  employee: { id: string; fullName: string };
  objectOptions: { key: string; label: string }[];
  /** Объект по умолчанию при создании. При правке не используется. */
  defaultObjectId: string;
  initial?: PayrollTransactionInitial | null;
  onClose: () => void;
};

/** Окно премии или удержания: создание и правка. */
export function PayrollTransactionDialog({
  kind,
  employee,
  objectOptions,
  defaultObjectId,
  initial = null,
  onClose,
}: PayrollTransactionDialogProps) {
  const isEdit = Boolean(initial);
  const isPenalty = kind === "penalty";
  const subject = isPenalty ? "Удержание" : "Премия";
  const { create, update, remove } = usePayrollTransactionMutations(kind);

  const [date, setDate] = useState(() => initial?.date ?? getTodayDateString());
  const [amount, setAmount] = useState(() =>
    initial ? String(initial.amount) : ""
  );
  const [objectId, setObjectId] = useState(
    () => initial?.objectId ?? defaultObjectId
  );
  const [reason, setReason] = useState(() => initial?.reason ?? "");

  const objectItems = objectOptions.map((option) => ({
    value: option.key,
    label: option.label,
  }));

  const isSaving = create.isPending || update.isPending;

  async function handleSave() {
    const parsed = parsePayrollAmount(amount);
    if (parsed == null || parsed <= 0) {
      toast.error("Укажите сумму больше нуля");
      return;
    }
    if (!objectId) {
      toast.error("Выберите объект");
      return;
    }
    if (!date) {
      toast.error("Укажите дату");
      return;
    }

    const draft = {
      employeeId: employee.id,
      objectId,
      date,
      amount: parsed,
      reason: reason.trim() || null,
    };

    try {
      if (initial) {
        const previous = {
          objectId: initial.objectId ?? "",
          date: initial.date,
          amount: initial.amount,
          reason: initial.reason,
        };
        await update.mutateAsync({ id: initial.id, patch: draft });
        toast.success(`${subject} изменено`, {
          action: {
            label: "Вернуть прежнее",
            onClick: () => {
              void update
                .mutateAsync({ id: initial.id, patch: previous })
                .catch((error) => {
                  toast.error(
                    error instanceof Error
                      ? error.message
                      : "Не удалось вернуть прежнее"
                  );
                });
            },
          },
        });
      } else {
        const id = await create.mutateAsync({ draft });
        toast.success(`${subject} добавлено`, {
          action: {
            label: "Отменить",
            onClick: () => void remove.mutateAsync(id),
          },
        });
      }
      onClose();
    } catch (error) {
      toast.error(
        error instanceof Error ? error.message : "Не удалось сохранить"
      );
    }
  }

  return (
    <Dialog
      open
      onOpenChange={(next) => {
        if (!next) {
          onClose();
        }
      }}
    >
      <DialogContent className="sm:max-w-md">
        <DialogHeader>
          <DialogTitle>
            {isEdit
              ? isPenalty
                ? "Изменить удержание"
                : "Изменить премию"
              : isPenalty
                ? "Добавить удержание"
                : "Начислить премию"}
          </DialogTitle>
          <DialogDescription>{employee.fullName}</DialogDescription>
        </DialogHeader>

        <div className="grid gap-4">
          <Field>
            <FieldLabel htmlFor="payroll-op-date">Дата</FieldLabel>
            <Input
              id="payroll-op-date"
              type="date"
              value={date}
              disabled={isSaving}
              onChange={(event) => setDate(event.target.value)}
            />
          </Field>

          <Field>
            <FieldLabel htmlFor="payroll-op-amount">Сумма</FieldLabel>
            <Input
              id="payroll-op-amount"
              autoFocus
              inputMode="decimal"
              placeholder="0,00"
              value={amount}
              disabled={isSaving}
              onChange={(event) => setAmount(event.target.value)}
              onKeyDown={(event) => {
                if (event.key === "Enter") {
                  event.preventDefault();
                  void handleSave();
                }
              }}
            />
          </Field>

          <Field>
            <FieldLabel htmlFor="payroll-op-object">Объект</FieldLabel>
            <Select
              value={objectId || undefined}
              items={objectItems}
              onValueChange={(value) => {
                if (typeof value === "string") {
                  setObjectId(value);
                }
              }}
            >
              <SelectTrigger id="payroll-op-object" className="w-full">
                <SelectValue placeholder="Выберите объект" />
              </SelectTrigger>
              <SelectContent align="start">
                <SelectGroup>
                  {objectItems.map((item) => (
                    <SelectItem key={item.value} value={item.value}>
                      {item.label}
                    </SelectItem>
                  ))}
                </SelectGroup>
              </SelectContent>
            </Select>
          </Field>

          <Field>
            <FieldLabel htmlFor="payroll-op-reason">
              {isPenalty ? "Комментарий" : "Примечание"}
            </FieldLabel>
            <Input
              id="payroll-op-reason"
              value={reason}
              placeholder="Необязательно"
              disabled={isSaving}
              onChange={(event) => setReason(event.target.value)}
              onKeyDown={(event) => {
                if (event.key === "Enter") {
                  event.preventDefault();
                  void handleSave();
                }
              }}
            />
          </Field>
        </div>

        <DialogFooter>
          <Button
            type="button"
            variant="outline"
            disabled={isSaving}
            onClick={onClose}
          >
            Отмена
          </Button>
          <Button
            type="button"
            disabled={isSaving}
            onClick={() => void handleSave()}
          >
            {isSaving ? <Spinner data-icon="inline-start" /> : null}
            Сохранить
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
