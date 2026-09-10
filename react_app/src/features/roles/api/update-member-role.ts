import { roleDbErrorMessage } from "@/features/roles/utils/role.utils";
import { getActiveCompanyId } from "@/lib/supabase/company";
import { getRequiredClient } from "@/lib/supabase/client";

/**
 * Assigns a custom role. Database allows UPDATE on company_members
 * only for the company owner (`get_owned_company_ids`).
 */
export async function updateMemberRole(
  userId: string,
  roleId: string | null
): Promise<void> {
  const client = getRequiredClient();
  const companyId = await getActiveCompanyId();

  const { data, error } = await client
    .from("company_members")
    .update({ role_id: roleId })
    .eq("company_id", companyId)
    .eq("user_id", userId)
    .select("user_id")
    .maybeSingle();

  if (error) {
    throw new Error(roleDbErrorMessage(error));
  }
  if (!data) {
    throw new Error("Назначить роль может только владелец компании");
  }
}
