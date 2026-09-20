"use client";

import { useMemo, useRef, useState } from "react";
import { DownloadIcon, UploadIcon } from "lucide-react";
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
import { useEmployees } from "@/features/employees/hooks/use-employees";
import { employeeFullName } from "@/features/employees/utils/employee.utils";
import {
  usePayrollPayoutMutations,
  usePayrollTransactionMutations,
} from "@/features/payrolls/hooks/use-payroll-mutations";
import {
  matchEmployeeIds,
  normalizePersonName,
  type PayrollImportKind,
  type PayrollImportRow,
} from "@/features/payrolls/utils/payroll-import";
import {
  PAYOUT_METHOD_OPTIONS,
  PAYOUT_TYPE_OPTIONS,
  formatPayrollMoney,
} from "@/features/payrolls/utils/payroll.utils";
import { getAccessToken } from "@/lib/supabase/client";
import { getTodayDateString } from "@/features/timesheet/utils/timesheet-date";

type PayrollImportDialogProps = {
  kind: PayrollImportKind;
  objectOptions: { key: string; label: string }[];
  /** Объект по умолчанию для премий и удержаний. */
  defaultObjectId: string;
  onClose: () => void;
};

/** Состояние строки предпросмотра: выбранный сотрудник и объект. */
type ImportRowState = {
  employeeId: string | null;
  objectId: string | null;
};

const TITLES: Record<PayrollImportKind, string> = {
  payout: "Импорт выплат",
  bonus: "Импорт премий",
  penalty: "Импорт удержаний",
};

const SUBJECTS: Record<PayrollImportKind, string> = {
  payout: "выплат",
  bonus: "премий",
  penalty: "удержаний",
};

/**
 * Импорт операций из `.xlsx`: разбор на Node-роуте, предпросмотр и запись
 * из браузера. Ненайденные сотрудники пропускаются.
 */
export function PayrollImportDialog({
  kind,
  objectOptions,
  defaultObjectId,
  onClose,
}: PayrollImportDialogProps) {
  const isPayout = kind === "payout";
  const transactionKind = kind === "penalty" ? "penalty" : "bonus";

  const employeesQuery = useEmployees();
  const payoutMutations = usePayrollPayoutMutations();
  const transactionMutations = usePayrollTransactionMutations(transactionKind);
  const removeMany = isPayout
    ? payoutMutations.removeMany
    : transactionMutations.removeMany;
  const isSaving = isPayout
    ? payoutMutations.createMany.isPending
    : transactionMutations.createMany.isPending;

  const fileRef = useRef<HTMLInputElement>(null);
  const [rows, setRows] = useState<PayrollImportRow[] | null>(null);
  const [rowState, setRowState] = useState<Record<number, ImportRowState>>({});
  const [fileName, setFileName] = useState("");
  const [isParsing, setIsParsing] = useState(false);
  const [date, setDate] = useState(getTodayDateString);
  const [method, setMethod] = useState(
    PAYOUT_METHOD_OPTIONS[0]?.value ?? "card"
  );
  const [type, setType] = useState(PAYOUT_TYPE_OPTIONS[0]?.value ?? "salary");
  const [comment, setComment] = useState("");
  const [objectId, setObjectId] = useState(defaultObjectId);

  const employees = useMemo(
    () =>
      (employeesQuery.data ?? []).map((employee) => ({
        id: employee.id,
        fullName: employeeFullName(employee),
      })),
    [employeesQuery.data]
  );

  const employeesById = useMemo(
    () => new Map(employees.map((employee) => [employee.id, employee.fullName])),
    [employees]
  );

  const objectItems = objectOptions.map((option) => ({
    key: option.key,
    label: option.label,
  }));

  const objectsByName = useMemo(() => {
    const map = new Map<string, string>();
    for (const option of objectItems) {
      map.set(normalizePersonName(option.label), option.key);
    }
    return map;
  }, [objectItems]);

  /** Разбор файла на Node-роуте: только чтение, без записи в базу. */
  async function parseFile(file: File) {
    setIsParsing(true);
    try {
      const token = await getAccessToken();
      const form = new FormData();
      form.append("file", file);

      const response = await fetch("/api/payroll/import/parse", {
        method: "POST",
        headers: { Authorization: `Bearer ${token}` },
        body: form,
      });
      const payload = (await response.json()) as {
        rows?: PayrollImportRow[];
        error?: string;
      };
      if (!response.ok || !payload.rows) {
        throw new Error(payload.error ?? "Не удалось разобрать файл");
      }

      const parsedRows = payload.rows;
      const nextState: Record<number, ImportRowState> = {};
      for (const row of parsedRows) {
        const match = matchEmployeeIds(row.fullName, employees);
        nextState[row.rowNumber] = {
          employeeId:
            match.status === "matched" ? match.employeeIds[0] : null,
          objectId: null,
        };
      }

      setRows(parsedRows);
      setRowState(nextState);
      setFileName(file.name);
    } catch (error) {
      toast.error(
        error instanceof Error ? error.message : "Не удалось разобрать файл"
      );
    } finally {
      setIsParsing(false);
    }
  }

  /** Скачивает шаблон нужного вида с Node-роута. */
  async function downloadTemplate() {
    try {
      const token = await getAccessToken();
      const response = await fetch(
        `/api/payroll/import/template?kind=${kind}`,
        { headers: { Authorization: `Bearer ${token}` } }
      );
      if (!response.ok) {
        throw new Error("Не удалось получить шаблон");
      }
      const blob = await response.blob();
      const url = window.URL.createObjectURL(blob);
      const link = document.createElement("a");
      link.href = url;
      link.download = `Шаблон_${SUBJECTS[kind]}.xlsx`;
      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);
      window.URL.revokeObjectURL(url);
    } catch (error) {
      toast.error(
        error instanceof Error ? error.message : "Не удалось получить шаблон"
      );
    }
  }

  /** Объект строки: из файла по названию, иначе общий из окна. */
  function resolveObjectId(row: PayrollImportRow): string {
    if (row.objectName) {
      const byName = objectsByName.get(normalizePersonName(row.objectName));
      if (byName) {
        return byName;
      }
    }
    return objectId;
  }

  const readyRows = useMemo(() => {
    if (!rows) {
      return [];
    }
    return rows.filter((row) => {
      const state = rowState[row.rowNumber];
      return Boolean(state?.employeeId) && row.amount > 0;
    });
  }, [rows, rowState]);

  const totalAmount = readyRows.reduce((sum, row) => sum + row.amount, 0);
  const skippedCount = (rows?.length ?? 0) - readyRows.length;

  async function handleSave() {
    if (readyRows.length === 0) {
      toast.error("Нет строк для сохранения");
      return;
    }
    if (!isPayout && !objectId) {
      toast.error("Выберите объект");
      return;
    }

    try {
      let ids: string[];
      if (isPayout) {
        ids = await payoutMutations.createMany.mutateAsync(
          readyRows.map((row) => ({
            employeeId: rowState[row.rowNumber].employeeId as string,
            date: row.date ?? date,
            amount: row.amount,
            method,
            type,
            comment: row.note || comment.trim() || null,
          }))
        );
      } else {
        ids = await transactionMutations.createMany.mutateAsync(
          readyRows.map((row) => ({
            employeeId: rowState[row.rowNumber].employeeId as string,
            objectId: rowState[row.rowNumber].objectId ?? resolveObjectId(row),
            date: row.date ?? date,
            amount: row.amount,
            reason: row.note || null,
          }))
        );
      }

      toast.success(`Сохранено записей: ${ids.length}`, {
        action: {
          label: "Отменить",
          onClick: () => {
            void removeMany.mutateAsync(ids).catch((error) => {
              toast.error(
                error instanceof Error ? error.message : "Не удалось отменить"
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

  return (
    <Dialog
      open
      onOpenChange={(next) => {
        if (!next) {
          onClose();
        }
      }}
    >
      <DialogContent className="flex max-h-[min(92vh,52rem)] flex-col sm:max-w-4xl">
        <DialogHeader>
          <DialogTitle>{TITLES[kind]}</DialogTitle>
          <DialogDescription>
            Колонки файла: ФИО, Сумма
            {isPayout ? ", Дата, Комментарий" : ", Дата, Объект, Примечание"}.
            Ненайденные сотрудники пропускаются.
          </DialogDescription>
        </DialogHeader>

        <div className="flex flex-wrap items-center gap-2">
          <input
            ref={fileRef}
            type="file"
            accept=".xlsx"
            className="sr-only"
            onChange={(event) => {
              const file = event.target.files?.[0];
              event.target.value = "";
              if (file) {
                void parseFile(file);
              }
            }}
          />
          <Button
            type="button"
            variant="outline"
            disabled={isParsing}
            onClick={() => fileRef.current?.click()}
          >
            {isParsing ? (
              <Spinner data-icon="inline-start" />
            ) : (
              <UploadIcon data-icon="inline-start" />
            )}
            Выбрать файл
          </Button>
          <Button type="button" variant="ghost" onClick={() => void downloadTemplate()}>
            <DownloadIcon data-icon="inline-start" />
            Шаблон
          </Button>
          {fileName ? (
            <span className="text-xs text-muted-foreground">{fileName}</span>
          ) : null}
        </div>

        <div className="grid gap-3 sm:grid-cols-3">
          <Field>
            <FieldLabel htmlFor="import-date">Дата (если нет в файле)</FieldLabel>
            <Input
              id="import-date"
              type="date"
              value={date}
              disabled={isSaving}
              onChange={(event) => setDate(event.target.value)}
            />
          </Field>

          {isPayout ? (
            <>
              <Field>
                <FieldLabel htmlFor="import-method">Способ</FieldLabel>
                <Select
                  value={method}
                  items={PAYOUT_METHOD_OPTIONS}
                  onValueChange={(value) => {
                    if (typeof value === "string") {
                      setMethod(value);
                    }
                  }}
                >
                  <SelectTrigger id="import-method" className="w-full">
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
                <FieldLabel htmlFor="import-type">Тип</FieldLabel>
                <Select
                  value={type}
                  items={PAYOUT_TYPE_OPTIONS}
                  onValueChange={(value) => {
                    if (typeof value === "string") {
                      setType(value);
                    }
                  }}
                >
                  <SelectTrigger id="import-type" className="w-full">
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
              <Field className="sm:col-span-3">
                <FieldLabel htmlFor="import-comment">
                  Комментарий (если нет в файле)
                </FieldLabel>
                <Input
                  id="import-comment"
                  value={comment}
                  placeholder="Необязательно"
                  disabled={isSaving}
                  onChange={(event) => setComment(event.target.value)}
                />
              </Field>
            </>
          ) : (
            <Field className="sm:col-span-2">
              <FieldLabel htmlFor="import-object">
                Объект (если нет в файле)
              </FieldLabel>
              <Select
                value={objectId || undefined}
                items={objectItems.map((item) => ({
                  value: item.key,
                  label: item.label,
                }))}
                onValueChange={(value) => {
                  if (typeof value === "string") {
                    setObjectId(value);
                  }
                }}
              >
                <SelectTrigger id="import-object" className="w-full">
                  <SelectValue placeholder="Выберите объект" />
                </SelectTrigger>
                <SelectContent align="start">
                  <SelectGroup>
                    {objectItems.map((item) => (
                      <SelectItem key={item.key} value={item.key}>
                        {item.label}
                      </SelectItem>
                    ))}
                  </SelectGroup>
                </SelectContent>
              </Select>
            </Field>
          )}
        </div>

        <div className="min-h-0 flex-1 overflow-y-auto overscroll-contain rounded-lg border border-border/70">
          {!rows ? (
            <p className="px-3 py-10 text-center text-sm text-muted-foreground">
              Выберите файл .xlsx — строки появятся здесь для проверки.
            </p>
          ) : rows.length === 0 ? (
            <p className="px-3 py-10 text-center text-sm text-muted-foreground">
              В файле нет строк с данными.
            </p>
          ) : (
            <table className="w-full border-separate border-spacing-0 text-sm">
              <thead className="sticky top-0 bg-muted">
                <tr>
                  <th className="px-3 py-2 text-left text-xs font-semibold">
                    ФИО из файла
                  </th>
                  <th className="px-3 py-2 text-left text-xs font-semibold">
                    Сотрудник
                  </th>
                  <th className="px-3 py-2 text-right text-xs font-semibold">
                    Сумма
                  </th>
                  {!isPayout ? (
                    <th className="px-3 py-2 text-left text-xs font-semibold">
                      Объект
                    </th>
                  ) : null}
                  <th className="px-3 py-2 text-left text-xs font-semibold">
                    Дата
                  </th>
                  <th className="px-3 py-2 text-left text-xs font-semibold">
                    {isPayout ? "Комментарий" : "Примечание"}
                  </th>
                </tr>
              </thead>
              <tbody>
                {rows.map((row) => {
                  const state = rowState[row.rowNumber];
                  const employeeId = state?.employeeId ?? null;
                  const isReady = Boolean(employeeId) && row.amount > 0;

                  return (
                    <tr
                      key={row.rowNumber}
                      className={isReady ? undefined : "opacity-60"}
                    >
                      <td className="px-3 py-1.5">{row.fullName || "—"}</td>
                      <td className="px-3 py-1.5">
                        <Select
                          value={employeeId ?? undefined}
                          items={employees.map((employee) => ({
                            value: employee.id,
                            label: employee.fullName,
                          }))}
                          onValueChange={(value) => {
                            if (typeof value === "string") {
                              setRowState((current) => ({
                                ...current,
                                [row.rowNumber]: {
                                  ...current[row.rowNumber],
                                  employeeId: value,
                                },
                              }));
                            }
                          }}
                        >
                          <SelectTrigger
                            size="sm"
                            className="h-8 w-56"
                            aria-label={`Сотрудник для строки ${row.rowNumber}`}
                          >
                            <SelectValue placeholder="Не найден — пропуск" />
                          </SelectTrigger>
                          <SelectContent align="start">
                            <SelectGroup>
                              {employees.map((employee) => (
                                <SelectItem
                                  key={employee.id}
                                  value={employee.id}
                                >
                                  {employee.fullName}
                                </SelectItem>
                              ))}
                            </SelectGroup>
                          </SelectContent>
                        </Select>
                      </td>
                      <td className="px-3 py-1.5 text-right tabular-nums">
                        {formatPayrollMoney(row.amount)}
                      </td>
                      {!isPayout ? (
                        <td className="px-3 py-1.5">
                          {row.objectName || (
                            <span className="text-muted-foreground">общий</span>
                          )}
                        </td>
                      ) : null}
                      <td className="px-3 py-1.5 text-muted-foreground">
                        {row.date ?? date}
                      </td>
                      <td className="px-3 py-1.5 text-muted-foreground">
                        {row.note || "—"}
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          )}
        </div>

        <DialogFooter>
          <p className="mr-auto text-xs text-muted-foreground">
            {rows
              ? `К сохранению: ${readyRows.length} · пропущено: ${skippedCount} · сумма ${formatPayrollMoney(totalAmount)}`
              : `Проверьте ФИО: ${employeesById.size} сотрудников в справочнике`}
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
            disabled={isSaving || readyRows.length === 0}
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
