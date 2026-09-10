import { getRequiredClient } from "@/lib/supabase/client";
import { formatPhone } from "@/lib/utils/phone";
import type { ProfileDraft } from "@/features/profile/types/profile.types";
import { generateShortName } from "@/features/profile/utils/profile.utils";

/**
 * Updates the signed-in user's name and phone on `profiles`.
 * Does not change role, status, objects, or company — those live in `company_members`.
 */
export async function updateCurrentProfile(draft: ProfileDraft): Promise<void> {
  const client = getRequiredClient();
  const {
    data: { user },
    error: userError,
  } = await client.auth.getUser();

  if (userError || !user) {
    throw new Error("Нужно войти в аккаунт");
  }

  const fullName = draft.fullName.trim();
  const phone = formatPhone(draft.phone);

  const { error } = await client
    .from("profiles")
    .update({
      full_name: fullName,
      short_name: generateShortName(fullName),
      phone: phone || null,
      updated_at: new Date().toISOString(),
    })
    .eq("id", user.id);

  if (error) {
    throw new Error(error.message);
  }
}
