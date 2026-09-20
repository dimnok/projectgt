import { assertCanManageUsers } from "@/features/profile/api/can-manage-users";
import { getActiveCompanyId } from "@/lib/supabase/company";

export type UpdateUserPreferWebAppInput = {
  userId: string;
  preferWebApp: boolean;
};

/**
 * Moves a company user to the web app or back to Flutter.
 * Requires `users.update` (same rule as employee linking).
 */
export async function updateUserPreferWebApp({
  userId,
  preferWebApp,
}: UpdateUserPreferWebAppInput): Promise<void> {
  const { client } = await assertCanManageUsers();

  if (!userId) {
    throw new Error("Не указан пользователь");
  }

  const companyId = await getActiveCompanyId();
  const memberResult = await client
    .from("company_members")
    .select("user_id")
    .eq("company_id", companyId)
    .eq("user_id", userId)
    .maybeSingle();

  if (memberResult.error) {
    throw new Error(memberResult.error.message);
  }
  if (!memberResult.data) {
    throw new Error("Пользователь не состоит в активной компании");
  }

  const { error } = await client
    .from("profiles")
    .update({
      prefer_web_app: preferWebApp,
      updated_at: new Date().toISOString(),
    })
    .eq("id", userId);

  if (error) {
    throw new Error(error.message);
  }
}
