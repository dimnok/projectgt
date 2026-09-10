import { getActiveCompanyId } from "@/lib/supabase/company";
import { getRequiredClient } from "@/lib/supabase/client";
import {
  CONTRACTOR_SELECT,
  contractorWriteError,
  mapContractorRow,
  toContractorPayload,
} from "@/features/contractors/utils/contractor.utils";
import type {
  Contractor,
  ContractorDraft,
} from "@/features/contractors/types/contractor.types";
import type { ContractorsRow } from "@/types/database.types";

/**
 * Updates a contractor in the active company.
 */
export async function updateContractor(
  contractor: Contractor,
  draft: ContractorDraft
): Promise<Contractor> {
  const client = getRequiredClient();
  const companyId = await getActiveCompanyId();

  const { data, error } = await client
    .from("contractors")
    .update(toContractorPayload(draft))
    .eq("id", contractor.id)
    .eq("company_id", companyId)
    .select(CONTRACTOR_SELECT)
    .maybeSingle();

  if (error) {
    throw contractorWriteError(error);
  }

  if (!data) {
    throw new Error("Контрагент не найден для обновления");
  }

  return mapContractorRow(data as ContractorsRow);
}
