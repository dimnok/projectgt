import { assertCanManageUsers } from "@/features/profile/api/can-manage-users";

export type LinkProfileEmployeeInput = {
  userId: string;
  employeeId: string | null;
};

/**
 * Links or unlinks an employee card for a company user.
 * Allowed only for users with `users.update` (owner, super-admin, admin).
 */
export async function linkProfileEmployee({
  userId,
  employeeId,
}: LinkProfileEmployeeInput): Promise<void> {
  const { client } = await assertCanManageUsers();

  if (!userId) {
    throw new Error("Не указан пользователь");
  }

  const { data: existingProfile, error: profileError } = await client
    .from("profiles")
    .select("object")
    .eq("id", userId)
    .maybeSingle();

  if (profileError) {
    throw new Error(profileError.message);
  }
  if (!existingProfile) {
    throw new Error("Профиль пользователя не найден");
  }

  const currentObject =
    existingProfile.object && typeof existingProfile.object === "object"
      ? { ...(existingProfile.object as Record<string, unknown>) }
      : {};

  if (employeeId) {
    currentObject.employee_id = employeeId;
  } else {
    delete currentObject.employee_id;
  }

  const { error } = await client
    .from("profiles")
    .update({
      employee_id: employeeId || null,
      object: currentObject,
      updated_at: new Date().toISOString(),
    })
    .eq("id", userId);

  if (error) {
    throw new Error(error.message);
  }
}
