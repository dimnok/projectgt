import { getActiveCompanyId } from "@/lib/supabase/company";
import { getRequiredClient } from "@/lib/supabase/client";
import {
  SETTLEMENT_SELECT,
  mapSettlementRow,
} from "@/features/settlements/utils/settlement.utils";
import type { Settlement } from "@/features/settlements/types/settlement.types";
import type { SettlementOperationJoinRow } from "@/types/database.types";

/** Один счёт по идентификатору (или null, если не найден). */
export async function getSettlement(id: string): Promise<Settlement | null> {
  const client = getRequiredClient();
  const companyId = await getActiveCompanyId();

  const { data, error } = await client
    .from("settlement_operations")
    .select(SETTLEMENT_SELECT)
    .eq("company_id", companyId)
    .eq("id", id)
    .maybeSingle();

  if (error) {
    throw new Error(error.message);
  }
  if (!data) {
    return null;
  }

  return mapSettlementRow(data as unknown as SettlementOperationJoinRow);
}
