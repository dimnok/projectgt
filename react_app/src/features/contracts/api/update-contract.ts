import { getActiveCompanyId } from "@/lib/supabase/company";
import { getRequiredClient } from "@/lib/supabase/client";
import {
  CONTRACT_SELECT,
  contractWriteError,
  draftToPayload,
  mapContractRow,
} from "@/features/contracts/utils/contract.utils";
import type {
  Contract,
  ContractDraft,
} from "@/features/contracts/types/contract.types";
import type { ContractJoinRow } from "@/types/database.types";

/**
 * Updates a contract in the active company.
 */
export async function updateContract(
  contract: Contract,
  draft: ContractDraft
): Promise<Contract> {
  const client = getRequiredClient();
  const companyId = await getActiveCompanyId();

  const { data, error } = await client
    .from("contracts")
    .update({
      ...draftToPayload(draft),
      updated_at: new Date().toISOString(),
    })
    .eq("id", contract.id)
    .eq("company_id", companyId)
    .select(CONTRACT_SELECT)
    .maybeSingle();

  if (error) {
    throw contractWriteError(error);
  }

  if (!data) {
    throw new Error("Договор не найден для обновления");
  }

  return mapContractRow(data as unknown as ContractJoinRow);
}
