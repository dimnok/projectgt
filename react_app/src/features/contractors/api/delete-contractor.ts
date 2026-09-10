import { getActiveCompanyId } from "@/lib/supabase/company";
import { getRequiredClient } from "@/lib/supabase/client";

/**
 * Deletes a contractor from the active company.
 */
export async function deleteContractor(id: string): Promise<void> {
  const client = getRequiredClient();
  const companyId = await getActiveCompanyId();

  const { error } = await client
    .from("contractors")
    .delete()
    .eq("id", id)
    .eq("company_id", companyId);

  if (error) {
    throw new Error(error.message);
  }
}
