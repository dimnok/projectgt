import { getActiveCompanyId } from "@/lib/supabase/company";
import { getRequiredClient } from "@/lib/supabase/client";
import {
  SETTLEMENT_SELECT,
  mapSettlementRow,
  settlementDraftToPayload,
  settlementWriteError,
} from "@/features/settlements/utils/settlement.utils";
import type {
  Settlement,
  SettlementDraft,
} from "@/features/settlements/types/settlement.types";
import type { SettlementOperationJoinRow } from "@/types/database.types";

/**
 * Обновляет счёт в активной компании.
 *
 * Уникальность номера по договору проверяет база (уникальный индекс): отдельная
 * проверка перед записью не нужна и не защищала от одновременных сохранений.
 */
export async function updateSettlement(
  settlement: Settlement,
  draft: SettlementDraft
): Promise<Settlement> {
  const client = getRequiredClient();
  const companyId = await getActiveCompanyId();

  const { data, error } = await client
    .from("settlement_operations")
    .update({
      ...settlementDraftToPayload(draft, settlement),
      updated_at: new Date().toISOString(),
    })
    .eq("id", settlement.id)
    .eq("company_id", companyId)
    .select(SETTLEMENT_SELECT)
    .maybeSingle();

  if (error) {
    throw settlementWriteError(error, draft.invoiceNumber);
  }
  if (!data) {
    throw new Error("Счёт не найден для обновления");
  }

  return mapSettlementRow(data as unknown as SettlementOperationJoinRow);
}
