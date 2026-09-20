import { getActiveCompanyId } from "@/lib/supabase/company";
import { getRequiredClient } from "@/lib/supabase/client";
import type {
  SettlementPayment,
  SettlementPaymentDraft,
} from "@/features/settlements/types/settlement.types";
import type { SettlementPaymentsRow } from "@/types/database.types";
import { parseAmount } from "@/features/settlements/utils/settlement.utils";

/** Колонки оплаты, которые читает и возвращает веб. */
const PAYMENTS_SELECT =
  "id, company_id, settlement_operation_id, payment_date, amount, note, cash_flow_transaction_id, created_at, created_by";

/** Строка таблицы оплат → оплата для интерфейса. */
function mapPaymentRow(row: SettlementPaymentsRow): SettlementPayment {
  return {
    id: row.id,
    companyId: row.company_id,
    settlementOperationId: row.settlement_operation_id,
    paymentDate: row.payment_date,
    amount: Number(row.amount ?? 0),
    note: row.note,
    cashFlowTransactionId: row.cash_flow_transaction_id,
    createdAt: row.created_at,
    createdBy: row.created_by,
  };
}

/**
 * Понятный текст ошибки записи оплаты.
 *
 * Оплаты из банковской выписки менять нельзя: база отвечает ошибкой с
 * упоминанием выписки — подсказываем, что правка идёт в модуле ДДС.
 */
function paymentError(error: { code?: string; message: string }): Error {
  if (error.message.includes("банковской выписки")) {
    return new Error(
      "Оплата из банковской выписки. Измените или удалите транзакцию в модуле ДДС."
    );
  }
  return new Error(error.message);
}

/** Оплаты по счёту. */
export async function getSettlementPayments(
  settlementOperationId: string
): Promise<SettlementPayment[]> {
  const client = getRequiredClient();
  const companyId = await getActiveCompanyId();

  const { data, error } = await client
    .from("settlement_payments")
    .select(PAYMENTS_SELECT)
    .eq("company_id", companyId)
    .eq("settlement_operation_id", settlementOperationId)
    .order("payment_date", { ascending: false })
    .order("created_at", { ascending: false });

  if (error) {
    throw new Error(error.message);
  }

  return ((data ?? []) as unknown as SettlementPaymentsRow[]).map(mapPaymentRow);
}

/** Создаёт оплату по счёту. */
export async function createSettlementPayment(
  settlementOperationId: string,
  draft: SettlementPaymentDraft
): Promise<SettlementPayment> {
  const client = getRequiredClient();
  const companyId = await getActiveCompanyId();
  const amount = parseAmount(draft.amount) ?? 0;

  if (amount <= 0) {
    throw new Error("Укажите сумму оплаты");
  }

  // Автора записи проставляет база (auth.uid()) — отдельный запрос не нужен.
  const { data, error } = await client
    .from("settlement_payments")
    .insert({
      company_id: companyId,
      settlement_operation_id: settlementOperationId,
      payment_date: draft.paymentDate,
      amount,
      note: draft.note.trim() || null,
    })
    .select(PAYMENTS_SELECT)
    .maybeSingle();

  if (error) {
    throw paymentError(error);
  }
  if (!data) {
    throw new Error("Не удалось сохранить оплату");
  }

  return mapPaymentRow(data as unknown as SettlementPaymentsRow);
}

/** Обновляет оплату. */
export async function updateSettlementPayment(
  paymentId: string,
  draft: SettlementPaymentDraft
): Promise<SettlementPayment> {
  const client = getRequiredClient();
  const companyId = await getActiveCompanyId();
  const amount = parseAmount(draft.amount) ?? 0;

  if (amount <= 0) {
    throw new Error("Укажите сумму оплаты");
  }

  const { data, error } = await client
    .from("settlement_payments")
    .update({
      payment_date: draft.paymentDate,
      amount,
      note: draft.note.trim() || null,
      updated_at: new Date().toISOString(),
    })
    .eq("id", paymentId)
    .eq("company_id", companyId)
    .select(PAYMENTS_SELECT)
    .maybeSingle();

  if (error) {
    throw paymentError(error);
  }
  if (!data) {
    throw new Error("Оплата не найдена для обновления");
  }

  return mapPaymentRow(data as unknown as SettlementPaymentsRow);
}

/** Удаляет оплату. */
export async function deleteSettlementPayment(paymentId: string): Promise<void> {
  const client = getRequiredClient();
  const companyId = await getActiveCompanyId();

  const { error } = await client
    .from("settlement_payments")
    .delete()
    .eq("id", paymentId)
    .eq("company_id", companyId);

  if (error) {
    throw paymentError(error);
  }
}
