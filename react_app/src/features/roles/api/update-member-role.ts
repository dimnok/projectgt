import { assertCompanyOwner } from "@/features/company/api/assert-company-owner";
import { roleDbErrorMessage } from "@/features/roles/utils/role.utils";

/**
 * Assigns a custom role. Database allows UPDATE on `company_members`
 * only for the company owner (`get_owned_company_ids`);
 * `assertCompanyOwner` repeats the same check client-side.
 */
export async function updateMemberRole(
  userId: string,
  roleId: string | null
): Promise<void> {
  const { client, companyId } = await assertCompanyOwner();

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
    throw new Error("Пользователь не состоит в активной компании");
  }
}
