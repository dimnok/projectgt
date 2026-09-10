import { getActiveCompanyId } from "@/lib/supabase/company";
import { getRequiredClient } from "@/lib/supabase/client";
import {
  CONTRACT_SELECT,
  mapContractRow,
} from "@/features/contracts/utils/contract.utils";
import type { Contract } from "@/features/contracts/types/contract.types";
import type { ContractJoinRow } from "@/types/database.types";

/**
 * Loads contracts for the active company, with contractor and object names.
 */
export async function getContracts(): Promise<Contract[]> {
  const client = getRequiredClient();
  const companyId = await getActiveCompanyId();

  const { data, error } = await client
    .from("contracts")
    .select(CONTRACT_SELECT)
    .eq("company_id", companyId)
    .order("date", { ascending: false });

  if (error) {
    throw new Error(error.message);
  }

  return ((data ?? []) as unknown as ContractJoinRow[]).map(mapContractRow);
}
