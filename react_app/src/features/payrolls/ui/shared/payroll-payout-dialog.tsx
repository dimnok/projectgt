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
import { usePayrollPayoutMutations } from "@/features/payrolls/hooks/use-payroll-mutations";
import {
  PAYOUT_METHOD_OPTIONS,
  PAYOUT_TYPE_OPTIONS,
  formatPayrollMoney,
  parsePayrollAmount,
} from "@/features/payrolls/utils/payroll.utils";
import { getTodayDateString } from "@/features/timesheet/utils/timesheet-date";

/** Данные существующей выплаты для правки. */
export type PayrollPayoutInitial = {
  id: string;
  date: string;
  amount: number;
  method: string;
  type: string;
  comment: string;
};

type PayrollPayoutDialogProps = {
  employee: { id: string; fullName: string };
  /** Предзаполненная сумма при создании — остаток или баланс сотрудника. */
  defaultAmount: string;
  /**
   * Текущий долг компании сотруднику (баланс). Если сумма выплаты больше,
   * показываем предупреждение о переплате, но сохранять не запрещаем.
   */
  debt?: number;
  initial?: PayrollPayoutInitial | null;
  onClose: () => void;
};

/** Окно выплаты: создание и правка. */
export function PayrollPayoutDialog({
  employee,
  defaultAmount,
  debt,
  initial = null,
  onClose,
}: PayrollPayoutDialogProps) {
  const isEdit = Boolean(initial);
  const { create, update, remove } = usePayrollPayoutMutations();

  const [date, setDate] = useState(() => initial?.date ?? getTodayDateString());
  const [amount, setAmount] = useState(() =>
    initial ? String(initial.amount) : defaultAmount
  );
  const [method, setMethod] = useState(
    () => initial?.method ?? PAYOUT_METHOD_OPTIONS[0]?.value ?? "card"
  );
  const [type, setType] = useState(
    () => initial?.type ?? PAYOUT_TYPE_OPTIONS[0]?.value ?? "salary"
  );
  const [comment, setComment] = useState(() => initial?.comment ?? "");

  const isSaving = create.isPending || update.isPending;

  const parsedAmount = parsePayrollAmount(amount);
  /** Сумма сверх долга — показываем предупреждение, но сохранять разрешаем. */
  const overpayment =
    debt != null && parsedAmount != null && parsedAmount > debt + 0.005
      ? parsedAmount - debt
      : 0;

  async function handleSave() {
    const parsed = parsePayrollAmount(amount);
    if (parsed == null || parsed <= 0) {
      toast.error("Укажите сумму больше нуля");
      return;
    }
    if (!date) {
      toast.error("Укажите дату");
      return;
    }

    const draft = {
      employeeId: employee.id,
      date,
      amount: parsed,
      method,
      type,
      comment: comment.trim() || null,
    };

    try {
      if (initial) {
        const previous = {
          date: initial.date,
          amount: initial.amount,
          method: initial.method,
          type: initial.type,
          comment: initial.comment || null,
        };
        await update.mutateAsync({ id: initial.id, patch: draft });
        toast.success("Выплата изменена", {
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
        toast.success("Выплата добавлена", {
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
            {isEdit ? "Изменить выплату" : "Сделать выплату"}
          </DialogTitle>
          <DialogDescription>{employee.fullName}</DialogDescription>
        </DialogHeader>

        <div className="grid gap-4">
          <Field>
            <FieldLabel htmlFor="payroll-payout-date">Дата выплаты</FieldLabel>
            <Input
              id="payroll-payout-date"
              type="date"
              value={date}
              disabled={isSaving}
              onChange={(event) => setDate(event.target.value)}
            />
          </Field>

          <Field>
            <FieldLabel htmlFor="payroll-payout-amount">Сумма</FieldLabel>
            <Input
              id="payroll-payout-amount"
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

          {overpayment > 0 ? (
            <p className="rounded-lg border border-warning/40 bg-warning/10 px-3 py-2 text-xs">
              Переплата: сумма больше долга на{" "}
              {formatPayrollMoney(overpayment)}. Выплату можно сохранить.
            </p>
          ) : null}

          <div className="grid grid-cols-2 gap-4">
            <Field>
              <FieldLabel htmlFor="payroll-payout-method">Способ</FieldLabel>
              <Select
                value={method}
                items={PAYOUT_METHOD_OPTIONS}
                onValueChange={(value) => {
                  if (typeof value === "string") {
                    setMethod(value);
                  }
                }}
              >
                <SelectTrigger id="payroll-payout-method" className="w-full">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent align="start">
                  <SelectGroup>
                    {PAYOUT_METHOD_OPTIONS.map((item) => (
                      <SelectItem key={item.value} value={item.value}>
                        {item.label}
                      </SelectItem>
                    ))}
                  </SelectGroup>
                </SelectContent>
              </Select>
            </Field>

            <Field>
              <FieldLabel htmlFor="payroll-payout-type">Тип</FieldLabel>
              <Select
                value={type}
                items={PAYOUT_TYPE_OPTIONS}
                onValueChange={(value) => {
                  if (typeof value === "string") {
                    setType(value);
                  }
                }}
              >
                <SelectTrigger id="payroll-payout-type" className="w-full">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent align="start">
                  <SelectGroup>
                    {PAYOUT_TYPE_OPTIONS.map((item) => (
                      <SelectItem key={item.value} value={item.value}>
                        {item.label}
                      </SelectItem>
                    ))}
                  </SelectGroup>
                </SelectContent>
              </Select>
            </Field>
          </div>

          <Field>
            <FieldLabel htmlFor="payroll-payout-comment">
              Комментарий
            </FieldLabel>
            <Input
              id="payroll-payout-comment"
              value={comment}
              placeholder="Необязательно"
              disabled={isSaving}
              onChange={(event) => setComment(event.target.value)}
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
