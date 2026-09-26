import { getRequiredClient } from "@/lib/supabase/client";
import type { SupabaseClient } from "@supabase/supabase-js";

/**
 * `true`, если у пользователя системная роль «Супер-админ».
 * Та же проверка, что в базе (`is_super_admin`).
 */
export async function isSuperAdmin(
  client: SupabaseClient,
  userId: string
): Promise<boolean> {
  const { data, error } = await client.rpc("is_super_admin", {
    user_id: userId,
  });

  if (error) {
    throw new Error(error.message);
  }

  return data === true;
}

/**
 * Same rule as Flutter Users list: `check_permission(..., 'users', 'update')`.
 * Owner always passes. Super-admin and «Админ» have this permission.
 */
export async function canManageUsers(
  client: SupabaseClient,
  userId: string
): Promise<boolean> {
  const [permissionResult, superAdmin] = await Promise.all([
    client.rpc("check_permission", {
      user_id: userId,
      module_slug: "users",
      permission_slug: "update",
    }),
    isSuperAdmin(client, userId),
  ]);

  if (permissionResult.error) {
    throw new Error(permissionResult.error.message);
  }

  return permissionResult.data === true || superAdmin;
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
