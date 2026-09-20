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
import {
  usePayrollPayoutMutations,
  usePayrollTransactionMutations,
} from "@/features/payrolls/hooks/use-payroll-mutations";
import {
  PAYOUT_METHOD_OPTIONS,
  PAYOUT_TYPE_OPTIONS,
  formatPayrollMoney,
  parsePayrollAmount,
} from "@/features/payrolls/utils/payroll.utils";
import { getTodayDateString } from "@/features/timesheet/utils/timesheet-date";

/** Виды массовых операций. */
export type PayrollBulkKind = "payout" | "bonus" | "penalty";

/** Сотрудник в массовой операции: ФИО и текущий долг (для подсказки). */
export type PayrollBulkEmployee = {
  id: string;
  fullName: string;
  debt: number;
};

type PayrollBulkDialogProps = {
  kind: PayrollBulkKind;
  employees: PayrollBulkEmployee[];
  objectOptions: { key: string; label: string }[];
  /** Объект по умолчанию для премий и удержаний. */
  defaultObjectId: string;
  onClose: () => void;
};

const TITLES: Record<PayrollBulkKind, string> = {
  payout: "Выплаты нескольким сотрудникам",
  bonus: "Премии нескольким сотрудникам",
  penalty: "Удержания нескольким сотрудникам",
};

/**
 * Массовая операция: общие поля плюс сумма по каждому сотруднику.
 * Строки с нулевой суммой пропускаются.
 */
export function PayrollBulkDialog({
  kind,
  employees,
  objectOptions,
  defaultObjectId,
  onClose,
}: PayrollBulkDialogProps) {
  const isPayout = kind === "payout";
  const transactionKind = kind === "penalty" ? "penalty" : "bonus";

  const payoutMutations = usePayrollPayoutMutations();
  const transactionMutations = usePayrollTransactionMutations(transactionKind);
  const removeMany = isPayout
    ? payoutMutations.removeMany
    : transactionMutations.removeMany;

  const [date, setDate] = useState(getTodayDateString);
  const [method, setMethod] = useState(
    PAYOUT_METHOD_OPTIONS[0]?.value ?? "card"
  );
  const [type, setType] = useState(PAYOUT_TYPE_OPTIONS[0]?.value ?? "salary");
  const [comment, setComment] = useState("");
  const [objectId, setObjectId] = useState(defaultObjectId);
  const [reason, setReason] = useState("");
  const [fillValue, setFillValue] = useState("");
  const [amounts, setAmounts] = useState<Record<string, string>>(() =>
    Object.fromEntries(
      employees.map((employee) => [
        employee.id,
        isPayout && employee.debt > 0 ? String(employee.debt) : "",
      ])
    )
  );

  const objectItems = objectOptions.map((option) => ({
    value: option.key,
    label: option.label,
  }));

  const isSaving = isPayout
    ? payoutMutations.createMany.isPending
    : transactionMutations.createMany.isPending;

  function setAmount(employeeId: string, value: string) {
    setAmounts((current) => ({ ...current, [employeeId]: value }));
  }

  function fillAll() {
    const parsed = parsePayrollAmount(fillValue);
    if (parsed == null || parsed <= 0) {
      toast.error("Укажите сумму для заполнения");
      return;
    }
    setAmounts(
      Object.fromEntries(employees.map((employee) => [employee.id, fillValue]))
    );
  }

  async function handleSave() {
    if (!date) {
      toast.error("Укажите дату");
      return;
    }
    if (!isPayout && !objectId) {
      toast.error("Выберите объект");
      return;
    }

    const parsedRows = employees
      .map((employee) => ({
        employeeId: employee.id,
        amount: parsePayrollAmount(amounts[employee.id] ?? ""),
      }))
      .filter(
        (row): row is { employeeId: string; amount: number } =>
          row.amount != null && row.amount > 0
      );

    if (parsedRows.length === 0) {
      toast.error("Укажите сумму хотя бы одному сотруднику");
      return;
    }

    try {
      const ids = isPayout
        ? await payoutMutations.createMany.mutateAsync(
            parsedRows.map((row) => ({
              employeeId: row.employeeId,
              date,
              amount: row.amount,
              method,
              type,
              comment: comment.trim() || null,
            }))
          )
        : await transactionMutations.createMany.mutateAsync(
            parsedRows.map((row) => ({
              employeeId: row.employeeId,
              objectId,
              date,
              amount: row.amount,
              reason: reason.trim() || null,
            }))
          );

      toast.success(`Добавлено записей: ${ids.length}`, {
        action: {
          label: "Отменить",
          onClick: () => {
            void removeMany.mutateAsync(ids).catch((error) => {
              toast.error(
                error instanceof Error
                  ? error.message
                  : "Не удалось отменить"
              );
            });
          },
        },
      });
      onClose();
    } catch (error) {
      toast.error(
        error instanceof Error ? error.message : "Не удалось сохранить"
      );
    }
  }

  const filledCount = employees.filter((employee) => {
    const parsed = parsePayrollAmount(amounts[employee.id] ?? "");
    return parsed != null && parsed > 0;
  }).length;

  return (
    <Dialog
      open
      onOpenChange={(next) => {
        if (!next) {
          onClose();
        }
      }}
    >
      <DialogContent className="flex max-h-[min(92vh,48rem)] flex-col sm:max-w-2xl">
        <DialogHeader>
          <DialogTitle>{TITLES[kind]}</DialogTitle>
          <DialogDescription>
            Выбрано сотрудников: {employees.length}
          </DialogDescription>
        </DialogHeader>

        <div className="grid gap-3 sm:grid-cols-2">
          <Field>
            <FieldLabel htmlFor="bulk-date">Дата</FieldLabel>
            <Input
              id="bulk-date"
              type="date"
              value={date}
              disabled={isSaving}
              onChange={(event) => setDate(event.target.value)}
            />
          </Field>

          {isPayout ? (
            <>
              <div className="grid grid-cols-2 gap-3">
                <Field>
                  <FieldLabel htmlFor="bulk-method">Способ</FieldLabel>
                  <Select
                    value={method}
                    items={PAYOUT_METHOD_OPTIONS}
                    onValueChange={(value) => {
                      if (typeof value === "string") {
                        setMethod(value);
                      }
                    }}
                  >
                    <SelectTrigger id="bulk-method" className="w-full">
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
                  <FieldLabel htmlFor="bulk-type">Тип</FieldLabel>
                  <Select
                    value={type}
                    items={PAYOUT_TYPE_OPTIONS}
                    onValueChange={(value) => {
                      if (typeof value === "string") {
                        setType(value);
                      }
                    }}
                  >
                    <SelectTrigger id="bulk-type" className="w-full">
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
              <Field className="sm:col-span-2">
                <FieldLabel htmlFor="bulk-comment">Комментарий</FieldLabel>
                <Input
                  id="bulk-comment"
                  value={comment}
                  placeholder="Необязательно"
                  disabled={isSaving}
                  onChange={(event) => setComment(event.target.value)}
                />
              </Field>
            </>
          ) : (
            <>
              <Field>
                <FieldLabel htmlFor="bulk-object">Объект</FieldLabel>
                <Select
                  value={objectId || undefined}
                  items={objectItems}
                  onValueChange={(value) => {
                    if (typeof value === "string") {
                      setObjectId(value);
                    }
                  }}
                >
                  <SelectTrigger id="bulk-object" className="w-full">
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
              <Field className="sm:col-span-2">
                <FieldLabel htmlFor="bulk-reason">
                  {kind === "penalty" ? "Комментарий" : "Примечание"}
                </FieldLabel>
                <Input
                  id="bulk-reason"
                  value={reason}
                  placeholder="Необязательно"
                  disabled={isSaving}
                  onChange={(event) => setReason(event.target.value)}
                />
              </Field>
            </>
          )}
        </div>

        <div className="flex items-end gap-2">
          <Field className="w-40">
            <FieldLabel htmlFor="bulk-fill">Сумма всем</FieldLabel>
            <Input
              id="bulk-fill"
              inputMode="decimal"
              placeholder="0,00"
              value={fillValue}
              disabled={isSaving}
              onChange={(event) => setFillValue(event.target.value)}
            />
          </Field>
          <Button
            type="button"
            variant="outline"
            disabled={isSaving}
            onClick={fillAll}
          >
            Заполнить всем
          </Button>
        </div>

        <div className="min-h-0 flex-1 overflow-y-auto overscroll-contain rounded-lg border border-border/70">
          <ul className="divide-y divide-border/50">
            {employees.map((employee) => {
              const parsed = parsePayrollAmount(amounts[employee.id] ?? "");
              const overpayment =
                isPayout && parsed != null && parsed > employee.debt + 0.005
                  ? parsed - employee.debt
                  : 0;

              return (
                <li
                  key={employee.id}
                  className="flex items-center gap-3 px-3 py-2"
                >
                  <span className="min-w-0 flex-1 truncate text-sm">
                    {employee.fullName}
                  </span>
                  {overpayment > 0 ? (
                    <span className="shrink-0 text-xs text-warning">
                      переплата {formatPayrollMoney(overpayment)}
                    </span>
                  ) : null}
                  <Input
                    inputMode="decimal"
                    placeholder="0,00"
                    aria-label={`Сумма: ${employee.fullName}`}
                    className="h-8 w-32 text-right"
                    value={amounts[employee.id] ?? ""}
                    disabled={isSaving}
                    onChange={(event) =>
                      setAmount(employee.id, event.target.value)
                    }
                  />
                </li>
              );
            })}
          </ul>
        </div>

        <DialogFooter>
          <p className="mr-auto text-xs text-muted-foreground">
            Заполнено строк: {filledCount} из {employees.length}
          </p>
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
