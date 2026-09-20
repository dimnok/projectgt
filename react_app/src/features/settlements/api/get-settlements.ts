import { getActiveCompanyId } from "@/lib/supabase/company";
import { getRequiredClient } from "@/lib/supabase/client";
import {
  SETTLEMENT_SELECT,
  mapSettlementRow,
} from "@/features/settlements/utils/settlement.utils";
import type { Settlement } from "@/features/settlements/types/settlement.types";
import type { SettlementOperationJoinRow } from "@/types/database.types";

/**
 * Счета активной компании. При `contractId` — только по договору.
 */
export async function getSettlements(contractId?: string): Promise<Settlement[]> {
  const client = getRequiredClient();
  const companyId = await getActiveCompanyId();

  let query = client
    .from("settlement_operations")
    .select(SETTLEMENT_SELECT)
    .eq("company_id", companyId);

  if (contractId) {
    query = query.eq("contract_id", contractId);
  }

  const { data, error } = await query.order("invoice_date", {
    ascending: false,
  });

  if (error) {
    throw new Error(error.message);
  }

  return ((data ?? []) as unknown as SettlementOperationJoinRow[]).map(
    mapSettlementRow
  );
}
