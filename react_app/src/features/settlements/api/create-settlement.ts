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
import { createId } from "@/lib/utils";

/**
 * Создаёт счёт в активной компании.
 *
 * Уникальность номера по договору проверяет база (уникальный индекс), поэтому
 * отдельного запроса перед вставкой нет — гонка двух одновременных сохранений
 * теперь невозможна.
 */
export async function createSettlement(
  draft: SettlementDraft
): Promise<Settlement> {
  const client = getRequiredClient();
  const companyId = await getActiveCompanyId();

  const { data, error } = await client
    .from("settlement_operations")
    .insert({
      id: createId(),
      company_id: companyId,
      ...settlementDraftToPayload(draft),
    })
    .select(SETTLEMENT_SELECT)
    .maybeSingle();

  if (error) {
    throw settlementWriteError(error, draft.invoiceNumber);
  }
  if (!data) {
    throw new Error("Ошибка создания счёта");
  }

  return mapSettlementRow(data as unknown as SettlementOperationJoinRow);
}
