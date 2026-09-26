import { getActiveCompanyId } from "@/lib/supabase/company";
import { getRequiredClient } from "@/lib/supabase/client";
import type { SupabaseClient } from "@supabase/supabase-js";

/**
 * Ensures the signed-in user owns the active company.
 * Same rule as the database: UPDATE on `company_members` is allowed
 * only via `get_owned_company_ids` (member with `is_owner = true`),
 * so super-admin and role permissions do not count here.
 */
export async function assertCompanyOwner(): Promise<{
  client: SupabaseClient;
  userId: string;
  companyId: string;
}> {
  const client = getRequiredClient();
  const {
    data: { user },
    error,
  } = await client.auth.getUser();

  if (error || !user) {
    throw new Error("Нужно войти в аккаунт");
  }

  const companyId = await getActiveCompanyId();
  const { data: membership, error: memberError } = await client
    .from("company_members")
    .select("is_owner")
    .eq("company_id", companyId)
    .eq("user_id", user.id)
    .maybeSingle();

  if (memberError) {
    throw new Error(memberError.message);
  }
  if (membership?.is_owner !== true) {
    throw new Error("Управлять участниками может только владелец компании");
  }

  return { client, userId: user.id, companyId };
}
