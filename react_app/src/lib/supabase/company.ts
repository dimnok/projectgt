import { getRequiredClient } from "@/lib/supabase/client";

/**
 * Reads the active company from the signed-in user's profile.
 * Matches Flutter's `activeCompanyIdProvider` (`profiles.last_company_id`).
 */
export async function getActiveCompanyId(): Promise<string> {
  const client = getRequiredClient();
  const {
    data: { user },
    error: userError,
  } = await client.auth.getUser();

  if (userError || !user) {
    throw new Error("Нужно войти в аккаунт");
  }

  const { data, error } = await client
    .from("profiles")
    .select("last_company_id")
    .eq("id", user.id)
    .maybeSingle();

  if (error) {
    throw new Error(error.message);
  }

  const companyId = data?.last_company_id;
  if (typeof companyId !== "string" || !companyId) {
    throw new Error("Активная компания не выбрана");
  }

  return companyId;
}
