import { assertPermission } from "@/features/roles/api/assert-permission";
import { roleDbErrorMessage } from "@/features/roles/utils/role.utils";

export async function deleteCompanyRole(roleId: string): Promise<void> {
  const { client } = await assertPermission("roles", "delete");
  const { data, error: loadError } = await client
    .from("roles")
    .select("is_system")
    .eq("id", roleId)
    .maybeSingle();

  if (loadError) {
    throw new Error(loadError.message);
  }
  if (!data) {
    throw new Error("Роль не найдена");
  }
  if (data.is_system === true) {
    throw new Error("Системную роль нельзя удалить");
  }

  const { error } = await client.from("roles").delete().eq("id", roleId);

  if (error) {
    throw new Error(roleDbErrorMessage(error));
  }
}
