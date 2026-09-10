import { getActiveCompanyId } from "@/lib/supabase/company";
import { getRequiredClient } from "@/lib/supabase/client";
import {
  CONTRACTOR_SELECT,
  mapContractorRow,
} from "@/features/contractors/utils/contractor.utils";
import type { Contractor } from "@/features/contractors/types/contractor.types";
import type { ContractorsRow } from "@/types/database.types";

/**
 * Loads contractors for the active company from Supabase.
 */
export async function getContractors(): Promise<Contractor[]> {
  const client = getRequiredClient();
  const companyId = await getActiveCompanyId();

  const { data, error } = await client
    .from("contractors")
    .select(CONTRACTOR_SELECT)
    .eq("company_id", companyId)
    .order("short_name");

  if (error) {
    throw new Error(error.message);
  }

  return ((data ?? []) as ContractorsRow[]).map(mapContractorRow);
}
