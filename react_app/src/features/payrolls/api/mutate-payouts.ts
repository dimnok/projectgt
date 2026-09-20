import { getActiveCompanyId } from "@/lib/supabase/company";
import { getRequiredClient } from "@/lib/supabase/client";
import { createId } from "@/lib/utils";

/** Данные выплаты из формы. */
export type PayrollPayoutDraft = {
  employeeId: string;
  /** Дата выплаты в формате `YYYY-MM-DD`. */
  date: string;
  amount: number;
  method: string;
  type: string;
  comment: string | null;
};

/** Переводит поля формы в колонки таблицы, пропуская незаданные. */
function toPayoutColumns(
  patch: Partial<PayrollPayoutDraft>
): Record<string, unknown> {
  const columns: Record<string, unknown> = {};
  if (patch.employeeId !== undefined) {
    columns.employee_id = patch.employeeId;
  }
  if (patch.date !== undefined) {
    columns.payout_date = patch.date;
  }
  if (patch.amount !== undefined) {
    columns.amount = patch.amount;
  }
  if (patch.method !== undefined) {
    columns.method = patch.method;
  }
  if (patch.type !== undefined) {
    columns.type = patch.type;
  }
  if (patch.comment !== undefined) {
    columns.comment = patch.comment;
  }
  return columns;
}

/**
 * Создаёт выплату. `id` можно передать явно — так возвращают запись
 * при отмене удаления, чтобы сохранить тот же идентификатор.
 */
export async function createPayrollPayout(
  draft: PayrollPayoutDraft,
  id: string = createId()
): Promise<string> {
  const client = getRequiredClient();
  const companyId = await getActiveCompanyId();

  const { error } = await client.from("payroll_payout").insert({
    id,
    company_id: companyId,
    employee_id: draft.employeeId,
    amount: draft.amount,
    payout_date: draft.date,
    method: draft.method,
    type: draft.type,
    comment: draft.comment,
    created_at: new Date().toISOString(),
  });

  if (error) {
    throw new Error(error.message);
  }
  return id;
}

/**
 * Создаёт несколько выплат одной вставкой: либо все строки, либо ни одной.
 * Возвращает id созданных записей — для отмены.
 */
export async function createPayrollPayoutsBatch(
  drafts: PayrollPayoutDraft[]
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
    amount: draft.amount,
    payout_date: draft.date,
    method: draft.method,
    type: draft.type,
    comment: draft.comment,
    created_at: now,
  }));

  const { error } = await client.from("payroll_payout").insert(rows);
  if (error) {
    throw new Error(error.message);
  }
  return rows.map((row) => row.id);
}

/** Удаляет несколько выплат — отмена массовой вставки. */
export async function deletePayrollPayouts(ids: string[]): Promise<void> {
  if (ids.length === 0) {
    return;
  }

  const client = getRequiredClient();
  const companyId = await getActiveCompanyId();

  const { error } = await client
    .from("payroll_payout")
    .delete()
    .in("id", ids)
    .eq("company_id", companyId);

  if (error) {
    throw new Error(error.message);
  }
}

export async function updatePayrollPayout(
  id: string,
  patch: Partial<PayrollPayoutDraft>
): Promise<void> {
  const client = getRequiredClient();
  const companyId = await getActiveCompanyId();

  const { error } = await client
    .from("payroll_payout")
    .update(toPayoutColumns(patch))
    .eq("id", id)
    .eq("company_id", companyId);

  if (error) {
    throw new Error(error.message);
  }
}

export async function deletePayrollPayout(id: string): Promise<void> {
  const client = getRequiredClient();
  const companyId = await getActiveCompanyId();

  const { error } = await client
    .from("payroll_payout")
    .delete()
    .eq("id", id)
    .eq("company_id", companyId);

  if (error) {
    throw new Error(error.message);
  }
}
