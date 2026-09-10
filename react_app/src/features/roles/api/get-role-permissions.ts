import type { RolePermissionMap } from "@/config/permissions";
import { getRequiredClient } from "@/lib/supabase/client";

export const myRolePermissionsQueryKey = (roleId: string | null) =>
  ["my-role-permissions", roleId] as const;

export const rolePermissionsQueryKey = (roleId: string) =>
  ["role-permissions", roleId] as const;

type PermissionRow = {
  module_code: string;
  permission_code: string;
  is_enabled: boolean | null;
};

/**
 * Loads enabled flags for a role. Does not filter by company_id:
 * `check_permission` also reads the unique (role, module, action) row.
 */
export async function getRolePermissions(
  roleId: string
): Promise<RolePermissionMap> {
  const client = getRequiredClient();
  const { data, error } = await client
    .from("role_permissions")
    .select("module_code, permission_code, is_enabled")
    .eq("role_id", roleId);

  if (error) {
    throw new Error(error.message);
  }

  const map: RolePermissionMap = {};

  for (const row of (data ?? []) as PermissionRow[]) {
    map[row.module_code] ??= {};
    map[row.module_code][row.permission_code] = row.is_enabled === true;
  }

  return map;
}
