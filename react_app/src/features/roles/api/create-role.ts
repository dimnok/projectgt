import { assertPermission } from "@/features/roles/api/assert-permission";
import type { CompanyRole } from "@/features/roles/types/role.types";
import { roleDbErrorMessage } from "@/features/roles/utils/role.utils";
import { getActiveCompanyId } from "@/lib/supabase/company";

export async function createCompanyRole(input: {
  name: string;
  description: string;
}): Promise<CompanyRole> {
  const { client } = await assertPermission("roles", "create");
  const companyId = await getActiveCompanyId();
  const name = input.name.trim();

  if (!name) {
    throw new Error("Укажите название роли");
  }

  const { data, error } = await client
    .from("roles")
    .insert({
      role_name: name,
      description: input.description.trim() || null,
      is_system: false,
      company_id: companyId,
    })
    .select("id, role_name, description, company_id, is_system")
    .single();

  if (error) {
    throw new Error(roleDbErrorMessage(error));
  }

  return {
    id: data.id,
    name: data.role_name,
    description: data.description?.trim() ?? "",
    companyId: data.company_id,
    isSystem: data.is_system === true,
  };
}
