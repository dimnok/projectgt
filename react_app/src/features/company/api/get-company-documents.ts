import { getActiveCompanyId } from "@/lib/supabase/company";
import { getRequiredClient } from "@/lib/supabase/client";
import type { CompanyDocument } from "@/features/company/types/company.types";
import {
  DOCUMENT_SELECT,
  mapDocumentRow,
} from "@/features/company/utils/company-document";

/** Документы (лицензии, СРО) активной компании. */
export async function getCompanyDocuments(): Promise<CompanyDocument[]> {
  const client = getRequiredClient();
  const companyId = await getActiveCompanyId();

  const { data, error } = await client
    .from("company_documents")
    .select(DOCUMENT_SELECT)
    .eq("company_id", companyId)
    .order("created_at", { ascending: false });

  if (error) {
    throw new Error(error.message);
  }

  return (data ?? []).map(mapDocumentRow);
}
