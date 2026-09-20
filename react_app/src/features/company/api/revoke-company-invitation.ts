import { getRequiredClient } from "@/lib/supabase/client";
import { invitationErrorMessage } from "@/features/company/utils/invitation-error";

/** Отзывает неиспользованное приглашение. */
export async function revokeCompanyInvitation(
  invitationId: string
): Promise<void> {
  const { error } = await getRequiredClient().rpc(
    "revoke_company_invitation",
    { p_invitation_id: invitationId }
  );

  if (error) {
    throw new Error(invitationErrorMessage(error.message));
  }
}
