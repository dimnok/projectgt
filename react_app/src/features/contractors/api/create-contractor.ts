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
import { createId } from "@/lib/utils";

/**
 * Creates a contractor in the active company.
 */
export async function createContractor(
  draft: ContractorDraft
): Promise<Contractor> {
  const client = getRequiredClient();
  const companyId = await getActiveCompanyId();

  const { data, error } = await client
    .from("contractors")
    .insert({
      id: createId(),
      company_id: companyId,
      ...toContractorPayload(draft),
    })
    .select(CONTRACTOR_SELECT)
    .maybeSingle();

  if (error) {
    throw contractorWriteError(error);
  }

  if (!data) {
    throw new Error("Ошибка создания контрагента");
  }

  return mapContractorRow(data as ContractorsRow);
}
