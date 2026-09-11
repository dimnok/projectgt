import { assertCanManageUsers } from "@/features/profile/api/can-manage-users";
import { getActiveCompanyId } from "@/lib/supabase/company";

export type UpdateUserObjectsInput = {
  userId: string;
  objectIds: string[];
};

function uniqueIds(ids: string[]): string[] {
  return [...new Set(ids.filter((id) => id.length > 0))];
}

/**
 * Assigns construction objects of the active company to a company user.
 * Objects from other companies on the profile are kept.
 * Requires `users.update` (same rule as employee linking).
 */
export async function updateUserObjects({
  userId,
  objectIds,
}: UpdateUserObjectsInput): Promise<void> {
  const { client } = await assertCanManageUsers();

  if (!userId) {
    throw new Error("Не указан пользователь");
  }

  const companyId = await getActiveCompanyId();
  const selected = uniqueIds(objectIds);

  const [memberResult, objectsResult, profileResult] = await Promise.all([
    client
      .from("company_members")
      .select("user_id")
      .eq("company_id", companyId)
      .eq("user_id", userId)
      .maybeSingle(),
    client.from("objects").select("id").eq("company_id", companyId),
    client.from("profiles").select("object_ids").eq("id", userId).maybeSingle(),
  ]);

  if (memberResult.error) {
    throw new Error(memberResult.error.message);
  }
  if (!memberResult.data) {
    throw new Error("Пользователь не состоит в активной компании");
  }

  if (objectsResult.error) {
    throw new Error(objectsResult.error.message);
  }
  if (profileResult.error) {
    throw new Error(profileResult.error.message);
  }
  if (!profileResult.data) {
    throw new Error("Профиль пользователя не найден");
  }

  const companyObjectIds = new Set(
    (objectsResult.data ?? [])
      .map((row) => row.id)
      .filter((id): id is string => typeof id === "string" && id.length > 0)
  );

  const unknown = selected.filter((id) => !companyObjectIds.has(id));
  if (unknown.length > 0) {
    throw new Error("Можно назначать только объекты текущей компании");
  }

  const current = Array.isArray(profileResult.data.object_ids)
    ? profileResult.data.object_ids.filter(
        (id): id is string => typeof id === "string" && id.length > 0
      )
    : [];
  const fromOtherCompanies = current.filter((id) => !companyObjectIds.has(id));
  const nextObjectIds = uniqueIds([...fromOtherCompanies, ...selected]);

  const { error } = await client
    .from("profiles")
    .update({
      object_ids: nextObjectIds,
      updated_at: new Date().toISOString(),
    })
    .eq("id", userId);

  if (error) {
    throw new Error(error.message);
  }
}
