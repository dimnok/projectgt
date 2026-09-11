import { getRequiredClient } from "@/lib/supabase/client";
import type { SupabaseClient } from "@supabase/supabase-js";

/**
 * Same rule as Flutter Users list: `check_permission(..., 'users', 'update')`.
 * Owner always passes. Super-admin and «Админ» have this permission.
 */
export async function canManageUsers(
  client: SupabaseClient,
  userId: string
): Promise<boolean> {
  const [permissionResult, superAdminResult] = await Promise.all([
    client.rpc("check_permission", {
      user_id: userId,
      module_slug: "users",
      permission_slug: "update",
    }),
    client.rpc("is_super_admin", { user_id: userId }),
  ]);

  if (permissionResult.error) {
    throw new Error(permissionResult.error.message);
  }
  if (superAdminResult.error) {
    throw new Error(superAdminResult.error.message);
  }

  return permissionResult.data === true || superAdminResult.data === true;
}

/**
 * Ensures the signed-in user may assign employee cards to user accounts.
 */
export async function assertCanManageUsers(): Promise<{
  client: SupabaseClient;
  userId: string;
}> {
  const client = getRequiredClient();
  const {
    data: { user },
    error,
  } = await client.auth.getUser();

  if (error || !user) {
    throw new Error("Нужно войти в аккаунт");
  }

  const allowed = await canManageUsers(client, user.id);
  if (!allowed) {
    throw new Error(
      "Объекты и карточку сотрудника может менять только супер-админ или руководитель"
    );
  }

  return { client, userId: user.id };
}
