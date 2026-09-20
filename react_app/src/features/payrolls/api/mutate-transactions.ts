import { getActiveCompanyId } from "@/lib/supabase/company";
import { getRequiredClient } from "@/lib/supabase/client";
import { createId } from "@/lib/utils";
import type { PayrollTransactionKind } from "@/features/payrolls/types/payroll.types";

/** Данные премии или удержания из формы. */
export type PayrollTransactionDraft = {
  employeeId: string;
  objectId: string;
  /** Дата в формате `YYYY-MM-DD`. */
  date: string;
  amount: number;
  reason: string | null;
};

function tableFor(kind: PayrollTransactionKind): string {
  return kind === "bonus" ? "payroll_bonus" : "payroll_penalty";
}

/** Переводит поля формы в колонки таблицы, пропуская незаданные. */
function toTransactionColumns(
  patch: Partial<PayrollTransactionDraft>
): Record<string, unknown> {
  const columns: Record<string, unknown> = {};
  if (patch.employeeId !== undefined) {
    columns.employee_id = patch.employeeId;
  }
  if (patch.objectId !== undefined) {
    columns.object_id = patch.objectId || null;
  }
  if (patch.date !== undefined) {
    columns.date = patch.date;
  }
  if (patch.amount !== undefined) {
    columns.amount = patch.amount;
  }
  if (patch.reason !== undefined) {
    columns.reason = patch.reason;
  }
  return columns;
}

/**
 * Создаёт премию или удержание. `id` можно передать явно — так возвращают
 * запись при отмене удаления, чтобы сохранить тот же идентификатор.
 */
export async function createPayrollTransaction(
  kind: PayrollTransactionKind,
  draft: PayrollTransactionDraft,
  id: string = createId()
): Promise<string> {
  const client = getRequiredClient();
  const companyId = await getActiveCompanyId();

  const { error } = await client.from(tableFor(kind)).insert({
    id,
    company_id: companyId,
    employee_id: draft.employeeId,
    object_id: draft.objectId || null,
    date: draft.date,
    amount: draft.amount,
    reason: draft.reason,
    type: "manual",
    created_at: new Date().toISOString(),
  });

  if (error) {
    throw new Error(error.message);
  }
  return id;
}

/**
 * Создаёт несколько премий или удержаний одной вставкой: либо все строки,
 * либо ни одной. Возвращает id созданных записей — для отмены.
 */
export async function createPayrollTransactionsBatch(
  kind: PayrollTransactionKind,
  drafts: PayrollTransactionDraft[]
): Promise<string[]> {
  if (drafts.length === 0) {
    return [];
  }

  const client = getRequiredClient();
  const companyId = await getActiveCompanyId();
  const now = new Date().toISOString();

  const rows = drafts.map((draft) => ({
    id: createId(),
    company_id: companyId,
    employee_id: draft.employeeId,
    object_id: draft.objectId || null,
    date: draft.date,
    amount: draft.amount,
    reason: draft.reason,
    type: "manual",
    created_at: now,
  }));

  const { error } = await client.from(tableFor(kind)).insert(rows);
  if (error) {
    throw new Error(error.message);
  }
  return rows.map((row) => row.id);
}

/** Удаляет несколько премий или удержаний — отмена массовой вставки. */
export async function deletePayrollTransactions(
  kind: PayrollTransactionKind,
  ids: string[]
): Promise<void> {
  if (ids.length === 0) {
    return;
  }

  const client = getRequiredClient();
  const companyId = await getActiveCompanyId();

  const { error } = await client
    .from(tableFor(kind))
    .delete()
    .in("id", ids)
    .eq("company_id", companyId);

  if (error) {
    throw new Error(error.message);
  }
}

export async function updatePayrollTransaction(
  kind: PayrollTransactionKind,
  id: string,
  patch: Partial<PayrollTransactionDraft>
): Promise<void> {
  const client = getRequiredClient();
  const companyId = await getActiveCompanyId();

  const { error } = await client
    .from(tableFor(kind))
    .update(toTransactionColumns(patch))
    .eq("id", id)
    .eq("company_id", companyId);

  if (error) {
    throw new Error(error.message);
  }
}

export async function deletePayrollTransaction(
  kind: PayrollTransactionKind,
  id: string
): Promise<void> {
  const client = getRequiredClient();
  const companyId = await getActiveCompanyId();

  const { error } = await client
    .from(tableFor(kind))
    .delete()
    .eq("id", id)
    .eq("company_id", companyId);

  if (error) {
    throw new Error(error.message);
  }
}
