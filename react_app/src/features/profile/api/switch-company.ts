import { getRequiredClient } from "@/lib/supabase/client";

/**
 * Sets the active company for the signed-in user (`profiles.last_company_id`).
 * Same field as Flutter `switchCompany`.
 */
export async function switchActiveCompany(companyId: string): Promise<void> {
  const client = getRequiredClient();
  const {
    data: { user },
    error: userError,
  } = await client.auth.getUser();

  if (userError || !user) {
    throw new Error("Нужно войти в аккаунт");
  }

  const { data: membership, error: membershipError } = await client
    .from("company_members")
    .select("company_id")
    .eq("user_id", user.id)
    .eq("company_id", companyId)
    .eq("is_active", true)
    .maybeSingle();

  if (membershipError) {
    throw new Error(membershipError.message);
  }

  if (!membership) {
    throw new Error("Нет доступа к этой компании");
  }

  const { error } = await client
    .from("profiles")
    .update({
      last_company_id: companyId,
      updated_at: new Date().toISOString(),
    })
    .eq("id", user.id);

  if (error) {
    throw new Error(error.message);
  }
}
