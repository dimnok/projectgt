import { getActiveCompanyId } from "@/lib/supabase/company";
import { getRequiredClient } from "@/lib/supabase/client";

/** Удаляет документ компании. */
export async function deleteCompanyDocument(documentId: string): Promise<void> {
  const companyId = await getActiveCompanyId();

  const { error } = await getRequiredClient()
    .from("company_documents")
    .delete()
    .eq("id", documentId)
    .eq("company_id", companyId);

  if (error) {
    throw new Error(error.message);
  }
}
