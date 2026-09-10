import { getActiveCompanyId } from "@/lib/supabase/company";
import { getRequiredClient } from "@/lib/supabase/client";
import { toDateKey } from "@/features/works/utils/work.utils";

/**
 * Id of the current user's open shift in the active company, or null.
 * Same as Flutter `getOpenWorkIdForUser`.
 */
export async function getMyOpenWorkId(): Promise<string | null> {
  const client = getRequiredClient();
  const companyId = await getActiveCompanyId();
  const {
    data: { user },
    error: userError,
  } = await client.auth.getUser();

  if (userError || !user) {
    throw new Error("Нужно войти в аккаунт");
  }

  const { data, error } = await client
    .from("works")
    .select("id")
    .eq("company_id", companyId)
    .eq("opened_by", user.id)
    .eq("status", "open")
    .limit(1)
    .maybeSingle();

  if (error) {
    throw new Error(error.message);
  }

  return data?.id ?? null;
}

/**
 * Object ids assigned to the signed-in profile.
 * Same filter as Flutter work open form (`profile.objectIds`).
 */
export async function getProfileObjectIds(): Promise<string[]> {
  const client = getRequiredClient();
  const {
    data: { user },
    error: userError,
  } = await client.auth.getUser();

  if (userError || !user) {
    throw new Error("Нужно войти в аккаунт");
  }

  const { data, error } = await client
    .from("profiles")
    .select("object_ids")
    .eq("id", user.id)
    .maybeSingle();

  if (error) {
    throw new Error(error.message);
  }

  const raw = data?.object_ids;
  if (!Array.isArray(raw)) {
    return [];
  }
  return raw.filter((id): id is string => typeof id === "string" && id.length > 0);
}

/**
 * Employees already listed on an open shift today.
 * Same as Flutter `_getEmployeesInOpenShifts`.
 */
export async function getOccupiedEmployeeIdsToday(): Promise<string[]> {
  const client = getRequiredClient();
  const companyId = await getActiveCompanyId();
  const today = toDateKey(new Date());

  const { data, error } = await client
    .from("works")
    .select("work_hours(employee_id)")
    .eq("company_id", companyId)
    .eq("date", today)
    .eq("status", "open");

  if (error) {
    throw new Error(error.message);
  }

  const ids = new Set<string>();
  for (const work of data ?? []) {
    const hours = work.work_hours as { employee_id?: string }[] | null;
    if (!hours) {
      continue;
    }
    for (const row of hours) {
      if (row.employee_id) {
        ids.add(row.employee_id);
      }
    }
  }
  return [...ids];
}
