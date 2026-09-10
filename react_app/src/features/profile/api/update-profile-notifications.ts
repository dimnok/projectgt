import { getRequiredClient } from "@/lib/supabase/client";

/**
 * Updates the user's shift reminder slot times in `profiles.slot_times`.
 * Matches Flutter `NotificationsSettingsScreen` logic.
 */
export async function updateProfileNotifications(
  slotTimes: string[]
): Promise<void> {
  const client = getRequiredClient();
  const {
    data: { user },
    error: userError,
  } = await client.auth.getUser();

  if (userError || !user) {
    throw new Error("Нужно войти в аккаунт");
  }

  const { error } = await client
    .from("profiles")
    .update({
      slot_times: slotTimes,
      updated_at: new Date().toISOString(),
    })
    .eq("id", user.id);

  if (error) {
    throw new Error(error.message);
  }
}
