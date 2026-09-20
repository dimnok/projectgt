import { getActiveCompanyId } from "@/lib/supabase/company";
import { getRequiredClient } from "@/lib/supabase/client";
import type { CompanyInvitation } from "@/features/company/types/company.types";
import { mapInvitationRow } from "@/features/company/utils/company-invitation";
import { invitationErrorMessage } from "@/features/company/utils/invitation-error";

/** Создаёт код приглашения (владелец или админ). */
export async function createCompanyInvitation(
  expiresInDays = 7
): Promise<CompanyInvitation> {
  const companyId = await getActiveCompanyId();

  const { data, error } = await getRequiredClient().rpc(
    "create_company_invitation",
    { p_company_id: companyId, p_expires_in_days: expiresInDays }
  );

  if (error) {
    throw new Error(invitationErrorMessage(error.message));
  }

  return mapInvitationRow(data as Parameters<typeof mapInvitationRow>[0]);
}
