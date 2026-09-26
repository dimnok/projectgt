import { assertCompanyOwner } from "@/features/company/api/assert-company-owner";

export type UpdateUserStatusInput = {
  userId: string;
  isActive: boolean;
};

/**
 * Turns company access on or off for a member of the active company.
 * Database allows UPDATE on `company_members` only for the company owner
 * (`get_owned_company_ids`); `assertCompanyOwner` repeats the same check
 * client-side for a fast, clear error.
 */
export async function updateUserStatus({
  userId,
  isActive,
}: UpdateUserStatusInput): Promise<void> {
  const { client, userId: callerId, companyId } = await assertCompanyOwner();

  if (!userId) {
    throw new Error("Не указан пользователь");
  }
  if (userId === callerId && !isActive) {
    throw new Error("Нельзя отключить доступ самому себе");
  }

  const { data, error } = await client
    .from("company_members")
    .update({ is_active: isActive })
    .eq("company_id", companyId)
    .eq("user_id", userId)
    .select("user_id")
    .maybeSingle();

  if (error) {
    throw new Error(
      /row-level security|42501/i.test(error.message)
        ? "Менять статус может только владелец компании"
        : error.message
    );
  }
  if (!data) {
    throw new Error("Пользователь не состоит в активной компании");
  }
}
