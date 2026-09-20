import { getActiveCompanyId } from "@/lib/supabase/company";
import { getRequiredClient } from "@/lib/supabase/client";
import type { CompanyInvitation } from "@/features/company/types/company.types";
import {
  INVITATION_SELECT,
  mapInvitationRow,
} from "@/features/company/utils/company-invitation";

/** Последние приглашения активной компании. */
export async function getCompanyInvitations(): Promise<CompanyInvitation[]> {
  const companyId = await getActiveCompanyId();

  const { data, error } = await getRequiredClient()
    .from("company_invitations")
    .select(INVITATION_SELECT)
    .eq("company_id", companyId)
    .order("created_at", { ascending: false })
    .limit(20);

  if (error) {
    throw new Error(error.message);
  }

  return (data ?? []).map(mapInvitationRow);
}
