import { getRequiredClient } from "@/lib/supabase/client";
import { invitationErrorMessage } from "@/features/company/utils/invitation-error";

/**
 * Joins an existing company by invitation code via `redeem_company_invitation`.
 * Same RPC as the Flutter app.
 */
export async function joinCompany(invitationCode: string): Promise<string> {
  const code = invitationCode.trim().toUpperCase();
  if (!code) {
    throw new Error("Введите код приглашения");
  }

  const { data, error } = await getRequiredClient().rpc(
    "redeem_company_invitation",
    { p_code: code }
  );

  if (error) {
    throw new Error(invitationErrorMessage(error.message));
  }

  return data as string;
}
