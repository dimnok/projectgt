import { actionsForModule, type RolePermissionMap } from "@/config/permissions";
import { assertPermission } from "@/features/roles/api/assert-permission";
import { getAppModules } from "@/features/roles/api/get-app-modules";
import { roleDbErrorMessage } from "@/features/roles/utils/role.utils";
import { getActiveCompanyId } from "@/lib/supabase/company";

/**
 * Writes only actions shown for each module.
 * Unique key is (role_id, module_code, permission_code) — same as the database.
 */
export async function saveRolePermissions(
  roleId: string,
  map: RolePermissionMap
): Promise<void> {
  const { client } = await assertPermission("roles", "update");
  const companyId = await getActiveCompanyId();
  const [{ data: role, error: roleError }, modules] = await Promise.all([
    client
      .from("roles")
      .select("company_id, is_system")
      .eq("id", roleId)
      .maybeSingle(),
    getAppModules(),
  ]);

  if (roleError) {
    throw new Error(roleError.message);
  }
  if (!role) {
    throw new Error("Роль не найдена");
  }
  if (role.is_system === true) {
    throw new Error("Системную роль нельзя изменить");
  }

  const rows: {
    role_id: string;
    company_id: string;
    module_code: string;
    permission_code: string;
    is_enabled: boolean;
  }[] = [];

  for (const appModule of modules) {
    for (const action of actionsForModule(appModule.code)) {
      rows.push({
        role_id: roleId,
        company_id: role.company_id ?? companyId,
        module_code: appModule.code,
        permission_code: action,
        is_enabled: map[appModule.code]?.[action] === true,
      });
    }
  }

  if (rows.length === 0) {
    return;
  }

  const { error } = await client.from("role_permissions").upsert(rows, {
    onConflict: "role_id,module_code,permission_code",
  });

  if (error) {
    throw new Error(roleDbErrorMessage(error));
  }
}
