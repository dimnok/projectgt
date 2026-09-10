import { getRequiredClient } from "@/lib/supabase/client";
import type { SupabaseClient } from "@supabase/supabase-js";

/**
 * Checks `check_permission` for the signed-in user.
 * Owner always passes (same function as Postgres RLS).
 */
export async function assertPermission(
  module: string,
  action: string
): Promise<{ client: SupabaseClient; userId: string }> {
  const client = getRequiredClient();
  const {
    data: { user },
    error,
  } = await client.auth.getUser();

  if (error || !user) {
    throw new Error("Нужно войти в аккаунт");
  }

  const result = await client.rpc("check_permission", {
    user_id: user.id,
    module_slug: module,
    permission_slug: action,
  });

  if (result.error) {
    throw new Error(result.error.message);
  }

  if (result.data !== true) {
    throw new Error("Недостаточно прав");
  }

  return { client, userId: user.id };
}
