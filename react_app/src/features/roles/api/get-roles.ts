import type { CompanyRole } from "@/features/roles/types/role.types";
import { getActiveCompanyId } from "@/lib/supabase/company";
import { getRequiredClient } from "@/lib/supabase/client";

export const companyRolesQueryKey = ["company-roles"] as const;

type RoleRow = {
  id: string;
  role_name: string;
  description: string | null;
  company_id: string | null;
  is_system: boolean | null;
};

/**
 * System roles (company_id is null) plus roles of the active company.
 */
export async function getCompanyRoles(): Promise<CompanyRole[]> {
  const client = getRequiredClient();
  const companyId = await getActiveCompanyId();

  const { data, error } = await client
    .from("roles")
    .select("id, role_name, description, company_id, is_system")
    .or(`company_id.is.null,company_id.eq.${companyId}`);

  if (error) {
    throw new Error(error.message);
  }

  return ((data ?? []) as RoleRow[]).map((row) => ({
    id: row.id,
    name: row.role_name,
    description: row.description?.trim() ?? "",
    companyId: row.company_id,
    isSystem: row.is_system === true,
  }));
}
