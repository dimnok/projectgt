import { getActiveCompanyId } from "@/lib/supabase/company";
import { getRequiredClient } from "@/lib/supabase/client";
import type { CompanyDocument, CompanyDocumentDraft } from "@/features/company/types/company.types";
import {
  DOCUMENT_SELECT,
  mapDocumentRow,
  toDocumentPayload,
} from "@/features/company/utils/company-document";

/** Добавляет документ компании. */
export async function createCompanyDocument(
  draft: CompanyDocumentDraft
): Promise<CompanyDocument> {
  const companyId = await getActiveCompanyId();

  const { data, error } = await getRequiredClient()
    .from("company_documents")
    .insert(toDocumentPayload(companyId, draft))
    .select(DOCUMENT_SELECT)
    .single();

  if (error) {
    throw new Error(error.message);
  }

  return mapDocumentRow(data);
}

/** Обновляет документ компании. */
export async function updateCompanyDocument(
  documentId: string,
  draft: CompanyDocumentDraft
): Promise<CompanyDocument> {
  const companyId = await getActiveCompanyId();

  const { data, error } = await getRequiredClient()
    .from("company_documents")
    .update(toDocumentPayload(companyId, draft))
    .eq("id", documentId)
    .eq("company_id", companyId)
    .select(DOCUMENT_SELECT)
    .single();

  if (error) {
    throw new Error(error.message);
  }

  return mapDocumentRow(data);
}
