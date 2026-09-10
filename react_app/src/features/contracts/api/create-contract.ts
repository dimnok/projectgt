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
import { createId } from "@/lib/utils";

/**
 * Creates a contract in the active company.
 */
export async function createContract(draft: ContractDraft): Promise<Contract> {
  const client = getRequiredClient();
  const companyId = await getActiveCompanyId();

  const { data, error } = await client
    .from("contracts")
    .insert({
      id: createId(),
      company_id: companyId,
      ...draftToPayload(draft),
    })
    .select(CONTRACT_SELECT)
    .maybeSingle();

  if (error) {
    throw contractWriteError(error);
  }

  if (!data) {
    throw new Error("Ошибка создания договора");
  }

  return mapContractRow(data as unknown as ContractJoinRow);
}
